<?php

namespace App\Http\Resources;

use App\Models\PriceHistory;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class WishlistResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $rate = (float) config('services.currency.usd_to_idr_rate', 16000);
        $game = $this->game;
        $genreNames = $game && $game->relationLoaded('genres') ? $game->genres->pluck('nama')->toArray() : ($game ? $game->genres()->pluck('nama')->toArray() : []);
        $platformNames = $game && $game->relationLoaded('platforms') ? $game->platforms->pluck('nama')->toArray() : ($game ? $game->platforms()->pluck('nama')->toArray() : []);

        // Ambil harga terkini per toko dari price_history untuk game ini
        $latestPrice = null;
        if ($game) {
            $latestPrice = PriceHistory::where('game_id', $game->id)
                ->whereIn('id', function ($query) use ($game) {
                    $query->selectRaw('MAX(id)')
                        ->from('price_history')
                        ->where('game_id', $game->id)
                        ->groupBy('toko');
                })
                ->orderBy('harga', 'asc')
                ->first();
        }

        $hargaTarget = (float) $this->harga_target;
        $hargaTargetIdr = (int) round($hargaTarget * $rate);

        $hargaTerendah = $latestPrice ? (float) $latestPrice->harga : null;
        $tokoTermurah = $latestPrice?->toko;
        $diskonPersen = $latestPrice ? (float) $latestPrice->diskon_persen : null;
        $hargaTerendahIdr = $hargaTerendah !== null ? (int) round($hargaTerendah * $rate) : null;

        $selisih = $hargaTerendah !== null ? round($hargaTerendah - $hargaTarget, 2) : null;
        $selisihIdr = $selisih !== null ? (int) round($selisih * $rate) : null;

        return [
            'id'                                => $this->id,
            'user_id'                           => $this->user_id,
            'game_id'                           => $this->game_id,
            'harga_target'                      => $hargaTarget,
            'harga_target_idr_estimasi'         => $hargaTargetIdr,
            'aktif'                             => (bool) $this->aktif,
            'harga_tersedia'                    => $hargaTerendah !== null,
            'harga_terendah'                    => $hargaTerendah,
            'harga_terendah_idr_estimasi'       => $hargaTerendahIdr,
            'toko_termurah'                     => $tokoTermurah,
            'diskon_persen'                     => $diskonPersen,
            'selisih_harga_target'              => $selisih,
            'selisih_harga_target_idr_estimasi' => $selisihIdr,
            'kurs_usd_ke_idr_estimasi'          => $rate,
            'dicek_terakhir'                    => $latestPrice?->dicek_pada ? Carbon::parse($latestPrice->dicek_pada)->toIso8601String() : null,
            'created_at'                        => $this->created_at?->toIso8601String(),
            'updated_at'                        => $this->updated_at?->toIso8601String(),
            'game'                              => $game ? [
                'id'            => $game->id,
                'rawg_id'       => $game->rawg_id,
                'cheapshark_id' => $game->cheapshark_id,
                'judul'         => $game->judul,
                'cover_url'     => $game->cover_url,
                'rating'        => (float) $game->rating,
                'genre'         => implode(', ', $genreNames),
                'genres'        => $genreNames,
                'platform'      => implode(', ', $platformNames),
                'platforms'     => $platformNames,
                'tanggal_rilis' => $game->tanggal_rilis ? Carbon::parse($game->tanggal_rilis)->format('Y-m-d') : null,
            ] : null,
        ];
    }
}
