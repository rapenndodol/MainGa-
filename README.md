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

   RAWG_API_KEY=xxxxxxxxxxxxxxxxxxxx
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


---

## 📌 Deskripsi Tahap 3 (Library Pribadi — US-03 & F-04)

Tahap 3 mengimplementasikan fitur pengelolaan koleksi dan backlog bermain game milik pengguna secara terpersonalisasi sesuai [PRD](rules/PRD_MainGA.md) dan aturan [rules_mainga.md](rules/rules_mainga.md):

- **Backend (Laravel REST API)**:
  - Menggunakan tabel `library_entries` yang terelasi dengan `users` dan `games`.
  - **Form Request & API Resource**:
    - `StoreLibraryEntryRequest`: Validasi input penambahan game ke library (game_id/rawg_id, status bermain, rating_pribadi 1-10, jam_main non-negatif, catatan).
    - `UpdateLibraryEntryRequest`: Validasi pembaruan data entry library.
    - `LibraryEntryResource`: Transformasi respons seragam memuat data game (judul, cover_url, rating, genre, platform) dan data entry (status, rating_pribadi, jam_main, catatan, tanggal_tamat).
  - **Endpoint REST API Terproteksi Sanctum (`auth:sanctum`)**:
    - `GET /api/library`: Daftar library milik pengguna yang sedang login, dilengkapi filter status horizontal (`Semua`, `Wishlist`, `Backlog`, `Sedang Dimainkan`, `Tamat`, `Dropped`) dan pagination.
    - `POST /api/library`: Menambahkan game ke library. Menerima `game_id` atau `rawg_id`. Jika hanya `rawg_id` yang dikirim dan game belum ada di database lokal, backend mengambil detail dari `RawgService` dan menyimpannya.
    - `GET /api/library/{id}`: Detail satu entry library milik pengguna.
    - `PUT /api/library/{id}`: Mengubah status, rating pribadi (1-10), jam main (>= 0), dan catatan.
    - `DELETE /api/library/{id}`: Menghapus game dari library pribadi.
    - `GET /api/games/{id}`: Diperluas dengan field `library_status` (string status atau `null` jika belum ada di library) dan `library_entry` agar layar detail game langsung mengetahui status kepemilikan pengguna.
  - **Aturan Bisnis & Integritas Data**:
    - Status valid: `Wishlist`, `Backlog`, `Sedang Dimainkan`, `Tamat`, `Dropped`.
    - Rating pribadi: integer 1 hingga 10 (opsional).
    - Jam main: angka non-negatif (>= 0).
    - Satu game hanya dapat muncul sekali per pengguna. Duplikasi ditolak dengan HTTP 422 dan pesan JSON informatif.
    - Isolasi kepemilikan: pengguna hanya dapat melihat, mengubah, dan menghapus entry miliknya sendiri (mengembalikan HTTP 403 untuk akses entry orang lain).
    - Otomatisasi `tanggal_tamat`: saat status berubah menjadi `Tamat`, `tanggal_tamat` otomatis diisi dengan tanggal hari ini; saat status diubah dari `Tamat` ke status lain, `tanggal_tamat` otomatis dikosongkan (`null`).
  - **11 Feature Tests Backend Komprehensif** (`LibraryTest.php`):
    - Tambah entry dengan `game_id`.
    - Tambah entry dengan `rawg_id` (menggunakan `Http::fake` untuk menyimulasikan RAWG API).
    - Penolakan game duplikat dengan status 422.
    - Validasi aturan input (rating out of range, jam main negatif, status tidak valid).
    - Otomatisasi pengisian dan pengosongan `tanggal_tamat`.
    - Pembaruan status, rating, jam main, dan catatan.
    - Penghapusan game dari library.
    - Filter status dan pagination pada daftar library.
    - Proteksi akses entry milik pengguna lain (403).
    - Proteksi endpoint tanpa token Sanctum (401).
    - Penyertaan status library pengguna pada endpoint detail game.

