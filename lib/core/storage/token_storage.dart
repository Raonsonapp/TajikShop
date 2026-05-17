import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _accessKey  = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _userIdKey  = 'user_id';

  // FIX: Кэши дохилӣ — FlutterSecureStorage танҳо 1 маротиба хонда мешавад
  // Ин ANR-ро ислоҳ мекунад: FlutterSecureStorage 200-500ms блок мекард
  static String? _cachedAccess;
  static String? _cachedRefresh;
  static String? _cachedUserId;

  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    _cachedAccess  = accessToken;
    if (refreshToken != null) _cachedRefresh = refreshToken;
    try {
      await _secure.write(key: _accessKey, value: accessToken);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _secure.write(key: _refreshKey, value: refreshToken);
      }
    } catch (e) {
      debugPrint('[TokenStorage] secure write failed: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessKey, accessToken);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await prefs.setString(_refreshKey, refreshToken);
      }
    }
  }

  static Future<String?> getAccessToken() async {
    // FIX: Кэш аввал — disk нест → ANR нест
    if (_cachedAccess != null && _cachedAccess!.isNotEmpty) return _cachedAccess;
    try {
      final val = await _secure.read(key: _accessKey);
      if (val != null && val.isNotEmpty) { _cachedAccess = val; return val; }
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_accessKey);
      if (val != null) _cachedAccess = val;
      return val;
    } catch (_) {}
    return null;
  }

  static Future<String?> getRefreshToken() async {
    if (_cachedRefresh != null && _cachedRefresh!.isNotEmpty) return _cachedRefresh;
    try {
      final val = await _secure.read(key: _refreshKey);
      if (val != null && val.isNotEmpty) { _cachedRefresh = val; return val; }
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_refreshKey);
      if (val != null) _cachedRefresh = val;
      return val;
    } catch (_) {}
    return null;
  }

  static Future<void> saveUserId(String id) async {
    _cachedUserId = id;
    try {
      await _secure.write(key: _userIdKey, value: id);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, id);
    }
  }

  static Future<String?> getUserId() async {
    if (_cachedUserId != null) return _cachedUserId;
    try {
      final val = await _secure.read(key: _userIdKey);
      if (val != null) { _cachedUserId = val; return val; }
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_userIdKey);
      if (val != null) _cachedUserId = val;
      return val;
    } catch (_) {}
    return null;
  }

  static Future<void> clearTokens() async {
    _cachedAccess  = null;
    _cachedRefresh = null;
    _cachedUserId  = null;
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
