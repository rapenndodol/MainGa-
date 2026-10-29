# MainGa? — Aplikasi Pengelola Koleksi dan Backlog Game

> Proyek UAS Pemrograman Aplikasi Bergerak — S1 Sistem Informasi, Universitas Negeri Surabaya  
> Penulis: Yosua Arthur P. S

---

## 📌 Deskripsi Tahap 2

Tahap 2 mengimplementasikan integrasi katalog game RAWG API dengan strategi *caching multi-layer*, fitur pencarian dan filter game, layar detail game, serta arsitektur navigasi utama aplikasi mobile sesuai [PRD](rules/PRD_MainGA.md) dan aturan [rules_mainga.md](rules/rules_mainga.md):

- **Backend (Laravel REST API)**:
  - Pembacaan aman `RAWG_API_KEY` dari `.env` via `config/services.php` (kunci tidak pernah terekspos ke aplikasi client, repositori, maupun log).
  - Service class `RawgService` dengan timeout 10 detik dan penanganan galat yang aman.
  - Artisan Command `php artisan rawg:sync-master` untuk mengisi data master `genres` dan `platforms` dari RAWG API (dengan fallback data standar jika offline).
  - Endpoint terproteksi Sanctum (`auth:sanctum`):
    - `GET /api/games` : Pencarian judul game, filter genre, platform, rating minimum, serta pagination.
    - `GET /api/games/{id}` : Detail game lengkap (deskripsi, genre, platform, rating, tanggal rilis).
    - `GET /api/genres` : Daftar seluruh master genre untuk filter.
    - `GET /api/platforms` : Daftar seluruh master platform untuk filter.
  - Caching 2-lapis:
    - *Layer A (Response Cache)*: Laravel Cache selama 1 jam untuk pencarian identik agar waktu respons di bawah 3 detik dan menghemat kuota RAWG (20.000 req/bulan).
    - *Layer B (Database Cache)*: Data game dan relasi pivot `game_genre` & `game_platform` disimpan ke database dengan kolom `cached_at`, dianggap kedaluwarsa setelah 7 hari. Deskripsi lengkap diambil hanya saat detail dibuka dan belum tersimpan.
  - Fallback ke database lokal jika RAWG gagal dijangkau, atau mengembalikan JSON error 503 jika data belum pernah dicache.
  - 8 Feature Tests komprehensif menggunakan `Http::fake` mencakup pencarian, filter, cache panggilan kedua, detail game, 401 tanpa token, dan penanganan galat RAWG.

- **Mobile (Flutter Android)**:
  - Navigasi utama 4 tab bergaya melayang (*floating bottom navigation*) dengan warna aksen ungu/indigo: **Jelajah**, **Library**, **Wishlist**, dan **Profil**. Pengguna otomatis diarahkan ke tab Jelajah setelah login.
  - **Tab Jelajah**: Kolom pencarian dengan debounce, chip filter genre horizontal, filter platform & rating minimum via modal bottom sheet, daftar kartu game (cover thumbnail, judul, genre, rating), *infinite scroll pagination*, serta *loading*, *empty*, dan *error state*.
  - **Layar Detail Game**: Cover besar dengan gradient scrim, judul game, badge rating & tanggal rilis, tag chip genre & platform, dan deskripsi lengkap dengan tombol toggle *"Baca selengkapnya"*.
  - **Tab Library & Wishlist**: Tampilan kosong yang informatif (*"Belum ada game"*) tanpa teks pengembangan tahap/versi.
  - **Tab Profil**: Nama pengguna, email, dan tombol konfirmasi logout. Seluruh teks konfirmasi sementara tahap 1 telah dibersihkan dari aplikasi.
  - **Atribusi "Data by RAWG"**: Tautan interaktif yang dapat diklik membuka `https://rawg.io` menggunakan plugin `url_launcher`, tampil di halaman Jelajah dan layar detail game.
  - Semua pemanggilan API murni ke backend sendiri melalui `ApiConstants`.

---

## 🏗️ Struktur Proyek

