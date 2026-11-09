import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/user_stats_model.dart';

class StatsResult {
  final bool success;
  final String message;
  final UserStatsModel stats;

  const StatsResult({
    required this.success,
    required this.message,
    required this.stats,
  });
}

class StatsRemoteDataSource {
  final http.Client client;

  StatsRemoteDataSource({http.Client? client}) : client = client ?? http.Client();

  static const Duration _timeout = Duration(seconds: 15);

  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Ambil statistik bermain milik pengguna
  Future<StatsResult> fetchStats() async {
    final uri = Uri.parse(ApiConstants.statsEndpoint);

    try {
      final headers = await _getHeaders();
      final response = await client.get(uri, headers: headers).timeout(_timeout);

      final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true && body['data'] != null) {
        return StatsResult(
          success: true,
          message: body['message'] ?? 'Statistik berhasil diambil',
          stats: UserStatsModel.fromJson(body['data'] as Map<String, dynamic>),
        );
      }

      return StatsResult(
        success: false,
        message: body['message'] ?? 'Gagal mengambil statistik.',
        stats: UserStatsModel.empty,
      );
    } on SocketException {
      return const StatsResult(
        success: false,
        message: 'Koneksi gagal. Pastikan backend aktif dan jaringan terhubung.',
        stats: UserStatsModel.empty,
      );
    } on TimeoutException {
      return const StatsResult(
        success: false,
        message: 'Permintaan timeout. Server tidak merespons.',
        stats: UserStatsModel.empty,
      );
    } catch (e) {
      return StatsResult(
        success: false,
        message: 'Terjadi kesalahan: $e',
        stats: UserStatsModel.empty,
      );
    }
  }
}
