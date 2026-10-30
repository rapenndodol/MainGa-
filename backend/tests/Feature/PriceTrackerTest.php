<?php

namespace Tests\Feature;

use App\Models\Game;
use App\Models\PriceHistory;
use App\Models\User;
use App\Models\WishlistAlert;
use App\Services\PriceService;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Tests\TestCase;

class PriceTrackerTest extends TestCase
{
    use RefreshDatabase;

    protected User $user1;
    protected User $user2;
    protected string $token1;
    protected Game $game1;
    protected Game $game2;
    protected Game $game3;

    protected function setUp(): void
    {
        parent::setUp();

        Cache::flush();

        $this->user1 = User::factory()->create([
            'nama'  => 'Gamer Satu',
            'email' => 'gamer1@test.com',
        ]);
        $this->token1 = $this->user1->createToken('token1')->plainTextToken;

        $this->user2 = User::factory()->create([
            'nama'  => 'Gamer Dua',
            'email' => 'gamer2@test.com',
        ]);

        $this->game1 = Game::create([
            'rawg_id'       => 201,
            'judul'         => 'The Witcher 3: Wild Hunt',
            'cover_url'     => 'https://media.rawg.io/witcher3.jpg',
            'rating'        => 4.7,
            'cached_at'     => now(),
        ]);

        $this->game2 = Game::create([
            'rawg_id'       => 202,
            'judul'         => "Marvel's Spider-Man: Miles Morales",
            'cover_url'     => 'https://media.rawg.io/spiderman.jpg',
            'rating'        => 4.6,
            'cached_at'     => now(),
        ]);

        $this->game3 = Game::create([
            'rawg_id'       => 203,
            'judul'         => 'Super Indie Game Langka',
            'cover_url'     => 'https://media.rawg.io/indie.jpg',
            'rating'        => 4.0,
            'cached_at'     => now(),
        ]);
    }

    protected function authHeaders(): array
    {
        return [
            'Authorization' => 'Bearer ' . $this->token1,
            'Accept'        => 'application/json',
        ];
    }

    /**
     * 1. Pencocokan judul persis cocok dari bentuk respons nyata CheapShark
     * termasuk kandidat dengan steamAppID null terpilih sebagai hasil utama.
     */
    public function test_exact_match_with_null_steam_app_id_from_real_response(): void
    {
        Log::spy();

        Http::fake([
            '*/stores' => Http::response([
                ['storeID' => '11', 'storeName' => 'Humble Store'],
            ], 200),
            '*/games?title=*' => Http::response([
                [
                    'gameID'         => '112330',
                    'steamAppID'     => null,
                    'cheapest'       => '39.99',
                    'cheapestDealID' => 'deal1',
                    'external'       => 'The Witcher 3: Wild Hunt',
                    'internalName'   => 'THEWITCHER3WILDHUNT',
                    'thumb'          => 'https://cdn.humblebundle.com/thumb.jpg',
                ],
                [
                    'gameID'         => '332562',
                    'steamAppID'     => '292030',
                    'cheapest'       => '24.99',
                    'cheapestDealID' => 'deal2',
                    'external'       => 'The Witcher 3: Wild Hunt  Remastered',
                    'internalName'   => 'THEWITCHER3WILDHUNTREMASTERED',
                    'thumb'          => 'https://shared.fastly.steamstatic.com/capsule.jpg',
                ],
                [
                    'gameID'         => '152494',
                    'steamAppID'     => null,
                    'cheapest'       => '19.99',
                    'cheapestDealID' => 'deal3',
                    'external'       => 'The Witcher 3: Wild Hunt - Blood and Wine',
                    'internalName'   => 'THEWITCHER3WILDHUNTBLOODANDWINE',
                    'thumb'          => 'https://cdn.humblebundle.com/thumb2.jpg',
                ],
            ], 200),
            '*/games?id=112330' => Http::response([
                'info'  => [
                    'title'      => 'The Witcher 3: Wild Hunt',
                    'steamAppID' => null,
                ],
                'deals' => [
                    [
                        'storeID'     => '11',
                        'dealID'      => 'deal1',
                        'price'       => '39.99',
                        'retailPrice' => '39.99',
                        'savings'     => '0.000000',
                    ],
                ],
            ], 200),
        ]);

        $priceService = app(PriceService::class);
        $result = $priceService->fetchPrices($this->game1);

        $this->assertTrue($result['available']);
        $this->assertEquals('112330', $result['cheapshark_id']);
        $this->assertCount(1, $result['deals']);
        $this->assertEquals('Humble Store', $result['deals'][0]['toko']);
        $this->assertEquals(39.99, $result['deals'][0]['harga']);

        // Pastikan cheapshark_id tersimpan di model game
        $this->game1->refresh();
        $this->assertEquals('112330', $this->game1->cheapshark_id);

        // Verifikasi log info mencatat judul yang dicari, jumlah kandidat, dan kandidat terpilih
        Log::shouldHaveReceived('info')->withArgs(function ($message) {
            return str_contains($message, 'The Witcher 3: Wild Hunt')
                && str_contains($message, '3 kandidat')
                && str_contains($message, '112330');
        });
    }

