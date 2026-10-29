<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Genre extends Model
{
    use HasFactory;

    protected $table = 'genres';

    protected $fillable = [
        'nama',
        'rawg_id',
    ];

    protected function casts(): array
    {
        return [
            'rawg_id' => 'integer',
        ];
    }

    /**
     * Relasi many-to-many ke Game via game_genre
     */
    public function games(): BelongsToMany
    {
        return $this->belongsToMany(Game::class, 'game_genre', 'genre_id', 'game_id');
    }
}
