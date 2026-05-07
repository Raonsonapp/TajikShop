import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../models/user_model.dart';

class AuthRemote {
  Dio get _dio => ApiClient.instance.dio;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post(ApiEndpoints.login, data: {
      'email': email,
      'password': password,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(String email, String password, String fullName) async {
    final res = await _dio.post(ApiEndpoints.register, data: {
      'email': email,
      'password': password,
      'full_name': fullName,
      'name': fullName,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<UserModel> getMe() async {
    final res = await _dio.get(ApiEndpoints.me);
    final data = res.data;
    if (data is Map<String, dynamic>) {
      final user = data['user'] ?? data;
      return UserModel.fromJson(user as Map<String, dynamic>);
    }
    throw Exception('Формати посух нодуруст');
  }
}