- **Mobile (Flutter Android)**:
  - **Tab Library**:
    - Daftar kartu game koleksi (`LibraryGameCard`): cover thumbnail, judul game, badge status bermain dengan warna tematik, rating pribadi (`⭐ X/10`), jam bermain (`⏱️ X jam`), tanggal tamat jika selesai, dan preview kutipan catatan.
    - Filter horizontal status chip (`Semua`, `Wishlist`, `Backlog`, `Sedang Dimainkan`, `Tamat`, `Dropped`) dengan indikator aktif berwarna aksen.
    - *Pull-to-refresh* (`RefreshIndicator`) untuk memperbarui data seketika.
    - *Infinite scroll pagination* otomatis saat mendekati bagian bawah layar.
    - Penanganan status yang rapi: *loading indicator*, *empty state* informatif ("Belum ada game"), dan *error state* dengan tombol coba lagi.
  - **Layar Detail Game**:
    - Tombol aksi status library adaptif:
      - Jika game belum ada di library: Tombol *"Tambah ke Library"* membuka form pemilihan status dan detail bermain.
      - Jika game sudah tersimpan: Menampilkan badge status bermain aktif beserta keterangan *"Tersimpan di Library"* dan ikon edit untuk membuka form pembaruan.
  - **Form Edit / Tambah Entry (`LibraryEntrySheet`)**:
    - Modal bottom sheet modern berlatar gelap sesuai filosofi anti-slop `design-taste-frontend`.
    - Pilihan status bermain interaktif berbentuk chip badge.
    - Slider dan visual rating pribadi (1-10) dengan opsi hapus rating.
    - Input jam bermain dengan validasi angka desimal non-negatif di sisi klien.
    - Input catatan pribadi multi-line.
    - Tombol simpan primer dengan status loading.
    - Tombol hapus destruktif (khusus mode edit) dilengkapi dialog konfirmasi pencegahan salah hapus.
  - **Reaktivitas Antar Layar Real-time (`LibraryNotifier`)**:
    - Menggunakan pola Singleton `ChangeNotifier` (`LibraryNotifier.instance`).
    - Setiap penambahan, pembaruan, atau penghapusan entry langsung menyinkronkan Tab Library dan Layar Detail Game secara instan tanpa perlu memuat ulang aplikasi atau login ulang.
  - Semua pemanggilan API murni ke backend sendiri melalui `ApiConstants.libraryEndpoint`.

---

## 🎨 Desain UI — Redesain Total Identitas Visual (Warm Obsidian & Coral Terracotta)

Sebelum melanjutkan ke Tahap 4 (Wishlist & Price Tracker), aplikasi **MainGa?** telah melalui redesain antarmuka total. Identitas visual lama yang bernuansa gradient ungu-indigo generik telah digantikan secara penuh dengan sistem visual baru yang diturunkan dari referensi desain studio game modern (`docs/ui-reference/reference.jpg`), dirancang dengan standar anti-slop dari skill `design-taste-frontend`.

### 1. Ringkasan Design System

- **Filosofi Visual**: *Warm Obsidian & Crimson Terracotta Gaming Suite*. Menggunakan kanvas gelap dengan saturasi hangat (deep black-cherry obsidian `#140C0F`), bertingkat secara elegan (*tone steps*) tanpa efek glassmorphism murahan atau gradient neon yang berlebihan.
- **Single Source of Truth (`lib/core/theme/`)**:
  - `app_colors.dart`: Seluruh token warna (`bg`, `surface`, `surfaceElevated`, `primary`, `secondary`, `textPrimary`, `textSecondary`, `status*`). Tidak ada warna yang di-hardcode di layar atau widget.
  - `app_radius.dart`: Skala radius komponen terukur (`sm: 8.0`, `md: 14.0`, `lg: 20.0`, `xl: 24.0`, `full: 999.0`).
  - `app_spacing.dart`: Skala jarak konsisten (`xs: 4`, `sm: 8`, `md: 12`, `lg: 16`, `xl: 20`, `xxl: 28`).
  - `app_typography.dart`: Tipografi modern geometris berbasis **Plus Jakarta Sans** (Google Fonts) dengan kontras bobot tegas antara display, title, body, dan micro-label.
  - `app_theme.dart`: Konfigurasi global `ThemeData` terpadu untuk tombol, input form, card, bottom sheet, dialog, dan app bar.
- **Komponen Bersama (`lib/core/widgets/`)**:
  - `AppButton`: Tombol pill (`radius: 999dp`, tinggi minimal 50dp) dengan varian primer, sekunder, outline, dan destruktif, terintegrasi indikator loading.
  - `AppTextField`: Input rounded dengan batas fokus `#E14B44` dan latar `#1A1014`.
  - `AppGameCard`: Kartu game konsisten dengan cover rounded (`14dp`), rating bintang warm amber, genre, tahun rilis, dan penanda detail.
  - `AppStatusChip`: Chip status bermain dengan warna tematik dan ikon representatif tanpa emoji.
  - `AppSkeletonBox`, `AppGameCardSkeleton`, `AppListSkeleton`: Animasi pulse shimmer untuk indikator pemuatan data (bukan sekadar spinner polos).
  - `AppEmptyState`: Tampilan kosong dengan ikon tematik, judul tebal, deskripsi komunikatif, dan tombol aksi pemulihan.
  - `AppErrorState`: Tampilan galat komunikatif dengan tombol coba lagi.
  - `AppBadge`: Komponen badge serbaguna untuk rating dan kategori.
  - `AppHeader`: App bar standar dengan back button yang rapi dan konsisten.
  - `AppRawgAttribution`: Atribusi resmi RAWG.io dengan tautan aktif yang menyatu dengan estetika warm dark.

