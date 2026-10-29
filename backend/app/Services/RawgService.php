<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Throwable;

class RawgService
{
    protected string $key;
    protected string $baseUrl;
    protected int $timeout;

    public function __construct()
    {
        $this->key = (string) config('services.rawg.key');
        $this->baseUrl = rtrim((string) config('services.rawg.base_url', 'https://api.rawg.io/api'), '/');
        $this->timeout = (int) config('services.rawg.timeout', 10);
    }

    /**
     * Ambil daftar genre dari RAWG API
     */
    public function getGenres(int $pageSize = 50): ?array
    {
        return $this->request('/genres', [
            'page_size' => $pageSize,
        ]);
    }

    /**
     * Ambil daftar platform dari RAWG API
     */
    public function getPlatforms(int $pageSize = 50): ?array
    {
        return $this->request('/platforms', [
            'page_size' => $pageSize,
        ]);
    }

    /**
     * Cari dan filter game dari RAWG API
     *
     * @param array $params ['search', 'genres', 'platforms', 'page', 'page_size']
     */
    public function getGames(array $params = []): ?array
    {
        $queryParams = [
            'page' => $params['page'] ?? 1,
            'page_size' => $params['page_size'] ?? 20,
        ];

        if (!empty($params['search'])) {
            $queryParams['search'] = $params['search'];
        }

        if (!empty($params['genres'])) {
            $queryParams['genres'] = $params['genres'];
        }

        if (!empty($params['platforms'])) {
            $queryParams['platforms'] = $params['platforms'];
        }

        return $this->request('/games', $queryParams);
    }

    /**
     * Ambil detail lengkap suatu game dari RAWG API berdasarkan rawg_id
     */
    public function getGameDetail(int $rawgId): ?array
    {
        return $this->request("/games/{$rawgId}");
    }

    /**
     * Helper request internal dengan timeout dan error handling aman
     */
    protected function request(string $endpoint, array $queryParams = []): ?array
    {
        if (empty($this->key)) {
            Log::warning('RAWG_API_KEY belum dikonfigurasi.');
            return null;
        }

        $url = $this->baseUrl . $endpoint;
        $queryParams['key'] = $this->key;

        try {
            $response = Http::timeout($this->timeout)
                ->acceptJson()
                ->get($url, $queryParams);

            if ($response->successful()) {
                return $response->json();
            }

            Log::warning("RAWG API mengembalikan status: {$response->status()} untuk {$endpoint}");
            return null;
        } catch (Throwable $e) {
            // Catat pesan error tanpa mengekspos API key
            Log::error("Gagal menghubungi RAWG API untuk {$endpoint}: " . $e->getMessage());
            return null;
        }
    }
}
