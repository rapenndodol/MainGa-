<?php

namespace Tests\Feature;

use App\Models\Game;
use App\Models\Genre;
use App\Models\Notification;
use App\Models\Platform;
use App\Models\PriceHistory;
use App\Models\User;
use App\Models\WishlistAlert;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class NotificationTest extends TestCase
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
            'nama'  => 'User Pertama',
            'email' => 'user1@test.com',
        ]);
        $this->token1 = $this->user1->createToken('token1')->plainTextToken;

        $this->user2 = User::factory()->create([
            'nama'  => 'User Kedua',
            'email' => 'user2@test.com',
        ]);
        $this->token2 = $this->user2->createToken('token2')->plainTextToken;

        $this->game1 = Game::create([
            'rawg_id'       => 501,
            'judul'         => 'Cyberpunk 2077',
            'cover_url'     => 'https://media.rawg.io/cyberpunk.jpg',
            'rating'        => 4.5,
            'tanggal_rilis' => '2020-12-10',
            'deskripsi'     => 'Night City adventure.',
            'cached_at'     => now(),
        ]);

        $this->game2 = Game::create([
            'rawg_id'       => 502,
            'judul'         => 'Elden Ring',
            'cover_url'     => 'https://media.rawg.io/eldenring.jpg',
            'rating'        => 4.9,
            'tanggal_rilis' => '2022-02-25',
            'deskripsi'     => 'Lands Between masterpiece.',
            'cached_at'     => now(),
        ]);
    }

    protected function authHeaders(string $token): array
    {
        return [
            'Authorization' => 'Bearer ' . $token,
            'Accept'        => 'application/json',
        ];
    }

    /**
     * 1. Notifikasi dibuat tepat saat harga <= target
     */
    public function test_notification_created_when_price_is_less_than_or_equal_to_target(): void
    {
        WishlistAlert::create([
            'user_id'      => $this->user1->id,
            'game_id'      => $this->game1->id,
            'harga_target' => 29.99,
            'aktif'        => true,
        ]);

        Http::fake([
            '*/stores' => Http::response([
                ['storeID' => '1', 'storeName' => 'Steam'],
            ], 200),
            '*/games?title=*' => Http::response([
                ['gameID' => '9901', 'external' => 'Cyberpunk 2077', 'cheapest' => '24.99'],
            ], 200),
            '*/games?id=9901' => Http::response([
                'info'  => ['title' => 'Cyberpunk 2077'],
                'deals' => [
                    ['storeID' => '1', 'price' => '24.99', 'retailPrice' => '59.99', 'savings' => '58.34'],
                ],
            ], 200),
        ]);

        Artisan::call('prices:check', ['--game' => $this->game1->id]);

        $this->assertDatabaseHas('notifications', [
            'user_id' => $this->user1->id,
            'game_id' => $this->game1->id,
            'harga'   => 24.99,
            'toko'    => 'Steam',
        ]);

        $notif = Notification::where('user_id', $this->user1->id)->first();
        $this->assertNotNull($notif);
        $this->assertEquals('Cyberpunk 2077', $notif->judul);
        $this->assertStringContainsString('24.99', $notif->pesan);
        $this->assertStringContainsString('Steam', $notif->pesan);
        $this->assertNull($notif->dibaca_pada);
    }

    /**
     * 2. Notifikasi tidak dibuat saat harga di atas target
     */
    public function test_notification_not_created_when_price_is_above_target(): void
    {
        WishlistAlert::create([
            'user_id'      => $this->user1->id,
            'game_id'      => $this->game1->id,
            'harga_target' => 20.00,
            'aktif'        => true,
        ]);

        Http::fake([
            '*/stores' => Http::response([
                ['storeID' => '1', 'storeName' => 'Steam'],
            ], 200),
            '*/games?title=*' => Http::response([
                ['gameID' => '9901', 'external' => 'Cyberpunk 2077', 'cheapest' => '29.99'],
            ], 200),
            '*/games?id=9901' => Http::response([
                'info'  => ['title' => 'Cyberpunk 2077'],
                'deals' => [
                    ['storeID' => '1', 'price' => '29.99', 'retailPrice' => '59.99', 'savings' => '50.0'],
                ],
            ], 200),
        ]);

        Artisan::call('prices:check', ['--game' => $this->game1->id]);

        $this->assertDatabaseMissing('notifications', [
            'user_id' => $this->user1->id,
            'game_id' => $this->game1->id,
        ]);
    }

    /**
     * 3. Cegah duplikasi: tidak membuat notifikasi baru untuk harga yang sama
     */
    public function test_notification_not_duplicated_for_same_price(): void
    {
        WishlistAlert::create([
            'user_id'      => $this->user1->id,
            'game_id'      => $this->game1->id,
            'harga_target' => 30.00,
            'aktif'        => true,
        ]);

        Http::fake([
            '*/stores' => Http::response([
                ['storeID' => '1', 'storeName' => 'Steam'],
            ], 200),
            '*/games?title=*' => Http::response([
                ['gameID' => '9901', 'external' => 'Cyberpunk 2077', 'cheapest' => '25.00'],
            ], 200),
            '*/games?id=9901' => Http::response([
                'info'  => ['title' => 'Cyberpunk 2077'],
                'deals' => [
                    ['storeID' => '1', 'price' => '25.00', 'retailPrice' => '59.99', 'savings' => '58.33'],
                ],
            ], 200),
        ]);

        // Pengecekan pertama -> menghasilkan notifikasi
        Artisan::call('prices:check', ['--game' => $this->game1->id]);
        $this->assertEquals(1, Notification::where('user_id', $this->user1->id)->count());

        // Pengecekan kedua dengan harga yang sama (25.00) -> tidak boleh ada notifikasi baru
        Artisan::call('prices:check', ['--game' => $this->game1->id]);
        $this->assertEquals(1, Notification::where('user_id', $this->user1->id)->count());
    }

    /**
     * 4. Notifikasi dibuat lagi saat harga berubah (turun lebih jauh atau naik lalu turun lagi)
     */
    public function test_notification_created_again_when_price_changes(): void
    {
        WishlistAlert::create([
            'user_id'      => $this->user1->id,
            'game_id'      => $this->game1->id,
            'harga_target' => 30.00,
            'aktif'        => true,
        ]);

        // 1. Harga turun ke 25.00
        Artisan::call('prices:simulate', [
            'game_id' => $this->game1->id,
            'harga'   => 25.00,
        ]);
        $this->assertEquals(1, Notification::where('user_id', $this->user1->id)->count());

        // 2. Harga sama 25.00 -> tidak buat notifikasi baru
        Artisan::call('prices:simulate', [
            'game_id' => $this->game1->id,
            'harga'   => 25.00,
        ]);
        $this->assertEquals(1, Notification::where('user_id', $this->user1->id)->count());

        // 3. Harga turun lebih jauh ke 19.99 -> buat notifikasi baru
        Artisan::call('prices:simulate', [
            'game_id' => $this->game1->id,
            'harga'   => 19.99,
        ]);
        $this->assertEquals(2, Notification::where('user_id', $this->user1->id)->count());

        // 4. Harga naik ke 35.00 (di atas target) -> tidak buat notifikasi
        Artisan::call('prices:simulate', [
            'game_id' => $this->game1->id,
            'harga'   => 35.00,
        ]);
        $this->assertEquals(2, Notification::where('user_id', $this->user1->id)->count());

        // 5. Harga turun kembali ke 25.00 (naik lalu turun lagi) -> buat notifikasi baru
        Artisan::call('prices:simulate', [
            'game_id' => $this->game1->id,
            'harga'   => 25.00,
        ]);
        $this->assertEquals(3, Notification::where('user_id', $this->user1->id)->count());
    }

    /**
     * 5. Wishlist nonaktif tidak menghasilkan notifikasi
     */
    public function test_inactive_wishlist_does_not_create_notification(): void
    {
        WishlistAlert::create([
            'user_id'      => $this->user1->id,
            'game_id'      => $this->game1->id,
            'harga_target' => 50.00,
            'aktif'        => false, // Pantauan dinonaktifkan
        ]);

        Artisan::call('prices:simulate', [
            'game_id' => $this->game1->id,
            'harga'   => 20.00,
        ]);

        $this->assertEquals(0, Notification::where('user_id', $this->user1->id)->count());
    }

    /**
     * 6. Beberapa pengguna yang memantau game yang sama mendapat notifikasi masing-masing
     */
    public function test_multiple_users_monitoring_same_game_receive_their_own_notifications(): void
    {
        // User 1 target 30.00
        WishlistAlert::create([
            'user_id'      => $this->user1->id,
            'game_id'      => $this->game1->id,
            'harga_target' => 30.00,
            'aktif'        => true,
        ]);

        // User 2 target 25.00
        WishlistAlert::create([
            'user_id'      => $this->user2->id,
            'game_id'      => $this->game1->id,
            'harga_target' => 25.00,
            'aktif'        => true,
        ]);

        // Simulasi harga 22.00 (memenuhi target User 1 dan User 2)
        Artisan::call('prices:simulate', [
            'game_id' => $this->game1->id,
            'harga'   => 22.00,
        ]);

        $this->assertEquals(1, Notification::where('user_id', $this->user1->id)->count());
        $this->assertEquals(1, Notification::where('user_id', $this->user2->id)->count());

        $this->assertDatabaseHas('notifications', [
            'user_id' => $this->user1->id,
            'game_id' => $this->game1->id,
            'harga'   => 22.00,
        ]);
        $this->assertDatabaseHas('notifications', [
            'user_id' => $this->user2->id,
            'game_id' => $this->game1->id,
            'harga'   => 22.00,
        ]);
    }

    /**
     * 7. Pengecekan awal saat POST /api/wishlist langsung memicu notifikasi jika harga <= target
     */
    public function test_notification_created_on_post_wishlist(): void
    {
        Http::fake([
            '*/stores' => Http::response([
                ['storeID' => '1', 'storeName' => 'Steam'],
            ], 200),
            '*/games?title=*' => Http::response([
                ['gameID' => '9902', 'external' => 'Elden Ring', 'cheapest' => '39.99'],
            ], 200),
            '*/games?id=9902' => Http::response([
                'info'  => ['title' => 'Elden Ring'],
                'deals' => [
                    ['storeID' => '1', 'price' => '39.99', 'retailPrice' => '59.99', 'savings' => '33.34'],
                ],
            ], 200),
        ]);

        $response = $this->postJson('/api/wishlist', [
            'game_id'      => $this->game2->id,
            'harga_target' => 45.00,
            'aktif'        => true,
        ], $this->authHeaders($this->token1));

        $response->assertStatus(201);

        $this->assertDatabaseHas('notifications', [
            'user_id' => $this->user1->id,
            'game_id' => $this->game2->id,
            'harga'   => 39.99,
            'toko'    => 'Steam',
        ]);
    }

    /**
     * 8. Endpoint GET /api/notifications (urut terbaru, pagination, memuat judul game, toko, harga, waktu, status dibaca)
     */
    public function test_get_notifications_list(): void
    {
        Notification::create([
            'user_id'     => $this->user1->id,
            'game_id'     => $this->game1->id,
            'judul'       => $this->game1->judul,
            'pesan'       => 'Pesan notifikasi lama',
            'harga'       => 29.99,
            'toko'        => 'Steam',
            'dibaca_pada' => Carbon::now()->subDay(),
            'created_at'  => Carbon::now()->subDay(),
        ]);

        Notification::create([
            'user_id'     => $this->user1->id,
            'game_id'     => $this->game2->id,
            'judul'       => $this->game2->judul,
            'pesan'       => 'Pesan notifikasi terbaru',
            'harga'       => 19.99,
            'toko'        => 'GOG',
            'dibaca_pada' => null,
            'created_at'  => Carbon::now(),
        ]);

        $response = $this->getJson('/api/notifications', $this->authHeaders($this->token1));

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Daftar notifikasi berhasil diambil',
            ])
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'notifications' => [
                        '*' => [
                            'id',
                            'user_id',
                            'game_id',
                            'judul',
                            'judul_game',
                            'pesan',
                            'harga',
                            'toko',
                            'dibaca_pada',
                            'status_dibaca',
                            'sudah_dibaca',
                            'waktu',
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

        $items = $response->json('data.notifications');
        $this->assertCount(2, $items);
        // Notifikasi terbaru tampil di urutan pertama
        $this->assertEquals('Elden Ring', $items[0]['judul']);
        $this->assertEquals('GOG', $items[0]['toko']);
        $this->assertEquals(19.99, $items[0]['harga']);
        $this->assertEquals('belum_dibaca', $items[0]['status_dibaca']);
        $this->assertFalse($items[0]['sudah_dibaca']);

        $this->assertEquals('Cyberpunk 2077', $items[1]['judul']);
        $this->assertEquals('dibaca', $items[1]['status_dibaca']);
        $this->assertTrue($items[1]['sudah_dibaca']);
    }

    /**
     * 9. Endpoint GET /api/notifications/unread-count
     */
    public function test_get_unread_count(): void
    {
        Notification::create([
            'user_id'     => $this->user1->id,
            'game_id'     => $this->game1->id,
            'judul'       => $this->game1->judul,
            'pesan'       => 'Notif 1',
            'harga'       => 20.00,
            'toko'        => 'Steam',
            'dibaca_pada' => null,
        ]);

        Notification::create([
            'user_id'     => $this->user1->id,
            'game_id'     => $this->game2->id,
            'judul'       => $this->game2->judul,
            'pesan'       => 'Notif 2',
            'harga'       => 15.00,
            'toko'        => 'Steam',
            'dibaca_pada' => null,
        ]);

        Notification::create([
            'user_id'     => $this->user1->id,
            'game_id'     => $this->game1->id,
            'judul'       => $this->game1->judul,
            'pesan'       => 'Notif 3 sudah dibaca',
            'harga'       => 25.00,
            'toko'        => 'Steam',
            'dibaca_pada' => now(),
        ]);

        $response = $this->getJson('/api/notifications/unread-count', $this->authHeaders($this->token1));

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data'    => [
                    'unread_count' => 2,
                ],
            ]);
    }

    /**
     * 10. Endpoint PUT /api/notifications/{id}/read
     */
    public function test_mark_notification_as_read(): void
    {
        $notif = Notification::create([
            'user_id'     => $this->user1->id,
            'game_id'     => $this->game1->id,
            'judul'       => $this->game1->judul,
            'pesan'       => 'Notif unread',
            'harga'       => 20.00,
            'toko'        => 'Steam',
            'dibaca_pada' => null,
        ]);

        $response = $this->putJson("/api/notifications/{$notif->id}/read", [], $this->authHeaders($this->token1));

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data'    => [
                    'id'           => $notif->id,
                    'sudah_dibaca' => true,
                    'status_dibaca'=> 'dibaca',
                ],
            ]);

        $notif->refresh();
        $this->assertNotNull($notif->dibaca_pada);
    }

    /**
     * 11. Endpoint PUT /api/notifications/read-all
     */
    public function test_mark_all_notifications_as_read(): void
    {
        Notification::create([
            'user_id'     => $this->user1->id,
            'game_id'     => $this->game1->id,
            'judul'       => 'Game 1',
            'pesan'       => 'Unread 1',
            'harga'       => 20.00,
            'toko'        => 'Steam',
            'dibaca_pada' => null,
        ]);

        Notification::create([
            'user_id'     => $this->user1->id,
            'game_id'     => $this->game2->id,
            'judul'       => 'Game 2',
            'pesan'       => 'Unread 2',
            'harga'       => 30.00,
            'toko'        => 'Steam',
            'dibaca_pada' => null,
        ]);

        $response = $this->putJson('/api/notifications/read-all', [], $this->authHeaders($this->token1));

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data'    => [
                    'updated_count' => 2,
                ],
            ]);

        $this->assertEquals(0, Notification::where('user_id', $this->user1->id)->whereNull('dibaca_pada')->count());
    }

    /**
     * 12. Notifikasi pengguna lain tidak bisa diakses (403)
     */
    public function test_cannot_access_other_users_notification(): void
    {
        $notifUser2 = Notification::create([
            'user_id'     => $this->user2->id,
            'game_id'     => $this->game1->id,
            'judul'       => $this->game1->judul,
            'pesan'       => 'Milik User 2',
            'harga'       => 20.00,
            'toko'        => 'Steam',
            'dibaca_pada' => null,
        ]);

        // User 1 mencoba menandai dibaca notifikasi User 2
        $response = $this->putJson("/api/notifications/{$notifUser2->id}/read", [], $this->authHeaders($this->token1));

        $response->assertStatus(403);
    }

    /**
     * 13. Akses endpoint notifikasi tanpa token mengembalikan 401
     */
    public function test_unauthenticated_access_returns_401(): void
    {
        $this->getJson('/api/notifications')->assertStatus(401);
        $this->getJson('/api/notifications/unread-count')->assertStatus(401);
        $this->putJson('/api/notifications/1/read')->assertStatus(401);
        $this->putJson('/api/notifications/read-all')->assertStatus(401);
    }
}
