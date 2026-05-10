import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../models/user_model.dart';

class AuthRemote {
  Dio get _dio => ApiClient.instance.dio;

  // Unwrap server envelope: {"success": true, "data": {...}}
  Map<String, dynamic> _unwrap(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      return responseData['data'] as Map<String, dynamic>? ?? responseData;
    }
    return responseData as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post(ApiEndpoints.login, data: {
      'email':    email,
      'password': password,
    });
    return _unwrap(res.data);
  }

  Future<Map<String, dynamic>> register(
      String email, String password, String fullName) async {
    final res = await _dio.post(ApiEndpoints.register, data: {
      'name':     fullName,
      'email':    email,
      'password': password,
    });
    return _unwrap(res.data);
  }

  Future<UserModel> getMe() async {
    final res = await _dio.get(ApiEndpoints.me);
    final data = _unwrap(res.data);
    final map = data['user'] as Map<String, dynamic>? ?? data;
    return UserModel.fromJson(map);
  }
}
