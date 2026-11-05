<?php

namespace App\Http\Resources;

use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class GameResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $genreNames = $this->relationLoaded('genres')
            ? $this->genres->pluck('nama')->toArray()
            : $this->genres()->pluck('nama')->toArray();

        $platformNames = $this->relationLoaded('platforms')
            ? $this->platforms->pluck('nama')->toArray()
            : $this->platforms()->pluck('nama')->toArray();

        $data = [
            'id'            => $this->id,
            'rawg_id'       => $this->rawg_id,
            'judul'         => $this->judul,
            'cover_url'     => $this->cover_url,
            'rating'        => (float) $this->rating,
            'genre'         => implode(', ', $genreNames),
            'genres'        => $genreNames,
            'platform'      => implode(', ', $platformNames),
            'platforms'     => $platformNames,
            'tanggal_rilis' => $this->tanggal_rilis ? Carbon::parse($this->tanggal_rilis)->format('Y-m-d') : null,
        ];

        if (isset($this->alasan)) {
            $data['alasan'] = (string) $this->alasan;
        }

        return $data;
    }
}
