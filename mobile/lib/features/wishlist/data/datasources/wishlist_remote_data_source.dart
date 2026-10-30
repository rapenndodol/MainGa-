import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/game_price_model.dart';
import '../models/wishlist_item_model.dart';
import '../models/wishlist_response_model.dart';

class WishlistRemoteDataSource {
  final http.Client client;

  WishlistRemoteDataSource({http.Client? client}) : client = client ?? http.Client();

  static const Duration _timeout = Duration(seconds: 15);

  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Ambil daftar wishlist milik pengguna dengan filter aktif dan pagination
  Future<WishlistResponseModel> fetchWishlist({
    bool? aktif,
    int page = 1,
    int perPage = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    if (aktif != null) {
      queryParams['aktif'] = aktif ? '1' : '0';
    }

    final uri = Uri.parse(ApiConstants.wishlistEndpoint).replace(queryParameters: queryParams);

    try {
      final headers = await _getHeaders();
      final response = await client.get(uri, headers: headers).timeout(_timeout);

      final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
      return WishlistResponseModel.fromJson(body);
    } on SocketException {
      return const WishlistResponseModel(
        success: false,
        message: 'Koneksi gagal. Pastikan backend aktif dan jaringan terhubung.',
        wishlists: [],
        currentPage: 1,
        lastPage: 1,
        perPage: 20,
        total: 0,
      );
    } on TimeoutException {
      return const WishlistResponseModel(
        success: false,
        message: 'Permintaan timeout. Server tidak merespons.',
        wishlists: [],
        currentPage: 1,
        lastPage: 1,
        perPage: 20,
        total: 0,
      );
    } catch (e) {
      return WishlistResponseModel(
        success: false,
        message: 'Terjadi kesalahan: $e',
        wishlists: [],
        currentPage: 1,
        lastPage: 1,
        perPage: 20,
        total: 0,
      );
    }
  }

  /// Tambah game ke wishlist dengan harga target dalam USD
  Future<Map<String, dynamic>> addWishlist({
    int? gameId,
    int? rawgId,
    required double hargaTarget,
    bool aktif = true,
  }) async {
    final uri = Uri.parse(ApiConstants.wishlistEndpoint);
    final payload = <String, dynamic>{
      'harga_target': hargaTarget,
      'aktif': aktif,
    };
    if (gameId != null && gameId > 0) {
      payload['game_id'] = gameId;
    }
    if (rawgId != null && rawgId > 0) {
      payload['rawg_id'] = rawgId;
    }

    try {
      final headers = await _getHeaders();
      final response = await client
          .post(uri, headers: headers, body: jsonEncode(payload))
          .timeout(_timeout);

      final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201 || response.statusCode == 200) {
        WishlistItemModel? item;
        if (body['data'] is Map<String, dynamic>) {
          item = WishlistItemModel.fromJson(body['data'] as Map<String, dynamic>);
        }
        return {
          'success': true,
          'message': body['message'] ?? 'Game berhasil ditambahkan ke wishlist',
          'data': item,
        };
      }

      String errorMsg = body['message'] ?? 'Gagal menambahkan ke wishlist';
      if (body['errors'] is Map) {
        final errors = body['errors'] as Map;
        final firstKey = errors.keys.firstOrNull;
        if (firstKey != null && errors[firstKey] is List && (errors[firstKey] as List).isNotEmpty) {
          errorMsg = errors[firstKey][0].toString();
        }
      }

      return {
        'success': false,
        'message': errorMsg,
      };
    } on SocketException {
      return {
        'success': false,
        'message': 'Koneksi gagal. Periksa koneksi backend Anda.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan sistem: $e',
      };
    }
  }

  /// Ubah target harga atau status pantauan aktif wishlist
  Future<Map<String, dynamic>> updateWishlist({
    required int id,
    double? hargaTarget,
    bool? aktif,
  }) async {
    final uri = Uri.parse('${ApiConstants.wishlistEndpoint}/$id');
    final payload = <String, dynamic>{};
    if (hargaTarget != null) {
      payload['harga_target'] = hargaTarget;
    }
    if (aktif != null) {
      payload['aktif'] = aktif;
    }

    try {
      final headers = await _getHeaders();
      final response = await client
          .put(uri, headers: headers, body: jsonEncode(payload))
          .timeout(_timeout);

      final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        WishlistItemModel? item;
        if (body['data'] is Map<String, dynamic>) {
          item = WishlistItemModel.fromJson(body['data'] as Map<String, dynamic>);
        }
        return {
          'success': true,
          'message': body['message'] ?? 'Wishlist berhasil diperbarui',
          'data': item,
        };
      }

      return {
        'success': false,
        'message': body['message'] ?? 'Gagal memperbarui wishlist',
      };
    } on SocketException {
      return {
        'success': false,
        'message': 'Koneksi gagal. Periksa koneksi backend Anda.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan sistem: $e',
      };
    }
  }

  /// Hapus game dari wishlist pengguna
  Future<Map<String, dynamic>> deleteWishlist({required int id}) async {
    final uri = Uri.parse('${ApiConstants.wishlistEndpoint}/$id');

    try {
      final headers = await _getHeaders();
      final response = await client.delete(uri, headers: headers).timeout(_timeout);

      final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': body['message'] ?? 'Game berhasil dihapus dari wishlist',
        };
      }

      return {
        'success': false,
        'message': body['message'] ?? 'Gagal menghapus dari wishlist',
      };
    } on SocketException {
      return {
        'success': false,
        'message': 'Koneksi gagal. Periksa koneksi backend Anda.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan sistem: $e',
      };
    }
  }

  /// Ambil riwayat harga dan harga terkini untuk game tertentu
  Future<GamePricesResponseModel> fetchGamePrices(int gameIdOrRawgId) async {
    final uri = Uri.parse(ApiConstants.gamePricesEndpoint(gameIdOrRawgId));

    try {
      final headers = await _getHeaders();
      final response = await client.get(uri, headers: headers).timeout(_timeout);

      final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
      return GamePricesResponseModel.fromJson(body);
    } on SocketException {
      return const GamePricesResponseModel(
        success: false,
        message: 'Koneksi gagal saat memuat harga.',
        hargaTersedia: false,
        statusKeterangan: 'Koneksi gagal',
        hargaTerkini: [],
        riwayatHarga: [],
      );
    } on TimeoutException {
      return const GamePricesResponseModel(
        success: false,
        message: 'Permintaan data harga timeout.',
        hargaTersedia: false,
        statusKeterangan: 'Timeout',
        hargaTerkini: [],
        riwayatHarga: [],
      );
    } catch (e) {
      return GamePricesResponseModel(
        success: false,
        message: 'Gagal memuat harga: $e',
        hargaTersedia: false,
        statusKeterangan: 'Harga belum tersedia',
        hargaTerkini: [],
        riwayatHarga: [],
      );
    }
  }
}
