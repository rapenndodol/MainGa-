<?php

namespace App\Services;

use App\Models\Game;
use App\Models\PriceHistory;
use Illuminate\Http\Client\PendingRequest;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Throwable;

class PriceService
{
    protected string $baseUrl;
    protected int $timeout;
    protected string $userAgent;

    public function __construct()
    {
        $this->baseUrl = rtrim((string) config('services.cheapshark.base_url', 'https://www.cheapshark.com/api/1.0'), '/');
        $this->timeout = (int) config('services.cheapshark.timeout', 10);
        $this->userAgent = (string) config('services.cheapshark.user_agent', 'MainGa/1.0 (support@mainga.app)');
    }

    /**
     * Inisialisasi HTTP client dengan descriptive User-Agent header (wajib bagi CheapShark API).
     */
    protected function client(): PendingRequest
    {
        return Http::withUserAgent($this->userAgent)
            ->timeout($this->timeout)
            ->acceptJson();
    }

    /**
     * Ambil daftar toko dari CheapShark dan simpan di cache selama 24 jam.
     * Mengembalikan mapping: [storeID => storeName]
     *
     * @return array<string, string>
     */
    public function getStores(): array
    {
        return Cache::remember('cheapshark_stores', now()->addDay(), function () {
            try {
                $response = $this->client()->get("{$this->baseUrl}/stores");

                if ($response->successful()) {
                    $stores = $response->json();
                    $storeMap = [];
                    if (is_array($stores)) {
                        foreach ($stores as $store) {
                            if (isset($store['storeID'], $store['storeName'])) {
                                $storeMap[(string) $store['storeID']] = (string) $store['storeName'];
                            }
                        }
                    }

                    if (!empty($storeMap)) {
                        return $storeMap;
                    }
                } else {
                    Log::warning("CheapShark API stores gagal, status: {$response->status()}");
                }
            } catch (Throwable $e) {
                Log::warning('Gagal mengambil daftar store dari CheapShark API: ' . $e->getMessage());
            }

            return $this->fallbackStores();
        });
    }

    /**
     * Normalisasi string judul:
     * - huruf kecil
     * - tanpa tanda baca
     * - tanpa awalan "the"
     * - spasi diseragamkan
     */
    public function normalizeTitle(string $title): string
    {
        $title = mb_strtolower($title, 'UTF-8');
        // Ganti semua tanda baca dan simbol non-huruf/non-angka dengan spasi
        $cleaned = preg_replace('/[^\p{L}\p{N}]+/u', ' ', $title);
        // Rapikan spasi berlebih
        $cleaned = trim(preg_replace('/\s+/', ' ', (string) $cleaned));
        // Hapus awalan "the " jika ada
        return trim((string) preg_replace('/^the\s+/u', '', $cleaned));
    }

    /**
     * Cek apakah judul kandidat merupakan DLC, bundle, soundtrack, atau expansion pass.
     */
    public function isDlcOrExtra(string $title): bool
    {
        return (bool) preg_match('/\b(dlc|bundle|soundtrack|ost|expansion pass|season pass|expansion pack|artbook|pass)\b/i', $title);
    }

