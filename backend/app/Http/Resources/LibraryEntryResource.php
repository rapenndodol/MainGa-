<?php

namespace App\Http\Resources;

use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class LibraryEntryResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $game = $this->game;
        $genreNames = $game && $game->relationLoaded('genres') ? $game->genres->pluck('nama')->toArray() : ($game ? $game->genres()->pluck('nama')->toArray() : []);
        $platformNames = $game && $game->relationLoaded('platforms') ? $game->platforms->pluck('nama')->toArray() : ($game ? $game->platforms()->pluck('nama')->toArray() : []);

        return [
            'id'             => $this->id,
            'user_id'        => $this->user_id,
            'game_id'        => $this->game_id,
            'status'         => $this->status,
            'rating_pribadi' => $this->rating_pribadi !== null ? (int) $this->rating_pribadi : null,
            'jam_main'       => (float) $this->jam_main,
            'catatan'        => $this->catatan,
            'tanggal_tamat'  => $this->tanggal_tamat ? Carbon::parse($this->tanggal_tamat)->format('Y-m-d') : null,
            'created_at'     => $this->created_at?->toIso8601String(),
            'updated_at'     => $this->updated_at?->toIso8601String(),
            'game'           => $game ? [
                'id'            => $game->id,
                'rawg_id'       => $game->rawg_id,
                'judul'         => $game->judul,
                'cover_url'     => $game->cover_url,
                'rating'        => (float) $game->rating,
                'genre'         => implode(', ', $genreNames),
                'genres'        => $genreNames,
                'platform'      => implode(', ', $platformNames),
                'platforms'     => $platformNames,
                'tanggal_rilis' => $game->tanggal_rilis ? Carbon::parse($game->tanggal_rilis)->format('Y-m-d') : null,
            ] : null,
            'judul'          => $game?->judul,
            'cover_url'      => $game?->cover_url,
            'game_rating'    => $game ? (float) $game->rating : 0.0,
            'genre'          => implode(', ', $genreNames),
            'platform'       => implode(', ', $platformNames),
        ];
    }
}
