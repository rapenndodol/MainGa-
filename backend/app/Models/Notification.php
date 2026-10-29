<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Notification extends Model
{
    use HasFactory;

    protected $table = 'notifications';

    protected $fillable = [
        'user_id',
        'game_id',
        'judul',
        'pesan',
        'harga',
        'toko',
        'dibaca_pada',
    ];

    protected function casts(): array
    {
        return [
            'harga' => 'float',
            'dibaca_pada' => 'datetime',
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
