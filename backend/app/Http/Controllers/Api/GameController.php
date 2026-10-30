<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\LibraryEntryResource;
use App\Models\Game;
use App\Models\Genre;
use App\Models\LibraryEntry;
use App\Models\Platform;
use App\Models\PriceHistory;
use App\Models\WishlistAlert;
use App\Services\RawgService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Throwable;

class GameController extends Controller
{
    protected RawgService $rawgService;

    public function __construct(RawgService $rawgService)
    {
        $this->rawgService = $rawgService;
    }

    /**
     * GET /api/genres
     * Daftar seluruh master genre untuk filter
     */
    public function genres(): JsonResponse
    {
        $genres = Genre::orderBy('nama', 'asc')->get(['id', 'nama', 'rawg_id']);

        return response()->json([
            'success' => true,
            'message' => 'Daftar genre berhasil diambil',
            'data'    => $genres,
        ], 200);
    }

    /**
     * GET /api/platforms
     * Daftar seluruh master platform untuk filter
     */
    public function platforms(): JsonResponse
    {
        $platforms = Platform::orderBy('nama', 'asc')->get(['id', 'nama', 'rawg_id']);

        return response()->json([
            'success' => true,
            'message' => 'Daftar platform berhasil diambil',
            'data'    => $platforms,
        ], 200);
    }