    /**
     * 2. Pencocokan judul dengan subjudul dan awalan "The"
     * Normalisasi mengabaikan awalan "the", tanda baca (titik dua, strip), dan spasi ganda.
     */
    public function test_title_matching_with_subtitle_and_the_prefix(): void
    {
        $priceService = app(PriceService::class);

        // Uji normalisasi
        $this->assertEquals('witcher 3 wild hunt', $priceService->normalizeTitle('The Witcher 3: Wild Hunt'));
        $this->assertEquals('witcher 3 wild hunt', $priceService->normalizeTitle('Witcher 3: Wild Hunt'));
        $this->assertEquals('witcher 3 wild hunt', $priceService->normalizeTitle('The Witcher 3 - Wild Hunt'));
        $this->assertEquals('marvel s spider man miles morales', $priceService->normalizeTitle("Marvel's Spider-Man: Miles Morales"));
        $this->assertEquals('marvel s spider man miles morales', $priceService->normalizeTitle("The Marvel's Spider-Man - Miles Morales"));

        // Cari kandidat yang judulnya tanpa awalan "The", sementara game target memiliki "The"
        $candidates = [
            [
                'gameID'   => '501',
                'external' => 'Witcher 3: Wild Hunt', // Tanpa "The"
            ],
            [
                'gameID'   => '502',
                'external' => 'The Witcher 2: Assassins of Kings',
            ],
        ];

        $match = $priceService->findBestMatch('The Witcher 3: Wild Hunt', $candidates);
        $this->assertNotNull($match);
        $this->assertEquals('501', $match['gameID']);
    }

    /**
     * 3. Kandidat DLC, bundle, soundtrack, dan expansion pass tidak terpilih
     * bila ada kandidat game utama yang lebih cocok.
     */
    public function test_dlc_and_expansion_pass_candidates_are_not_selected_when_main_game_available(): void
    {
        $priceService = app(PriceService::class);

        $candidates = [
            [
                'gameID'   => '9001',
                'external' => 'The Witcher 3: Wild Hunt Expansion Pass', // DLC
            ],
            [
                'gameID'   => '9002',
                'external' => 'The Witcher 3: Wild Hunt Official Soundtrack Bundle', // Soundtrack / Bundle
            ],
            [
                'gameID'   => '9003',
                'external' => 'The Witcher 3: Wild Hunt - Complete Edition', // Edisi Utama
            ],
        ];

        // Jika mencari "The Witcher 3: Wild Hunt" dan tidak ada yang persis sama,
        // kandidat Complete Edition harus terpilih, BUKAN Expansion Pass atau Soundtrack Bundle
        $match = $priceService->findBestMatch('The Witcher 3: Wild Hunt Game', $candidates);
        $this->assertNotNull($match);
        $this->assertEquals('9003', $match['gameID']);
    }

