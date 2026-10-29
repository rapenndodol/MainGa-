<?php

namespace Tests\Feature;

use App\Models\Game;
use App\Models\Genre;
use App\Models\Platform;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class GameTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected string $token;

    protected function setUp(): void
    {
        parent::setUp();

        Cache::flush();

        $this->user = User::factory()->create([
            'nama'  => 'Test Gamer',
            'email' => 'gamer@test.com',
        ]);
        $this->token = $this->user->createToken('test_token')->plainTextToken;
    }

    protected function authHeaders(): array
    {
        return [
            'Authorization' => 'Bearer ' . $this->token,
            'Accept'        => 'application/json',
        ];
    }

    /**
     * Uji akses tanpa token mengembalikan status 401
     */
    public function test_unauthenticated_access_without_token_returns_401(): void
    {
        $this->getJson('/api/games')->assertStatus(401);
        $this->getJson('/api/games/1')->assertStatus(401);
        $this->getJson('/api/genres')->assertStatus(401);
        $this->getJson('/api/platforms')->assertStatus(401);
    }

    /**
     * Uji endpoint master genres dan platforms
     */
    public function test_genres_and_platforms_endpoints(): void
    {
        Genre::create(['nama' => 'Action', 'rawg_id' => 4]);
        Genre::create(['nama' => 'RPG', 'rawg_id' => 5]);

        Platform::create(['nama' => 'PC', 'rawg_id' => 4]);
        Platform::create(['nama' => 'PlayStation 5', 'rawg_id' => 187]);

        $genreResponse = $this->withHeaders($this->authHeaders())->getJson('/api/genres');
        $genreResponse->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonCount(2, 'data');

        $platformResponse = $this->withHeaders($this->authHeaders())->getJson('/api/platforms');
        $platformResponse->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonCount(2, 'data');
    }

    /**
     * Uji pencarian game dengan Http::fake dan caching ke database
     */
    public function test_search_games_with_http_fake(): void
    {
        Http::fake([
            'https://api.rawg.io/api/games*' => Http::response([
                'count' => 1,
                'results' => [
                    [
                        'id'               => 3498,
                        'name'             => 'Grand Theft Auto V',
                        'background_image' => 'https://media.rawg.io/media/games/gta5.jpg',
                        'rating'           => 4.47,
                        'released'         => '2013-09-17',
                        'genres'           => [
                            ['id' => 4, 'name' => 'Action'],
                        ],
                        'platforms'        => [
                            ['platform' => ['id' => 4, 'name' => 'PC']],
                        ],
                    ],
                ],
            ], 200),
        ]);

        $response = $this->withHeaders($this->authHeaders())
            ->getJson('/api/games?search=Grand');

        $response->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'games' => [
                        '*' => [
                            'id',
                            'rawg_id',
                            'judul',
                            'cover_url',
                            'genre',
                            'platform',
                            'rating',
                            'tanggal_rilis',
                        ],
                    ],
                    'pagination' => [
                        'current_page',
                        'last_page',
                        'per_page',
                        'total',
                    ],
                ],
            ]);

        // Verifikasi game tersimpan di tabel games database
        $this->assertDatabaseHas('games', [
            'rawg_id' => 3498,
            'judul'   => 'Grand Theft Auto V',
        ]);

        // Verifikasi relasi pivot tersimpan
        $game = Game::where('rawg_id', 3498)->first();
        $this->assertNotNull($game->cached_at);
        $this->assertTrue($game->genres()->where('nama', 'Action')->exists());
        $this->assertTrue($game->platforms()->where('nama', 'PC')->exists());
    }

    /**
     * Uji filter genre, platform, dan rating minimum
     */
    public function test_filter_games_by_genre_platform_and_rating(): void
    {
        Genre::create(['nama' => 'Action', 'rawg_id' => 4]);
        Platform::create(['nama' => 'PC', 'rawg_id' => 4]);

        Http::fake([
            'https://api.rawg.io/api/games*' => Http::response([
                'count' => 2,
                'results' => [
                    [
                        'id'               => 101,
                        'name'             => 'High Rating Game',
                        'background_image' => 'https://media.rawg.io/high.jpg',
                        'rating'           => 4.5,
                        'released'         => '2022-01-01',
                        'genres'           => [['id' => 4, 'name' => 'Action']],
                        'platforms'        => [['platform' => ['id' => 4, 'name' => 'PC']]],
                    ],
                    [
                        'id'               => 102,
                        'name'             => 'Low Rating Game',
                        'background_image' => 'https://media.rawg.io/low.jpg',
                        'rating'           => 2.8,
                        'released'         => '2021-01-01',
                        'genres'           => [['id' => 4, 'name' => 'Action']],
                        'platforms'        => [['platform' => ['id' => 4, 'name' => 'PC']]],
                    ],
                ],
            ], 200),
        ]);

        // Minta game dengan minimum rating 4.0
        $response = $this->withHeaders($this->authHeaders())
            ->getJson('/api/games?genre=Action&platform=PC&rating=4.0');

        $response->assertStatus(200);
        $games = $response->json('data.games');

        // Low Rating Game (2.8) harus terfilter keluar
        $this->assertCount(1, $games);
        $this->assertEquals('High Rating Game', $games[0]['judul']);
    }

    /**
     * Uji cache query respons: panggilan kedua dalam waktu singkat tidak memanggil RAWG lagi
     */
    public function test_search_uses_cache_on_second_call(): void
    {
        Http::fake([
            'https://api.rawg.io/api/games*' => Http::response([
                'count' => 1,
                'results' => [
                    [
                        'id'               => 999,
                        'name'             => 'Zelda Wild',
                        'background_image' => 'https://media.rawg.io/zelda.jpg',
                        'rating'           => 4.8,
                        'released'         => '2017-03-03',
                        'genres'           => [['id' => 3, 'name' => 'Adventure']],
                        'platforms'        => [['platform' => ['id' => 7, 'name' => 'Nintendo Switch']]],
                    ],
                ],
            ], 200),
        ]);

        // Panggilan 1
        $res1 = $this->withHeaders($this->authHeaders())->getJson('/api/games?search=Zelda');
        $res1->assertStatus(200);

        // Panggilan 2 dengan parameter yang sama
        $res2 = $this->withHeaders($this->authHeaders())->getJson('/api/games?search=Zelda');
        $res2->assertStatus(200)
            ->assertJson([
                'message' => 'Daftar game berhasil diambil (dari cache)',
            ]);

        // RAWG hanya dipanggil 1 kali berkat cache
        Http::assertSentCount(1);
    }

    /**
     * Uji detail game: mengambil deskripsi dari detail RAWG hanya saat detail dibuka
     */
    public function test_game_detail_fetches_and_caches_description(): void
    {
        // Buat data game awal di DB tanpa deskripsi
        $game = Game::create([
            'rawg_id'       => 4200,
            'judul'         => 'Portal 2',
            'cover_url'     => 'https://media.rawg.io/portal2.jpg',
            'rating'        => 4.6,
            'tanggal_rilis' => '2011-04-18',
            'deskripsi'     => null, // belum ada deskripsi
            'cached_at'     => now(),
        ]);

        Http::fake([
            'https://api.rawg.io/api/games/4200*' => Http::response([
                'id'               => 4200,
                'name'             => 'Portal 2',
                'description_raw'  => 'Portal 2 is a first-person puzzle-platform video game developed by Valve.',
                'background_image' => 'https://media.rawg.io/portal2.jpg',
                'rating'           => 4.6,
                'released'         => '2011-04-18',
                'genres'           => [['id' => 7, 'name' => 'Puzzle']],
                'platforms'        => [['platform' => ['id' => 4, 'name' => 'PC']]],
            ], 200),
        ]);

        $response = $this->withHeaders($this->authHeaders())
            ->getJson("/api/games/{$game->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data'    => [
                    'id'        => $game->id,
                    'rawg_id'   => 4200,
                    'judul'     => 'Portal 2',
                    'deskripsi' => 'Portal 2 is a first-person puzzle-platform video game developed by Valve.',
                ],
            ]);

        // Verifikasi deskripsi kini tersimpan di database
        $this->assertDatabaseHas('games', [
            'id'        => $game->id,
            'deskripsi' => 'Portal 2 is a first-person puzzle-platform video game developed by Valve.',
        ]);

        // Panggilan kedua untuk detail tidak memanggil endpoint RAWG detail lagi karena sudah tersimpan
        $response2 = $this->withHeaders($this->authHeaders())
            ->getJson("/api/games/{$game->id}");
        $response2->assertStatus(200);

        Http::assertSentCount(1);
    }

    /**
     * Uji bila RAWG gagal dijangkau, kembalikan data dari database jika ada
     */
    public function test_rawg_failure_falls_back_to_database_if_available(): void
    {
        $game = Game::create([
            'rawg_id'       => 5555,
            'judul'         => 'Hollow Knight',
            'cover_url'     => 'https://media.rawg.io/hk.jpg',
            'rating'        => 4.7,
            'tanggal_rilis' => '2017-02-24',
            'cached_at'     => now(),
        ]);
        $genre = Genre::create(['nama' => 'Metroidvania', 'rawg_id' => 88]);
        $game->genres()->attach($genre->id);

        // Simulasikan RAWG gagal total (500)
        Http::fake([
            'https://api.rawg.io/api/games*' => Http::response(null, 500),
        ]);

        $response = $this->withHeaders($this->authHeaders())
            ->getJson('/api/games?search=Hollow');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Daftar game berhasil diambil dari database lokal',
                'data'    => [
                    'games' => [
                        [
                            'rawg_id' => 5555,
                            'judul'   => 'Hollow Knight',
                        ],
                    ],
                ],
            ]);
    }

    /**
     * Uji bila RAWG gagal dijangkau dan database kosong, kembalikan JSON error 503 yang jelas
     */
    public function test_rawg_failure_returns_error_json_when_no_local_data(): void
    {
        Http::fake([
            'https://api.rawg.io/api/games*' => Http::response(null, 500),
        ]);

        $response = $this->withHeaders($this->authHeaders())
            ->getJson('/api/games?search=NonExistentGame');

        $response->assertStatus(503)
            ->assertJson([
                'success' => false,
                'data'    => null,
            ]);

        $this->assertNotEmpty($response->json('message'));
    }
}
