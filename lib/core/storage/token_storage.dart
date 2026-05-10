// lib/core/storage/token_storage.dart
// flutter_secure_storage istifoda мекунад — токен дар Keychain/Keystore захира мешавад
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _accessKey  = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _userIdKey  = 'user_id';

  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(key: _accessKey, value: accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(key: _refreshKey, value: refreshToken);
    }
  }

  static Future<String?> getAccessToken() async {
    return _storage.read(key: _accessKey);
  }

  static Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshKey);
  }

  static Future<void> saveUserId(String id) async {
    await _storage.write(key: _userIdKey, value: id);
  }

  static Future<String?> getUserId() async {
    return _storage.read(key: _userIdKey);
  }

  static Future<void> clearTokens() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _userIdKey);
  }
}