    /**
     * 4. Game tidak ditemukan di CheapShark: tandai sebagai harga belum tersedia tanpa galat,
     * serta mencatat Log::info.
     */
    public function test_game_not_found_on_cheapshark_handled_gracefully(): void
    {
        Log::spy();

        Http::fake([
            '*/stores' => Http::response([
                ['storeID' => '1', 'storeName' => 'Steam'],
            ], 200),
            '*/games?title=*' => Http::response([], 200),
        ]);

        $priceService = app(PriceService::class);
        $result = $priceService->fetchPrices($this->game3);

        $this->assertFalse($result['available']);
        $this->assertNull($result['cheapshark_id']);
        $this->assertEmpty($result['deals']);
        $this->assertNull($result['cheapest']);

        $this->assertDatabaseMissing('price_history', [
            'game_id' => $this->game3->id,
        ]);

        Log::shouldHaveReceived('info')->withArgs(function ($message) {
            return str_contains($message, 'Super Indie Game Langka')
                && str_contains($message, '0 kandidat');
        });
    }

    /**
     * 5. CheapShark gagal (status bukan 2xx atau timeout) mencatat Log::warning
     * dengan status dan judul, tanpa membuat aplikasi melempar galat.
     */
    public function test_cheapshark_api_failure_logs_warning_and_does_not_crash(): void
    {
        Log::spy();

        Http::fake([
            '*/stores' => Http::response('Internal Server Error', 500),
            '*/games*' => Http::response(['error' => 'Bad Request'], 400),
        ]);

        $priceService = app(PriceService::class);
        $result = $priceService->fetchPrices($this->game1);

        $this->assertFalse($result['available']);
        $this->assertEmpty($result['deals']);

        // Pastikan Log::warning tercatat dengan status HTTP 400 dan judul game
        Log::shouldHaveReceived('warning')->withArgs(function ($message) {
            return str_contains($message, 'The Witcher 3: Wild Hunt')
                && str_contains($message, '400');
        });

        // Endpoint GET /api/games/{id}/prices tetap merespons 200 OK dengan harga belum tersedia
        $response = $this->withHeaders($this->authHeaders())
            ->getJson("/api/games/{$this->game1->id}/prices");

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.harga_tersedia', false)
            ->assertJsonPath('data.status_keterangan', 'Harga belum tersedia');
    }

    /**
     * 6. Pengecekan berikutnya langsung memakai cheapshark_id yang tersimpan tanpa query pencarian ulang
     */
    public function test_subsequent_check_uses_saved_cheapshark_id_without_re_searching(): void
    {
        $this->game1->update(['cheapshark_id' => '5555']);

        Http::fake([
            '*/stores' => Http::response([
                ['storeID' => '1', 'storeName' => 'Steam'],
            ], 200),
            '*/games?id=5555' => Http::response([
                'info'  => ['title' => 'The Witcher 3: Wild Hunt'],
                'deals' => [
                    ['storeID' => '1', 'price' => '11.99', 'retailPrice' => '39.99', 'savings' => '70.0'],
                ],
            ], 200),
        ]);

        $priceService = app(PriceService::class);
        $result = $priceService->fetchPrices($this->game1);

        $this->assertTrue($result['available']);
        $this->assertEquals('5555', $result['cheapshark_id']);
        $this->assertEquals(11.99, $result['cheapest']['harga']);

        // Pastikan tidak ada request ke endpoint ?title=
        Http::assertNotSent(function ($request) {
            return str_contains($request->url(), 'title=');
        });
    }

