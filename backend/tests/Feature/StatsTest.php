<?php

namespace Tests\Feature;

use App\Models\Game;
use App\Models\Genre;
use App\Models\LibraryEntry;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;

class StatsTest extends TestCase
{
    use RefreshDatabase;

    protected User $user1;
    protected User $user2;
    protected string $token1;
    protected string $token2;

    protected function setUp(): void
    {
        parent::setUp();

        Cache::flush();

        $this->user1 = User::factory()->create([
            'nama'  => 'User Statistik Satu',
            'email' => 'stats1@test.com',
        ]);
        $this->token1 = $this->user1->createToken('token1')->plainTextToken;

        $this->user2 = User::factory()->create([
            'nama'  => 'User Statistik Dua',
            'email' => 'stats2@test.com',
        ]);
        $this->token2 = $this->user2->createToken('token2')->plainTextToken;
    }

    protected function authHeaders(string $token): array
    {
        return [
            'Authorization' => 'Bearer ' . $token,
            'Accept'        => 'application/json',
        ];
    }

    /**
     * 1. Pengguna tanpa data mendapat nilai nol dan daftar kosong, bukan galat (200 OK)
     */
    public function test_stats_for_user_without_data(): void
    {
        $response = $this->getJson('/api/stats', $this->authHeaders($this->token1));

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Statistik bermain berhasil diambil',
                'data'    => [
                    'total_game'    => 0,
                    'total_jam'     => 0.0,
                    'jumlah_tamat'  => 0,
                    'genre_favorit' => [],
                ],
            ]);

        $monthly = $response->json('data.game_tamat_per_bulan');
        $this->assertIsArray($monthly);
        $this->assertCount(12, $monthly);

        foreach ($monthly as $item) {
            $this->assertEquals(0, $item['jumlah']);
            $this->assertArrayHasKey('label', $item);
            $this->assertArrayHasKey('periode', $item);
        }
    }

    /**
     * 2. Statistik benar untuk data library campuran:
     * total_game, total_jam, jumlah_tamat, game_tamat_per_bulan (12 bulan), genre_favorit (max 5)
     */
    public function test_stats_with_mixed_library_data(): void
    {
        // Buat master genres
        $genreRpg = Genre::create(['nama' => 'RPG']);
        $genreAction = Genre::create(['nama' => 'Action']);
        $genreAdventure = Genre::create(['nama' => 'Adventure']);
        $genreStrategy = Genre::create(['nama' => 'Strategy']);
        $genreShooter = Genre::create(['nama' => 'Shooter']);
        $genrePuzzle = Genre::create(['nama' => 'Puzzle']);

        // Game 1: RPG, Action
        $game1 = Game::create(['rawg_id' => 701, 'judul' => 'The Witcher 3']);
        $game1->genres()->attach([$genreRpg->id, $genreAction->id]);

        // Game 2: RPG, Adventure
        $game2 = Game::create(['rawg_id' => 702, 'judul' => 'Skyrim']);
        $game2->genres()->attach([$genreRpg->id, $genreAdventure->id]);

        // Game 3: Action, Shooter
        $game3 = Game::create(['rawg_id' => 703, 'judul' => 'Doom Eternal']);
        $game3->genres()->attach([$genreAction->id, $genreShooter->id]);

        // Game 4: Strategy
        $game4 = Game::create(['rawg_id' => 704, 'judul' => 'Civilization VI']);
        $game4->genres()->attach([$genreStrategy->id]);

        // Game 5: Puzzle
        $game5 = Game::create(['rawg_id' => 705, 'judul' => 'Portal 2']);
        $game5->genres()->attach([$genrePuzzle->id]);

        // Library entries User 1:
        // Entry 1: Tamat di bulan ini
        LibraryEntry::create([
            'user_id'        => $this->user1->id,
            'game_id'        => $game1->id,
            'status'         => 'Tamat',
            'jam_main'       => 50.5,
            'tanggal_tamat'  => now()->toDateString(),
        ]);

        // Entry 2: Tamat di 2 bulan lalu
        LibraryEntry::create([
            'user_id'        => $this->user1->id,
            'game_id'        => $game2->id,
            'status'         => 'Tamat',
            'jam_main'       => 40.0,
            'tanggal_tamat'  => now()->copy()->subMonths(2)->startOfMonth()->toDateString(),
        ]);

        // Entry 3: Sedang Dimainkan
        LibraryEntry::create([
            'user_id'        => $this->user1->id,
            'game_id'        => $game3->id,
            'status'         => 'Sedang Dimainkan',
            'jam_main'       => 15.25,
            'tanggal_tamat'  => null,
        ]);

        // Entry 4: Backlog
        LibraryEntry::create([
            'user_id'        => $this->user1->id,
            'game_id'        => $game4->id,
            'status'         => 'Backlog',
            'jam_main'       => 0.0,
            'tanggal_tamat'  => null,
        ]);

        // Entry 5: Dropped
        LibraryEntry::create([
            'user_id'        => $this->user1->id,
            'game_id'        => $game5->id,
            'status'         => 'Dropped',
            'jam_main'       => 4.25,
            'tanggal_tamat'  => null,
        ]);

        $response = $this->getJson('/api/stats', $this->authHeaders($this->token1));

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data'    => [
                    'total_game'   => 5,
                    'total_jam'    => 110.0, // 50.5 + 40.0 + 15.25 + 0.0 + 4.25 = 110.0
                    'jumlah_tamat' => 2,
                ],
            ]);

        // Cek game_tamat_per_bulan
        $monthly = $response->json('data.game_tamat_per_bulan');
        $this->assertCount(12, $monthly);

        // Terakhir (bulan ini) harus berjumlah 1
        $currentMonthItem = end($monthly);
        $this->assertEquals(now()->format('Y-m'), $currentMonthItem['periode']);
        $this->assertEquals(1, $currentMonthItem['jumlah']);

        // Bulan ke-3 dari belakang (2 bulan lalu) harus berjumlah 1
        $twoMonthsAgoPeriod = now()->copy()->subMonths(2)->format('Y-m');
        $found = false;
        foreach ($monthly as $item) {
            if ($item['periode'] === $twoMonthsAgoPeriod) {
                $this->assertEquals(1, $item['jumlah']);
                $found = true;
            }
        }
        $this->assertTrue($found);

        // Cek genre_favorit:
        // game1 (RPG, Action), game2 (RPG, Adventure), game3 (Action, Shooter), game4 (Strategy), game5 (Puzzle)
        // Hitungan per genre di library user:
        // RPG: 2 (game1, game2)
        // Action: 2 (game1, game3)
        // Adventure: 1 (game2)
        // Shooter: 1 (game3)
        // Strategy: 1 (game4)
        // Puzzle: 1 (game5)
        // Maksimal 5 teratas
        $genres = $response->json('data.genre_favorit');
        $this->assertCount(5, $genres);
        // Dua genre teratas harus berfrekuensi 2 (Action dan RPG)
        $this->assertEquals(2, $genres[0]['jumlah']);
        $this->assertEquals(2, $genres[1]['jumlah']);
        $topGenreNames = [$genres[0]['nama'], $genres[1]['nama']];
        $this->assertContains('Action', $topGenreNames);
        $this->assertContains('RPG', $topGenreNames);
    }

    /**
     * 3. Statistik hanya menghitung data milik pengguna yang sedang login
     */
    public function test_stats_only_aggregates_own_data(): void
    {
        $game1 = Game::create(['rawg_id' => 711, 'judul' => 'Game User 1']);
        $game2 = Game::create(['rawg_id' => 712, 'judul' => 'Game User 2']);

        // User 1 punya 1 game tamat
        LibraryEntry::create([
            'user_id'       => $this->user1->id,
            'game_id'       => $game1->id,
            'status'        => 'Tamat',
            'jam_main'      => 20.0,
            'tanggal_tamat' => now()->toDateString(),
        ]);

        // User 2 punya 1 game tamat dengan jam main 100 jam
        LibraryEntry::create([
            'user_id'       => $this->user2->id,
            'game_id'       => $game2->id,
            'status'        => 'Tamat',
            'jam_main'      => 100.0,
            'tanggal_tamat' => now()->toDateString(),
        ]);

        // Query stats untuk User 1
        $response = $this->getJson('/api/stats', $this->authHeaders($this->token1));

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data'    => [
                    'total_game'   => 1,
                    'total_jam'    => 20.0,
                    'jumlah_tamat' => 1,
                ],
            ]);
    }

    /**
     * 4. Akses tanpa token mengembalikan status 401
     */
    public function test_unauthenticated_access_returns_401(): void
    {
        $this->getJson('/api/stats')->assertStatus(401);
    }
}