    /**
     * GET /api/games
     * Pencarian dan filter game dengan cache 7 hari di database dan cache query respons
     */
    public function index(Request $request): JsonResponse
    {
        $search   = trim((string) $request->input('search', ''));
        $genre    = $request->input('genre');
        $platform = $request->input('platform');
        $rating   = (float) $request->input('rating', 0);
        $page     = max(1, (int) $request->input('page', 1));
        $perPage  = max(1, min(40, (int) $request->input('per_page', 20)));

        // Kunci cache respons pencarian (Layer A - Cache Laravel dalam waktu singkat)
        $cacheKey = 'games_search_' . md5(json_encode([
            's' => $search,
            'g' => $genre,
            'p' => $platform,
            'r' => $rating,
            'page' => $page,
            'per_page' => $perPage,
        ]));

        if (Cache::has($cacheKey)) {
            $cachedData = Cache::get($cacheKey);
            return response()->json([
                'success' => true,
                'message' => 'Daftar game berhasil diambil (dari cache)',
                'data'    => $cachedData,
            ], 200);
        }

        // Resolusi parameter genre & platform ke rawg_id untuk pemanggilan RAWG
        $rawgGenreParam = null;
        if (!empty($genre)) {
            $genreObj = Genre::where('id', $genre)
                ->orWhere('rawg_id', $genre)
                ->orWhere('nama', $genre)
                ->first();
            $rawgGenreParam = $genreObj ? ($genreObj->rawg_id ?? $genreObj->id) : $genre;
        }

        $rawgPlatformParam = null;
        if (!empty($platform)) {
            $platformObj = Platform::where('id', $platform)
                ->orWhere('rawg_id', $platform)
                ->orWhere('nama', $platform)
                ->first();
            $rawgPlatformParam = $platformObj ? ($platformObj->rawg_id ?? $platformObj->id) : $platform;
        }

        // Panggil RAWG API
        $rawgParams = [
            'page'      => $page,
            'page_size' => $perPage,
        ];
        if (!empty($search)) {
            $rawgParams['search'] = $search;
        }
        if (!empty($rawgGenreParam)) {
            $rawgParams['genres'] = $rawgGenreParam;
        }
        if (!empty($rawgPlatformParam)) {
            $rawgParams['platforms'] = $rawgPlatformParam;
        }

        $rawgResponse = null;
        try {
            $rawgResponse = $this->rawgService->getGames($rawgParams);
        } catch (Throwable $e) {
            $rawgResponse = null;
        }

        // Jika RAWG berhasil memberikan data
        if ($rawgResponse && isset($rawgResponse['results'])) {
            $gamesList = [];

            foreach ($rawgResponse['results'] as $item) {
                $rawgId = (int) $item['id'];
                $itemRating = isset($item['rating']) ? (float) $item['rating'] : 0.0;

                // Terapkan filter rating minimum jika diminta
                if ($rating > 0 && $itemRating < $rating) {
                    continue;
                }

                $judul        = $item['name'] ?? 'Untitled Game';
                $coverUrl     = $item['background_image'] ?? null;
                $tanggalRilis = !empty($item['released']) ? $item['released'] : null;

                // Layer B: Simpan/Perbarui ke database lokal tabel games & pivot
                $game = Game::where('rawg_id', $rawgId)->first();
                $shouldRefresh = false;

                if (! $game) {
                    $game = new Game();
                    $game->rawg_id = $rawgId;
                    $shouldRefresh = true;
                } elseif (! $game->cached_at || Carbon::parse($game->cached_at)->addDays(7)->isPast()) {
                    $shouldRefresh = true;
                }

                if ($shouldRefresh) {
                    $game->judul         = $judul;
                    $game->cover_url     = $coverUrl;
                    $game->rating        = $itemRating;
                    $game->tanggal_rilis = $tanggalRilis;
                    $game->cached_at     = now();
                    $game->save();

                    // Simpan relasi genre
                    if (!empty($item['genres'])) {
                        $genreIds = [];
                        foreach ($item['genres'] as $g) {
                            $gModel = Genre::firstOrCreate(
                                ['rawg_id' => $g['id']],
                                ['nama' => $g['name']]
                            );
                            $genreIds[] = $gModel->id;
                        }
                        $game->genres()->sync($genreIds);
                    }

                    // Simpan relasi platform
                    if (!empty($item['platforms'])) {
                        $platformIds = [];
                        foreach ($item['platforms'] as $p) {
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
                } else {
                    // Pastikan relasi genres dan platforms sudah dimuat
                    $game->loadMissing(['genres', 'platforms']);
                }

                $genreNames = $game->genres->pluck('nama')->toArray();
                $platformNames = $game->platforms->pluck('nama')->toArray();

                $gamesList[] = [
                    'id'            => $game->id,
                    'rawg_id'       => $game->rawg_id,
                    'judul'         => $game->judul,
                    'cover_url'     => $game->cover_url,
                    'rating'        => (float) $game->rating,
                    'genre'         => implode(', ', $genreNames),
                    'genres'        => $genreNames,
                    'platform'      => implode(', ', $platformNames),
                    'platforms'     => $platformNames,
                    'tanggal_rilis' => $game->tanggal_rilis ? Carbon::parse($game->tanggal_rilis)->format('Y-m-d') : null,
                ];
            }

            $totalCount = $rawgResponse['count'] ?? count($gamesList);
            $lastPage = (int) ceil($totalCount / $perPage);

            $payload = [
                'games'      => $gamesList,
                'pagination' => [
                    'current_page' => $page,
                    'last_page'    => max(1, $lastPage),
                    'per_page'     => $perPage,
                    'total'        => $totalCount,
                ],
            ];

            // Simpan ke Cache Laravel selama 1 jam
            Cache::put($cacheKey, $payload, now()->addHour());

            return response()->json([
                'success' => true,
                'message' => 'Daftar game berhasil diambil',
                'data'    => $payload,
            ], 200);
        }

        // ── Fallback Database Lokal saat RAWG gagal dijangkau ──
        $query = Game::with(['genres', 'platforms']);

        if (!empty($search)) {
            $query->where('judul', 'like', "%{$search}%");
        }

        if (!empty($genre)) {
            $query->whereHas('genres', function ($q) use ($genre) {
                $q->where('genres.id', $genre)
                  ->orWhere('genres.rawg_id', $genre)
                  ->orWhere('genres.nama', 'like', "%{$genre}%");
            });
        }

        if (!empty($platform)) {
            $query->whereHas('platforms', function ($q) use ($platform) {
                $q->where('platforms.id', $platform)
                  ->orWhere('platforms.rawg_id', $platform)
                  ->orWhere('platforms.nama', 'like', "%{$platform}%");
            });
        }

        if ($rating > 0) {
            $query->where('rating', '>=', $rating);
        }

        $localPaginated = $query->paginate($perPage, ['*'], 'page', $page);

        if ($localPaginated->total() > 0) {
            $gamesList = [];
            foreach ($localPaginated->items() as $game) {
                $genreNames = $game->genres->pluck('nama')->toArray();
                $platformNames = $game->platforms->pluck('nama')->toArray();

                $gamesList[] = [
                    'id'            => $game->id,
                    'rawg_id'       => $game->rawg_id,
                    'judul'         => $game->judul,
                    'cover_url'     => $game->cover_url,
                    'rating'        => (float) $game->rating,
                    'genre'         => implode(', ', $genreNames),
                    'genres'        => $genreNames,
                    'platform'      => implode(', ', $platformNames),
                    'platforms'     => $platformNames,
                    'tanggal_rilis' => $game->tanggal_rilis ? Carbon::parse($game->tanggal_rilis)->format('Y-m-d') : null,
                ];
            }

            return response()->json([
                'success' => true,
                'message' => 'Daftar game berhasil diambil dari database lokal',
                'data'    => [
                    'games'      => $gamesList,
                    'pagination' => [
                        'current_page' => $localPaginated->currentPage(),
                        'last_page'    => $localPaginated->lastPage(),
                        'per_page'     => $localPaginated->perPage(),
                        'total'        => $localPaginated->total(),
                    ],
                ],
            ], 200);
        }

        // Bila tidak ada di database dan RAWG gagal
        return response()->json([
            'success' => false,
            'message' => 'Layanan RAWG tidak dapat dijangkau dan tidak ada data game pada database lokal.',
            'data'    => null,
        ], 503);
    }

    /**
     * GET /api/games/{id}
     * Detail game: deskripsi, genre, platform, rating, tanggal rilis, dan status library pengguna
     */
    public function show(Request $request, $id): JsonResponse
    {
        // Cari game di database berdasarkan id (primary key) atau rawg_id
        $game = Game::with(['genres', 'platforms'])
            ->where('id', $id)
            ->orWhere('rawg_id', $id)
            ->first();

        $shouldFetchDetail = false;

        if (! $game) {
            $shouldFetchDetail = true;
        } elseif (empty($game->deskripsi) || ! $game->cached_at || Carbon::parse($game->cached_at)->addDays(7)->isPast()) {
            $shouldFetchDetail = true;
        }

        if ($shouldFetchDetail) {
            $rawgIdToFetch = $game ? $game->rawg_id : (int) $id;
            $rawgDetail = null;

            try {
                $rawgDetail = $this->rawgService->getGameDetail($rawgIdToFetch);
            } catch (Throwable $e) {
                $rawgDetail = null;
            }

            if ($rawgDetail && isset($rawgDetail['id'])) {
                if (! $game) {
                    $game = new Game();
                    $game->rawg_id = (int) $rawgDetail['id'];
                }

                $deskripsi = !empty($rawgDetail['description_raw'])
                    ? $rawgDetail['description_raw']
                    : strip_tags($rawgDetail['description'] ?? '');

                $game->judul         = $rawgDetail['name'] ?? $game->judul ?? 'Untitled Game';
                $game->cover_url     = $rawgDetail['background_image'] ?? $game->cover_url;
                $game->rating        = isset($rawgDetail['rating']) ? (float) $rawgDetail['rating'] : $game->rating;
                $game->deskripsi     = $deskripsi;
                $game->tanggal_rilis = !empty($rawgDetail['released']) ? $rawgDetail['released'] : $game->tanggal_rilis;
                $game->cached_at     = now();
                $game->save();

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

        // Jika game ditemukan (baik dari RAWG atau cache database)
        if ($game) {
            $genreNames = $game->genres->pluck('nama')->toArray();
            $platformNames = $game->platforms->pluck('nama')->toArray();

            $user = $request->user() ?? auth('sanctum')->user();
            $libraryEntry = null;
            $wishlistAlert = null;
            if ($user) {
                $libraryEntry = LibraryEntry::with(['game.genres', 'game.platforms'])
                    ->where('user_id', $user->id)
                    ->where('game_id', $game->id)
                    ->first();

                $wishlistAlert = WishlistAlert::where('user_id', $user->id)
                    ->where('game_id', $game->id)
                    ->first();
            }

            // Ambil harga terkini per toko dari price_history
            $rate = (float) config('services.currency.usd_to_idr_rate', 16000);
            $latestPrices = PriceHistory::where('game_id', $game->id)
                ->whereIn('id', function ($query) use ($game) {
                    $query->selectRaw('MAX(id)')
                        ->from('price_history')
                        ->where('game_id', $game->id)
                        ->groupBy('toko');
                })
                ->orderBy('harga', 'asc')
                ->get();

            $formattedPrices = $latestPrices->map(function ($item) use ($rate) {
                return [
                    'toko'               => $item->toko,
                    'harga'              => (float) $item->harga,
                    'harga_idr_estimasi' => (int) round($item->harga * $rate),
                    'diskon_persen'      => (float) $item->diskon_persen,
                    'dicek_pada'         => $item->dicek_pada ? Carbon::parse($item->dicek_pada)->toIso8601String() : null,
                ];
            })->values()->toArray();

            $cheapest = $latestPrices->first();

            return response()->json([
                'success' => true,
                'message' => 'Detail game berhasil diambil',
                'data'    => [
                    'id'                          => $game->id,
                    'rawg_id'                     => $game->rawg_id,
                    'cheapshark_id'               => $game->cheapshark_id,
                    'judul'                       => $game->judul,
                    'cover_url'                   => $game->cover_url,
                    'rating'                      => (float) $game->rating,
                    'deskripsi'                   => $game->deskripsi ?? 'Deskripsi belum tersedia.',
                    'tanggal_rilis'               => $game->tanggal_rilis ? Carbon::parse($game->tanggal_rilis)->format('Y-m-d') : null,
                    'genre'                       => implode(', ', $genreNames),
                    'genres'                      => $genreNames,
                    'platform'                    => implode(', ', $platformNames),
                    'platforms'                   => $platformNames,
                    'cached_at'                   => $game->cached_at ? Carbon::parse($game->cached_at)->toIso8601String() : null,
                    'library_status'              => $libraryEntry?->status,
                    'library_entry'               => $libraryEntry ? new LibraryEntryResource($libraryEntry) : null,
                    'in_wishlist'                 => $wishlistAlert !== null,
                    'wishlist_status'             => $wishlistAlert ? ($wishlistAlert->aktif ? 'Aktif' : 'Nonaktif') : null,
                    'wishlist_alert'              => $wishlistAlert ? [
                        'id'                        => $wishlistAlert->id,
                        'harga_target'              => (float) $wishlistAlert->harga_target,
                        'harga_target_idr_estimasi' => (int) round($wishlistAlert->harga_target * $rate),
                        'aktif'                     => (bool) $wishlistAlert->aktif,
                    ] : null,
                    'harga_tersedia'              => !empty($formattedPrices),
                    'status_harga'                => !empty($formattedPrices) ? 'Harga tersedia' : 'Harga belum tersedia',
                    'harga_terendah'              => $cheapest ? (float) $cheapest->harga : null,
                    'harga_terendah_idr_estimasi' => $cheapest ? (int) round($cheapest->harga * $rate) : null,
                    'toko_termurah'               => $cheapest?->toko,
                    'kurs_usd_ke_idr_estimasi'    => $rate,
                    'harga_terkini'               => $formattedPrices,
                ],
            ], 200);
        }

        return response()->json([
            'success' => false,
            'message' => 'Game tidak ditemukan atau layanan RAWG tidak dapat dijangkau.',
            'data'    => null,
        ], 404);
    }
}
