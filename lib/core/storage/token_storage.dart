import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _accessKey  = 'ts_access_token';
  static const _refreshKey = 'ts_refresh_token';

  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(_refreshKey, refreshToken);
    }
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_accessKey);
    return (token == null || token.isEmpty) ? null : token;
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshKey);
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
  }
}
