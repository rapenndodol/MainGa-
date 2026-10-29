import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final http.Client client;

  AuthRemoteDataSource({http.Client? client}) : client = client ?? http.Client();

  static const Duration _timeout = Duration(seconds: 15);

  /// Registrasi akun baru
  Future<AuthResponseModel> register({
    required String nama,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse(ApiConstants.registerEndpoint);

    try {
      final response = await client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'nama': nama,
              'email': email,
              'password': password,
            }),
          )
          .timeout(_timeout);

      final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthResponseModel.fromJson(body);
    } on SocketException {
      return const AuthResponseModel(
        success: false,
        message: 'Tidak dapat terhubung ke server. Pastikan backend aktif dan URL benar.',
      );
    } on TimeoutException {
      return const AuthResponseModel(
        success: false,
        message: 'Koneksi timeout. Server tidak merespons dalam waktu 15 detik.',
      );
    } catch (e) {
      return AuthResponseModel(
        success: false,
        message: 'Terjadi kesalahan sistem: $e',
      );
    }
  }

  /// Login dengan email & password
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse(ApiConstants.loginEndpoint);

    try {
      final response = await client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(_timeout);

      final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthResponseModel.fromJson(body);
    } on SocketException {
      return const AuthResponseModel(
        success: false,
        message: 'Tidak dapat terhubung ke server. Pastikan backend aktif dan URL benar.',
      );
    } on TimeoutException {
      return const AuthResponseModel(
        success: false,
        message: 'Koneksi timeout. Server tidak merespons dalam waktu 15 detik.',
      );
    } catch (e) {
      return AuthResponseModel(
        success: false,
        message: 'Terjadi kesalahan sistem: $e',
      );
    }
  }

  /// Logout dan pencabutan token
  Future<bool> logout(String token) async {
    final uri = Uri.parse(ApiConstants.logoutEndpoint);

    try {
      final response = await client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout);

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Ambil profil saat ini
  Future<UserModel?> getProfile(String token) async {
    final uri = Uri.parse(ApiConstants.meEndpoint);

    try {
      final response = await client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['data'] != null && body['data']['user'] != null) {
          return UserModel.fromJson(body['data']['user'] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
