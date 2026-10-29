import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();

  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user';

  /// Simpan auth token ke secure storage
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  /// Ambil auth token dari secure storage
  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  /// Hapus auth token
  static Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }

  /// Simpan profil pengguna ke secure storage (JSON)
  static Future<void> saveUser(Map<String, dynamic> user) async {
    await _storage.write(key: _keyUser, value: jsonEncode(user));
  }

  /// Ambil profil pengguna tersimpan
  static Future<Map<String, dynamic>?> getUser() async {
    final str = await _storage.read(key: _keyUser);
    if (str == null || str.isEmpty) return null;
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Hapus seluruh data autentikasi (token dan user)
  static Future<void> clearAll() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUser);
  }
}
