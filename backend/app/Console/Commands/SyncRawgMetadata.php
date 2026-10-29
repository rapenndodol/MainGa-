<?php

namespace App\Console\Commands;

use App\Models\Genre;
use App\Models\Platform;
use App\Services\RawgService;
use Illuminate\Console\Command;

class SyncRawgMetadata extends Command
{
    /**
     * Nama dan signature command
     */
    protected $signature = 'rawg:sync-master';

    /**
     * Deskripsi command
     */
    protected $description = 'Mengisi dan memperbarui master tabel genres dan platforms dari RAWG API';

    public function handle(RawgService $rawgService): int
    {
        $this->info('Memulai sinkronisasi genre dan platform dari RAWG...');

        // ── 1. Sinkronisasi Genre ────────────────────────────────
        $this->info('Mengambil data genre dari RAWG...');
        $genresData = $rawgService->getGenres(50);

        if ($genresData && !empty($genresData['results'])) {
            $count = 0;
            foreach ($genresData['results'] as $item) {
                Genre::updateOrCreate(
                    ['rawg_id' => $item['id']],
                    ['nama' => $item['name']]
                );
                $count++;
            }
            $this->info("Berhasil sinkronisasi {$count} genre dari RAWG API.");
        } else {
            $this->warn('Gagal mengambil genre dari RAWG atau API offline. Memeriksa fallback data standar...');
            if (Genre::count() === 0) {
                $defaultGenres = [
                    ['id' => 4, 'name' => 'Action'],
                    ['id' => 51, 'name' => 'Indie'],
                    ['id' => 3, 'name' => 'Adventure'],
                    ['id' => 5, 'name' => 'RPG'],
                    ['id' => 10, 'name' => 'Strategy'],
                    ['id' => 2, 'name' => 'Shooter'],
                    ['id' => 40, 'name' => 'Casual'],
                    ['id' => 14, 'name' => 'Simulation'],
                    ['id' => 7, 'name' => 'Puzzle'],
                    ['id' => 11, 'name' => 'Arcade'],
                    ['id' => 83, 'name' => 'Platformer'],
                    ['id' => 1, 'name' => 'Racing'],
                    ['id' => 59, 'name' => 'Massively Multiplayer'],
                    ['id' => 15, 'name' => 'Sports'],
                    ['id' => 6, 'name' => 'Fighting'],
                    ['id' => 19, 'name' => 'Family'],
                ];
                foreach ($defaultGenres as $item) {
                    Genre::updateOrCreate(
                        ['rawg_id' => $item['id']],
                        ['nama' => $item['name']]
                    );
                }
                $this->info('Berhasil mengisi ' . count($defaultGenres) . ' genre standar.');
            }
        }

        // ── 2. Sinkronisasi Platform ─────────────────────────────
        $this->info('Mengambil data platform dari RAWG...');
        $platformsData = $rawgService->getPlatforms(50);

        if ($platformsData && !empty($platformsData['results'])) {
            $count = 0;
            foreach ($platformsData['results'] as $item) {
                Platform::updateOrCreate(
                    ['rawg_id' => $item['id']],
                    ['nama' => $item['name']]
                );
                $count++;
            }
            $this->info("Berhasil sinkronisasi {$count} platform dari RAWG API.");
        } else {
            $this->warn('Gagal mengambil platform dari RAWG atau API offline. Memeriksa fallback data standar...');
            if (Platform::count() === 0) {
                $defaultPlatforms = [
                    ['id' => 4, 'name' => 'PC'],
                    ['id' => 187, 'name' => 'PlayStation 5'],
                    ['id' => 18, 'name' => 'PlayStation 4'],
                    ['id' => 1, 'name' => 'Xbox One'],
                    ['id' => 186, 'name' => 'Xbox Series S/X'],
                    ['id' => 7, 'name' => 'Nintendo Switch'],
                    ['id' => 3, 'name' => 'iOS'],
                    ['id' => 21, 'name' => 'Android'],
                    ['id' => 8, 'name' => 'Nintendo 3DS'],
                    ['id' => 9, 'name' => 'Nintendo DS'],
                    ['id' => 14, 'name' => 'Xbox 360'],
                    ['id' => 16, 'name' => 'PlayStation 3'],
                ];
                foreach ($defaultPlatforms as $item) {
                    Platform::updateOrCreate(
                        ['rawg_id' => $item['id']],
                        ['nama' => $item['name']]
                    );
                }
                $this->info('Berhasil mengisi ' . count($defaultPlatforms) . ' platform standar.');
            }
        }

        $this->info('Sinkronisasi metadata selesai.');
        return Command::SUCCESS;
    }
}
