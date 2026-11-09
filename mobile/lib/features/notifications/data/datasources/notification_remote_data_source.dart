import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/notification_model.dart';
import '../models/notifications_response_model.dart';

class NotificationRemoteDataSource {
  final http.Client client;

  NotificationRemoteDataSource({http.Client? client}) : client = client ?? http.Client();

  static const Duration _timeout = Duration(seconds: 15);

  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Ambil daftar notifikasi dengan pagination
  Future<NotificationsResponseModel> fetchNotifications({
    int page = 1,
    int perPage = 15,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    final uri = Uri.parse(ApiConstants.notificationsEndpoint).replace(queryParameters: queryParams);

    try {
      final headers = await _getHeaders();
      final response = await client.get(uri, headers: headers).timeout(_timeout);

      final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
      return NotificationsResponseModel.fromJson(body);
    } on SocketException {
      return const NotificationsResponseModel(
        success: false,
        message: 'Koneksi gagal. Pastikan backend aktif dan jaringan terhubung.',
        notifications: [],
        currentPage: 1,
        lastPage: 1,
        perPage: 15,
        total: 0,
      );
    } on TimeoutException {
      return const NotificationsResponseModel(
        success: false,
        message: 'Permintaan timeout. Server tidak merespons.',
        notifications: [],
        currentPage: 1,
        lastPage: 1,
        perPage: 15,
        total: 0,
      );
    } catch (e) {
      return NotificationsResponseModel(
        success: false,
        message: 'Terjadi kesalahan: $e',
        notifications: [],
        currentPage: 1,
        lastPage: 1,
        perPage: 15,
        total: 0,
      );
    }
  }

  /// Ambil jumlah notifikasi yang belum dibaca
  Future<int> fetchUnreadCount() async {
    final uri = Uri.parse(ApiConstants.notificationsUnreadCountEndpoint);

    try {
      final headers = await _getHeaders();
      final response = await client.get(uri, headers: headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['data'] is Map<String, dynamic>) {
          final count = body['data']['unread_count'];
          if (count is int) return count;
          return int.tryParse(count?.toString() ?? '0') ?? 0;
        }
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  /// Tandai satu notifikasi sebagai sudah dibaca
  Future<Map<String, dynamic>> markAsRead(int id) async {
    final uri = Uri.parse(ApiConstants.notificationReadEndpoint(id));

    try {
      final headers = await _getHeaders();
      final response = await client.put(uri, headers: headers).timeout(_timeout);

      final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': body['message'] ?? 'Notifikasi berhasil ditandai sebagai dibaca',
          'notification': body['data'] != null ? NotificationModel.fromJson(body['data']) : null,
        };
      }

      return {
        'success': false,
        'message': body['message'] ?? 'Gagal menandai notifikasi.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  /// Tandai semua notifikasi sebagai sudah dibaca
  Future<Map<String, dynamic>> markAllAsRead() async {
    final uri = Uri.parse(ApiConstants.notificationsReadAllEndpoint);

    try {
      final headers = await _getHeaders();
      final response = await client.put(uri, headers: headers).timeout(_timeout);

      final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': body['message'] ?? 'Semua notifikasi berhasil ditandai sebagai dibaca',
          'updated_count': body['data']?['updated_count'] ?? 0,
        };
      }

      return {
        'success': false,
        'message': body['message'] ?? 'Gagal menandai seluruh notifikasi.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
}
