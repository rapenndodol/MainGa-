<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WishlistAlert extends Model
{
    use HasFactory;

    protected $table = 'wishlist_alerts';

    protected $fillable = [
        'user_id',
        'game_id',
        'harga_target',
        'aktif',
    ];

    protected function casts(): array
    {
        return [
            'harga_target' => 'float',
            'aktif' => 'boolean',
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
