<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class LibraryEntry extends Model
{
    use HasFactory;

    protected $table = 'library_entries';

    protected $fillable = [
        'user_id',
        'game_id',
        'status',
        'rating_pribadi',
        'jam_main',
        'catatan',
        'tanggal_tamat',
    ];

    protected function casts(): array
    {
        return [
            'rating_pribadi' => 'integer',
            'jam_main' => 'float',
            'tanggal_tamat' => 'date',
        ];
    }

    /**
     * Relasi belongsTo User
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    /**
     * Relasi belongsTo Game
     */
    public function game(): BelongsTo
    {
        return $this->belongsTo(Game::class, 'game_id');
    }
}
