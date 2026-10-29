<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Game extends Model
{
    use HasFactory;

    protected $table = 'games';

    protected $fillable = [
        'rawg_id',
        'judul',
        'cover_url',
        'rating',
        'deskripsi',
        'tanggal_rilis',
        'cached_at',
    ];

    protected function casts(): array
    {
        return [
            'rawg_id' => 'integer',
            'rating' => 'float',
            'tanggal_rilis' => 'date',
            'cached_at' => 'datetime',
        ];
    }

    /**
     * Relasi many-to-many ke Genre via game_genre
     */
    public function genres(): BelongsToMany
    {
        return $this->belongsToMany(Genre::class, 'game_genre', 'game_id', 'genre_id');
    }

    /**
     * Relasi many-to-many ke Platform via game_platform
     */
    public function platforms(): BelongsToMany
    {
        return $this->belongsToMany(Platform::class, 'game_platform', 'game_id', 'platform_id');
    }

    /**
     * Relasi 1-N ke library_entries
     */
    public function libraryEntries(): HasMany
    {
        return $this->hasMany(LibraryEntry::class, 'game_id');
    }

    /**
     * Relasi 1-N ke wishlist_alerts
     */
    public function wishlistAlerts(): HasMany
    {
        return $this->hasMany(WishlistAlert::class, 'game_id');
    }

    /**
     * Relasi 1-N ke price_history
     */
    public function priceHistories(): HasMany
    {
        return $this->hasMany(PriceHistory::class, 'game_id');
    }

    /**
     * Relasi 1-N ke notifications
     */
    public function notifications(): HasMany
    {
        return $this->hasMany(Notification::class, 'game_id');
    }
}
