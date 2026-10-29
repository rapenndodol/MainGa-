import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/game_model.dart';
import '../models/games_response_model.dart';
import '../models/genre_model.dart';
import '../models/platform_model.dart';

class GameRemoteDataSource {
  final http.Client client;

  GameRemoteDataSource({http.Client? client}) : client = client ?? http.Client();

  static const Duration _timeout = Duration(seconds: 15);

  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Ambil daftar game dengan pencarian, filter, dan pagination
  Future<GamesResponseModel> fetchGames({
    String? search,
    String? genre,
    String? platform,
    double? rating,
    int page = 1,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
    };

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (genre != null && genre.trim().isNotEmpty && genre != 'Semua') {
      queryParams['genre'] = genre.trim();
    }
    if (platform != null && platform.trim().isNotEmpty && platform != 'Semua') {
      queryParams['platform'] = platform.trim();
    }
    if (rating != null && rating > 0) {
      queryParams['rating'] = rating.toString();
    }

    final uri = Uri.parse(ApiConstants.gamesEndpoint).replace(queryParameters: queryParams);

    try {
      final headers = await _getHeaders();
      final response = await client.get(uri, headers: headers).timeout(_timeout);

      final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
      return GamesResponseModel.fromJson(body);
    } on SocketException {
      return const GamesResponseModel(
        success: false,
        message: 'Koneksi gagal. Pastikan backend aktif dan jaringan terhubung.',
        games: [],
        currentPage: 1,
        lastPage: 1,
        total: 0,
      );
    } on TimeoutException {
      return const GamesResponseModel(
        success: false,
        message: 'Permintaan timeout. Server tidak merespons dalam waktu 15 detik.',
        games: [],
        currentPage: 1,
        lastPage: 1,
        total: 0,
      );
    } catch (e) {
      return GamesResponseModel(
        success: false,
        message: 'Terjadi kesalahan sistem: $e',
        games: [],
        currentPage: 1,
        lastPage: 1,
        total: 0,
      );
    }
  }

  /// Ambil detail lengkap suatu game
  Future<GameModel?> getGameDetail(int id) async {
    final uri = Uri.parse('${ApiConstants.gamesEndpoint}/$id');

    try {
      final headers = await _getHeaders();
      final response = await client.get(uri, headers: headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['data'] is Map<String, dynamic>) {
          return GameModel.fromJson(body['data'] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Ambil seluruh master genre untuk filter
  Future<List<GenreModel>> getGenres() async {
    final uri = Uri.parse(ApiConstants.genresEndpoint);

    try {
      final headers = await _getHeaders();
      final response = await client.get(uri, headers: headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['data'] is List) {
          return (body['data'] as List)
              .map((item) => GenreModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Ambil seluruh master platform untuk filter
  Future<List<PlatformModel>> getPlatforms() async {
    final uri = Uri.parse(ApiConstants.platformsEndpoint);

    try {
      final headers = await _getHeaders();
      final response = await client.get(uri, headers: headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['data'] is List) {
          return (body['data'] as List)
              .map((item) => PlatformModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