```text
MainGa/
├── backend/                             # REST API Laravel
│   ├── app/
│   │   ├── Console/Commands/
│   │   │   └── SyncRawgMetadata.php    # Command artisan rawg:sync-master
│   │   ├── Http/Controllers/Api/
│   │   │   ├── AuthController.php      # Controller Register, Login, Logout, Me
│   │   │   └── GameController.php      # Controller Games, Genres, Platforms
│   │   ├── Models/                     # 8 Eloquent Models & Relasi
│   │   │   ├── User.php
│   │   │   ├── Game.php
│   │   │   ├── Genre.php
│   │   │   ├── Platform.php
│   │   │   ├── LibraryEntry.php
│   │   │   ├── WishlistAlert.php
│   │   │   ├── PriceHistory.php
│   │   │   └── Notification.php
│   │   └── Services/
│   │       └── RawgService.php         # Service klien RAWG API aman & terisolasi
│   ├── config/
│   │   └── services.php                # Konfigurasi rawg (key, base_url, timeout)
│   ├── database/
│   │   ├── factories/UserFactory.php
│   │   └── migrations/                 # 10 Tabel PRD Bagian 11
│   ├── routes/
│   │   └── api.php                     # Route API Auth & Games
│   ├── tests/Feature/
│   │   ├── AuthTest.php                # 10 Tests Auth (Sanctum)
│   │   └── GameTest.php                # 8 Tests Games (Http::fake & RAWG)
│   ├── .env.example                    # Template konfigurasi MySQL & RAWG_API_KEY
│   └── .env                            # Konfigurasi aktif lokal
│
├── mobile/                              # Aplikasi Flutter (Android)
│   ├── lib/
│   │   ├── core/
│   │   │   ├── constants/
│   │   │   │   └── api_constants.dart  # Konfigurasi Base URL & Endpoint terpusat
│   │   │   ├── storage/
│   │   │   │   └── token_storage.dart  # flutter_secure_storage
│   │   │   └── theme/
│   │   │       └── app_theme.dart      # Tema gelap ungu-indigo (anti-slop)
│   │   ├── features/
│   │   │   ├── auth/                   # Fitur Autentikasi
│   │   │   │   ├── data/
│   │   │   │   └── presentation/
│   │   │   ├── games/                  # Fitur Jelajah & Detail Game (Tahap 2)
│   │   │   │   ├── data/
│   │   │   │   │   ├── datasources/game_remote_data_source.dart
│   │   │   │   │   └── models/
│   │   │   │   │       ├── game_model.dart
│   │   │   │   │       ├── games_response_model.dart
│   │   │   │   │       ├── genre_model.dart
│   │   │   │   │       └── platform_model.dart
│   │   │   │   └── presentation/
│   │   │   │       ├── screens/
│   │   │   │       │   ├── explore_screen.dart
│   │   │   │       │   └── game_detail_screen.dart
│   │   │   │       └── widgets/
│   │   │   │           ├── game_card.dart
│   │   │   │           └── rawg_attribution.dart
│   │   │   ├── home/
│   │   │   │   └── presentation/screens/
│   │   │   │       └── home_screen.dart # Floating Bottom Navigation (4 Tab)
│   │   │   ├── library/
│   │   │   │   └── presentation/screens/library_screen.dart
│   │   │   ├── wishlist/
│   │   │   │   └── presentation/screens/wishlist_screen.dart
│   │   │   └── profile/
│   │   │       └── presentation/screens/profile_screen.dart
│   │   └── main.dart
│   └── test/
│       └── widget_test.dart            # Unit & Widget Tests Flutter (13 tests)
│
└── rules/                               # Dokumen Acuan
    ├── PRD_MainGA.md
    └── rules_mainga.md
```

---

## 🔑 Konfigurasi RAWG_API_KEY

