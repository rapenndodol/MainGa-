# MainGa? — Aplikasi Pengelola Koleksi dan Backlog Game

> Proyek UAS Pemrograman Aplikasi Bergerak — S1 Sistem Informasi, Universitas Negeri Surabaya  
> Penulis: Yosua Arthur P. S

---

## 📌 Deskripsi Tahap 1 (MVP)

Tahap 1 mencakup fondasi arsitektur sistem dari **Minggu 1** dan fitur autentikasi dari **Minggu 2** sesuai [PRD](file:///c:/Kuliah/Semester%205/PEMR.%20APLIKASI%20BERGERAK/MainGa/rules/PRD_MainGA.md) dan aturan [rules_mainga.md](file:///c:/Kuliah/Semester%205/PEMR.%20APLIKASI%20BERGERAK/MainGa/rules/rules_mainga.md):
- **Backend**: Laravel REST API dengan database MySQL, otentikasi token menggunakan Laravel Sanctum, 10 migration tabel lengkap beserta model Eloquent & relasi, dan Feature Tests.
- **Mobile**: Flutter untuk Android dengan struktur folder per fitur (*feature-first*), tema gelap elegan (*ungu-indigo*), penyimpanan token dengan `flutter_secure_storage`, konfigurasi base URL terpusat, layar Register, Login, serta Temporary Home Screen dengan tombol Logout.
- **Batasan**: Tanpa Supabase / Firebase; seluruh pemanggilan pihak ketiga (RAWG/CheapShark) diisolasi di backend; tidak ada kode placeholder / kosong.

---

## 🏗️ Struktur Proyek

```text
MainGa/
├── backend/                             # REST API Laravel
│   ├── app/
│   │   ├── Http/Controllers/Api/
│   │   │   └── AuthController.php      # Controller Register, Login, Logout, Me
│   │   └── Models/                     # 8 Eloquent Models & Relasi
│   │       ├── User.php
│   │       ├── Game.php
│   │       ├── Genre.php
│   │       ├── Platform.php
│   │       ├── LibraryEntry.php
│   │       ├── WishlistAlert.php
│   │       ├── PriceHistory.php
│   │       └── Notification.php
│   ├── database/
│   │   ├── factories/UserFactory.php
│   │   └── migrations/                 # 10 Tabel PRD Bagian 11
│   │       ├── 0001_01_01_000000_create_users_table.php
│   │       ├── 2026_10_29_113018_create_personal_access_tokens_table.php
│   │       ├── 2026_10_29_120000_create_games_table.php
│   │       ├── 2026_10_29_120001_create_genres_table.php
│   │       ├── 2026_10_29_120002_create_game_genre_table.php
│   │       ├── 2026_10_29_120003_create_platforms_table.php
│   │       ├── 2026_10_29_120004_create_game_platform_table.php
│   │       ├── 2026_10_29_120005_create_library_entries_table.php
│   │       ├── 2026_10_29_120006_create_wishlist_alerts_table.php
│   │       ├── 2026_10_29_120007_create_price_history_table.php
│   │       └── 2026_10_29_120008_create_notifications_table.php
│   ├── routes/
│   │   └── api.php                     # Route API Auth (register, login, logout, me)
│   ├── tests/Feature/
│   │   └── AuthTest.php                # 8 Feature Tests Auth
│   ├── .env.example                    # Template konfigurasi MySQL & RAWG_API_KEY
│   └── .env                            # Konfigurasi aktif lokal
│
├── mobile/                              # Aplikasi Flutter (Android)
│   ├── lib/
│   │   ├── core/
│   │   │   ├── constants/
│   │   │   │   └── api_constants.dart  # 1 File Konfigurasi Base URL terpusat
│   │   │   ├── storage/
│   │   │   │   └── token_storage.dart  # Penyimpanan flutter_secure_storage
│   │   │   └── theme/
│   │   │       └── app_theme.dart      # Tema gelap bernuansa ungu-indigo
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   │   ├── data/
│   │   │   │   │   ├── datasources/auth_remote_data_source.dart
│   │   │   │   │   └── models/
│   │   │   │   │       ├── auth_response_model.dart
│   │   │   │   │       └── user_model.dart
│   │   │   │   └── presentation/
│   │   │   │       ├── screens/
│   │   │   │       │   ├── login_screen.dart
│   │   │   │       │   ├── register_screen.dart
│   │   │   │       │   └── splash_screen.dart
│   │   │   │       └── widgets/
│   │   │   │           ├── custom_text_field.dart
│   │   │   │           └── primary_button.dart
│   │   │   └── home/
│   │   │       └── presentation/screens/
│   │   │           └── home_screen.dart # Halaman Utama Sementara + Tombol Logout
│   │   └── main.dart
│   └── test/
│       └── widget_test.dart            # Unit & Widget Tests Flutter
│
└── rules/                               # Dokumen Acuan (PRD & Rules)
    ├── PRD_MainGA.md
    └── rules_mainga.md
```

---

## 🗄️ Skema Database (Sesuai Bagian 11 PRD)

Semua tabel telah diimplementasikan dengan migrasi dan model Eloquent:

1. **`users`**: `id`, `nama`, `email` *(unik)*, `password` *(bcrypt hash)*, `timestamps`.
2. **`games`**: `id`, `rawg_id` *(unik)*, `judul`, `cover_url`, `rating`, `deskripsi`, `tanggal_rilis`, `cached_at`, `timestamps`.
3. **`genres`**: `id`, `nama`, `rawg_id`, `timestamps`.
4. **`game_genre`** *(pivot)*: `game_id`, `genre_id` *(primary composite key & cascade delete)*.
5. **`platforms`**: `id`, `nama`, `rawg_id`, `timestamps`.
6. **`game_platform`** *(pivot)*: `game_id`, `platform_id` *(primary composite key & cascade delete)*.
7. **`library_entries`**: `id`, `user_id`, `game_id`, `status` (*Wishlist, Backlog, Sedang Dimainkan, Tamat, Dropped*), `rating_pribadi` *(1-10)*, `jam_main`, `catatan`, `tanggal_tamat`, `timestamps`. **Constraint**: `UNIQUE(user_id, game_id)`.
8. **`wishlist_alerts`**: `id`, `user_id`, `game_id`, `harga_target` *(USD)*, `aktif` *(boolean)*, `timestamps`. **Constraint**: `UNIQUE(user_id, game_id)`.
9. **`price_history`**: `id`, `game_id`, `toko`, `harga`, `diskon_persen`, `dicek_pada`, `timestamps`. **Indeks**: indeks pada `game_id`, `dicek_pada`, dan indeks gabungan `(game_id, dicek_pada)`.
10. **`notifications`**: `id`, `user_id`, `game_id` *(nullable)*, `judul`, `pesan`, `harga`, `toko`, `dibaca_pada`, `timestamps`.

---

## 🔌 Dokumentasi REST API Tahap 1

Format respons terstruktur JSON seragam:
```json
{
  "success": true,
  "message": "Pesan deskriptif",
  "data": { ... }
}
```

### 1. Register Pengguna
- **Method / URL**: `POST /api/register`
- **Headers**: `Content-Type: application/json`, `Accept: application/json`
- **Body**:
  ```json
  {
    "nama": "Dimas Gamer",
    "email": "dimas@example.com",
    "password": "password123"
  }
  ```
- **Validasi**: `nama` wajib, `email` valid & unik di tabel `users`, `password` minimal 8 karakter.
- **Respons Sukses (201 Created)**: Mengembalikan user dan Sanctum `token`.
- **Respons Gagal (422 Unprocessable Content)**: Mengembalikan pesan error validasi terstruktur per field.

### 2. Login Pengguna
- **Method / URL**: `POST /api/login`
- **Headers**: `Content-Type: application/json`, `Accept: application/json`
- **Body**:
  ```json
  {
    "email": "dimas@example.com",
    "password": "password123"
  }
  ```
- **Respons Sukses (200 OK)**: Mengembalikan user dan Sanctum `token`.
- **Respons Gagal (401 Unauthorized)**: Jika email atau password salah.

### 3. Logout Pengguna
- **Method / URL**: `POST /api/logout`
- **Headers**: `Authorization: Bearer <TOKEN>`, `Accept: application/json`
- **Respons Sukses (200 OK)**: Mencabut dan menghapus token aktif di server.
- **Respons Tanpa Token (401 Unauthorized)**: Akses ditolak.

### 4. Ambil Profil Pengguna
- **Method / URL**: `GET /api/me`
- **Headers**: `Authorization: Bearer <TOKEN>`, `Accept: application/json`
- **Respons Sukses (200 OK)**: Mengembalikan data user yang sedang login.

---

## 🚀 Cara Menjalankan Backend (Laravel)

### 1. Prasyarat
- PHP 8.2+ (dengan extension `pdo_mysql`, `zip`, `mbstring`, `curl`)
- MySQL Server (misal via XAMPP Control Panel)
- Composer 2.x

### 2. Langkah Setup
1. Masuk ke folder backend:
   ```bash
   cd backend
   ```
2. Pastikan file `.env` sudah ada dan database MySQL aktif:
   ```env
   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=mainga
   DB_USERNAME=root
   DB_PASSWORD=
   ```
3. Buat database di MySQL jika belum ada:
   ```sql
   CREATE DATABASE mainga;
   ```
4. Jalankan migrasi database:
   ```bash
   php artisan migrate
   ```
5. Jalankan Feature Tests backend untuk memastikan semua fungsi lulus:
   ```bash
   php artisan test
   ```
6. Jalankan development server backend:
   ```bash
   php artisan serve --host=0.0.0.0 --port=8000
   ```
   Server akan berjalan di `http://127.0.0.1:8000` (atau IP lokal host).

---

## 📱 Cara Menjalankan Mobile (Flutter)

### 1. Prasyarat
- Flutter SDK 3.13+
- Android Studio / Android SDK (Emulator atau HP Fisik dengan USB Debugging aktif)

### 2. Konfigurasi Base URL API
Buka satu file konfigurasi di:
`mobile/lib/core/constants/api_constants.dart`

- **Jika menggunakan Android Emulator**:
  ```dart
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  ```
- **Jika menggunakan HP Android Fisik via Wi-Fi**:
  Ganti dengan alamat IP LAN laptop/komputer Anda, misalnya:
  ```dart
  static const String baseUrl = 'http://192.168.1.15:8000/api';
  ```
- **Jika diuji di Windows Desktop / Web**:
  ```dart
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  ```

### 3. Menjalankan Aplikasi
1. Masuk ke folder mobile:
   ```bash
   cd mobile
   ```
2. Jalankan test otomatis:
   ```bash
   flutter test
   ```
3. Hubungkan perangkat / nyalakan Android Emulator, lalu jalankan aplikasi:
   ```bash
   flutter run
   ```

---

## 🧪 Hasil Pengujian Otomatis

### 1. Backend (PHPUnit / Laravel Feature Tests)
Dijalankan dengan perintah: `php artisan test`
- ✅ `User can register with valid data` — Registrasi sukses (status 201, password ter-hash bcrypt, token terbit, data masuk ke database MySQL).
- ✅ `Register fails when email already registered` — Validasi email unik (status 422).
- ✅ `Register fails when password too short` — Validasi password min 8 karakter sesuai PRD (status 422).
- ✅ `User can login with correct credentials` — Login sukses menerbitkan token Sanctum (status 200).
- ✅ `User cannot login with wrong password` — Login ditolak saat password salah (status 401).
- ✅ `User cannot login with nonexistent email` — Login ditolak saat email tidak terdaftar (status 401).
- ✅ `User can logout with valid token` — Logout berhasil dan token dicabut dari server (status 200).
- ✅ `Unauthenticated access without token returns 401` — Akses endpoint terproteksi tanpa token ditolak (status 401).

**Hasil**: **10 passed, 31 assertions, 0 failed**.

### 2. Mobile (Flutter Unit & Widget Tests)
Dijalankan dengan perintah: `flutter test`
- ✅ `UserModel.fromJson parses attributes correctly`
- ✅ `AuthResponseModel.fromJson parses success response correctly`
- ✅ `AuthResponseModel.fromJson parses error response correctly`
- ✅ `MainGaApp builds successfully`
- ✅ `LoginScreen displays required form fields and buttons`
- ✅ `flutter analyze` : **No issues found!**

---

## 📝 Catatan Keputusan Desain

1. **Kolom Nama Pengguna**:
   Tabel `users` menggunakan kolom `nama` sesuai Bagian 11 PRD. Model Eloquent `User.php` dilengkapi mutator/accessor `name` agar kompatibel dengan fungsionalitas internal Laravel bila diperlukan.
2. **Penyimpanan Token Mobile**:
   Menggunakan `flutter_secure_storage` dengan opsi terenkripsi. Token otomatis dibaca saat splash screen dibuka untuk fitur auto-login.
3. **Penanganan Akses Tanpa Token**:
   Dikonfigurasi di `backend/bootstrap/app.php` dengan `shouldRenderJsonWhen` dan render khusus `AuthenticationException` serta `ValidationException`, memastikan semua rute API mengembalikan status 401/422 berformat JSON yang konsisten.
4. **Atribusi RAWG**:
   Sesuai `rules_mainga.md`, badge atribusi *"Data by RAWG & CheapShark"* telah disematkan pada layar Login dan Halaman Utama.