    /**
     * Pilih hasil pencarian CheapShark yang judulnya paling cocok dengan judul game target.
     * - Utamakan kecocokan persis
     * - Bila tidak ada, pilih kemiripan tertinggi dan abaikan DLC/bundle/soundtrack/expansion pass bila ada kandidat utama
     * - Tidak mensyaratkan steamAppID terisi
     *
     * @param string $targetTitle
     * @param array $searchResults
     * @return array|null
     */
    public function findBestMatch(string $targetTitle, array $searchResults): ?array
    {
        if (empty($searchResults)) {
            return null;
        }

        $normTarget = $this->normalizeTitle($targetTitle);
        if ($normTarget === '') {
            return null;
        }

        // 1. Utamakan kecocokan persis
        foreach ($searchResults as $item) {
            if (!is_array($item)) {
                continue;
            }
            $candidateTitle = $item['external'] ?? ($item['title'] ?? '');
            $normCandidate = $this->normalizeTitle($candidateTitle);

            if ($normTarget === $normCandidate) {
                return $item;
            }
        }

        // 2. Pisahkan kandidat utama (non-DLC) dan kandidat DLC/extra
        $mainCandidates = [];
        $dlcCandidates = [];

        foreach ($searchResults as $item) {
            if (!is_array($item)) {
                continue;
            }
            $candidateTitle = $item['external'] ?? ($item['title'] ?? '');
            if ($this->isDlcOrExtra($candidateTitle)) {
                $dlcCandidates[] = $item;
            } else {
                $mainCandidates[] = $item;
            }
        }

        // Utamakan evaluasi kandidat non-DLC jika tersedia
        $candidatesToEvaluate = !empty($mainCandidates) ? $mainCandidates : $dlcCandidates;

        $bestMatch = null;
        $highestScore = -1.0;

        foreach ($candidatesToEvaluate as $item) {
            $candidateTitle = $item['external'] ?? ($item['title'] ?? '');
            $normCandidate = $this->normalizeTitle($candidateTitle);

            // Hitung kemiripan teks
            similar_text($normTarget, $normCandidate, $percent);

            // Bonus jika target adalah bagian dari kandidat atau sebaliknya
            if (str_contains($normCandidate, $normTarget) || str_contains($normTarget, $normCandidate)) {
                $percent += 15.0;
            }

            if ($percent > $highestScore) {
                $highestScore = $percent;
                $bestMatch = $item;
            }
        }

        // Ambang batas kemiripan wajar (>= 35.0) atau satu-satunya kandidat
        if ($bestMatch !== null && ($highestScore >= 35.0 || count($searchResults) === 1)) {
            return $bestMatch;
        }

        return null;
    }

    /**
     * Cari ID game CheapShark berdasarkan judul game dan simpan ke kolom cheapshark_id tabel games.
     */
    public function resolveCheapSharkId(Game $game): ?string
    {
        // Jika sudah tersimpan, langsung gunakan agar tidak perlu mencari ulang
        if (!empty($game->cheapshark_id)) {
            return (string) $game->cheapshark_id;
        }

        try {
            $response = $this->client()->get("{$this->baseUrl}/games", [
                'title' => $game->judul,
            ]);

            // (a) Respons CheapShark gagal (status bukan 2xx)
            if (! $response->successful()) {
                Log::warning("CheapShark API gagal untuk judul '{$game->judul}', status: {$response->status()}");
                return null;
            }

            $results = $response->json();
            $count = is_array($results) ? count($results) : 0;

            // (b) Tidak ada kandidat
            if ($count === 0) {
                Log::info("Pencarian CheapShark untuk '{$game->judul}': 0 kandidat ditemukan (tidak ada kandidat).");
                return null;
            }

            $match = $this->findBestMatch($game->judul, $results);

            if ($match && isset($match['gameID'])) {
                $selectedTitle = $match['external'] ?? ($match['title'] ?? 'Unknown');
                $cheapsharkId = (string) $match['gameID'];

                Log::info("Pencarian CheapShark untuk '{$game->judul}': {$count} kandidat ditemukan. Terpilih: '{$selectedTitle}' (ID: {$cheapsharkId}).");

                $game->cheapshark_id = $cheapsharkId;
                $game->save();

                return $cheapsharkId;
            }

            Log::info("Pencarian CheapShark untuk '{$game->judul}': {$count} kandidat ditemukan, tetapi tidak ada kandidat yang cocok.");
            return null;
        } catch (Throwable $e) {
            // (a) Respons CheapShark timeout / error
            Log::warning("CheapShark API timeout/error untuk judul '{$game->judul}': " . $e->getMessage());
            return null;
        }
    }

