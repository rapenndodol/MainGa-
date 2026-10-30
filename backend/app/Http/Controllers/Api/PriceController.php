<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Game;
use App\Models\PriceHistory;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PriceController extends Controller
{
    /**
     * GET /api/games/{id}/prices
     * Mengambil harga terkini per toko dan riwayat harga (untuk grafik garis) dalam urutan waktu.
     */
    public function gamePrices(Request $request, $id): JsonResponse
    {
        $game = Game::where('id', $id)
            ->orWhere('rawg_id', $id)
            ->first();

        if (! $game) {
            return response()->json([
                'success' => false,
                'message' => 'Game tidak ditemukan.',
                'data'    => null,
            ], 404);
        }

        $rate = (float) config('services.currency.usd_to_idr_rate', 16000);

        // Ambil harga terkini per toko (entri terbaru per toko)
        $latestPrices = PriceHistory::where('game_id', $game->id)
            ->whereIn('id', function ($query) use ($game) {
                $query->selectRaw('MAX(id)')
                    ->from('price_history')
                    ->where('game_id', $game->id)
                    ->groupBy('toko');
            })
            ->orderBy('harga', 'asc')
            ->get();

        // Ambil riwayat lengkap seluruh pengecekan harga dalam urutan waktu kronologis (untuk grafik garis)
        $history = PriceHistory::where('game_id', $game->id)
            ->orderBy('dicek_pada', 'asc')
            ->get();

        $cheapest = $latestPrices->first();

        $formattedCurrent = $latestPrices->map(function ($item) use ($rate) {
            return [
                'id'                 => $item->id,
                'toko'               => $item->toko,
                'harga'              => (float) $item->harga,
                'harga_idr_estimasi' => (int) round($item->harga * $rate),
                'diskon_persen'      => (float) $item->diskon_persen,
                'dicek_pada'         => $item->dicek_pada ? Carbon::parse($item->dicek_pada)->toIso8601String() : null,
            ];
        });

        $formattedHistory = $history->map(function ($item) use ($rate) {
            return [
                'id'                 => $item->id,
                'toko'               => $item->toko,
                'harga'              => (float) $item->harga,
                'harga_idr_estimasi' => (int) round($item->harga * $rate),
                'diskon_persen'      => (float) $item->diskon_persen,
                'dicek_pada'         => $item->dicek_pada ? Carbon::parse($item->dicek_pada)->toIso8601String() : null,
            ];
        });

        $hasPrices = $latestPrices->isNotEmpty();

        return response()->json([
            'success' => true,
            'message' => $hasPrices ? 'Data harga game berhasil diambil' : 'Harga belum tersedia untuk game ini',
            'data'    => [
                'game' => [
                    'id'            => $game->id,
                    'rawg_id'       => $game->rawg_id,
                    'cheapshark_id' => $game->cheapshark_id,
                    'judul'         => $game->judul,
                ],
                'harga_tersedia'              => $hasPrices,
                'status_keterangan'           => $hasPrices ? 'Harga tersedia' : 'Harga belum tersedia',
                'harga_terendah'              => $cheapest ? (float) $cheapest->harga : null,
                'harga_terendah_idr_estimasi' => $cheapest ? (int) round($cheapest->harga * $rate) : null,
                'toko_termurah'               => $cheapest?->toko,
                'kurs_usd_ke_idr_estimasi'    => $rate,
                'harga_terkini'               => $formattedCurrent,
                'riwayat_harga'               => $formattedHistory,
            ],
        ], 200);
    }
}