    /**
     * 7. Setiap pengecekan menyimpan satu baris per toko ke price_history.
     * Mencegah duplikasi baris bila harga dan toko sama dengan pengecekan sebelumnya dalam jam yang sama.
     */
    public function test_price_history_deduplication_in_same_hour(): void
    {
        Http::fake([
            '*/stores' => Http::response([
                ['storeID' => '1', 'storeName' => 'Steam'],
                ['storeID' => '2', 'storeName' => 'GamersGate'],
            ], 200),
            '*/games?title=*' => Http::response([
                ['gameID' => '2001', 'external' => 'The Witcher 3: Wild Hunt', 'cheapest' => '12.00'],
            ], 200),
            '*/games?id=2001' => Http::response([
                'info'  => ['title' => 'The Witcher 3: Wild Hunt'],
                'deals' => [
                    ['storeID' => '1', 'price' => '12.00', 'retailPrice' => '39.99', 'savings' => '70.0'],
                    ['storeID' => '2', 'price' => '14.50', 'retailPrice' => '39.99', 'savings' => '63.0'],
                ],
            ], 200),
        ]);

        $priceService = app(PriceService::class);

        // Pengecekan 1 pada waktu T
        Carbon::setTestNow('2026-10-30 14:15:00');
        $priceService->checkAndRecordPrices($this->game1);

        // Harus ada 2 baris (Steam dan GamersGate)
        $this->assertEquals(2, PriceHistory::where('game_id', $this->game1->id)->count());

        // Pengecekan 2 pada waktu T + 20 menit (jam yang sama, harga persis sama)
        Carbon::setTestNow('2026-10-30 14:35:00');
        $priceService->checkAndRecordPrices($this->game1);

        // Jumlah baris TIDAK boleh bertambah karena toko dan harga sama dalam jam yang sama
        $this->assertEquals(2, PriceHistory::where('game_id', $this->game1->id)->count());

        // Pengecekan 3 pada jam berikutnya (15:10:00) dengan harga yang sama
        Carbon::setTestNow('2026-10-30 15:10:00');
        $priceService->checkAndRecordPrices($this->game1);

        // Baris HARUS bertambah 2 (total 4 baris) karena sudah berbeda jam
        $this->assertEquals(4, PriceHistory::where('game_id', $this->game1->id)->count());

        Carbon::setTestNow();
    }

    /**
     * 8. Bila harga berubah dalam jam yang sama, catatan baru tetap disimpan
     */
    public function test_price_change_in_same_hour_is_recorded(): void
    {
        $priceService = app(PriceService::class);
        $this->game1->update(['cheapshark_id' => '3001']);

        $dealSequence = Http::sequence()
            ->push([
                'info'  => ['title' => 'The Witcher 3: Wild Hunt'],
                'deals' => [['storeID' => '1', 'price' => '15.00', 'savings' => '60.0']],
            ], 200)
            ->push([
                'info'  => ['title' => 'The Witcher 3: Wild Hunt'],
                'deals' => [['storeID' => '1', 'price' => '9.99', 'savings' => '75.0']],
            ], 200);

        Http::fake([
            '*/stores' => Http::response([['storeID' => '1', 'storeName' => 'Steam']], 200),
            '*/games?id=3001' => $dealSequence,
        ]);

        // Check 1: Harga $15.00 pada 10:05
        Carbon::setTestNow('2026-10-30 10:05:00');
        $priceService->checkAndRecordPrices($this->game1);
        $this->assertEquals(1, PriceHistory::where('game_id', $this->game1->id)->count());

        // Check 2: Flash sale harga turun menjadi $9.99 pada 10:15 (masih jam yang sama)
        Carbon::setTestNow('2026-10-30 10:15:00');
        $priceService->checkAndRecordPrices($this->game1);

        // Harus ada 2 baris karena harganya berbeda (15.00 dan 9.99)
        $this->assertEquals(2, PriceHistory::where('game_id', $this->game1->id)->count());

        Carbon::setTestNow();
    }

    /**
     * 9. GET /api/games/{id}/prices mengembalikan harga terkini per toko dan riwayat dalam urutan kronologis
     */
    public function test_get_game_prices_endpoint_returns_current_and_chronological_history(): void
    {
        PriceHistory::create([
            'game_id'       => $this->game1->id,
            'toko'          => 'Steam',
            'harga'         => 19.99,
            'diskon_persen' => 50.0,
            'dicek_pada'    => Carbon::parse('2026-10-25 10:00:00'),
        ]);

        PriceHistory::create([
            'game_id'       => $this->game1->id,
            'toko'          => 'Steam',
            'harga'         => 14.99,
            'diskon_persen' => 62.5,
            'dicek_pada'    => Carbon::parse('2026-10-28 10:00:00'),
        ]);

        PriceHistory::create([
            'game_id'       => $this->game1->id,
            'toko'          => 'GOG',
            'harga'         => 16.99,
            'diskon_persen' => 57.5,
            'dicek_pada'    => Carbon::parse('2026-10-29 10:00:00'),
        ]);

        $response = $this->withHeaders($this->authHeaders())
            ->getJson("/api/games/{$this->game1->id}/prices");

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.harga_tersedia', true)
            ->assertJsonPath('data.harga_terendah', 14.99)
            ->assertJsonPath('data.toko_termurah', 'Steam')
            ->assertJsonCount(2, 'data.harga_terkini')
            ->assertJsonCount(3, 'data.riwayat_harga');

        $history = $response->json('data.riwayat_harga');
        $this->assertEquals(19.99, $history[0]['harga']);
        $this->assertEquals(14.99, $history[1]['harga']);
        $this->assertEquals(16.99, $history[2]['harga']);
    }