    /**
     * Ambil harga terkini per toko dari CheapShark untuk suatu game.
     * Bila game tidak ditemukan atau harga kosong, tandai sebagai harga belum tersedia tanpa melempar galat.
     *
     * @param Game $game
     * @return array{available: bool, cheapshark_id: string|null, deals: array, cheapest: array|null}
     */
    public function fetchPrices(Game $game): array
    {
        $cheapsharkId = $this->resolveCheapSharkId($game);

        if (! $cheapsharkId) {
            return [
                'available'     => false,
                'cheapshark_id' => null,
                'deals'         => [],
                'cheapest'      => null,
            ];
        }

        try {
            $response = $this->client()->get("{$this->baseUrl}/games", [
                'id' => $cheapsharkId,
            ]);

            // (a) Respons CheapShark gagal
            if (! $response->successful()) {
                Log::warning("CheapShark API detail harga gagal untuk ID '{$cheapsharkId}' (judul: '{$game->judul}'), status: {$response->status()}");
                return [
                    'available'     => false,
                    'cheapshark_id' => $cheapsharkId,
                    'deals'         => [],
                    'cheapest'      => null,
                ];
            }

            $data = $response->json();
            $stores = $this->getStores();

            if (isset($data['deals']) && is_array($data['deals']) && !empty($data['deals'])) {
                $dealsList = [];
                $cheapest = null;
                $minPrice = PHP_FLOAT_MAX;

                foreach ($data['deals'] as $deal) {
                    $storeId = (string) ($deal['storeID'] ?? '');
                    $storeName = $stores[$storeId] ?? "Toko #{$storeId}";
                    $price = (float) ($deal['price'] ?? 0.0);
                    $retailPrice = (float) ($deal['retailPrice'] ?? $price);
                    $savings = (float) ($deal['savings'] ?? 0.0);

                    $dealData = [
                        'toko'          => $storeName,
                        'store_id'      => $storeId,
                        'harga'         => $price,
                        'harga_normal'  => $retailPrice,
                        'diskon_persen' => round($savings, 2),
                        'deal_id'       => $deal['dealID'] ?? null,
                    ];

                    $dealsList[] = $dealData;

                    if ($price < $minPrice) {
                        $minPrice = $price;
                        $cheapest = $dealData;
                    }
                }

                return [
                    'available'     => !empty($dealsList),
                    'cheapshark_id' => $cheapsharkId,
                    'deals'         => $dealsList,
                    'cheapest'      => $cheapest,
                ];
            }

            // (c) Kandidat ditemukan tapi daftar harganya kosong
            Log::info("Kandidat '{$game->judul}' (ID: {$cheapsharkId}) ditemukan, tetapi daftar harga kosong.");
        } catch (Throwable $e) {
            Log::warning("CheapShark API detail harga timeout/error untuk ID '{$cheapsharkId}' (judul: '{$game->judul}'): " . $e->getMessage());
        }

        return [
            'available'     => false,
            'cheapshark_id' => $cheapsharkId,
            'deals'         => [],
            'cheapest'      => null,
        ];
    }

    /**
     * Jalankan pengecekan harga dan simpan satu baris per toko ke tabel price_history.
     * Mencegah duplikasi jika harga dan toko sama dengan pengecekan sebelumnya dalam jam yang sama.
     *
     * @param Game $game
     * @return array
     */
    public function checkAndRecordPrices(Game $game): array
    {
        $prices = $this->fetchPrices($game);

        if ($prices['available'] && !empty($prices['deals'])) {
            $now = now();
            foreach ($prices['deals'] as $deal) {
                $storeName = $deal['toko'];
                $price = (float) $deal['harga'];
                $savings = (float) $deal['diskon_persen'];

                // Cek duplikasi: hindari menyimpan bila toko dan harga sama dalam jam yang sama
                $isDuplicate = PriceHistory::where('game_id', $game->id)
                    ->where('toko', $storeName)
                    ->whereBetween('dicek_pada', [$now->copy()->startOfHour(), $now->copy()->endOfHour()])
                    ->where('harga', $price)
                    ->exists();

                if (! $isDuplicate) {
                    PriceHistory::create([
                        'game_id'       => $game->id,
                        'toko'          => $storeName,
                        'harga'         => $price,
                        'diskon_persen' => $savings,
                        'dicek_pada'    => $now,
                    ]);
                }
            }
        }

        return $prices;
    }

    /**
     * Fallback nama toko populer bila CheapShark stores endpoint tidak dapat dihubungi.
     */
    protected function fallbackStores(): array
    {
        return [
            '1'  => 'Steam',
            '2'  => 'GamersGate',
            '3'  => 'GreenManGaming',
            '6'  => 'Direct2Drive',
            '7'  => 'GOG',
            '8'  => 'Origin',
            '11' => 'Humble Store',
            '15' => 'Fanatical',
            '25' => 'Epic Games Store',
            '31' => 'Blizzard Shop',
        ];
    }
}
