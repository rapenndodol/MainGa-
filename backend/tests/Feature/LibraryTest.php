<?php

namespace Tests\Feature;

use App\Models\Game;
use App\Models\Genre;
use App\Models\LibraryEntry;
use App\Models\Platform;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class LibraryTest extends TestCase
{
    use RefreshDatabase;

    protected User $user1;
    protected User $user2;
    protected string $token1;
    protected string $token2;
    protected Game $game1;
    protected Game $game2;

    protected function setUp(): void
    {
        parent::setUp();

        Cache::flush();

        $this->user1 = User::factory()->create([
            'nama'  => 'User Satu',
            'email' => 'user1@test.com',
        ]);
        $this->token1 = $this->user1->createToken('token1')->plainTextToken;

        $this->user2 = User::factory()->create([
            'nama'  => 'User Dua',
            'email' => 'user2@test.com',
        ]);
        $this->token2 = $this->user2->createToken('token2')->plainTextToken;

        $this->game1 = Game::create([
            'rawg_id'       => 101,
            'judul'         => 'The Witcher 3: Wild Hunt',
            'cover_url'     => 'https://media.rawg.io/witcher3.jpg',
            'rating'        => 4.7,
            'tanggal_rilis' => '2015-05-18',
            'deskripsi'     => 'RPG open-world yang epik.',
            'cached_at'     => now(),
        ]);

        $this->game2 = Game::create([
            'rawg_id'       => 102,
            'judul'         => 'Hollow Knight',
            'cover_url'     => 'https://media.rawg.io/hollowknight.jpg',
            'rating'        => 4.8,
            'tanggal_rilis' => '2017-02-24',
            'deskripsi'     => 'Metroidvania masterpiece.',
            'cached_at'     => now(),
        ]);

        $genre = Genre::create(['nama' => 'RPG', 'rawg_id' => 5]);
        $platform = Platform::create(['nama' => 'PC', 'rawg_id' => 4]);

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
     * 1. Akses tanpa token mengembalikan status 401
     */
    public function test_unauthenticated_access_returns_401(): void
    {
        $this->getJson('/api/library')->assertStatus(401);
        $this->postJson('/api/library', ['game_id' => $this->game1->id, 'status' => 'Backlog'])->assertStatus(401);
        $this->putJson('/api/library/1', ['status' => 'Tamat'])->assertStatus(401);
        $this->deleteJson('/api/library/1')->assertStatus(401);
    }

    /**
     * 2. Tambah game ke library dengan game_id
     */
    public function test_can_add_game_to_library_with_game_id(): void
    {
        $response = $this->withHeaders($this->authHeaders($this->token1))
            ->postJson('/api/library', [
                'game_id'        => $this->game1->id,
                'status'         => 'Backlog',
                'rating_pribadi' => 9,
                'jam_main'       => 15.5,
                'catatan'        => 'Akan dimainkan setelah liburan.',
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'Game berhasil ditambahkan ke library',
                'data'    => [
                    'game_id'        => $this->game1->id,
                    'status'         => 'Backlog',
                    'rating_pribadi' => 9,
                    'jam_main'       => 15.5,
                    'catatan'        => 'Akan dimainkan setelah liburan.',
                    'tanggal_tamat'  => null,
                    'game'           => [
                        'id'    => $this->game1->id,
                        'judul' => 'The Witcher 3: Wild Hunt',
                    ],
                ],
            ]);

        $this->assertDatabaseHas('library_entries', [
            'user_id'        => $this->user1->id,
            'game_id'        => $this->game1->id,
            'status'         => 'Backlog',
            'rating_pribadi' => 9,
            'jam_main'       => 15.5,
            'catatan'        => 'Akan dimainkan setelah liburan.',
            'tanggal_tamat'  => null,
        ]);
    }

    /**
     * 3. Tambah game ke library menggunakan rawg_id yang belum ada di tabel games (Http::fake)
     */
    public function test_can_add_game_to_library_with_rawg_id_fetches_from_rawg(): void
    {
        Http::fake([
            'https://api.rawg.io/api/games/999*' => Http::response([
                'id'               => 999,
                'name'             => 'Elden Ring',
                'description_raw'  => 'Rise, Tarnished.',
                'background_image' => 'https://media.rawg.io/eldenring.jpg',
                'rating'           => 4.9,
                'released'         => '2022-02-25',
                'genres'           => [['id' => 5, 'name' => 'RPG']],
                'platforms'        => [['platform' => ['id' => 4, 'name' => 'PC']]],
            ], 200),
        ]);

        $response = $this->withHeaders($this->authHeaders($this->token1))
            ->postJson('/api/library', [
                'rawg_id' => 999,
                'status'  => 'Sedang Dimainkan',
                'jam_main' => 40.0,
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'data'    => [
                    'status'   => 'Sedang Dimainkan',
                    'jam_main' => 40.0,
                    'game'     => [
                        'rawg_id' => 999,
                        'judul'   => 'Elden Ring',
                    ],
                ],
            ]);

        $this->assertDatabaseHas('games', [
            'rawg_id' => 999,
            'judul'   => 'Elden Ring',
        ]);
    }

    /**
     * 4. Game duplikat ditolak dengan kode 422 dan pesan jelas
     */
    public function test_duplicate_game_in_library_is_rejected_with_422(): void
    {
        // Masukkan game1 ke library user1
        LibraryEntry::create([
            'user_id' => $this->user1->id,
            'game_id' => $this->game1->id,
            'status'  => 'Backlog',
        ]);

        // Coba masukkan game1 lagi
        $response = $this->withHeaders($this->authHeaders($this->token1))
            ->postJson('/api/library', [
                'game_id' => $this->game1->id,
                'status'  => 'Sedang Dimainkan',
            ]);

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
                'message' => 'Game sudah ada di dalam library Anda.',
            ]);
    }

    /**
     * 5. Validasi input: rating di luar 1-10, jam main negatif, status tidak valid
     */
    public function test_validation_rules_for_library_entry(): void
    {
        // Status tidak valid
        $response1 = $this->withHeaders($this->authHeaders($this->token1))
            ->postJson('/api/library', [
                'game_id' => $this->game1->id,
                'status'  => 'StatusSembarangan',
            ]);
        $response1->assertStatus(422);

        // Rating pribadi di atas 10
        $response2 = $this->withHeaders($this->authHeaders($this->token1))
            ->postJson('/api/library', [
                'game_id'        => $this->game1->id,
                'status'         => 'Backlog',
                'rating_pribadi' => 15,
            ]);
        $response2->assertStatus(422);

        // Rating pribadi kurang dari 1
        $response3 = $this->withHeaders($this->authHeaders($this->token1))
            ->postJson('/api/library', [
                'game_id'        => $this->game1->id,
                'status'         => 'Backlog',
                'rating_pribadi' => 0,
            ]);
        $response3->assertStatus(422);

        // Jam main bernilai negatif
        $response4 = $this->withHeaders($this->authHeaders($this->token1))
            ->postJson('/api/library', [
                'game_id'  => $this->game1->id,
                'status'   => 'Backlog',
                'jam_main' => -5,
            ]);
        $response4->assertStatus(422);

        // Tanpa game_id dan tanpa rawg_id
        $response5 = $this->withHeaders($this->authHeaders($this->token1))
            ->postJson('/api/library', [
                'status' => 'Backlog',
            ]);
        $response5->assertStatus(422);
    }

    /**
     * 6. Otomatisasi tanggal_tamat: saat status Tamat diisi otomatis, saat beralih ke status lain dikosongkan
     */
    public function test_tanggal_tamat_automated_handling(): void
    {
        // Buat entry baru berstatus Tamat -> tanggal_tamat harus terisi hari ini
        $response = $this->withHeaders($this->authHeaders($this->token1))
            ->postJson('/api/library', [
                'game_id' => $this->game1->id,
                'status'  => 'Tamat',
            ]);

        $response->assertStatus(201);
        $entryId = $response->json('data.id');
        $today = Carbon::today()->toDateString();

        $this->assertEquals($today, Carbon::parse(LibraryEntry::find($entryId)->tanggal_tamat)->format('Y-m-d'));
        $this->assertEquals('Tamat', LibraryEntry::find($entryId)->status);

        // Ubah status ke Sedang Dimainkan -> tanggal_tamat harus jadi null
        $updateResp = $this->withHeaders($this->authHeaders($this->token1))
            ->putJson("/api/library/{$entryId}", [
                'status' => 'Sedang Dimainkan',
            ]);

        $updateResp->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data'    => [
                    'status'        => 'Sedang Dimainkan',
                    'tanggal_tamat' => null,
                ],
            ]);

        $this->assertNull(LibraryEntry::find($entryId)->tanggal_tamat);
        $this->assertEquals('Sedang Dimainkan', LibraryEntry::find($entryId)->status);

        // Ubah kembali ke Tamat -> tanggal_tamat terisi lagi
        $updateTamatResp = $this->withHeaders($this->authHeaders($this->token1))
            ->putJson("/api/library/{$entryId}", [
                'status' => 'Tamat',
            ]);

        $updateTamatResp->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data'    => [
                    'status'        => 'Tamat',
                    'tanggal_tamat' => $today,
                ],
            ]);
    }

    /**
     * 7. Ubah entry library: status, rating pribadi, jam main, catatan
     */
    public function test_can_update_library_entry(): void
    {
        $entry = LibraryEntry::create([
            'user_id'        => $this->user1->id,
            'game_id'        => $this->game1->id,
            'status'         => 'Backlog',
            'rating_pribadi' => null,
            'jam_main'       => 0,
            'catatan'        => null,
        ]);

        $response = $this->withHeaders($this->authHeaders($this->token1))
            ->putJson("/api/library/{$entry->id}", [
                'status'         => 'Sedang Dimainkan',
                'rating_pribadi' => 8,
                'jam_main'       => 24.5,
                'catatan'        => 'Boss pertamanya seru sekali!',
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data'    => [
                    'id'             => $entry->id,
                    'status'         => 'Sedang Dimainkan',
                    'rating_pribadi' => 8,
                    'jam_main'       => 24.5,
                    'catatan'        => 'Boss pertamanya seru sekali!',
                ],
            ]);
    }

    /**
     * 8. Hapus game dari library
     */
    public function test_can_delete_game_from_library(): void
    {
        $entry = LibraryEntry::create([
            'user_id' => $this->user1->id,
            'game_id' => $this->game1->id,
            'status'  => 'Dropped',
        ]);

        $response = $this->withHeaders($this->authHeaders($this->token1))
            ->deleteJson("/api/library/{$entry->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Game berhasil dihapus dari library',
            ]);

        $this->assertDatabaseMissing('library_entries', [
            'id' => $entry->id,
        ]);
    }

    /**
     * 9. Filter status dan pagination pada GET /api/library
     */
    public function test_can_list_and_filter_library_by_status_with_pagination(): void
    {
        // Tambahkan game 1 berstatus Tamat dan game 2 berstatus Backlog untuk user1
        LibraryEntry::create([
            'user_id'       => $this->user1->id,
            'game_id'       => $this->game1->id,
            'status'        => 'Tamat',
            'tanggal_tamat' => Carbon::today()->toDateString(),
        ]);

        LibraryEntry::create([
            'user_id' => $this->user1->id,
            'game_id' => $this->game2->id,
            'status'  => 'Backlog',
        ]);

        // Ambil semua library user1
        $allResp = $this->withHeaders($this->authHeaders($this->token1))
            ->getJson('/api/library');

        $allResp->assertStatus(200)
            ->assertJsonCount(2, 'data.entries')
            ->assertJson([
                'data' => [
                    'pagination' => [
                        'total' => 2,
                    ],
                ],
            ]);

        // Filter hanya yang status Tamat
        $tamatResp = $this->withHeaders($this->authHeaders($this->token1))
            ->getJson('/api/library?status=Tamat');

        $tamatResp->assertStatus(200)
            ->assertJsonCount(1, 'data.entries')
            ->assertJson([
                'data' => [
                    'entries' => [
                        [
                            'game_id' => $this->game1->id,
                            'status'  => 'Tamat',
                        ],
                    ],
                ],
            ]);

        // Filter hanya yang status Dropped (harus 0 item)
        $droppedResp = $this->withHeaders($this->authHeaders($this->token1))
            ->getJson('/api/library?status=Dropped');

        $droppedResp->assertStatus(200)
            ->assertJsonCount(0, 'data.entries');
    }

    /**
     * 10. Pengguna tidak dapat melihat, mengubah, atau menghapus entry milik orang lain (403)
     */
    public function test_cannot_access_or_modify_other_users_library_entry(): void
    {
        // Entry milik user1
        $entry1 = LibraryEntry::create([
            'user_id' => $this->user1->id,
            'game_id' => $this->game1->id,
            'status'  => 'Backlog',
        ]);

        // User2 mencoba melihat detail entry user1 -> 403
        $this->withHeaders($this->authHeaders($this->token2))
            ->getJson("/api/library/{$entry1->id}")
            ->assertStatus(403);

        // User2 mencoba mengubah entry user1 -> 403
        $this->withHeaders($this->authHeaders($this->token2))
            ->putJson("/api/library/{$entry1->id}", ['status' => 'Tamat'])
            ->assertStatus(403);

        // User2 mencoba menghapus entry user1 -> 403
        $this->withHeaders($this->authHeaders($this->token2))
            ->deleteJson("/api/library/{$entry1->id}")
            ->assertStatus(403);

        // Pastikan entry user1 tetap utuh di database
        $this->assertDatabaseHas('library_entries', [
            'id'     => $entry1->id,
            'status' => 'Backlog',
        ]);
    }

    /**
     * 11. Endpoint detail game /api/games/{id} memuat status library pengguna
     */
    public function test_game_detail_includes_user_library_status(): void
    {
        // Sebelum dimasukkan ke library: library_status harus null
        $resp1 = $this->withHeaders($this->authHeaders($this->token1))
            ->getJson("/api/games/{$this->game1->id}");

        $resp1->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data'    => [
                    'id'             => $this->game1->id,
                    'library_status' => null,
                ],
            ]);

        // Tambahkan ke library berstatus "Sedang Dimainkan"
        LibraryEntry::create([
            'user_id' => $this->user1->id,
            'game_id' => $this->game1->id,
            'status'  => 'Sedang Dimainkan',
        ]);

        // Setelah dimasukkan ke library: library_status harus "Sedang Dimainkan"
        $resp2 = $this->withHeaders($this->authHeaders($this->token1))
            ->getJson("/api/games/{$this->game1->id}");

        $resp2->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data'    => [
                    'id'             => $this->game1->id,
                    'library_status' => 'Sedang Dimainkan',
                ],
            ]);

        // Bagi user2 yang belum menambah game1, tetap null
        auth()->forgetGuards();
        $respUser2 = $this->withHeaders($this->authHeaders($this->token2))
            ->getJson("/api/games/{$this->game1->id}");

        $respUser2->assertStatus(200)
            ->assertJson([
                'data' => [
                    'library_status' => null,
                ],
            ]);
    }
}
