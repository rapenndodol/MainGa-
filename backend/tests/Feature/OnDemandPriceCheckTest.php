<?php

namespace Tests\Feature;

use App\Models\Game;
use App\Models\Platform;
use App\Models\PriceHistory;
use App\Models\User;
use App\Services\PriceService;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class OnDemandPriceCheckTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected string $token;
    protected Platform $pcPlatform;
    protected Platform $psPlatform;

    protected function setUp(): void
    {
        parent::setUp();

        Cache::flush();

        $this->user = User::factory()->create([
            'nama'  => 'Tester On Demand',
            'email' => 'ondemand@test.com',
        ]);
        $this->token = $this->user->createToken('test_token')->plainTextToken;

        $this->pcPlatform = Platform::create(['nama' => 'PC', 'rawg_id' => 4]);
        $this->psPlatform = Platform::create(['nama' => 'PlayStation 5', 'rawg_id' => 187]);
    }

    protected function authHeaders(): array
    {
        return [
            'Authorization' => 'Bearer ' . $this->token,
            'Accept'        => 'application/json',
        ];
    }

    /**
     * 7(a) Game tanpa history memicu fetch saat detail dibuka,
     * menyimpan hasil ke price_history dan memperbarui price_checked_at.
     */
    public function test_game_without_history_triggers_fetch_when_detail_opened(): void
    {
        $game = Game::create([
            'rawg_id'          => 1001,
            'judul'            => 'Cyberpunk 2077',
            'cover_url'        => 'https://media.rawg.io/cyberpunk.jpg',
            'rating'           => 4.5,
            'deskripsi'        => 'Cyberpunk 2077 deskripsi.',
            'cached_at'        => now(),
            'price_checked_at' => null,
        ]);
        $game->platforms()->attach($this->pcPlatform->id);

        Http::fake([
            '*/stores' => Http::response([
                ['storeID' => '1', 'storeName' => 'Steam'],
            ], 200),
            '*/games?title=*' => Http::response([
                [
                    'gameID'     => '7701',
                    'external'   => 'Cyberpunk 2077',
                    'cheapest'   => '29.99',
                    'steamAppID' => null,
                ],
            ], 200),
            '*/games?id=7701' => Http::response([
                'info'  => ['title' => 'Cyberpunk 2077'],
                'deals' => [
                    ['storeID' => '1', 'price' => '29.99', 'retailPrice' => '59.99', 'savings' => '50.0'],
                ],
            ], 200),
        ]);

        $response = $this->withHeaders($this->authHeaders())
            ->getJson("/api/games/{$game->id}");

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.price_status', 'available')
            ->assertJsonPath('data.harga_tersedia', true)
            ->assertJsonPath('data.harga_terendah', 29.99)
            ->assertJsonPath('data.toko_termurah', 'Steam');

        $this->assertDatabaseHas('price_history', [
            'game_id' => $game->id,
            'toko'    => 'Steam',
            'harga'   => 29.99,
        ]);

        $this->assertNotNull($game->fresh()->price_checked_at);
        $this->assertEquals('7701', $game->fresh()->cheapshark_id);
    }

    /**
     * 7(b) Negative cache 24 jam mencegah panggilan ulang ke CheapShark
     * jika game sebelumnya tidak ditemukan di CheapShark.
     */
    public function test_negative_cache_prevents_subsequent_cheapshark_calls(): void
    {
        $game = Game::create([
            'rawg_id'          => 1002,
            'judul'            => 'Game Indie Tidak Ada Di CheapShark',
            'deskripsi'        => 'Deskripsi game indie lokal.',
            'cached_at'        => now(),
            'price_checked_at' => null,
        ]);
        $game->platforms()->attach($this->pcPlatform->id);

        Http::fake([
            '*/stores' => Http::response([
                ['storeID' => '1', 'storeName' => 'Steam'],
            ], 200),
            '*/games?title=*' => Http::response([], 200), // CheapShark tidak menemukan kandidat
        ]);

        // Panggilan 1: Cek harga via detail
        $res1 = $this->withHeaders($this->authHeaders())
            ->getJson("/api/games/{$game->id}");

        $res1->assertStatus(200)
            ->assertJsonPath('data.price_status', 'not_found')
            ->assertJsonPath('data.harga_tersedia', false);

        // Pastikan price_checked_at tercatat (negative cache) dan tidak ada baris di price_history
        $this->assertNotNull($game->fresh()->price_checked_at);
        $this->assertEquals(0, PriceHistory::where('game_id', $game->id)->count());

        $sentCountAfterFirst = Http::recorded()->count();

        // Panggilan 2: Buka detail lagi dalam 24 jam (negative cache aktif)
        $res2 = $this->withHeaders($this->authHeaders())
            ->getJson("/api/games/{$game->id}");
        $res2->assertStatus(200);

        // Panggilan 3: Buka endpoint GET /api/games/{id}/prices dalam 24 jam
        $res3 = $this->withHeaders($this->authHeaders())
            ->getJson("/api/games/{$game->id}/prices");
        $res3->assertStatus(200)
            ->assertJsonPath('data.price_status', 'not_found');

        // Jumlah HTTP request ke CheapShark TIDAK boleh bertambah karena negative cache aktif
        $this->assertEquals($sentCountAfterFirst, Http::recorded()->count());
    }

    /**
     * 7(c) Timeout CheapShark tidak membuat error 500, melainkan mengembalikan
     * status 200 dengan data terakhir atau fallback harga belum tersedia.
     */
    public function test_cheapshark_timeout_or_error_does_not_cause_500(): void
    {
        $game = Game::create([
            'rawg_id'          => 1003,
            'judul'            => 'Game Server Timeout',
            'deskripsi'        => 'Deskripsi game timeout.',
            'cached_at'        => now(),
            'price_checked_at' => null,
        ]);
        $game->platforms()->attach($this->pcPlatform->id);

        Http::fake([
            '*/stores' => Http::response([], 500),
            '*/games*' => function () {
                throw new ConnectionException('cURL error 28: Operation timed out after 5001 milliseconds');
            },
        ]);

        // GET /api/games/{id} tetap merespons 200 OK tanpa error 500
        $resDetail = $this->withHeaders($this->authHeaders())
            ->getJson("/api/games/{$game->id}");

        $resDetail->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.harga_tersedia', false);

        // GET /api/games/{id}/prices tetap merespons 200 OK tanpa error 500
        $resPrices = $this->withHeaders($this->authHeaders())
            ->getJson("/api/games/{$game->id}/prices");

        $resPrices->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.harga_tersedia', false);
    }

    /**
     * 7(d) Judul dengan subjudul / edisi berbeda tetap cocok:
     * - Normalisasi angka Romawi ke angka arab
     * - Pembuangan kata edition / remastered / goty / definitive
     * - Subjudul setelah ":" atau "-"
     * - Pencarian via steam_app_id lebih dulu jika tersedia
     */
    public function test_title_matching_with_subtitles_editions_and_steam_app_id(): void
    {
        $priceService = app(PriceService::class);

        // 1. Uji normalisasi edisi dan angka Romawi
        $this->assertEquals(
            'witcher 3 wild hunt',
            $priceService->normalizeTitle('The Witcher III: Wild Hunt Remastered')
        );
        $this->assertEquals(
            'witcher 3 wild hunt',
            $priceService->normalizeTitle('The Witcher 3: Wild Hunt - GOTY Edition')
        );
        $this->assertEquals(
            'witcher 3 wild hunt',
            $priceService->normalizeTitle('The Witcher 3: Wild Hunt Definitive Edition')
        );

        // 2. Uji pencocokan judul dengan similar_text >= 85%
        $candidates = [
            [
                'gameID'   => '4401',
                'external' => 'The Witcher 3: Wild Hunt',
            ],
            [
                'gameID'   => '4402',
                'external' => 'Completely Different Game',
            ],
        ];

        // Judul target memakai angka Romawi "III" dan kata "Remastered"
        $match = $priceService->findBestMatch('The Witcher III: Wild Hunt Remastered', $candidates);
        $this->assertNotNull($match);
        $this->assertEquals('4401', $match['gameID']);

        // 3. Uji subjudul setelah ":" atau "-"
        // Target: "Persona 5: Royal" vs CheapShark candidate: "Persona 5 Royal"
        $p5Candidates = [
            [
                'gameID'   => '5501',
                'external' => 'Persona 5 Royal',
            ],
        ];
        $p5Match = $priceService->findBestMatch('Persona 5: Royal', $p5Candidates);
        $this->assertNotNull($p5Match);
        $this->assertEquals('5501', $p5Match['gameID']);

        // 4. Uji steam_app_id digunakan lebih dulu jika tersedia
        $steamGame = Game::create([
            'rawg_id'          => 8080,
            'steam_app_id'     => '292030',
            'judul'            => 'The Witcher 3: Wild Hunt',
            'cached_at'        => now(),
            'price_checked_at' => null,
        ]);

        Http::fake([
            '*/stores' => Http::response([['storeID' => '1', 'storeName' => 'Steam']], 200),
            '*/games?steamAppID=292030' => Http::response([
                [
                    'gameID'     => '612',
                    'steamAppID' => '292030',
                    'external'   => 'The Witcher 3: Wild Hunt',
                ],
            ], 200),
            '*/games?id=612' => Http::response([
                'info'  => ['title' => 'The Witcher 3: Wild Hunt'],
                'deals' => [['storeID' => '1', 'price' => '14.99', 'retailPrice' => '39.99', 'savings' => '62.5']],
            ], 200),
        ]);

        $resolvedId = $priceService->resolveCheapSharkId($steamGame);
        $this->assertEquals('612', $resolvedId);

        // Pastikan endpoint steamAppID dipanggil
        Http::assertSent(function ($request) {
            return str_contains($request->url(), 'steamAppID=292030');
        });
    }

    /**
     * 7(e) Endpoint /api/games/{id}/prices dan grafik riwayat harga tetap
     * mengembalikan data kronologis dan harga per toko secara utuh.
     */
    public function test_riwayat_harga_chart_and_prices_endpoint_remain_consistent(): void
    {
        $game = Game::create([
            'rawg_id'          => 1005,
            'judul'            => 'The Witcher 3: Wild Hunt',
            'cached_at'        => now(),
            'price_checked_at' => now(), // Pengecekan baru saja dilakukan
        ]);
        $game->platforms()->attach($this->pcPlatform->id);

        PriceHistory::create([
            'game_id'       => $game->id,
            'toko'          => 'Steam',
            'harga'         => 29.99,
            'diskon_persen' => 25.0,
            'dicek_pada'    => Carbon::parse('2026-10-01 10:00:00'),
        ]);

        PriceHistory::create([
            'game_id'       => $game->id,
            'toko'          => 'Steam',
            'harga'         => 19.99,
            'diskon_persen' => 50.0,
            'dicek_pada'    => Carbon::parse('2026-10-15 10:00:00'),
        ]);

        PriceHistory::create([
            'game_id'       => $game->id,
            'toko'          => 'GOG',
            'harga'         => 24.99,
            'diskon_persen' => 37.5,
            'dicek_pada'    => Carbon::parse('2026-10-20 10:00:00'),
        ]);

        $response = $this->withHeaders($this->authHeaders())
            ->getJson("/api/games/{$game->id}/prices");

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.price_status', 'available')
            ->assertJsonPath('data.harga_tersedia', true)
            ->assertJsonPath('data.harga_terendah', 19.99)
            ->assertJsonPath('data.toko_termurah', 'Steam')
            ->assertJsonCount(2, 'data.harga_terkini')
            ->assertJsonCount(3, 'data.riwayat_harga');

        // Pastikan riwayat tersusun secara kronologis
        $history = $response->json('data.riwayat_harga');
        $this->assertEquals(29.99, $history[0]['harga']);
        $this->assertEquals(19.99, $history[1]['harga']);
        $this->assertEquals(24.99, $history[2]['harga']);
    }

    /**
     * Uji game eksklusif konsol (tanpa platform PC) mengembalikan price_status = 'unsupported'.
     */
    public function test_console_exclusive_game_returns_unsupported_price_status(): void
    {
        $game = Game::create([
            'rawg_id'          => 1009,
            'judul'            => 'PlayStation Console Exclusive Game',
            'deskripsi'        => 'Eksklusif PS5.',
            'cached_at'        => now(),
            'price_checked_at' => now(),
        ]);
        $game->platforms()->attach($this->psPlatform->id); // Hanya PlayStation 5, tidak ada PC

        $resDetail = $this->withHeaders($this->authHeaders())
            ->getJson("/api/games/{$game->id}");

        $resDetail->assertStatus(200)
            ->assertJsonPath('data.price_status', 'unsupported')
            ->assertJsonPath('data.harga_tersedia', false);

        $resPrices = $this->withHeaders($this->authHeaders())
            ->getJson("/api/games/{$game->id}/prices");

        $resPrices->assertStatus(200)
            ->assertJsonPath('data.price_status', 'unsupported')
            ->assertJsonPath('data.harga_tersedia', false);
    }
}
