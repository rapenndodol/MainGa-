<?php

namespace App\Console\Commands;

use App\Models\Game;
use App\Models\WishlistAlert;
use App\Services\PriceService;
use Illuminate\Console\Command;
use Throwable;

class CheckPrices extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'prices:check {--game= : ID game lokal atau RAWG ID untuk pengecekan manual}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Pengecekan harga game via CheapShark API untuk wishlist aktif atau game tertentu';

    /**
     * Execute the console command.
     */
    public function handle(PriceService $priceService): int
    {
        $gameOption = $this->option('game');

        if (!empty($gameOption)) {
            $game = Game::where('id', $gameOption)
                ->orWhere('rawg_id', $gameOption)
                ->first();

            if (! $game) {
                $this->error("Game dengan ID/RAWG ID {$gameOption} tidak ditemukan.");
                return 1;
            }

            $games = collect([$game]);
            $this->info("Memulai pengecekan harga manual untuk 1 game: {$game->judul}");
        } else {
            // Ambil ID game unik yang memiliki wishlist aktif (aktif = true)
            // tanpa duplikasi jika banyak pengguna memantau game yang sama
            $activeGameIds = WishlistAlert::where('aktif', true)
                ->distinct()
                ->pluck('game_id');

            if ($activeGameIds->isEmpty()) {
                $this->info('Tidak ada game dalam wishlist aktif untuk dicek.');
                return 0;
            }

            $games = Game::whereIn('id', $activeGameIds)->get();
            $this->info("Ditemukan {$games->count()} game unik dari wishlist aktif untuk dicek.");
        }

        $successCount = 0;
        foreach ($games as $game) {
            $this->line("Memeriksa: {$game->judul} (ID: {$game->id})...");
            try {
                $result = $priceService->checkAndRecordPrices($game);
                if ($result['available']) {
                    $cheapest = $result['cheapest'] ?? null;
                    $cheapestText = $cheapest ? "(\${$cheapest['harga']} di {$cheapest['toko']})" : '';
                    $this->info(" -> Berhasil diperbarui: " . count($result['deals']) . " deal toko ditemukan {$cheapestText}");
                    $successCount++;
                } else {
                    $this->warn(" -> Harga belum tersedia di CheapShark.");
                }
            } catch (Throwable $e) {
                $this->error(" -> Gagal memeriksa harga: " . $e->getMessage());
            }
        }

        $this->info("Pengecekan harga selesai. {$successCount} game berhasil diperbarui harganya.");
        return 0;
    }
}
