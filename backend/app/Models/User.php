<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'nama',
        'email',
        'password',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    /**
     * Interop accessor for name attribute if requested.
     */
    protected function name(): Attribute
    {
        return Attribute::make(
            get: fn () => $this->nama,
            set: fn ($value) => ['nama' => $value],
        );
    }

    /**
     * Relasi ke library_entries (1-N)
     */
    public function libraryEntries(): HasMany
    {
        return $this->hasMany(LibraryEntry::class, 'user_id');
    }

    /**
     * Relasi ke wishlist_alerts (1-N)
     */
    public function wishlistAlerts(): HasMany
    {
        return $this->hasMany(WishlistAlert::class, 'user_id');
    }

    /**
     * Relasi ke notifications (1-N)
     */
    public function notifications(): HasMany
    {
        return $this->hasMany(Notification::class, 'user_id');
    }
}
