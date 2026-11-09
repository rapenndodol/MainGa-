<?php

namespace Tests\Feature;

use App\Models\Game;
use App\Models\Notification;
use App\Models\PriceHistory;
use App\Models\User;
use App\Models\WishlistAlert;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\App;
use Illuminate\Support\Facades\Artisan;
use Tests\TestCase;

class PriceSimulateCommandTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected Game $game;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create([
            'nama'  => 'Sim Tester',
            'email' => 'sim@test.com',
        ]);

        $this->game = Game::create([
            'rawg_id'       => 999,
            'judul'         => 'Elden Ring: Shadow of the Erdtree',
            'cover_url'     => 'https://media.rawg.io/erdtree.jpg',
            'rating'        => 5.0,
            'tanggal_rilis' => '2024-06-21',
            'cached_at'     => now(),
        ]);
    }

    /**
     * 1. Command menolak berjalan di lingkungan production
     */
    public function test_prices_simulate_refuses_to_run_in_production(): void
    {
        App::detectEnvironment(fn () => 'production');

        $this->artisan("prices:simulate {$this->game->id} 19.99")
            ->expectsOutputToContain('hanya boleh dijalankan di lingkungan non-production')
            ->assertExitCode(1);

        $this->assertDatabaseMissing('price_history', [
            'game_id' => $this->game->id,
            'toko'    => 'Simulasi',
        ]);
    }

    /**
     * 2. Command berjalan di non-production, menyimpan price_history, dan memicu pembuatan notifikasi
     */
    public function test_prices_simulate_records_history_and_triggers_notifications(): void
    {
        WishlistAlert::create([
            'user_id'      => $this->user->id,
            'game_id'      => $this->game->id,
            'harga_target' => 25.00,
            'aktif'        => true,
        ]);

        $this->artisan("prices:simulate {$this->game->id} 19.99")
            ->expectsOutputToContain('Simulasi harga berhasil dicatat')
            ->expectsOutputToContain('Notifikasi penurunan harga berhasil dibuat untuk 1 pengguna')
            ->assertExitCode(0);

        // Baris price_history simulasi tersimpan
        $this->assertDatabaseHas('price_history', [
            'game_id' => $this->game->id,
            'toko'    => 'Simulasi',
            'harga'   => 19.99,
        ]);

        // Notifikasi penurunan harga terbuat
        $this->assertDatabaseHas('notifications', [
            'user_id' => $this->user->id,
            'game_id' => $this->game->id,
            'toko'    => 'Simulasi',
            'harga'   => 19.99,
        ]);
    }

    /**
     * 3. Validasi input: game tidak ditemukan atau harga tidak valid
     */
    public function test_prices_simulate_validates_game_and_price(): void
    {
        // ID game tidak ada
        $this->artisan('prices:simulate 99999 15.00')
            ->expectsOutputToContain('tidak ditemukan')
            ->assertExitCode(1);

        // Harga bukan angka
        $this->artisan('prices:simulate', [
            'game_id' => $this->game->id,
            'harga'   => 'bukan-angka',
        ])
            ->expectsOutputToContain('Harga harus berupa angka lebih besar atau sama dengan 0')
            ->assertExitCode(1);

        // Harga negatif
        $this->artisan('prices:simulate', [
            'game_id' => $this->game->id,
            'harga'   => '-10',
        ])
            ->expectsOutputToContain('Harga harus berupa angka lebih besar atau sama dengan 0')
            ->assertExitCode(1);
    }
}
