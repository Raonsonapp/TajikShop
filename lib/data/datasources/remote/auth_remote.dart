import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../models/user_model.dart';

class AuthRemote {
  Dio get _dio => ApiClient.instance.dio;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post(ApiEndpoints.login, data: {
      'email':    email,
      'password': password,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(
      String email, String password, String fullName) async {
    final res = await _dio.post(ApiEndpoints.register, data: {
      'name':     fullName, // backend expects "name" not "full_name"
      'email':    email,
      'password': password,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<UserModel> getMe() async {
    final res = await _dio.get(ApiEndpoints.me);
    final data = res.data as Map<String, dynamic>;
    return UserModel.fromJson(data['user'] as Map<String, dynamic>? ?? data);
  }
}
