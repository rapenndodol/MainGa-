<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreWishlistRequest;
use App\Http\Requests\UpdateWishlistRequest;
use App\Http\Resources\WishlistResource;
use App\Models\Game;
use App\Models\Genre;
use App\Models\Platform;
use App\Models\WishlistAlert;
use App\Services\PriceService;
use App\Services\RawgService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Throwable;

class WishlistController extends Controller
{
    protected PriceService $priceService;
    protected RawgService $rawgService;

    public function __construct(PriceService $priceService, RawgService $rawgService)
    {
        $this->priceService = $priceService;
        $this->rawgService = $rawgService;
    }

    /**
     * GET /api/wishlist
     * Daftar wishlist milik pengguna dengan data game, harga_target, aktif,
     * harga terendah saat ini beserta tokonya, dan selisih terhadap harga target.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $perPage = max(1, min(50, (int) $request->input('per_page', 20)));
        $page = max(1, (int) $request->input('page', 1));

        $query = WishlistAlert::with(['game.genres', 'game.platforms'])
            ->where('user_id', $user->id);

        if ($request->has('aktif')) {
            $query->where('aktif', $request->boolean('aktif'));
        }

        $paginated = $query->orderBy('created_at', 'desc')->paginate($perPage, ['*'], 'page', $page);

        return response()->json([
            'success' => true,
            'message' => 'Daftar wishlist berhasil diambil',
            'data'    => [
                'wishlists'  => WishlistResource::collection($paginated->items()),
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
     * POST /api/wishlist
     * Tambah game (game_id atau rawg_id) ke wishlist dengan harga_target dalam USD.
     * Setelah tersimpan, langsung lakukan satu kali pengecekan harga untuk game itu.
     */
    public function store(StoreWishlistRequest $request): JsonResponse
    {
        $user = $request->user();
        $game = null;

        // Cari berdasarkan game_id lokal
        if ($request->filled('game_id')) {
            $game = Game::with(['genres', 'platforms'])->find($request->input('game_id'));
        }

        // Jika belum ditemukan dan rawg_id disertakan, cari berdasarkan rawg_id atau ambil dari RAWG API
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

        // Cek duplikasi: satu game hanya dapat muncul sekali per pengguna di wishlist
        $exists = WishlistAlert::where('user_id', $user->id)
            ->where('game_id', $game->id)
            ->exists();

        if ($exists) {
            return response()->json([
                'success' => false,
                'message' => 'Game sudah ada di dalam wishlist Anda.',
            ], 422);
        }

        // Simpan wishlist entry
        $wishlist = WishlistAlert::create([
            'user_id'      => $user->id,
            'game_id'      => $game->id,
            'harga_target' => (float) $request->input('harga_target'),
            'aktif'        => $request->has('aktif') ? $request->boolean('aktif') : true,
        ]);

        // Setelah tersimpan, langsung lakukan satu kali pengecekan harga untuk game itu
        try {
            $this->priceService->checkAndRecordPrices($game);
        } catch (Throwable $e) {
            // Galat pada pengecekan CheapShark tidak boleh menggagalkan penambahan wishlist
        }

        $wishlist->load(['game.genres', 'game.platforms']);

        return response()->json([
            'success' => true,
            'message' => 'Game berhasil ditambahkan ke wishlist',
            'data'    => new WishlistResource($wishlist),
        ], 201);
    }

    /**
     * GET /api/wishlist/{id}
     * Ambil detail satu entri wishlist milik pengguna.
     */
    public function show(Request $request, $id): JsonResponse
    {
        $wishlist = WishlistAlert::with(['game.genres', 'game.platforms'])->find($id);

        if (! $wishlist) {
            return response()->json([
                'success' => false,
                'message' => 'Wishlist tidak ditemukan.',
            ], 404);
        }

        if ($wishlist->user_id !== $request->user()->id) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki izin untuk mengakses wishlist ini.',
            ], 403);
        }

        return response()->json([
            'success' => true,
            'message' => 'Detail wishlist berhasil diambil',
            'data'    => new WishlistResource($wishlist),
        ], 200);
    }

    /**
     * PUT /api/wishlist/{id}
     * Ubah harga_target atau status aktif wishlist.
     */
    public function update(UpdateWishlistRequest $request, $id): JsonResponse
    {
        $wishlist = WishlistAlert::with(['game.genres', 'game.platforms'])->find($id);

        if (! $wishlist) {
            return response()->json([
                'success' => false,
                'message' => 'Wishlist tidak ditemukan.',
            ], 404);
        }

        if ($wishlist->user_id !== $request->user()->id) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki izin untuk mengubah wishlist ini.',
            ], 403);
        }

        if ($request->has('harga_target')) {
            $wishlist->harga_target = (float) $request->input('harga_target');
        }

        if ($request->has('aktif')) {
            $wishlist->aktif = $request->boolean('aktif');
        }

        $wishlist->save();

        return response()->json([
            'success' => true,
            'message' => 'Wishlist berhasil diperbarui',
            'data'    => new WishlistResource($wishlist),
        ], 200);
    }

    /**
     * DELETE /api/wishlist/{id}
     * Hapus game dari wishlist pengguna.
     */
    public function destroy(Request $request, $id): JsonResponse
    {
        $wishlist = WishlistAlert::find($id);

        if (! $wishlist) {
            return response()->json([
                'success' => false,
                'message' => 'Wishlist tidak ditemukan.',
            ], 404);
        }

        if ($wishlist->user_id !== $request->user()->id) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki izin untuk menghapus wishlist ini.',
            ], 403);
        }

        $wishlist->delete();

        return response()->json([
            'success' => true,
            'message' => 'Game berhasil dihapus dari wishlist',
            'data'    => null,
        ], 200);
    }
}
