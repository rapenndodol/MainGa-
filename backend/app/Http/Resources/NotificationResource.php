<?php

namespace App\Http\Resources;

use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class NotificationResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $game = $this->game;

        return [
            'id'            => $this->id,
            'user_id'       => $this->user_id,
            'game_id'       => $this->game_id,
            'judul'         => $this->judul,
            'judul_game'    => $game?->judul ?? $this->judul,
            'pesan'         => $this->pesan,
            'harga'         => $this->harga !== null ? (float) $this->harga : null,
            'toko'          => $this->toko,
            'dibaca_pada'   => $this->dibaca_pada ? Carbon::parse($this->dibaca_pada)->toIso8601String() : null,
            'sudah_dibaca'  => $this->dibaca_pada !== null,
            'status_dibaca' => $this->dibaca_pada !== null ? 'dibaca' : 'belum_dibaca',
            'waktu'         => $this->created_at ? Carbon::parse($this->created_at)->toIso8601String() : null,
            'created_at'    => $this->created_at?->toIso8601String(),
            'updated_at'    => $this->updated_at?->toIso8601String(),
            'game'          => $game ? [
                'id'        => $game->id,
                'judul'     => $game->judul,
                'cover_url' => $game->cover_url,
            ] : null,
        ];
    }
}
