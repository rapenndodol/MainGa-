/// Konfigurasi URL dan Endpoint API MainGa?
///
/// Catatan untuk Pengujian di Android:
/// - Android Emulator: gunakan 'http://10.0.2.2:8000/api'
/// - Perangkat Fisik (HP Android via Wi-Fi): ganti dengan IP lokal laptop/PC Anda,
///   misalnya 'http://192.168.1.10:8000/api'
/// - Windows Desktop / Web: 'http://127.0.0.1:8000/api'
class ApiConstants {
  ApiConstants._();

  // Alamat aktif untuk pengujian lokal di Windows / Chrome
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // Auth Endpoints
  static const String registerEndpoint = '$baseUrl/register';
  static const String loginEndpoint = '$baseUrl/login';
  static const String logoutEndpoint = '$baseUrl/logout';
  static const String meEndpoint = '$baseUrl/me';

  // Games & Filter Endpoints
  static const String gamesEndpoint = '$baseUrl/games';
  static const String genresEndpoint = '$baseUrl/genres';
  static const String platformsEndpoint = '$baseUrl/platforms';

  // Library Endpoints (Tahap 3)
  static const String libraryEndpoint = '$baseUrl/library';
}