### 2. Daftar Keputusan Desain

1. **Eliminasi Gradient Ungu & Indigo**: Seluruh gradien ungu lama pada tombol, latar belakang, dan card telah dihapus total. Warna primer digantikan oleh **Coral Crimson** (`#E14B44`) yang dinamis dan berfokus pada aksi utama.
2. **Elevasi Berdasarkan Tone Steps**: Memisahkan bidang secara visual murni melalui tingkatan tone warna (`#140C0F` -> `#1E1216` -> `#29171E`), bukan menggunakan border tipis yang ramai atau bayangan neon.
3. **Bentuk Pill Ergonomis**: Selaras dengan referensi, tombol utama, input pencarian, chip filter, dan indikator navigasi mengadopsi bentuk pill penuh yang ramah sentuhan (memenuhi standar aksesibilitas area sentuh minimal 48dp).
4. **Floating Dock Navigation Bar**: Bar navigasi 4 tab melayang di atas konten dengan sudut membulat penuh (`32dp`), di mana tab aktif diberi penanda pill merah koral `#E14B44` dengan ikon dan label putih yang menonjol.
5. **State Interaktif yang Proper**: Seluruh daftar (Jelajah dan Library) kini menampilkan skeleton shimmer saat memuat data, bukan spinner mentah. Layar kosong menyajikan instruksi ramah dengan tombol reset filter atau panduan eksplorasi.
6. **Hierarki Konten Detail Game**: Cover game dijadikan elemen visual dominan dengan overlay gradient scrim netral agar judul dan rating tetap terbaca dengan kontras sempurna di semua resolusi layar.

---

## 🚀 Cara Menjalankan & Menguji Aplikasi

### 1. Backend (Laravel)
```bash
cd backend
php artisan test
php artisan serve --host=0.0.0.0 --port=8000
```

### 2. Mobile (Flutter)
```bash
cd mobile
flutter pub get
flutter analyze
flutter test
flutter run
```
*Hasil pengujian saat ini: `flutter analyze` 0 issues (bersih), dan `flutter test` 21 tests passed (100% lulus).*

---

## 📝 Catatan Keputusan Desain & Implementasi Tahap 3

### 1. Backend (Laravel)
1. Masuk ke folder backend:
   ```bash
   cd backend
   ```
2. Jalankan seluruh Feature Tests backend (29 tests):
   ```bash
   php artisan test
   ```
   *Seluruh 29 tests (Auth, Game, dan Library) akan lulus dengan status passed.*
3. Jalankan server backend:
   ```bash
   php artisan serve --host=0.0.0.0 --port=8000
   ```

### 2. Mobile (Flutter)
1. Masuk ke folder mobile:
   ```bash
   cd mobile
   ```
2. Jalankan analisis statis dan pengujian otomatis:
   ```bash
   flutter analyze
   flutter test
   ```
   *Analisis menghasilkan No issues found dan 17 tests passed.*
3. Jalankan aplikasi pada perangkat Android / emulator / desktop:
   ```bash
   flutter run
   ```

---

## 📝 Catatan Keputusan Desain & Implementasi Tahap 3

1. **Integritas Relasi dan Pencegahan Duplikasi**:
   - Backend memverifikasi keberadaan game pada database lokal maupun RAWG sebelum memasukkan ke library. Duplikasi diperiksa di level controller dan dijamin oleh indeks unik database `unique(['user_id', 'game_id'])`.
2. **Otomatisasi `tanggal_tamat`**:
   - Status `Tamat` secara cerdas mencatat `now()->toDateString()`. Jika pengguna mengembalikan status ke `Sedang Dimainkan` atau `Backlog`, `tanggal_tamat` otomatis di-reset menjadi `null` agar kalkulasi statistik (tahap berikutnya) tidak mengalami bias data.
3. **Sinkronisasi Reaktif Tanpa Refresh Manual (`LibraryNotifier`)**:
   - Modifikasi library pada layar detail atau bottom sheet memicu `LibraryNotifier.instance.notifyUpdated()` / `notifyAdded()` / `notifyDeleted()`. Tab Library yang berada di dalam `IndexedStack` mendengarkan notifikasi ini dan secara otomatis memuat ulang koleksi tanpa memerlukan intervensi pengguna.
4. **Penerapan Gaya Visual Anti-Slop (Skill `design-taste-frontend`)**:
   - Status badge diberi kode warna fungsional yang tenang: Cyan untuk Wishlist, Indigo untuk Backlog, Amber untuk Sedang Dimainkan, Emerald Green untuk Tamat, dan Rose untuk Dropped.
   - Kartu dirancang rata (*flat surfaces*), dibatasi garis 1px (`#2E2A48`), dengan hierarki tipografi kontras dan indikator data jujur (nilai kosong ditampilkan `-` atau indikasi ramah).