    /**
     * 10. GET /api/games/{id}/prices tanpa token mengembalikan status 401
     */
    public function test_get_game_prices_unauthenticated_returns_401(): void
    {
        $this->getJson("/api/games/{$this->game1->id}/prices")->assertStatus(401);
    }

    /**
     * 11. Command artisan prices:check hanya memproses game dengan wishlist aktif,
     * serta tidak menduplikasi pengecekan jika beberapa pengguna memantau game yang sama.
     */
    public function test_prices_check_command_only_processes_active_wishlists_and_deduplicates(): void
    {
        WishlistAlert::create([
            'user_id'      => $this->user1->id,
            'game_id'      => $this->game1->id,
            'harga_target' => 20.00,
            'aktif'        => true,
        ]);

        WishlistAlert::create([
            'user_id'      => $this->user2->id,
            'game_id'      => $this->game1->id,
            'harga_target' => 18.00,
            'aktif'        => true,
        ]);

        WishlistAlert::create([
            'user_id'      => $this->user1->id,
            'game_id'      => $this->game2->id,
            'harga_target' => 30.00,
            'aktif'        => false,
        ]);

        Http::fake([
            '*/stores' => Http::response([['storeID' => '1', 'storeName' => 'Steam']], 200),
            '*/games?title=*' => Http::response([
                ['gameID' => '9901', 'external' => 'The Witcher 3: Wild Hunt', 'cheapest' => '13.00'],
            ], 200),
            '*/games?id=9901' => Http::response([
                'info'  => ['title' => 'The Witcher 3: Wild Hunt'],
                'deals' => [['storeID' => '1', 'price' => '13.00', 'savings' => '65.0']],
            ], 200),
        ]);

        $this->artisan('prices:check')
            ->expectsOutputToContain('Ditemukan 1 game unik dari wishlist aktif untuk dicek.')
            ->expectsOutputToContain('The Witcher 3: Wild Hunt')
            ->assertExitCode(0);

        $this->assertDatabaseHas('price_history', [
            'game_id' => $this->game1->id,
            'harga'   => 13.00,
        ]);

        $this->assertDatabaseMissing('price_history', [
            'game_id' => $this->game2->id,
        ]);
    }

    /**
     * 12. Command artisan prices:check --game={id} mengecek 1 game secara manual
     */
    public function test_prices_check_command_manual_option(): void
    {
        Http::fake([
            '*/stores' => Http::response([['storeID' => '1', 'storeName' => 'Steam']], 200),
            '*/games?title=*' => Http::response([
                ['gameID' => '8801', 'external' => "Marvel's Spider-Man: Miles Morales", 'cheapest' => '24.99'],
            ], 200),
            '*/games?id=8801' => Http::response([
                'info'  => ['title' => "Marvel's Spider-Man: Miles Morales"],
                'deals' => [['storeID' => '1', 'price' => '24.99', 'savings' => '50.0']],
            ], 200),
        ]);

        $this->artisan("prices:check --game={$this->game2->id}")
            ->expectsOutputToContain("Memulai pengecekan harga manual untuk 1 game: {$this->game2->judul}")
            ->assertExitCode(0);

        $this->assertDatabaseHas('price_history', [
            'game_id' => $this->game2->id,
            'harga'   => 24.99,
        ]);
    }
}
