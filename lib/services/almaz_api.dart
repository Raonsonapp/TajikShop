import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Client for the existing Almaz TJ API hosted on Hugging Face Spaces.
/// Admin credentials stay on the server and are never embedded in the app.
class AlmazApi {
  AlmazApi._();
  static final AlmazApi instance = AlmazApi._();
  static const String baseUrl = 'https://mahmadmurodov-tajikshop.hf.space';
  static const Duration timeout = Duration(seconds: 18);
  static const String _tokenKey = 'almaz_access_token';

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (auth) {
      final token = await _token();
      if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  dynamic _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AlmazApiException('Дархости сервер иҷро нашуд (${response.statusCode})', statusCode: response.statusCode);
    }
    if (response.body.isEmpty) return <String, dynamic>{};
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<Map<String, dynamic>> health() async {
    final response = await http.get(_uri('/health'), headers: await _headers()).timeout(timeout);
    final data = _decode(response);
    if (data is Map<String, dynamic>) return data;
    return {'status': 'unknown', 'data': data};
  }

  Future<dynamic> getCategories() async {
    final response = await http.get(_uri('/api/v1/categories'), headers: await _headers()).timeout(timeout);
    return _decode(response);
  }

  Future<dynamic> getProducts({int page = 1, int limit = 30}) async {
    final response = await http.get(_uri('/api/v1/products', {'page': '$page', 'limit': '$limit'}), headers: await _headers()).timeout(timeout);
    return _decode(response);
  }

  Future<dynamic> getPublicSettings() async {
    final response = await http.get(_uri('/api/v1/settings'), headers: await _headers()).timeout(timeout);
    return _decode(response);
  }

  Future<dynamic> getMyOrders() async {
    final response = await http.get(_uri('/api/v1/orders'), headers: await _headers(auth: true)).timeout(timeout);
    return _decode(response);
  }

  Future<dynamic> getWallet() async {
    final response = await http.get(_uri('/api/v1/wallet'), headers: await _headers(auth: true)).timeout(timeout);
    return _decode(response);
  }

  Future<dynamic> login({required String email, required String password}) async {
    final response = await http.post(
      _uri('/api/v1/auth/login'),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'password': password}),
    ).timeout(timeout);
    final data = _decode(response);
    final token = _extractToken(data);
    if (token != null) await saveAccessToken(token);
    return data;
  }

  Future<dynamic> register({required String name, required String email, required String password}) async {
    final response = await http.post(
      _uri('/api/v1/auth/register'),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode({'name': name.trim(), 'email': email.trim(), 'password': password}),
    ).timeout(timeout);
    final data = _decode(response);
    final token = _extractToken(data);
    if (token != null) await saveAccessToken(token);
    return data;
  }

  String? _extractToken(dynamic data) {
    if (data is! Map) return null;
    dynamic value = data;
    for (var i = 0; i < 3 && value is Map; i++) {
      final map = value as Map;
      for (final key in ['access_token', 'accessToken', 'token', 'jwt']) {
        final token = map[key];
        if (token is String && token.isNotEmpty) return token;
      }
      value = map['data'] ?? map['user'] ?? map['result'];
    }
    return null;
  }

  Future<void> logout() async {
    try {
      final response = await http.post(
        _uri('/api/v1/auth/logout'),
        headers: await _headers(auth: true),
      ).timeout(timeout);
      if (response.statusCode >= 500) {
        throw AlmazApiException('Хатои сервер ҳангоми баромадан', statusCode: response.statusCode);
      }
    } finally {
      await clearAccessToken();
    }
  }

  Future<bool> hasAccessToken() async {
    final token = await _token();
    return token != null && token.isNotEmpty;
  }

  Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}

class AlmazApiException implements Exception {
  final String message;
  final int? statusCode;
  const AlmazApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}