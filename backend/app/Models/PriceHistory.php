<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PriceHistory extends Model
{
    use HasFactory;

    protected $table = 'price_history';

    protected $fillable = [
        'game_id',
        'toko',
        'harga',
        'diskon_persen',
        'dicek_pada',
    ];

    protected function casts(): array
    {
        return [
            'harga' => 'float',
            'diskon_persen' => 'float',
            'dicek_pada' => 'datetime',
        ];
    }

    /**
     * Relasi belongsTo Game
     */
    public function game(): BelongsTo
    {
        return $this->belongsTo(Game::class, 'game_id');
    }
}
