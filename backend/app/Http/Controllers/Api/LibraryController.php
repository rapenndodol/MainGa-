<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreLibraryEntryRequest;
use App\Http\Requests\UpdateLibraryEntryRequest;
use App\Http\Resources\LibraryEntryResource;
use App\Models\Game;
use App\Models\Genre;
use App\Models\LibraryEntry;
use App\Models\Platform;
use App\Services\RawgService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Throwable;

class LibraryController extends Controller
{
    protected RawgService $rawgService;

    public function __construct(RawgService $rawgService)
    {
        $this->rawgService = $rawgService;
    }

    /**
     * GET /api/library
     * Daftar library milik pengguna yang login, dengan filter status dan pagination.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $status = $request->input('status');
        $perPage = max(1, min(50, (int) $request->input('per_page', 15)));
        $page = max(1, (int) $request->input('page', 1));

        $query = LibraryEntry::with(['game.genres', 'game.platforms'])
            ->where('user_id', $user->id);

        if (!empty($status) && $status !== 'Semua') {
            $query->where('status', $status);
        }

        $query->orderBy('updated_at', 'desc');

        $paginated = $query->paginate($perPage, ['*'], 'page', $page);

        return response()->json([
            'success' => true,
            'message' => 'Daftar library berhasil diambil',
            'data'    => [
                'entries'    => LibraryEntryResource::collection($paginated->items()),
                'pagination' => [
                    'current_page' => $paginated->currentPage(),
                    'last_page'    => $paginated->lastPage(),
                    'per_page'     => $paginated->perPage(),
                    'total'        => $paginated->total(),
                ],
            ],
        ], 200);
    }

    /**
     * GET /api/library/{id}
     * Detail satu entry library milik pengguna.
     */
    public function show(Request $request, $id): JsonResponse
    {
        $entry = LibraryEntry::with(['game.genres', 'game.platforms'])->find($id);

        if (! $entry) {
            return response()->json([
                'success' => false,
                'message' => 'Entry library tidak ditemukan.',
            ], 404);
        }

        if ($entry->user_id !== $request->user()->id) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki izin untuk mengakses entry library ini.',
            ], 403);
        }

        return response()->json([
            'success' => true,
            'message' => 'Detail entry library berhasil diambil',
            'data'    => new LibraryEntryResource($entry),
        ], 200);
    }

    /**
     * POST /api/library
     * Tambah game ke library (game_id atau rawg_id, status, rating_pribadi, jam_main, catatan).
     */
    public function store(StoreLibraryEntryRequest $request): JsonResponse
    {
        $user = $request->user();
        $game = null;

        // Cari game berdasarkan game_id jika disertakan
        if ($request->filled('game_id')) {
            $game = Game::with(['genres', 'platforms'])->find($request->input('game_id'));
        }

        // Jika belum ditemukan dan rawg_id disertakan, cari berdasarkan rawg_id atau ambil lewat RawgService
        if (! $game && $request->filled('rawg_id')) {
            $rawgId = (int) $request->input('rawg_id');
            $game = Game::with(['genres', 'platforms'])->where('rawg_id', $rawgId)->first();

            if (! $game) {
                $rawgDetail = null;
                try {
                    $rawgDetail = $this->rawgService->getGameDetail($rawgId);
                } catch (Throwable $e) {
                    $rawgDetail = null;
                }

                if ($rawgDetail && isset($rawgDetail['id'])) {
                    $deskripsi = !empty($rawgDetail['description_raw'])
                        ? $rawgDetail['description_raw']
                        : strip_tags($rawgDetail['description'] ?? '');

                    $game = Game::create([
                        'rawg_id'       => (int) $rawgDetail['id'],
                        'judul'         => $rawgDetail['name'] ?? 'Untitled Game',
                        'cover_url'     => $rawgDetail['background_image'] ?? null,
                        'rating'        => isset($rawgDetail['rating']) ? (float) $rawgDetail['rating'] : 0.0,
                        'deskripsi'     => $deskripsi,
                        'tanggal_rilis' => !empty($rawgDetail['released']) ? $rawgDetail['released'] : null,
                        'cached_at'     => now(),
                    ]);

                    // Sinkronisasi genre
                    if (!empty($rawgDetail['genres'])) {
                        $genreIds = [];
                        foreach ($rawgDetail['genres'] as $g) {
                            $gModel = Genre::firstOrCreate(
                                ['rawg_id' => $g['id']],
                                ['nama' => $g['name']]
                            );
                            $genreIds[] = $gModel->id;
                        }
                        $game->genres()->sync($genreIds);
                    }

                    // Sinkronisasi platform
                    if (!empty($rawgDetail['platforms'])) {
                        $platformIds = [];
                        foreach ($rawgDetail['platforms'] as $p) {
                            $plat = $p['platform'] ?? $p;
                            if (!empty($plat['id'])) {
                                $pModel = Platform::firstOrCreate(
                                    ['rawg_id' => $plat['id']],
                                    ['nama' => $plat['name']]
                                );
                                $platformIds[] = $pModel->id;
                            }
                        }
                        $game->platforms()->sync($platformIds);
                    }

                    $game->load(['genres', 'platforms']);
                }
            }
        }

        if (! $game) {
            return response()->json([
                'success' => false,
                'message' => 'Game tidak ditemukan pada database lokal maupun RAWG.',
            ], 422);
        }

        // Cek duplikasi: satu game hanya dapat muncul sekali dalam library satu pengguna
        $exists = LibraryEntry::where('user_id', $user->id)
            ->where('game_id', $game->id)
            ->exists();

        if ($exists) {
            return response()->json([
                'success' => false,
                'message' => 'Game sudah ada di dalam library Anda.',
                'errors'  => [
                    'game_id' => ['Game sudah ada di dalam library Anda.'],
                ],
            ], 422);
        }

        $status = $request->input('status');
        $tanggalTamat = ($status === 'Tamat') ? Carbon::today()->toDateString() : null;

        $entry = LibraryEntry::create([
            'user_id'        => $user->id,
            'game_id'        => $game->id,
            'status'         => $status,
            'rating_pribadi' => $request->input('rating_pribadi'),
            'jam_main'       => $request->input('jam_main', 0) ?? 0,
            'catatan'        => $request->input('catatan'),
            'tanggal_tamat'  => $tanggalTamat,
        ]);

        $entry->load(['game.genres', 'game.platforms']);

        return response()->json([
            'success' => true,
            'message' => 'Game berhasil ditambahkan ke library',
            'data'    => new LibraryEntryResource($entry),
        ], 201);
    }

    /**
     * PUT /api/library/{id}
     * Ubah status, rating_pribadi, jam_main, dan catatan.
     */
    public function update(UpdateLibraryEntryRequest $request, $id): JsonResponse
    {
        $entry = LibraryEntry::with(['game.genres', 'game.platforms'])->find($id);

        if (! $entry) {
            return response()->json([
                'success' => false,
                'message' => 'Entry library tidak ditemukan.',
            ], 404);
        }

        if ($entry->user_id !== $request->user()->id) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki izin untuk mengubah entry library ini.',
            ], 403);
        }

        if ($request->has('status')) {
            $newStatus = $request->input('status');
            $oldStatus = $entry->status;
            $entry->status = $newStatus;

            // Saat status berubah menjadi Tamat, isi tanggal_tamat otomatis dengan tanggal hari ini;
            // saat status berubah dari Tamat ke status lain, kosongkan lagi.
            if ($newStatus === 'Tamat') {
                if ($oldStatus !== 'Tamat' || empty($entry->tanggal_tamat)) {
                    $entry->tanggal_tamat = Carbon::today()->toDateString();
                }
            } else {
                $entry->tanggal_tamat = null;
            }
        }

        if ($request->has('rating_pribadi')) {
            $entry->rating_pribadi = $request->input('rating_pribadi');
        }

        if ($request->has('jam_main')) {
            $entry->jam_main = $request->input('jam_main');
        }

        if ($request->has('catatan')) {
            $entry->catatan = $request->input('catatan');
        }

        $entry->save();

        return response()->json([
            'success' => true,
            'message' => 'Entry library berhasil diperbarui',
            'data'    => new LibraryEntryResource($entry),
        ], 200);
    }

    /**
     * DELETE /api/library/{id}
     * Hapus dari library.
     */
    public function destroy(Request $request, $id): JsonResponse
    {
        $entry = LibraryEntry::find($id);

        if (! $entry) {
            return response()->json([
                'success' => false,
                'message' => 'Entry library tidak ditemukan.',
            ], 404);
        }

        if ($entry->user_id !== $request->user()->id) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki izin untuk menghapus entry library ini.',
            ], 403);
        }

        $entry->delete();

        return response()->json([
            'success' => true,
            'message' => 'Game berhasil dihapus dari library',
            'data'    => null,
        ], 200);
    }
}
