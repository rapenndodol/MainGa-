<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\LibraryEntry;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class StatsController extends Controller
{
    /**
     * GET /api/stats
     * Statistik bermain dihitung hanya dari library_entries milik pengguna yang login
     * melalui query agregasi basis data:
     * - total_game, total_jam (jumlah jam_main), jumlah_tamat.
     * - game_tamat_per_bulan: 12 bulan terakhir berdasarkan tanggal_tamat (diurutkan terlama ke terbaru).
     * - genre_favorit: maksimal 5 genre teratas dari game di library pengguna.
     * - Pengguna tanpa data mendapat nilai nol dan daftar kosong, bukan galat.
     */
    public function index(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        // 1. Agregasi inti: total game, total jam bermain, dan jumlah game tamat
        $totalGame = (int) LibraryEntry::where('user_id', $userId)->count();
        $totalJam = round((float) (LibraryEntry::where('user_id', $userId)->sum('jam_main') ?? 0), 2);
        $jumlahTamat = (int) LibraryEntry::where('user_id', $userId)->where('status', 'Tamat')->count();

        // 2. Agregasi game tamat per bulan: 12 bulan terakhir berdasarkan tanggal_tamat
        $startDate = now()->copy()->subMonths(11)->startOfMonth()->toDateString();
        $endDate = now()->copy()->endOfMonth()->toDateString();

        $monthlyCounts = LibraryEntry::where('user_id', $userId)
            ->whereNotNull('tanggal_tamat')
            ->whereBetween('tanggal_tamat', [$startDate, $endDate])
            ->selectRaw('SUBSTR(tanggal_tamat, 1, 7) as periode, COUNT(*) as jumlah')
            ->groupBy('periode')
            ->pluck('jumlah', 'periode');

        $gameTamatPerBulan = [];
        for ($i = 11; $i >= 0; $i--) {
            $month = now()->copy()->subMonths($i);
            $periodKey = $month->format('Y-m');
            $count = (int) ($monthlyCounts[$periodKey] ?? 0);
            $label = $month->translatedFormat('M Y');

            $gameTamatPerBulan[] = [
                'periode' => $periodKey,
                'label'   => $label,
                'bulan'   => $label,
                'jumlah'  => $count,
            ];
        }

        // 3. Agregasi genre favorit: maksimal 5 genre teratas dari game di library
        $genreFavorit = DB::table('library_entries')
            ->join('game_genre', 'library_entries.game_id', '=', 'game_genre.game_id')
            ->join('genres', 'game_genre.genre_id', '=', 'genres.id')
            ->where('library_entries.user_id', $userId)
            ->select('genres.nama', DB::raw('COUNT(*) as jumlah'))
            ->groupBy('genres.id', 'genres.nama')
            ->orderByDesc('jumlah')
            ->orderBy('genres.nama', 'asc')
            ->limit(5)
            ->get()
            ->map(function ($row) {
                return [
                    'nama'   => (string) $row->nama,
                    'genre'  => (string) $row->nama,
                    'jumlah' => (int) $row->jumlah,
                ];
            })
            ->values()
            ->all();

        return response()->json([
            'success' => true,
            'message' => 'Statistik bermain berhasil diambil',
            'data'    => [
                'total_game'           => $totalGame,
                'total_jam'            => $totalJam,
                'jumlah_tamat'         => $jumlahTamat,
                'game_tamat_per_bulan' => $gameTamatPerBulan,
                'genre_favorit'        => $genreFavorit,
            ],
        ], 200);
    }
}
