import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TokenStorage — токенро амин захира мекунад
/// Primary: flutter_secure_storage (Keychain/Keystore)
/// Fallback: SharedPreferences (агар secure storage кор накунад)
class TokenStorage {
  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _accessKey  = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _userIdKey  = 'user_id';

  // ── Write ─────────────────────────────────────────────────────────────────
  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    try {
      await _secure.write(key: _accessKey, value: accessToken);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _secure.write(key: _refreshKey, value: refreshToken);
      }
    } catch (e) {
      debugPrint('[TokenStorage] secure write failed, using prefs: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessKey, accessToken);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await prefs.setString(_refreshKey, refreshToken);
      }
    }
  }

  // ── Read ──────────────────────────────────────────────────────────────────
  static Future<String?> getAccessToken() async {
    try {
      final val = await _secure.read(key: _accessKey);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    // Fallback to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accessKey);
    } catch (_) {}
    return null;
  }

  static Future<String?> getRefreshToken() async {
    try {
      final val = await _secure.read(key: _refreshKey);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshKey);
    } catch (_) {}
    return null;
  }

  static Future<void> saveUserId(String id) async {
    try {
      await _secure.write(key: _userIdKey, value: id);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, id);
    }
  }

  static Future<String?> getUserId() async {
    try {
      final val = await _secure.read(key: _userIdKey);
      if (val != null) return val;
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userIdKey);
    } catch (_) {}
    return null;
  }

  // ── Clear ─────────────────────────────────────────────────────────────────
  static Future<void> clearTokens() async {
    try {
      await _secure.delete(key: _accessKey);
      await _secure.delete(key: _refreshKey);
      await _secure.delete(key: _userIdKey);
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessKey);
      await prefs.remove(_refreshKey);
      await prefs.remove(_userIdKey);
    } catch (_) {}
  }
}
