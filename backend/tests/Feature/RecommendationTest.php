<?php

namespace Tests\Feature;

use App\Models\Game;
use App\Models\Genre;
use App\Models\LibraryEntry;
use App\Models\Platform;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class RecommendationTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected string $token;

    protected function setUp(): void
    {
        parent::setUp();
        Cache::flush();

        $this->user = User::factory()->create([
            'nama'  => 'Test Explorer',
            'email' => 'explorer@test.com',
        ]);
        $this->token = $this->user->createToken('test_token')->plainTextToken;
    }

    protected function authHeaders(?string $customToken = null): array
    {
        return [
            'Authorization' => 'Bearer ' . ($customToken ?? $this->token),
            'Accept'        => 'application/json',
        ];
    }

    /**
     * 1. Akses tanpa token mengembalikan status 401
     */
    public function test_unauthenticated_access_without_token_returns_401(): void
    {
        $this->getJson('/api/recommendations')->assertStatus(401);
        $this->getJson('/api/games/1/similar')->assertStatus(401);
    }

    /**
     * 2. Pengguna tanpa library mendapat daftar kosong dengan pesan penjelasan
     */
    public function test_user_without_library_returns_empty_list_with_informative_message(): void
    {
        $response = $this->withHeaders($this->authHeaders())
            ->getJson('/api/recommendations');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data'    => [],
            ]);

        $this->assertStringContainsString('Tambahkan game ke library', $response->json('message'));
    }

    /**
     * 3. Game bersatus Dropped tidak memengaruhi genre, dan jika hanya ada game Dropped respons kosong
     */
    public function test_dropped_games_do_not_affect_genres_and_only_dropped_returns_empty(): void
    {
        $horrorGenre = Genre::create(['nama' => 'Horror', 'rawg_id' => 10]);
        $rpgGenre    = Genre::create(['nama' => 'RPG', 'rawg_id' => 5]);

        $horrorGame = Game::create(['judul' => 'Scary Night', 'rawg_id' => 1001, 'rating' => 4.0, 'cached_at' => now()]);
        $horrorGame->genres()->attach($horrorGenre->id);

        // Kasus A: Hanya ada game Dropped
        $entry = LibraryEntry::create([
            'user_id' => $this->user->id,
            'game_id' => $horrorGame->id,
            'status'  => 'Dropped',
        ]);

        $resA = $this->withHeaders($this->authHeaders())->getJson('/api/recommendations');
        $resA->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data'    => [],
            ]);

        // Kasus B: Tambah game RPG dengan status Backlog
        $rpgGame = Game::create(['judul' => 'Fantasy Quest', 'rawg_id' => 1002, 'rating' => 4.5, 'cached_at' => now()]);
        $rpgGame->genres()->attach($rpgGenre->id);

        LibraryEntry::create([
            'user_id' => $this->user->id,
            'game_id' => $rpgGame->id,
            'status'  => 'Backlog',
        ]);

        // Buat kandidat di database
        $candHorror = Game::create(['judul' => 'Another Horror', 'rawg_id' => 2001, 'rating' => 4.8, 'cached_at' => now()]);
        $candHorror->genres()->attach($horrorGenre->id);

        $candRpg = Game::create(['judul' => 'Another RPG', 'rawg_id' => 2002, 'rating' => 4.2, 'cached_at' => now()]);
        $candRpg->genres()->attach($rpgGenre->id);

        // Mock RAWG agar tidak terpanggil atau mengembalikan kosong
        Http::fake([
            'https://api.rawg.io/api/games*' => Http::response(['results' => []], 200),
        ]);

        Cache::flush();
        $resB = $this->withHeaders($this->authHeaders())->getJson('/api/recommendations');
        $resB->assertStatus(200);

        $titles = collect($resB->json('data'))->pluck('judul')->toArray();
        $this->assertContains('Another RPG', $titles);
        $this->assertNotContains('Another Horror', $titles);
    }

    /**
     * 4. Rekomendasi memakai genre teratas library dengan aturan bobot
     */
    public function test_recommendations_use_top_genres_from_library_with_weights(): void
    {
        $actionGenre    = Genre::create(['nama' => 'Action', 'rawg_id' => 4]);
        $adventureGenre = Genre::create(['nama' => 'Adventure', 'rawg_id' => 3]);
        $puzzleGenre    = Genre::create(['nama' => 'Puzzle', 'rawg_id' => 7]);
        $sportsGenre    = Genre::create(['nama' => 'Sports', 'rawg_id' => 15]);

        // Game 1: Tamat & rating 9 (Bobot: 1 base + 1 Tamat + 1 rating >= 8 = 3 untuk Action & Adventure)
        $game1 = Game::create(['judul' => 'Uncharted 4', 'rawg_id' => 3001, 'rating' => 4.7, 'cached_at' => now()]);
        $game1->genres()->attach([$actionGenre->id, $adventureGenre->id]);
        LibraryEntry::create([
            'user_id'        => $this->user->id,
            'game_id'        => $game1->id,
            'status'         => 'Tamat',
            'rating_pribadi' => 9,
        ]);

        // Game 2: Sedang Dimainkan (Bobot: 1 base + 1 Sedang Dimainkan = 2 untuk Action) -> Total Action = 5
        $game2 = Game::create(['judul' => 'Doom Eternal', 'rawg_id' => 3002, 'rating' => 4.6, 'cached_at' => now()]);
        $game2->genres()->attach([$actionGenre->id]);
        LibraryEntry::create([
            'user_id' => $this->user->id,
            'game_id' => $game2->id,
            'status'  => 'Sedang Dimainkan',
        ]);

        // Game 3: Backlog tanpa rating (Bobot: 1 base untuk Puzzle)
        $game3 = Game::create(['judul' => 'Tetris Effect', 'rawg_id' => 3003, 'rating' => 4.2, 'cached_at' => now()]);
        $game3->genres()->attach([$puzzleGenre->id]);
        LibraryEntry::create([
            'user_id' => $this->user->id,
            'game_id' => $game3->id,
            'status'  => 'Backlog',
        ]);

        // Kandidat di DB:
        // Cand 1: Action + Adventure (cocok 2 genre teratas)
        $cand1 = Game::create(['judul' => 'Tomb Raider', 'rawg_id' => 4001, 'rating' => 4.1, 'cached_at' => now()]);
        $cand1->genres()->attach([$actionGenre->id, $adventureGenre->id]);

        // Cand 2: Action only, rating tinggi
        $cand2 = Game::create(['judul' => 'God of War', 'rawg_id' => 4002, 'rating' => 4.9, 'cached_at' => now()]);
        $cand2->genres()->attach([$actionGenre->id]);

        // Cand 3: Puzzle only
        $cand3 = Game::create(['judul' => 'The Witness', 'rawg_id' => 4003, 'rating' => 4.3, 'cached_at' => now()]);
        $cand3->genres()->attach([$puzzleGenre->id]);

        // Cand 4: Sports (bukan genre favorit)
        $cand4 = Game::create(['judul' => 'FIFA 23', 'rawg_id' => 4004, 'rating' => 4.9, 'cached_at' => now()]);
        $cand4->genres()->attach([$sportsGenre->id]);

        Http::fake([
            'https://api.rawg.io/api/games*' => Http::response(['results' => []], 200),
        ]);

        $response = $this->withHeaders($this->authHeaders())->getJson('/api/recommendations');
        $response->assertStatus(200);

        $data = $response->json('data');
        $this->assertNotEmpty($data);

        // FIFA 23 tidak boleh muncul
        $titles = collect($data)->pluck('judul')->toArray();
        $this->assertNotContains('FIFA 23', $titles);

        // Tomb Raider harus berada di urutan pertama karena cocok 2 genre (Action & Adventure)
        $this->assertEquals('Tomb Raider', $data[0]['judul']);
        $this->assertEquals('Karena kamu suka Action dan Adventure', $data[0]['alasan']);

        // God of War urutan kedua (cocok 1 genre Action, rating 4.9 > 4.3)
        $this->assertEquals('God of War', $data[1]['judul']);
        $this->assertEquals('Karena kamu suka Action', $data[1]['alasan']);
    }

    /**
     * 5. Game yang sudah ada di library tidak muncul di rekomendasi
     */
    public function test_games_already_in_library_do_not_appear_in_recommendations(): void
    {
        $actionGenre = Genre::create(['nama' => 'Action', 'rawg_id' => 4]);

        $ownedGame = Game::create(['judul' => 'Owned Action Game', 'rawg_id' => 5001, 'rating' => 4.5, 'cached_at' => now()]);
        $ownedGame->genres()->attach($actionGenre->id);

        // Masukkan ke library (misalnya status Wishlist)
        LibraryEntry::create([
            'user_id' => $this->user->id,
            'game_id' => $ownedGame->id,
            'status'  => 'Wishlist',
        ]);

        $candidateGame = Game::create(['judul' => 'Unowned Action Game', 'rawg_id' => 5002, 'rating' => 4.7, 'cached_at' => now()]);
        $candidateGame->genres()->attach($actionGenre->id);

        Http::fake([
            'https://api.rawg.io/api/games*' => Http::response(['results' => []], 200),
        ]);

        $response = $this->withHeaders($this->authHeaders())->getJson('/api/recommendations');
        $response->assertStatus(200);

        $titles = collect($response->json('data'))->pluck('judul')->toArray();
        $this->assertContains('Unowned Action Game', $titles);
        $this->assertNotContains('Owned Action Game', $titles);
    }

    /**
     * 6. Hanya data milik sendiri yang dipakai (dua pengguna dengan library berbeda mendapat hasil berbeda)
     */
    public function test_recommendations_only_use_own_user_data_two_users_get_different_results(): void
    {
        $shooterGenre  = Genre::create(['nama' => 'Shooter', 'rawg_id' => 2]);
        $strategyGenre = Genre::create(['nama' => 'Strategy', 'rawg_id' => 10]);

        $userB = User::factory()->create([
            'nama'  => 'Strategy Fan',
            'email' => 'strategy@test.com',
        ]);
        $tokenB = $userB->createToken('token_b')->plainTextToken;

        // User A suka Shooter
        $gameA = Game::create(['judul' => 'Halo Infinite', 'rawg_id' => 6001, 'rating' => 4.2, 'cached_at' => now()]);
        $gameA->genres()->attach($shooterGenre->id);
        LibraryEntry::create(['user_id' => $this->user->id, 'game_id' => $gameA->id, 'status' => 'Tamat']);

        // User B suka Strategy
        $gameB = Game::create(['judul' => 'Civilization VI', 'rawg_id' => 6002, 'rating' => 4.5, 'cached_at' => now()]);
        $gameB->genres()->attach($strategyGenre->id);
        LibraryEntry::create(['user_id' => $userB->id, 'game_id' => $gameB->id, 'status' => 'Tamat']);

        // Kandidat di database
        $candShooter = Game::create(['judul' => 'Titanfall 2', 'rawg_id' => 6003, 'rating' => 4.8, 'cached_at' => now()]);
        $candShooter->genres()->attach($shooterGenre->id);

        $candStrategy = Game::create(['judul' => 'StarCraft II', 'rawg_id' => 6004, 'rating' => 4.7, 'cached_at' => now()]);
        $candStrategy->genres()->attach($strategyGenre->id);

        Http::fake([
            'https://api.rawg.io/api/games*' => Http::response(['results' => []], 200),
        ]);

        $resA = $this->actingAs($this->user, 'sanctum')->getJson('/api/recommendations');
        $resB = $this->actingAs($userB, 'sanctum')->getJson('/api/recommendations');

        $titlesA = collect($resA->json('data'))->pluck('judul')->toArray();
        $titlesB = collect($resB->json('data'))->pluck('judul')->toArray();

        $this->assertContains('Titanfall 2', $titlesA);
        $this->assertNotContains('StarCraft II', $titlesA);

        $this->assertContains('StarCraft II', $titlesB);
        $this->assertNotContains('Titanfall 2', $titlesB);
    }

    /**
     * 7. RAWG gagal tetap mengembalikan data dari database tanpa galat
     */
    public function test_rawg_failure_still_returns_database_candidates(): void
    {
        $racingGenre = Genre::create(['nama' => 'Racing', 'rawg_id' => 1]);

        $game = Game::create(['judul' => 'Forza Horizon 5', 'rawg_id' => 7001, 'rating' => 4.6, 'cached_at' => now()]);
        $game->genres()->attach($racingGenre->id);
        LibraryEntry::create(['user_id' => $this->user->id, 'game_id' => $game->id, 'status' => 'Sedang Dimainkan']);

        // Ada 1 kandidat di DB (karena < 10, controller akan coba call RAWG)
        $cand = Game::create(['judul' => 'Gran Turismo 7', 'rawg_id' => 7002, 'rating' => 4.4, 'cached_at' => now()]);
        $cand->genres()->attach($racingGenre->id);

        // Simulasikan RAWG gagal total (500)
        Http::fake([
            'https://api.rawg.io/api/games*' => Http::response(null, 500),
        ]);

        $response = $this->withHeaders($this->authHeaders())->getJson('/api/recommendations');

        $response->assertStatus(200);
        $titles = collect($response->json('data'))->pluck('judul')->toArray();
        $this->assertContains('Gran Turismo 7', $titles);
    }

    /**
     * 8. Cache terhapus setelah library berubah (tambah, ubah status, atau hapus)
     */
    public function test_recommendations_cache_is_cleared_after_library_changes(): void
    {
        $genre = Genre::create(['nama' => 'Action', 'rawg_id' => 4]);

        $game1 = Game::create(['judul' => 'Game A', 'rawg_id' => 8001, 'rating' => 4.0, 'cached_at' => now()]);
        $game1->genres()->attach($genre->id);
        $entry1 = LibraryEntry::create(['user_id' => $this->user->id, 'game_id' => $game1->id, 'status' => 'Backlog']);

        $cand = Game::create(['judul' => 'Game B', 'rawg_id' => 8002, 'rating' => 4.5, 'cached_at' => now()]);
        $cand->genres()->attach($genre->id);

        Http::fake([
            'https://api.rawg.io/api/games*' => Http::response(['results' => []], 200),
        ]);

        // Panggilan awal -> masuk cache
        $res1 = $this->withHeaders($this->authHeaders())->getJson('/api/recommendations');
        $res1->assertStatus(200);
        $this->assertTrue(Cache::has('user_recommendations_' . $this->user->id));

        // 1. Tambah game baru ke library via POST /api/library
        $game2 = Game::create(['judul' => 'Game C', 'rawg_id' => 8003, 'rating' => 4.2, 'cached_at' => now()]);
        $game2->genres()->attach($genre->id);

        $this->withHeaders($this->authHeaders())->postJson('/api/library', [
            'game_id' => $game2->id,
            'status'  => 'Backlog',
        ])->assertStatus(201);

        $this->assertFalse(Cache::has('user_recommendations_' . $this->user->id));

        // Panggil lagi untuk isi cache
        $this->withHeaders($this->authHeaders())->getJson('/api/recommendations');
        $this->assertTrue(Cache::has('user_recommendations_' . $this->user->id));

        // 2. Ubah status entry via PUT /api/library/{id}
        $this->withHeaders($this->authHeaders())->putJson('/api/library/' . $entry1->id, [
            'status' => 'Tamat',
        ])->assertStatus(200);

        $this->assertFalse(Cache::has('user_recommendations_' . $this->user->id));

        // Panggil lagi untuk isi cache
        $this->withHeaders($this->authHeaders())->getJson('/api/recommendations');
        $this->assertTrue(Cache::has('user_recommendations_' . $this->user->id));

        // 3. Hapus entry via DELETE /api/library/{id}
        $this->withHeaders($this->authHeaders())->deleteJson('/api/library/' . $entry1->id)
            ->assertStatus(200);

        $this->assertFalse(Cache::has('user_recommendations_' . $this->user->id));
    }

    /**
     * 9. Endpoint similar tidak memuat game itu sendiri dan diurutkan berdasarkan kesamaan genre lalu rating
     */
    public function test_similar_games_does_not_include_the_game_itself(): void
    {
        $actionGenre = Genre::create(['nama' => 'Action', 'rawg_id' => 4]);
        $rpgGenre    = Genre::create(['nama' => 'RPG', 'rawg_id' => 5]);

        $targetGame = Game::create(['judul' => 'The Witcher 3', 'rawg_id' => 9001, 'rating' => 4.9, 'cached_at' => now()]);
        $targetGame->genres()->attach([$actionGenre->id, $rpgGenre->id]);

        // Game 1: 2 genre sama, rating 4.5
        $sim1 = Game::create(['judul' => 'Cyberpunk 2077', 'rawg_id' => 9002, 'rating' => 4.5, 'cached_at' => now()]);
        $sim1->genres()->attach([$actionGenre->id, $rpgGenre->id]);

        // Game 2: 1 genre sama, rating 4.8
        $sim2 = Game::create(['judul' => 'Skyrim', 'rawg_id' => 9003, 'rating' => 4.8, 'cached_at' => now()]);
        $sim2->genres()->attach([$rpgGenre->id]);

        // Game 3: 5 game agar total >= 5 dan tidak memicu RAWG
        $sim3 = Game::create(['judul' => 'Elden Ring', 'rawg_id' => 9004, 'rating' => 4.6, 'cached_at' => now()]);
        $sim3->genres()->attach([$actionGenre->id, $rpgGenre->id]);

        $sim4 = Game::create(['judul' => 'Dark Souls 3', 'rawg_id' => 9005, 'rating' => 4.4, 'cached_at' => now()]);
        $sim4->genres()->attach([$actionGenre->id]);

        $sim5 = Game::create(['judul' => 'Bloodborne', 'rawg_id' => 9006, 'rating' => 4.7, 'cached_at' => now()]);
        $sim5->genres()->attach([$actionGenre->id]);

        Http::fake();

        $response = $this->withHeaders($this->authHeaders())
            ->getJson("/api/games/{$targetGame->id}/similar");

        $response->assertStatus(200);
        $data = $response->json('data');

        // Target game tidak boleh ada di hasil
        $titles = collect($data)->pluck('judul')->toArray();
        $this->assertNotContains('The Witcher 3', $titles);

        // Hasil harus memuat game serupa
        $this->assertContains('Cyberpunk 2077', $titles);
        $this->assertContains('Elden Ring', $titles);

        // Cyberpunk & Elden Ring (2 genre sama) harus di urutan sebelum Bloodborne (1 genre sama)
        $cyberpunkIndex = array_search('Cyberpunk 2077', $titles);
        $bloodborneIndex = array_search('Bloodborne', $titles);
        $this->assertLessThan($bloodborneIndex, $cyberpunkIndex);

        // RAWG tidak dipanggil karena sudah ada 5 hasil lokal
        Http::assertNothingSent();
    }

    /**
     * 10. Endpoint similar melengkapi data dari RAWG bila hasil lokal kurang dari 5
     */
    public function test_similar_games_completes_from_rawg_when_fewer_than_five(): void
    {
        $puzzleGenre = Genre::create(['nama' => 'Puzzle', 'rawg_id' => 7]);

        $targetGame = Game::create(['judul' => 'Portal', 'rawg_id' => 9101, 'rating' => 4.7, 'cached_at' => now()]);
        $targetGame->genres()->attach([$puzzleGenre->id]);

        // Hanya 1 game lokal
        $localGame = Game::create(['judul' => 'Portal 2', 'rawg_id' => 9102, 'rating' => 4.8, 'cached_at' => now()]);
        $localGame->genres()->attach([$puzzleGenre->id]);

        // Mock RAWG mengembalikan game puzzle baru
        Http::fake([
            'https://api.rawg.io/api/games*' => Http::response([
                'count'   => 1,
                'results' => [
                    [
                        'id'               => 9103,
                        'name'             => 'The Talos Principle',
                        'background_image' => 'https://media.rawg.io/talos.jpg',
                        'rating'           => 4.5,
                        'released'         => '2014-12-11',
                        'genres'           => [['id' => 7, 'name' => 'Puzzle']],
                        'platforms'        => [],
                    ],
                ],
            ], 200),
        ]);

        $response = $this->withHeaders($this->authHeaders())
            ->getJson("/api/games/{$targetGame->id}/similar");

        $response->assertStatus(200);
        $titles = collect($response->json('data'))->pluck('judul')->toArray();

        $this->assertContains('Portal 2', $titles);
        $this->assertContains('The Talos Principle', $titles);
        $this->assertNotContains('Portal', $titles);
    }
}
