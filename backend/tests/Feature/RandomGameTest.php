<?php

namespace Tests\Feature;

use App\Models\Game;
use App\Models\Genre;
use App\Models\LibraryEntry;
use App\Models\Platform;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;

class RandomGameTest extends TestCase
{
    use RefreshDatabase;

    protected User $user1;
    protected User $user2;
    protected string $token1;
    protected string $token2;
    protected Game $game1;
    protected Game $game2;
    protected Game $game3;

    protected function setUp(): void
    {
        parent::setUp();

        Cache::flush();

        $this->user1 = User::factory()->create([
            'nama'  => 'User Random Satu',
            'email' => 'random1@test.com',
        ]);
        $this->token1 = $this->user1->createToken('token1')->plainTextToken;

        $this->user2 = User::factory()->create([
            'nama'  => 'User Random Dua',
            'email' => 'random2@test.com',
        ]);
        $this->token2 = $this->user2->createToken('token2')->plainTextToken;

        $this->game1 = Game::create([
            'rawg_id'       => 801,
            'judul'         => 'Hades',
            'cover_url'     => 'https://media.rawg.io/hades.jpg',
            'rating'        => 4.9,
            'tanggal_rilis' => '2020-09-17',
            'deskripsi'     => 'Rogue-like dungeon crawler.',
            'cached_at'     => now(),
        ]);

        $this->game2 = Game::create([
            'rawg_id'       => 802,
            'judul'         => 'Celeste',
            'cover_url'     => 'https://media.rawg.io/celeste.jpg',
            'rating'        => 4.8,
            'tanggal_rilis' => '2018-01-25',
            'deskripsi'     => 'Precision platformer.',
            'cached_at'     => now(),
        ]);

        $this->game3 = Game::create([
            'rawg_id'       => 803,
            'judul'         => 'Sekiro: Shadows Die Twice',
            'cover_url'     => 'https://media.rawg.io/sekiro.jpg',
            'rating'        => 4.9,
            'tanggal_rilis' => '2019-03-22',
            'deskripsi'     => 'Action ninja game.',
            'cached_at'     => now(),
        ]);

        $genre = Genre::create(['nama' => 'Action']);
        $platform = Platform::create(['nama' => 'PC']);

        $this->game1->genres()->attach($genre->id);
        $this->game1->platforms()->attach($platform->id);
    }

    protected function authHeaders(string $token): array
    {
        return [
            'Authorization' => 'Bearer ' . $token,
            'Accept'        => 'application/json',
        ];
    }

    /**
     * 1. Acak memilih HANYA dari game berstatus Backlog milik pengguna
     */
    public function test_random_game_picks_only_from_backlog(): void
    {
        // Entry 1: Tamat
        LibraryEntry::create([
            'user_id' => $this->user1->id,
            'game_id' => $this->game1->id,
            'status'  => 'Tamat',
        ]);

        // Entry 2: Sedang Dimainkan
        LibraryEntry::create([
            'user_id' => $this->user1->id,
            'game_id' => $this->game2->id,
            'status'  => 'Sedang Dimainkan',
        ]);

        // Entry 3: Backlog (hanya ini yang boleh terpilih!)
        $backlogEntry = LibraryEntry::create([
            'user_id' => $this->user1->id,
            'game_id' => $this->game3->id,
            'status'  => 'Backlog',
        ]);

        $response = $this->getJson('/api/library/random', $this->authHeaders($this->token1));

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Game acak dari backlog berhasil dipilih',
                'data'    => [
                    'id'      => $backlogEntry->id,
                    'status'  => 'Backlog',
                    'game_id' => $this->game3->id,
                    'judul'   => 'Sekiro: Shadows Die Twice',
                ],
            ]);
    }

    /**
     * 2. Bila backlog kosong, mengembalikan respons HTTP 404 dengan pesan JSON yang jelas
     */
    public function test_random_game_when_backlog_is_empty_returns_404(): void
    {
        // User 1 hanya punya game dengan status 'Sedang Dimainkan' dan 'Tamat'
        LibraryEntry::create([
            'user_id' => $this->user1->id,
            'game_id' => $this->game1->id,
            'status'  => 'Sedang Dimainkan',
        ]);

        LibraryEntry::create([
            'user_id' => $this->user1->id,
            'game_id' => $this->game2->id,
            'status'  => 'Tamat',
        ]);

        $response = $this->getJson('/api/library/random', $this->authHeaders($this->token1));

        $response->assertStatus(404)
            ->assertJson([
                'success' => false,
                'data'    => null,
            ]);

        $this->assertStringContainsString('Backlog kosong', $response->json('message'));
    }

    /**
     * 3. Game acak hanya memilih dari library milik pengguna sendiri
     */
    public function test_random_game_only_picks_from_own_library(): void
    {
        // User 2 punya game Backlog
        LibraryEntry::create([
            'user_id' => $this->user2->id,
            'game_id' => $this->game1->id,
            'status'  => 'Backlog',
        ]);

        // User 1 tidak punya game Backlog sama sekali
        $response = $this->getJson('/api/library/random', $this->authHeaders($this->token1));

        $response->assertStatus(404);
    }

    /**
     * 4. Akses endpoint random tanpa token mengembalikan 401
     */
    public function test_unauthenticated_access_returns_401(): void
    {
        $this->getJson('/api/library/random')->assertStatus(401);
    }
}
