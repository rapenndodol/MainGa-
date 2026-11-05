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

  // Library Endpoints (Tahap 3 & US-08)
  static const String libraryEndpoint = '$baseUrl/library';
  static const String libraryRandomEndpoint = '$baseUrl/library/random';

  // Wishlist & Price Endpoints
  static const String wishlistEndpoint = '$baseUrl/wishlist';
  static String gamePricesEndpoint(dynamic id) => '$baseUrl/games/$id/prices';

  // Notification Endpoints (Tahap 5 & US-06)
  static const String notificationsEndpoint = '$baseUrl/notifications';
  static const String notificationsUnreadCountEndpoint = '$baseUrl/notifications/unread-count';
  static String notificationReadEndpoint(dynamic id) => '$baseUrl/notifications/$id/read';
  static const String notificationsReadAllEndpoint = '$baseUrl/notifications/read-all';

  // Statistics Endpoint (Tahap 5 & US-07)
  static const String statsEndpoint = '$baseUrl/stats';
}
