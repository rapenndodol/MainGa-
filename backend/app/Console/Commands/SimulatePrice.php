<?php

namespace App\Console\Commands;

use App\Models\Game;
use App\Models\PriceHistory;
use App\Services\PriceService;
use Illuminate\Console\Command;

class SimulatePrice extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'prices:simulate {game_id : ID lokal atau RAWG ID game} {harga : Harga simulasi dalam USD}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Simulasi harga game dan picu alur pembuatan notifikasi penurunan harga (hanya non-production)';

    /**
     * Execute the console command.
     */
    public function handle(PriceService $priceService): int
    {
        // 1. Tolak jika berjalan di lingkungan production
        if (app()->environment('production')) {
            $this->error('Perintah prices:simulate hanya boleh dijalankan di lingkungan non-production (local/testing).');
            return 1;
        }

        $gameId = $this->argument('game_id');
        $game = Game::where('id', $gameId)->orWhere('rawg_id', $gameId)->first();

        if (! $game) {
            $this->error("Game dengan ID/RAWG ID {$gameId} tidak ditemukan.");
            return 1;
        }

        $hargaInput = $this->argument('harga');
        if (! is_numeric($hargaInput) || (float) $hargaInput < 0) {
            $this->error('Harga harus berupa angka lebih besar atau sama dengan 0.');
            return 1;
        }

        $harga = round((float) $hargaInput, 2);

        // 2. Simpan satu baris price_history simulasi
        PriceHistory::create([
            'game_id'       => $game->id,
            'toko'          => 'Simulasi',
            'harga'         => $harga,
            'diskon_persen' => 0.0,
            'dicek_pada'    => now(),
        ]);

        // 3. Jalankan logika pembuatan notifikasi penurunan harga seperti pengecekan sungguhan
        $notifiedCount = $priceService->notifyWishlistUsers($game, $harga, 'Simulasi');

        $this->info("Simulasi harga berhasil dicatat untuk game '{$game->judul}' dengan harga \${$harga} di toko Simulasi.");
        $this->info("Notifikasi penurunan harga berhasil dibuat untuk {$notifiedCount} pengguna.");

        return 0;
    }
}
