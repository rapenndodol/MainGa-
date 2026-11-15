<?php

namespace App\Services;

use App\Models\Game;
use App\Models\Notification;
use App\Models\PriceHistory;
use App\Models\WishlistAlert;
use Carbon\Carbon;
use Illuminate\Http\Client\PendingRequest;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Throwable;

class PriceService
{
    protected RawgService $rawgService;
    protected string $baseUrl;
    protected int $timeout;
    protected string $userAgent;

    public function __construct(?RawgService $rawgService = null)
    {
        $this->rawgService = $rawgService ?? app(RawgService::class);
        $this->baseUrl = rtrim((string) config('services.cheapshark.base_url', 'https://www.cheapshark.com/api/1.0'), '/');
        $this->timeout = (int) config('services.cheapshark.timeout', 5);
        $this->userAgent = (string) config('services.cheapshark.user_agent', 'MainGa/1.0 (support@mainga.app)');
    }

    public function setTimeout(int $timeout): self
    {
        $this->timeout = $timeout;
        return $this;
    }

    /**
     * Inisialisasi HTTP client dengan descriptive User-Agent header (wajib bagi CheapShark API).
     */
    protected function client(?int $timeout = null): PendingRequest
    {
        return Http::withUserAgent($this->userAgent)
            ->timeout($timeout ?? $this->timeout)
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
     * Konversi angka Romawi (kata utuh) ke angka arab.
     */
    public function convertRomanNumerals(string $text): string
    {
        $map = [
            'xviii' => '18',
            'xvii'  => '17',
            'xvi'   => '16',
            'xv'    => '15',
            'xiv'   => '14',
            'xiii'  => '13',
            'xii'   => '12',
            'xi'    => '11',
            'xix'   => '19',
            'xx'    => '20',
            'viii'  => '8',
            'vii'   => '7',
            'iii'   => '3',
            'iv'    => '4',
            'vi'    => '6',
            'ix'    => '9',
            'ii'    => '2',
            'x'     => '10',
            'v'     => '5',
            'i'     => '1',
        ];

        foreach ($map as $roman => $arabic) {
            $text = (string) preg_replace('/\b' . $roman . '\b/u', $arabic, $text);
        }

        return $text;
    }

    /**
     * Normalisasi string judul:
     * - huruf kecil
     * - tanpa tanda baca
     * - tanpa awalan "the"
     * - angka Romawi ke angka
     * - buang kata edition/remastered/goty/definitive
     * - spasi diseragamkan
     */
    public function normalizeTitle(string $title): string
    {
        $title = mb_strtolower($title, 'UTF-8');
        // Ganti semua tanda baca dan simbol non-huruf/non-angka dengan spasi
        $cleaned = (string) preg_replace('/[^\p{L}\p{N}]+/u', ' ', $title);
        // Hapus awalan "the " jika ada
        $cleaned = trim((string) preg_replace('/^the\s+/u', '', $cleaned));
        // Angka Romawi ke angka arab
        $cleaned = $this->convertRomanNumerals($cleaned);
        // Buang kata edition/remastered/goty/definitive
        $cleaned = (string) preg_replace('/\b(edition|remastered|goty|definitive)\b/u', ' ', $cleaned);
        // Rapikan spasi berlebih
        return trim((string) preg_replace('/\s+/u', ' ', $cleaned));
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
     * - Evaluasi kemiripan teks full title dan title tanpa subjudul
     * - Pilih kandidat dengan similar_text >= 85%
     *
     * @param string $targetTitle
     * @param array $searchResults
     * @param float $minScore
     * @return array|null
     */
    public function findBestMatch(string $targetTitle, array $searchResults, float $minScore = 85.0): ?array
    {
        if (empty($searchResults)) {
            return null;
        }

        $normTarget = $this->normalizeTitle($targetTitle);
        if ($normTarget === '') {
            return null;
        }

        $targetParts = preg_split('/[:\-]/', $targetTitle);
        $targetWithoutSub = trim($targetParts[0] ?? '');
        $normTargetWithoutSub = $this->normalizeTitle($targetWithoutSub);

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

            $candidateParts = preg_split('/[:\-]/', $candidateTitle);
            $candidateWithoutSub = trim($candidateParts[0] ?? '');
            $normCandidateWithoutSub = $this->normalizeTitle($candidateWithoutSub);

            // Hitung skor kemiripan teks berbagai kombinasi
            similar_text($normTarget, $normCandidate, $simFull);

            $simSub1 = 0.0;
            if ($normCandidateWithoutSub !== '') {
                similar_text($normTarget, $normCandidateWithoutSub, $simSub1);
            }

            $simSub2 = 0.0;
            if ($normTargetWithoutSub !== '') {
                similar_text($normTargetWithoutSub, $normCandidate, $simSub2);
            }

            $simSub3 = 0.0;
            if ($normTargetWithoutSub !== '' && $normCandidateWithoutSub !== '') {
                similar_text($normTargetWithoutSub, $normCandidateWithoutSub, $simSub3);
            }

            $score = max($simFull, $simSub1, $simSub2, $simSub3);

            // Bonus jika target adalah bagian dari kandidat atau sebaliknya
            if (str_contains($normCandidate, $normTarget) || str_contains($normTarget, $normCandidate)) {
                $score = max($score, min(100.0, $simFull + 15.0));
            }

            if ($score > $highestScore) {
                $highestScore = $score;
                $bestMatch = $item;
            }
        }

        // Ambang batas kemiripan: similar_text >= 85%
        if ($bestMatch !== null && $highestScore >= $minScore) {
            return $bestMatch;
        }

        return null;
    }

    /**
     * Ambil steam_app_id sekali saja dari RAWG stores jika belum tersimpan, lalu simpan ke database.
     */
    public function resolveSteamAppId(Game $game): ?string
    {
        if ($game->steam_app_id !== null) {
            return $game->steam_app_id !== '' ? (string) $game->steam_app_id : null;
        }

        if (empty($game->rawg_id)) {
            return null;
        }

        try {
            $storesData = $this->rawgService->getGameStores((int) $game->rawg_id);
            $foundSteamId = null;

            if ($storesData && !empty($storesData['results']) && is_array($storesData['results'])) {
                foreach ($storesData['results'] as $store) {
                    $url = (string) ($store['url'] ?? '');
                    if (preg_match('#store\.steampowered\.com/app/(\d+)#i', $url, $matches)) {
                        $foundSteamId = (string) $matches[1];
                        break;
                    }
                }
            }

            // Simpan ke database: isi ID steam jika ada, atau string kosong jika tidak ada (agar tidak fetch ulang)
            $game->steam_app_id = $foundSteamId ?? '';
            $game->save();

            return $foundSteamId;
        } catch (Throwable $e) {
            Log::warning("Gagal mengambil store RAWG untuk game '{$game->judul}': " . $e->getMessage());
            return null;
        }
    }

    /**
     * Cari ID game CheapShark berdasarkan steam_app_id atau judul game dan simpan ke kolom cheapshark_id tabel games.
     */
    public function resolveCheapSharkId(Game $game): ?string
    {
        // Jika sudah tersimpan, langsung gunakan agar tidak perlu mencari ulang
        if (!empty($game->cheapshark_id)) {
            return (string) $game->cheapshark_id;
        }

        // 1. Ambil steam_app_id (sekali saja dari RAWG jika belum ada)
        $steamAppId = $this->resolveSteamAppId($game);

        // 2. Jika steam_app_id tersedia, gunakan GET /games?steamAppID= lebih dulu
        if (!empty($steamAppId)) {
            try {
                $response = $this->client()->get("{$this->baseUrl}/games", [
                    'steamAppID' => $steamAppId,
                ]);

                if ($response->successful()) {
                    $results = $response->json();
                    if (is_array($results) && !empty($results)) {
                        $match = $this->findBestMatch($game->judul, $results);
                        if ($match && isset($match['gameID'])) {
                            $cheapsharkId = (string) $match['gameID'];
                            $selectedTitle = $match['external'] ?? ($match['title'] ?? 'Unknown');
                            Log::info("Pencarian CheapShark via steamAppID ({$steamAppId}) untuk '{$game->judul}': Terpilih '{$selectedTitle}' (ID: {$cheapsharkId}).");

                            $game->cheapshark_id = $cheapsharkId;
                            $game->save();

                            return $cheapsharkId;
                        }
                    }
                }
            } catch (Throwable $e) {
                Log::warning("CheapShark API steamAppID error untuk '{$game->judul}': " . $e->getMessage());
            }
        }

        // 3. Coba pencarian dengan judul penuh
        $match = $this->searchCheapSharkByTitle($game->judul, $game->judul);
        if ($match && isset($match['gameID'])) {
            $cheapsharkId = (string) $match['gameID'];
            $game->cheapshark_id = $cheapsharkId;
            $game->save();
            return $cheapsharkId;
        }

        // 4. Coba pencarian judul tanpa subjudul setelah ":" atau "-"
        $titleParts = preg_split('/[:\-]/', $game->judul);
        $titleWithoutSubtitle = trim($titleParts[0] ?? '');

        if ($titleWithoutSubtitle !== '' && $titleWithoutSubtitle !== $game->judul) {
            $match = $this->searchCheapSharkByTitle($titleWithoutSubtitle, $game->judul);
            if ($match && isset($match['gameID'])) {
                $cheapsharkId = (string) $match['gameID'];
                $game->cheapshark_id = $cheapsharkId;
                $game->save();
                return $cheapsharkId;
            }
        }

        return null;
    }

    /**
     * Helper pencarian CheapShark berdasarkan string judul dan pencocokan terhadap judul target.
     */
    protected function searchCheapSharkByTitle(string $searchTitle, string $targetTitle): ?array
    {
        try {
            $response = $this->client()->get("{$this->baseUrl}/games", [
                'title' => $searchTitle,
            ]);

            // (a) Respons CheapShark gagal (status bukan 2xx)
            if (! $response->successful()) {
                Log::warning("CheapShark API gagal untuk judul '{$searchTitle}', status: {$response->status()}");
                return null;
            }

            $results = $response->json();
            $count = is_array($results) ? count($results) : 0;

            // (b) Tidak ada kandidat
            if ($count === 0) {
                Log::info("Pencarian CheapShark untuk '{$searchTitle}': 0 kandidat ditemukan (tidak ada kandidat).");
                return null;
            }

            $match = $this->findBestMatch($targetTitle, $results);

            if ($match && isset($match['gameID'])) {
                $selectedTitle = $match['external'] ?? ($match['title'] ?? 'Unknown');
                $cheapsharkId = (string) $match['gameID'];

                Log::info("Pencarian CheapShark untuk '{$searchTitle}': {$count} kandidat ditemukan. Terpilih: '{$selectedTitle}' (ID: {$cheapsharkId}).");
                return $match;
            }

            Log::info("Pencarian CheapShark untuk '{$searchTitle}': {$count} kandidat ditemukan, tetapi tidak ada kandidat yang cocok.");
            return null;
        } catch (Throwable $e) {
            Log::warning("CheapShark API timeout/error untuk judul '{$searchTitle}': " . $e->getMessage());
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
     * Cek apakah game perlu diperiksa harganya:
     * - jika belum pernah punya price_history:
     *     - bila belum dicek sama sekali -> true
     *     - bila pernah dicek tapi tidak ditemukan -> negative cache 24 jam
     * - jika sudah punya price_history:
     *     - cek apakah pengecekan terakhir > 6 jam yang lalu
     */
    public function shouldCheckPrices(Game $game): bool
    {
        $hasHistory = $game->priceHistories()->exists();

        if (! $hasHistory) {
            if ($game->price_checked_at === null) {
                return true;
            }
            // Negative cache 24 jam: jangan panggil CheapShark lagi dalam 24 jam bila tidak ditemukan
            return Carbon::parse($game->price_checked_at)->addHours(24)->isPast();
        }

        // Sudah punya price_history: cek apakah pengecekan terakhir > 6 jam yang lalu
        $lastChecked = $game->price_checked_at
            ?? $game->priceHistories()->max('dicek_pada');

        if (! $lastChecked) {
            return true;
        }

        return Carbon::parse($lastChecked)->addHours(6)->isPast();
    }

    /**
     * Jalankan pengecekan harga on-demand secara sinkron dengan timeout 5 detik.
     */
    public function checkPricesOnDemand(Game $game, int $timeout = 5): array
    {
        if (! $this->shouldCheckPrices($game)) {
            return [
                'available'     => false,
                'cheapshark_id' => $game->cheapshark_id,
                'deals'         => [],
                'cheapest'      => null,
                'cached'        => true,
            ];
        }

        $originalTimeout = $this->timeout;
        $this->timeout = $timeout;

        try {
            return $this->checkAndRecordPrices($game);
        } catch (Throwable $e) {
            Log::warning("On-demand price check gagal untuk game '{$game->judul}': " . $e->getMessage());
            return [
                'available'     => false,
                'cheapshark_id' => $game->cheapshark_id,
                'deals'         => [],
                'cheapest'      => null,
            ];
        } finally {
            $this->timeout = $originalTimeout;
        }
    }

    /**
     * Jalankan pengecekan harga dan simpan satu baris per toko ke tabel price_history.
     * Mencegah duplikasi jika harga dan toko sama dengan pengecekan sebelumnya dalam jam yang sama.
     * Mengisi price_checked_at setiap pengecekan (termasuk bila tidak ditemukan).
     *
     * @param Game $game
     * @return array
     */
    public function checkAndRecordPrices(Game $game): array
    {
        // Catat waktu pengecekan (termasuk saat game tidak ditemukan) untuk negative cache 24 jam
        $game->price_checked_at = now();
        $game->save();

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

            // Jalankan alur notifikasi penurunan harga untuk wishlist aktif
            if (!empty($prices['cheapest'])) {
                $this->notifyWishlistUsers(
                    $game,
                    (float) $prices['cheapest']['harga'],
                    (string) $prices['cheapest']['toko']
                );
            }
        }

        return $prices;
    }

    /**
     * Tentukan status ketersediaan harga:
     * - available: harga tersedia di CheapShark
     * - unsupported: game tidak mendukung platform PC yang dipantau CheapShark
     * - not_found: game PC namun belum/tidak ditemukan di CheapShark
     */
    public function determinePriceStatus(Game $game, bool $hasPrices): string
    {
        if ($hasPrices) {
            return 'available';
        }

        $game->loadMissing('platforms');
        if ($game->platforms->isNotEmpty()) {
            $hasPc = $game->platforms->contains(function ($platform) {
                $name = strtolower($platform->nama ?? '');
                return str_contains($name, 'pc') || str_contains($name, 'windows');
            });

            if (! $hasPc) {
                return 'unsupported';
            }
        }

        return 'not_found';
    }

    /**
     * Periksa wishlist_alerts aktif untuk game tertentu dan buat notifikasi
     * jika harga terendah <= harga_target, serta cegah duplikasi jika harga tidak berubah.
     *
     * @param Game $game
     * @param float|null $cheapestPrice
     * @param string|null $cheapestStore
     * @return int Jumlah notifikasi baru yang dibuat
     */
    public function notifyWishlistUsers(Game $game, ?float $cheapestPrice = null, ?string $cheapestStore = null): int
    {
        // Jika parameter harga belum diberikan, cari harga terendah dari riwayat harga terkini
        if ($cheapestPrice === null) {
            $latestPrice = PriceHistory::where('game_id', $game->id)
                ->whereIn('id', function ($query) use ($game) {
                    $query->selectRaw('MAX(id)')
                        ->from('price_history')
                        ->where('game_id', $game->id)
                        ->groupBy('toko');
                })
                ->orderBy('harga', 'asc')
                ->first();

            if (! $latestPrice) {
                return 0;
            }

            $cheapestPrice = (float) $latestPrice->harga;
            $cheapestStore = $latestPrice->toko;
        }

        $cheapestStore = $cheapestStore ?: 'Toko';
        $cheapestPrice = round($cheapestPrice, 2);

        // Ambil semua wishlist_alerts yang AKTIF untuk game ini
        $activeAlerts = WishlistAlert::where('game_id', $game->id)
            ->where('aktif', true)
            ->get();

        $notificationsCreated = 0;

        foreach ($activeAlerts as $alert) {
            $targetPrice = round((float) $alert->harga_target, 2);

            // Kondisi 1: Harga terendah <= harga_target
            if ($cheapestPrice <= $targetPrice) {
                // Cek notifikasi terakhir untuk user dan game ini
                $lastNotification = Notification::where('user_id', $alert->user_id)
                    ->where('game_id', $game->id)
                    ->latest('id')
                    ->first();

                // Cegah duplikasi:
                // Jangan membuat notifikasi baru untuk pengguna dan game yang sama selama harga terendah
                // belum berubah dari harga pada notifikasi terakhir untuk game itu.
                // Bila harga berubah (naik lalu turun lagi, atau turun lebih jauh) dan masih <= target, buat notifikasi baru.
                if ($lastNotification) {
                    $lastNotifPrice = round((float) $lastNotification->harga, 2);
                    $priceIsSame = abs($lastNotifPrice - $cheapestPrice) < 0.001;

                    if ($priceIsSame) {
                        // Cek apakah pernah ada fluktuasi harga (naik lalu turun lagi) di price_history sejak notifikasi terakhir
                        $hasFluctuated = PriceHistory::where('game_id', $game->id)
                            ->where(function ($q) use ($lastNotification) {
                                $q->where('dicek_pada', '>', $lastNotification->created_at)
                                  ->orWhere('created_at', '>', $lastNotification->created_at);
                            })
                            ->where('harga', '!=', $lastNotifPrice)
                            ->exists();

                        if (! $hasFluctuated) {
                            // Harga belum berubah dari notifikasi terakhir, jangan buat duplikat
                            continue;
                        }
                    }
                }

                $formattedPrice = number_format($cheapestPrice, 2);
                $formattedTarget = number_format($targetPrice, 2);

                Notification::create([
                    'user_id'     => $alert->user_id,
                    'game_id'     => $game->id,
                    'judul'       => $game->judul,
                    'pesan'       => "Harga {$game->judul} turun menjadi \${$formattedPrice} di {$cheapestStore}! Sudah mencapai harga target Anda (\${$formattedTarget}).",
                    'harga'       => $cheapestPrice,
                    'toko'        => $cheapestStore,
                    'dibaca_pada' => null,
                ]);

                $notificationsCreated++;
            }
        }

        return $notificationsCreated;
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
