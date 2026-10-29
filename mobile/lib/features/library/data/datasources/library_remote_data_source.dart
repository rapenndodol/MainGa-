import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/library_entry_model.dart';
import '../models/library_response_model.dart';

class LibraryRemoteDataSource {
  final http.Client client;

  LibraryRemoteDataSource({http.Client? client}) : client = client ?? http.Client();

  static const Duration _timeout = Duration(seconds: 15);

  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Ambil daftar library dengan filter status dan pagination
  Future<LibraryResponseModel> fetchLibrary({
    String? status,
    int page = 1,
    int perPage = 15,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    if (status != null && status.trim().isNotEmpty && status != 'Semua') {
      queryParams['status'] = status.trim();
    }

    final uri = Uri.parse(ApiConstants.libraryEndpoint).replace(queryParameters: queryParams);

    try {
      final headers = await _getHeaders();
      final response = await client.get(uri, headers: headers).timeout(_timeout);

      final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
      return LibraryResponseModel.fromJson(body);
    } on SocketException {
      return const LibraryResponseModel(
        success: false,
        message: 'Koneksi gagal. Pastikan backend aktif dan jaringan terhubung.',
        entries: [],
        currentPage: 1,
        lastPage: 1,
        perPage: 15,
        total: 0,
      );
    } on TimeoutException {
      return const LibraryResponseModel(
        success: false,
        message: 'Permintaan timeout. Server tidak merespons.',
        entries: [],
        currentPage: 1,
        lastPage: 1,
        perPage: 15,
        total: 0,
      );
    } catch (e) {
      return LibraryResponseModel(
        success: false,
        message: 'Terjadi kesalahan: $e',
        entries: [],
        currentPage: 1,
        lastPage: 1,
        perPage: 15,
        total: 0,
      );
    }
  }

  /// Tambah game ke library
  Future<Map<String, dynamic>> addEntry({
    int? gameId,
    int? rawgId,
    required String status,
    int? ratingPribadi,
    double? jamMain,
    String? catatan,
  }) async {
    final uri = Uri.parse(ApiConstants.libraryEndpoint);
    final payload = <String, dynamic>{
      'status': status,
    };
    if (gameId != null && gameId > 0) {
      payload['game_id'] = gameId;
    }
    if (rawgId != null && rawgId > 0) {
      payload['rawg_id'] = rawgId;
    }
    if (ratingPribadi != null) {
      payload['rating_pribadi'] = ratingPribadi;
    }
    if (jamMain != null) {
      payload['jam_main'] = jamMain;
    }
    if (catatan != null) {
      payload['catatan'] = catatan;
    }

    try {
      final headers = await _getHeaders();
      final response = await client
          .post(uri, headers: headers, body: jsonEncode(payload))
          .timeout(_timeout);

      final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': body['message'] ?? 'Game berhasil ditambahkan ke library',
          'entry': body['data'] != null ? LibraryEntryModel.fromJson(body['data']) : null,
        };
      }

      return {
        'success': false,
        'message': body['message'] ?? 'Gagal menambahkan game ke library.',
        'errors': body['errors'],
      };
    } on SocketException {
      return {
        'success': false,
        'message': 'Koneksi gagal. Periksa jaringan Anda.',
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Permintaan timeout. Server tidak merespons.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan sistem: $e',
      };
    }
  }

  /// Ubah status, rating pribadi, jam bermain, atau catatan entry library
  Future<Map<String, dynamic>> updateEntry({
    required int id,
    required String status,
    int? ratingPribadi,
    double? jamMain,
    String? catatan,
  }) async {
    final uri = Uri.parse('${ApiConstants.libraryEndpoint}/$id');
    final payload = <String, dynamic>{
      'status': status,
      'rating_pribadi': ratingPribadi,
      'jam_main': jamMain ?? 0,
      'catatan': catatan,
    };

    try {
      final headers = await _getHeaders();
      final response = await client
          .put(uri, headers: headers, body: jsonEncode(payload))
          .timeout(_timeout);

      final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': body['message'] ?? 'Entry library berhasil diperbarui',
          'entry': body['data'] != null ? LibraryEntryModel.fromJson(body['data']) : null,
        };
      }

      return {
        'success': false,
        'message': body['message'] ?? 'Gagal memperbarui entry library.',
        'errors': body['errors'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  /// Hapus entry library
  Future<Map<String, dynamic>> deleteEntry(int id) async {
    final uri = Uri.parse('${ApiConstants.libraryEndpoint}/$id');

    try {
      final headers = await _getHeaders();
      final response = await client.delete(uri, headers: headers).timeout(_timeout);

      final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': body['message'] ?? 'Game berhasil dihapus dari library',
        };
      }

      return {
        'success': false,
        'message': body['message'] ?? 'Gagal menghapus game dari library.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
}
