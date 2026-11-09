<?php

namespace Tests\Feature;

use App\Models\Game;
use App\Models\Genre;
use App\Models\Platform;
use App\Models\PriceHistory;
use App\Models\User;
use App\Models\WishlistAlert;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class WishlistTest extends TestCase
{
    use RefreshDatabase;

    protected User $user1;
    protected User $user2;
    protected string $token1;
    protected string $token2;
    protected Game $game1;
    protected Game $game2;

    protected function setUp(): void
    {
        parent::setUp();

        Cache::flush();

        $this->user1 = User::factory()->create([
            'nama'  => 'User Satu',
            'email' => 'user1@test.com',
        ]);
        $this->token1 = $this->user1->createToken('token1')->plainTextToken;

        $this->user2 = User::factory()->create([
            'nama'  => 'User Dua',
            'email' => 'user2@test.com',
        ]);
        $this->token2 = $this->user2->createToken('token2')->plainTextToken;

        $this->game1 = Game::create([
            'rawg_id'       => 101,
            'judul'         => 'The Witcher 3: Wild Hunt',
            'cover_url'     => 'https://media.rawg.io/witcher3.jpg',
            'rating'        => 4.7,
            'tanggal_rilis' => '2015-05-18',
            'deskripsi'     => 'RPG open-world yang epik.',
            'cached_at'     => now(),
        ]);

        $this->game2 = Game::create([
            'rawg_id'       => 102,
            'judul'         => 'Hollow Knight',
            'cover_url'     => 'https://media.rawg.io/hollowknight.jpg',
            'rating'        => 4.8,
            'tanggal_rilis' => '2017-02-24',
            'deskripsi'     => 'Metroidvania masterpiece.',
            'cached_at'     => now(),
        ]);

        $genre = Genre::create(['nama' => 'Action RPG', 'rawg_id' => 5]);
        $platform = Platform::create(['nama' => 'PC', 'rawg_id' => 4]);

        $this->game1->genres()->attach($genre->id);
        $this->game1->platforms()->attach($platform->id);
    }

    protected function authHeaders(string $token): array
    {
        return [
            'Authorization' => 'Bearer ' . $token,
            'Accept'        => 'application/json',
        ];
    }

    protected function fakeCheapSharkSuccessful(): void
    {
        Http::fake([
            '*/stores' => Http::response([
                ['storeID' => '1', 'storeName' => 'Steam', 'isActive' => 1],
                ['storeID' => '7', 'storeName' => 'GOG', 'isActive' => 1],
            ], 200),
            '*/games?title=*' => Http::response([
                [
                    'gameID'   => '612',
                    'external' => 'The Witcher 3: Wild Hunt',
                    'cheapest' => '14.99',
                ],
            ], 200),
            '*/games?id=612' => Http::response([
                'info'  => ['title' => 'The Witcher 3: Wild Hunt'],
                'deals' => [
                    [
                        'storeID'     => '1',
                        'dealID'      => 'deal1',
                        'price'       => '14.99',
                        'retailPrice' => '39.99',
                        'savings'     => '62.51',
                    ],
                    [
                        'storeID'     => '7',
                        'dealID'      => 'deal2',
                        'price'       => '19.99',
                        'retailPrice' => '39.99',
                        'savings'     => '50.00',
                    ],
                ],
            ], 200),
        ]);
    }

    /**
     * 1. Akses tanpa token mengembalikan status 401
     */
    public function test_unauthenticated_access_returns_401(): void
    {
        $this->getJson('/api/wishlist')->assertStatus(401);
        $this->postJson('/api/wishlist', ['game_id' => $this->game1->id, 'harga_target' => 15.0])->assertStatus(401);
        $this->getJson('/api/wishlist/1')->assertStatus(401);
        $this->putJson('/api/wishlist/1', ['harga_target' => 10.0])->assertStatus(401);
        $this->deleteJson('/api/wishlist/1')->assertStatus(401);
    }

    /**
     * 2. Tambah game ke wishlist dengan game_id dan langsung memicu pengecekan harga
     */
    public function test_can_add_game_to_wishlist_with_game_id_and_triggers_price_check(): void
    {
        $this->fakeCheapSharkSuccessful();

        $response = $this->withHeaders($this->authHeaders($this->token1))
            ->postJson('/api/wishlist', [
                'game_id'      => $this->game1->id,
                'harga_target' => 20.00,
                'aktif'        => true,
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.game_id', $this->game1->id)
            ->assertJsonPath('data.aktif', true)
            ->assertJsonPath('data.harga_tersedia', true)
            ->assertJsonPath('data.harga_terendah', 14.99)
            ->assertJsonPath('data.toko_termurah', 'Steam')
            ->assertJsonPath('data.selisih_harga_target', -5.01);

        $this->assertEquals(20.0, (float) $response->json('data.harga_target'));

        $this->assertDatabaseHas('wishlist_alerts', [
            'user_id'      => $this->user1->id,
            'game_id'      => $this->game1->id,
            'harga_target' => 20.00,
            'aktif'        => 1,
        ]);

        // Verifikasi bahwa cheapshark_id tersimpan di tabel games
        $this->assertDatabaseHas('games', [
            'id'            => $this->game1->id,
            'cheapshark_id' => '612',
        ]);

        // Verifikasi bahwa harga tersimpan di price_history
        $this->assertDatabaseHas('price_history', [
            'game_id' => $this->game1->id,
            'toko'    => 'Steam',
            'harga'   => 14.99,
        ]);
        $this->assertDatabaseHas('price_history', [
            'game_id' => $this->game1->id,
            'toko'    => 'GOG',
            'harga'   => 19.99,
        ]);
    }

    /**
     * 3. Tambah game ke wishlist dengan rawg_id (auto-fetch dari RAWG bila belum ada di DB lokal)
     */
    public function test_can_add_game_to_wishlist_with_rawg_id(): void
    {
        Http::fake([
            '*/api/games/999*' => Http::response([
                'id'               => 999,
                'name'             => 'Elden Ring',
                'background_image' => 'https://media.rawg.io/eldenring.jpg',
                'rating'           => 4.9,
                'description_raw'  => 'Action RPG karya FromSoftware.',
                'released'         => '2022-02-25',
                'genres'           => [['id' => 5, 'name' => 'Action RPG']],
                'platforms'        => [['platform' => ['id' => 4, 'name' => 'PC']]],
            ], 200),
            '*/stores' => Http::response([
                ['storeID' => '1', 'storeName' => 'Steam', 'isActive' => 1],
            ], 200),
            '*/games?title=*' => Http::response([
                [
                    'gameID'   => '777',
                    'external' => 'Elden Ring',
                    'cheapest' => '39.99',
                ],
            ], 200),
            '*/games?id=777' => Http::response([
                'info'  => ['title' => 'Elden Ring'],
                'deals' => [
                    [
                        'storeID'     => '1',
                        'dealID'      => 'deal_er',
                        'price'       => '39.99',
                        'retailPrice' => '59.99',
                        'savings'     => '33.33',
                    ],
                ],
            ], 200),
        ]);

        $response = $this->withHeaders($this->authHeaders($this->token1))
            ->postJson('/api/wishlist', [
                'rawg_id'      => 999,
                'harga_target' => 40.00,
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.game.judul', 'Elden Ring')
            ->assertJsonPath('data.game.rawg_id', 999);

        $this->assertEquals(40.0, (float) $response->json('data.harga_target'));

        $this->assertDatabaseHas('games', [
            'rawg_id' => 999,
            'judul'   => 'Elden Ring',
        ]);
    }

    /**
     * 4. Validasi harga target: harus berupa angka numerik dan > 0 (422 bila tidak)
     */
    public function test_target_price_must_be_greater_than_zero(): void
    {
        // Harga 0
        $res1 = $this->withHeaders($this->authHeaders($this->token1))
            ->postJson('/api/wishlist', [
                'game_id'      => $this->game1->id,
                'harga_target' => 0,
            ]);
        $res1->assertStatus(422)
            ->assertJsonValidationErrors(['harga_target']);

        // Harga negatif
        $res2 = $this->withHeaders($this->authHeaders($this->token1))
            ->postJson('/api/wishlist', [
                'game_id'      => $this->game1->id,
                'harga_target' => -10.5,
            ]);
        $res2->assertStatus(422)
            ->assertJsonValidationErrors(['harga_target']);

        // Non numerik
        $res3 = $this->withHeaders($this->authHeaders($this->token1))
            ->postJson('/api/wishlist', [
                'game_id'      => $this->game1->id,
                'harga_target' => 'gratis',
            ]);
        $res3->assertStatus(422)
            ->assertJsonValidationErrors(['harga_target']);
    }

    /**
     * 5. Duplikat ditolak: satu game hanya dapat muncul sekali per pengguna di wishlist (422)
     */
    public function test_duplicate_game_in_wishlist_is_rejected_with_422(): void
    {
        $this->fakeCheapSharkSuccessful();

        // Tambah pertama kali
        $this->withHeaders($this->authHeaders($this->token1))
            ->postJson('/api/wishlist', [
                'game_id'      => $this->game1->id,
                'harga_target' => 20.00,
            ])
            ->assertStatus(201);

        // Tambah kedua kali untuk game yang sama
        $response = $this->withHeaders($this->authHeaders($this->token1))
            ->postJson('/api/wishlist', [
                'game_id'      => $this->game1->id,
                'harga_target' => 15.00,
            ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonPath('message', 'Game sudah ada di dalam wishlist Anda.');

        // Pengguna lain tetap boleh menambahkan game yang sama ke wishlist miliknya
        auth()->forgetGuards();
        $responseUser2 = $this->withHeaders($this->authHeaders($this->token2))
            ->postJson('/api/wishlist', [
                'game_id'      => $this->game1->id,
                'harga_target' => 18.00,
            ]);

        $responseUser2->assertStatus(201);
    }

    /**
     * 6. Akses data pengguna lain ditolak (403)
     */
    public function test_user_cannot_access_or_modify_other_user_wishlist(): void
    {
        $wishlistUser1 = WishlistAlert::create([
            'user_id'      => $this->user1->id,
            'game_id'      => $this->game1->id,
            'harga_target' => 25.00,
            'aktif'        => true,
        ]);

        // User2 mencoba melihat wishlist milik User1
        $this->withHeaders($this->authHeaders($this->token2))
            ->getJson("/api/wishlist/{$wishlistUser1->id}")
            ->assertStatus(403)
            ->assertJsonPath('success', false);

        // User2 mencoba mengubah wishlist milik User1
        $this->withHeaders($this->authHeaders($this->token2))
            ->putJson("/api/wishlist/{$wishlistUser1->id}", ['harga_target' => 10.00])
            ->assertStatus(403)
            ->assertJsonPath('success', false);

        // User2 mencoba menghapus wishlist milik User1
        $this->withHeaders($this->authHeaders($this->token2))
            ->deleteJson("/api/wishlist/{$wishlistUser1->id}")
            ->assertStatus(403)
            ->assertJsonPath('success', false);

        // Pastikan data di database tidak berubah
        $this->assertDatabaseHas('wishlist_alerts', [
            'id'           => $wishlistUser1->id,
            'harga_target' => 25.00,
        ]);
    }

    /**
     * 7. Ubah harga target dan status aktif wishlist (PUT /api/wishlist/{id})
     */
    public function test_can_update_wishlist_target_price_and_active_status(): void
    {
        $wishlist = WishlistAlert::create([
            'user_id'      => $this->user1->id,
            'game_id'      => $this->game1->id,
            'harga_target' => 25.00,
            'aktif'        => true,
        ]);

        $response = $this->withHeaders($this->authHeaders($this->token1))
            ->putJson("/api/wishlist/{$wishlist->id}", [
                'harga_target' => 12.50,
                'aktif'        => false,
            ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.harga_target', 12.5)
            ->assertJsonPath('data.aktif', false);

        $this->assertDatabaseHas('wishlist_alerts', [
            'id'           => $wishlist->id,
            'harga_target' => 12.50,
            'aktif'        => 0,
        ]);
    }

    /**
     * 8. Hapus game dari wishlist (DELETE /api/wishlist/{id})
     */
    public function test_can_delete_wishlist_entry(): void
    {
        $wishlist = WishlistAlert::create([
            'user_id'      => $this->user1->id,
            'game_id'      => $this->game1->id,
            'harga_target' => 25.00,
            'aktif'        => true,
        ]);

        $response = $this->withHeaders($this->authHeaders($this->token1))
            ->deleteJson("/api/wishlist/{$wishlist->id}");

        $response->assertStatus(200)
            ->assertJsonPath('success', true);

        $this->assertDatabaseMissing('wishlist_alerts', [
            'id' => $wishlist->id,
        ]);
    }

    /**
     * 9. GET /api/wishlist mengembalikan daftar milik pengguna dengan harga terendah, toko, dan selisih
     */
    public function test_get_wishlist_returns_user_entries_with_prices_and_difference(): void
    {
        // Buat wishlist untuk game1 (ada riwayat harga)
        $wishlist1 = WishlistAlert::create([
            'user_id'      => $this->user1->id,
            'game_id'      => $this->game1->id,
            'harga_target' => 20.00,
            'aktif'        => true,
        ]);

        // Simpan harga ke price_history
        PriceHistory::create([
            'game_id'       => $this->game1->id,
            'toko'          => 'Steam',
            'harga'         => 14.99,
            'diskon_persen' => 62.5,
            'dicek_pada'    => now(),
        ]);
        PriceHistory::create([
            'game_id'       => $this->game1->id,
            'toko'          => 'GOG',
            'harga'         => 18.00,
            'diskon_persen' => 55.0,
            'dicek_pada'    => now(),
        ]);

        // Buat wishlist untuk game2 (belum ada riwayat harga)
        $wishlist2 = WishlistAlert::create([
            'user_id'      => $this->user1->id,
            'game_id'      => $this->game2->id,
            'harga_target' => 10.00,
            'aktif'        => true,
        ]);

        $response = $this->withHeaders($this->authHeaders($this->token1))
            ->getJson('/api/wishlist');

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonCount(2, 'data.wishlists');

        $items = collect($response->json('data.wishlists'));
        $item1 = $items->firstWhere('game_id', $this->game1->id);
        $item2 = $items->firstWhere('game_id', $this->game2->id);

        // Verifikasi item1 (ada harga)
        $this->assertEquals(14.99, $item1['harga_terendah']);
        $this->assertEquals('Steam', $item1['toko_termurah']);
        $this->assertEquals(-5.01, $item1['selisih_harga_target']);
        $this->assertNotNull($item1['harga_target_idr_estimasi']);
        $this->assertNotNull($item1['harga_terendah_idr_estimasi']);
        $this->assertTrue($item1['harga_tersedia']);

        // Verifikasi item2 (belum ada harga, selisih null)
        $this->assertNull($item2['harga_terendah']);
        $this->assertNull($item2['toko_termurah']);
        $this->assertNull($item2['selisih_harga_target']);
        $this->assertNull($item2['harga_terendah_idr_estimasi']);
        $this->assertFalse($item2['harga_tersedia']);
    }

    /**
     * 10. Detail game diperluas dengan harga terkini dan status wishlist pengguna
     */
    public function test_game_detail_includes_wishlist_status_and_current_prices(): void
    {
        // Set wishlist alert
        WishlistAlert::create([
            'user_id'      => $this->user1->id,
            'game_id'      => $this->game1->id,
            'harga_target' => 20.00,
            'aktif'        => true,
        ]);

        // Set harga toko
        PriceHistory::create([
            'game_id'       => $this->game1->id,
            'toko'          => 'Steam',
            'harga'         => 14.99,
            'diskon_persen' => 60.0,
            'dicek_pada'    => now(),
        ]);

        $response = $this->withHeaders($this->authHeaders($this->token1))
            ->getJson("/api/games/{$this->game1->id}");

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.in_wishlist', true)
            ->assertJsonPath('data.wishlist_status', 'Aktif')
            ->assertJsonPath('data.harga_tersedia', true)
            ->assertJsonPath('data.harga_terendah', 14.99)
            ->assertJsonPath('data.toko_termurah', 'Steam')
            ->assertJsonCount(1, 'data.harga_terkini');
    }
}
