<?php

namespace Database\Seeders;

use App\Models\Game;
use App\Models\PriceHistory;
use App\Models\User;
use App\Models\WishlistAlert;
use Carbon\Carbon;
use Illuminate\Database\Seeder;

class PriceHistoryDemoSeeder extends Seeder
{
    /**
     * Jalankan seeder simulasi riwayat harga untuk pengembangan lokal dan demo.
     * PERINGATAN: Seeder ini khusus untuk demo/pengembangan lokal dan tidak
     * dijalankan secara otomatis oleh DatabaseSeeder.
     */
    public function run(): void
    {
        $this->command?->info('Menjalankan PriceHistoryDemoSeeder (data simulasi harga)...');

        $activeAlerts = WishlistAlert::with('game')->where('aktif', true)->get();

        // Bila belum ada wishlist aktif di database, siapkan data contoh agar seeder tetap menghasilkan data
        if ($activeAlerts->isEmpty()) {
            $user = User::first();
            if (! $user) {
                $user = User::create([
                    'nama'     => 'Dimas Demo',
                    'email'    => 'dimas.demo@mainga.local',
                    'password' => bcrypt('password123'),
                ]);
            }

            $game = Game::first();
            if (! $game) {
                $game = Game::create([
                    'rawg_id'       => 3498,
                    'cheapshark_id' => '1447',
                    'judul'         => 'Grand Theft Auto V',
                    'cover_url'     => 'https://media.rawg.io/media/games/20a/20aa58474e73893f35e2582230b7a4b5.jpg',
                    'rating'        => 4.47,
                    'deskripsi'     => 'Game open world dari Rockstar Games.',
                    'tanggal_rilis' => '2013-09-17',
                    'cached_at'     => now(),
                ]);
            }

            $alert = WishlistAlert::firstOrCreate(
                [
                    'user_id' => $user->id,
                    'game_id' => $game->id,
                ],
                [
                    'harga_target' => 20.00,
                    'aktif'        => true,
                ]
            );

            $activeAlerts = collect([$alert->load('game')]);
        }

        $now = Carbon::now();
        $seededCount = 0;

        foreach ($activeAlerts as $alert) {
            $game = $alert->game;
            if (! $game) {
                continue;
            }

            $target = (float) $alert->harga_target;
            if ($target <= 0) {
                $target = 25.00;
            }

            // Hapus riwayat harga lama untuk game ini agar data simulasi rapi
            PriceHistory::where('game_id', $game->id)->delete();

            // Skenario simulasi harga selama 4 minggu (beberapa toko: Steam, Epic Games Store, GOG)
            // Pola: Harga normal -> Diskon awal -> Diskon besar di bawah target -> Harga naik kembali -> Penawaran saat ini
            $timeline = [
                [
                    'sub_days' => 28,
                    'stores'   => [
                        ['toko' => 'Steam', 'harga' => round($target * 1.6, 2), 'diskon' => 0.0],
                        ['toko' => 'Epic Games Store', 'harga' => round($target * 1.6, 2), 'diskon' => 0.0],
                        ['toko' => 'GOG', 'harga' => round($target * 1.7, 2), 'diskon' => 0.0],
                    ],
                ],
                [
                    'sub_days' => 21,
                    'stores'   => [
                        ['toko' => 'Steam', 'harga' => round($target * 1.3, 2), 'diskon' => 20.0],
                        ['toko' => 'Epic Games Store', 'harga' => round($target * 1.6, 2), 'diskon' => 0.0],
                        ['toko' => 'GOG', 'harga' => round($target * 1.5, 2), 'diskon' => 10.0],
                    ],
                ],
                [
                    'sub_days' => 14,
                    'stores'   => [
                        ['toko' => 'Steam', 'harga' => round($target * 1.1, 2), 'diskon' => 30.0],
                        ['toko' => 'Epic Games Store', 'harga' => round($target * 1.25, 2), 'diskon' => 22.0],
                        ['toko' => 'GOG', 'harga' => round($target * 1.4, 2), 'diskon' => 15.0],
                    ],
                ],
                [
                    // Titik di mana harga jatuh DI BAWAH HARGA TARGET (Flash Sale)
                    'sub_days' => 7,
                    'stores'   => [
                        ['toko' => 'Steam', 'harga' => round($target * 0.85, 2), 'diskon' => 50.0],
                        ['toko' => 'Epic Games Store', 'harga' => round($target * 0.90, 2), 'diskon' => 45.0],
                        ['toko' => 'GOG', 'harga' => round($target * 1.2, 2), 'diskon' => 25.0],
                    ],
                ],
                [
                    'sub_days' => 3,
                    'stores'   => [
                        ['toko' => 'Steam', 'harga' => round($target * 1.25, 2), 'diskon' => 20.0],
                        ['toko' => 'Epic Games Store', 'harga' => round($target * 0.95, 2), 'diskon' => 40.0], // tetap di bawah target di Epic
                        ['toko' => 'GOG', 'harga' => round($target * 1.35, 2), 'diskon' => 15.0],
                    ],
                ],
                [
                    // Kondisi terkini
                    'sub_days' => 0,
                    'stores'   => [
                        ['toko' => 'Steam', 'harga' => round($target * 0.90, 2), 'diskon' => 45.0], // Steam di bawah target
                        ['toko' => 'Epic Games Store', 'harga' => round($target * 1.15, 2), 'diskon' => 25.0],
                        ['toko' => 'GOG', 'harga' => round($target * 1.30, 2), 'diskon' => 20.0],
                    ],
                ],
            ];

            foreach ($timeline as $point) {
                $checkedAt = (clone $now)->subDays($point['sub_days']);

                foreach ($point['stores'] as $st) {
                    PriceHistory::create([
                        'game_id'       => $game->id,
                        'toko'          => $st['toko'],
                        'harga'         => $st['harga'],
                        'diskon_persen' => $st['diskon'],
                        'dicek_pada'    => $checkedAt,
                    ]);
                    $seededCount++;
                }
            }

            $this->command?->info("✓ Berhasil membuat riwayat harga simulasi untuk game: '{$game->judul}' (Target: \${$target})");
        }

        $this->command?->info("PriceHistoryDemoSeeder selesai: {$seededCount} titik harga simulasi tersimpan.");
    }
}