1. Dapatkan API Key gratis di [RAWG API](https://rawg.io/apidocs).
2. Buka berkas `backend/.env` dan isi variabel `RAWG_API_KEY`:
   ```env
   RAWG_API_KEY=masukkan_api_key_rawg_anda_di_sini
   ```
3. Backend akan membaca konfigurasi ini melalui `backend/config/services.php`:
   ```php
   'rawg' => [
       'key' => env('RAWG_API_KEY'),
       'base_url' => env('RAWG_BASE_URL', 'https://api.rawg.io/api'),
       'timeout' => (int) env('RAWG_TIMEOUT', 10),
   ],
   ```
4. Kunci ini **tidak pernah dikirim ke aplikasi mobile**, tidak dicatat di log, dan tidak ditulis langsung pada kode sumber.

---

## 🚀 Cara Menjalankan Backend (Laravel)

### 1. Prasyarat
- PHP 8.2+ (disarankan PHP 8.3 / 8.5 dengan ekstensi `pdo_mysql`, `curl`, `mbstring`, `zip`, `fileinfo`)
- MySQL Server (misal via XAMPP Control Panel)
- Composer 2.x

### 2. Langkah Setup
1. Masuk ke direktori backend:
   ```bash
   cd backend
   ```
2. Pastikan file `.env` sudah sesuai:
   ```env
   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=mainga
   DB_USERNAME=root
   DB_PASSWORD=

   RAWG_API_KEY=60322e33ee95489f892585fe4cd58187
   ```
3. Pastikan database MySQL aktif dan jalankan migrasi tabel:
   ```bash
   php artisan migrate
   ```
4. **Jalankan command sinkronisasi master genre dan platform**:
   ```bash
   php artisan rawg:sync-master
   ```
   *Perintah ini memanggil RAWG API untuk mengisi master data ke tabel `genres` dan `platforms`. Jika offline, perintah secara cerdas menyemai data standar populer.*
5. Jalankan Feature Tests backend:
   ```bash
   php artisan test
   ```
6. Jalankan development server backend:
   ```bash
   php artisan serve --host=0.0.0.0 --port=8000
   ```
   Server REST API siap melayani permintaan di `http://127.0.0.1:8000` (atau IP LAN).

---

## 📱 Cara Menjalankan Mobile (Flutter)

### 1. Prasyarat
- Flutter SDK 3.13+ (didukung hingga Flutter 3.47 / Dart 3.13+)
- Android Emulator atau HP Android fisik

### 2. Konfigurasi Base URL API
Buka berkas konfigurasi di:
`mobile/lib/core/constants/api_constants.dart`

- **Jika menggunakan Android Emulator**:
  ```dart
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  ```
- **Jika menggunakan HP Android Fisik via Wi-Fi**:
  Ganti dengan IP lokal laptop/PC Anda, misalnya:
  ```dart
  static const String baseUrl = 'http://192.168.1.15:8000/api';
  ```
- **Jika diuji di Windows Desktop / Chrome**:
  ```dart
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  ```

### 3. Menjalankan Aplikasi
1. Masuk ke folder mobile:
   ```bash
   cd mobile
   ```
2. Ambil paket dependensi:
   ```bash
   flutter pub get
   ```
3. Jalankan pengujian statis dan pengujian otomatis:
   ```bash
   flutter analyze
   flutter test
   ```
4. Jalankan aplikasi pada perangkat atau emulator:
   ```bash
   flutter run
   ```

---

## 🔌 Dokumentasi REST API Lengkap

Semua endpoint mengembalikan respons seragam JSON:
```json
{
  "success": true,
  "message": "Pesan deskriptif",
  "data": { ... }
}
```

### Endpoint Autentikasi (Publik & Terproteksi)
- `POST /api/register` : Mendaftar akun baru (`nama`, `email`, `password` min 8 karakter). Status 201.
- `POST /api/login` : Masuk akun dan menerbitkan Bearer token. Status 200.
- `POST /api/logout` : Mencabut token aktif di server (`auth:sanctum`). Status 200.
- `GET /api/me` : Ambil data profil pengguna yang sedang login (`auth:sanctum`). Status 200.

### Endpoint Katalog Game (Tahap 2 — `auth:sanctum`)
- `GET /api/genres` :
  Mengambil daftar seluruh genre game untuk opsi filter.
- `GET /api/platforms` :
  Mengambil daftar seluruh platform game untuk opsi filter.
- `GET /api/games` :
  Pencarian dan penjelajahan game.
  - Parameter query:
    - `search` *(opsional)* : Kata kunci judul game.
    - `genre` *(opsional)* : Filter genre (id, nama, atau slug).
    - `platform` *(opsional)* : Filter platform (id atau nama).
    - `rating` *(opsional)* : Rating minimum (misal: `4.0`).
    - `page` *(opsional, default: 1)* : Halaman pagination.
    - `per_page` *(opsional, default: 20)* : Jumlah item per halaman.
- `GET /api/games/{id}` :
  Detail lengkap suatu game berdasarkan ID lokal atau RAWG ID. Mengambil deskripsi lengkap dari endpoint detail RAWG hanya saat detail dibuka dan belum tersimpan di database.

---

## 🧪 Hasil Pengujian Otomatis

### 1. Backend (PHPUnit / Laravel Feature Tests)
Dijalankan dengan perintah: `php artisan test`
- ✅ `User can register with valid data` (Auth)
- ✅ `Register fails when email already registered` (Auth)
- ✅ `Register fails when password too short` (Auth)
- ✅ `User can login with correct credentials` (Auth)
- ✅ `User cannot login with wrong password` (Auth)
- ✅ `User cannot login with nonexistent email` (Auth)
- ✅ `User can logout with valid token` (Auth)
- ✅ `Unauthenticated access without token returns 401` (Auth)
- ✅ `Me returns user data with valid token` (Auth)
- ✅ `Password is hashed in database` (Auth)
- ✅ `Unauthenticated access without token returns 401 on games, genres, platforms` (Game)
- ✅ `Genres and platforms endpoints return master data` (Game)
- ✅ `Search games with Http::fake and stores to database & pivot` (Game)
- ✅ `Filter games by genre, platform, and minimum rating` (Game)
- ✅ `Search uses cache on second call within short time` (Game - Layer A & B)
- ✅ `Game detail fetches and caches description on demand` (Game)
- ✅ `RAWG failure falls back to database if available` (Game)
- ✅ `RAWG failure returns clear error JSON 503 when no local data` (Game)

**Hasil Backend**: **18 passed, 82 assertions, 0 failed**.

### 2. Mobile (Flutter Unit & Widget Tests)
Dijalankan dengan perintah: `flutter test`
- ✅ `UserModel.fromJson parses attributes correctly`
- ✅ `AuthResponseModel.fromJson parses success response correctly`
- ✅ `AuthResponseModel.fromJson parses error response correctly`
- ✅ `GenreModel.fromJson parses attributes correctly`
- ✅ `PlatformModel.fromJson parses attributes correctly`
- ✅ `GameModel.fromJson parses attributes correctly`
- ✅ `GamesResponseModel.fromJson parses pagination and games list`
- ✅ `MainGaApp builds successfully`
- ✅ `LoginScreen displays required form fields and buttons`
- ✅ `RawgAttribution renders attribution text`
- ✅ `HomeScreen displays floating navigation bar with 4 tabs`
- ✅ `LibraryScreen displays informative empty state`
- ✅ `WishlistScreen displays informative empty state`
- ✅ `flutter analyze` : **No issues found!**

**Hasil Mobile**: **13 passed, 0 failed**.

---

## 📝 Catatan Keputusan Desain & Implementasi Tahap 2

1. **Strategi Caching 2-Lapis**:
   - *Layer A (Short-term Query Cache)*: Dikelola oleh Laravel `Cache::put()` berdasarkan hash parameter pencarian (search, genre, platform, rating, page) selama 1 jam. Panggilan identik dalam waktu singkat dilayani seketika tanpa melakukan query eksternal maupun komputasi berat.
   - *Layer B (Persistent DB Cache & 7-Day Invalidation)*: Setiap game yang diambil dari RAWG otomatis disinkronkan ke tabel `games` beserta relasi pivot `game_genre` dan `game_platform` dengan mencatat `cached_at = now()`. Data dianggap kedaluwarsa setelah 7 hari (`Carbon::parse($game->cached_at)->addDays(7)->isPast()`).
2. **On-Demand Game Description**:
   - Untuk menghemat kuota RAWG (20.000 req/bulan), deskripsi lengkap game hanya diambil dari endpoint detail RAWG saat pengguna membuka halaman detail game dan game tersebut belum memiliki deskripsi di database.
3. **Penyelamatan Saat RAWG Gagal (Graceful Degradation)**:
   - Jika panggilan ke RAWG mengalami timeout atau galat jaringan, backend secara otomatis melakukan pencarian pada database lokal `games` dengan filter Eloquent. Jika data lokal ada, sistem mengembalikannya dengan normal; bila tidak ada, sistem mengembalikan kode HTTP 503 dengan pesan JSON yang informatif.
4. **Navigasi Tab Melayang (Floating Bar)**:
   - Menggunakan `extendBody: true` pada Scaffold dengan `Container` berpenampilan modern, border halus, bayangan lembut, dan penanda aktif ungu (`Color(0xFF8B5CF6)`), sesuai filosofi anti-slop pada `design_taste_frontend` dan `rules_mainga.md`.
5. **Atribusi RAWG Sesuai Kebijakan Layanan**:
   - Komponen `RawgAttribution` disematkan di bagian bawah tab Jelajah dan layar detail game, dilengkapi penanganan `url_launcher` untuk membuka situs resmi `https://rawg.io` di browser eksternal.
