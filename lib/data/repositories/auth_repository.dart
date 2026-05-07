import '../datasources/remote/auth_remote.dart';
import '../models/user_model.dart';
import '../../core/storage/token_storage.dart';
import '../../core/api/api_client.dart';

class AuthRepository {
  final AuthRemote _remote = AuthRemote();

  Future<UserModel> login(String email, String password) async {
    final data = await _remote.login(email, password);
    final token = data['token'] ?? data['access_token'] ?? '';
    final refresh = data['refresh_token'];
    await TokenStorage.saveTokens(accessToken: token, refreshToken: refresh);
    ApiClient.instance.init(token: token);
    return UserModel.fromJson(data['user'] ?? data);
  }

  Future<UserModel> register(String email, String password, String fullName) async {
    final data = await _remote.register(email, password, fullName);
    final token = data['token'] ?? data['access_token'] ?? '';
    await TokenStorage.saveTokens(accessToken: token);
    ApiClient.instance.init(token: token);
    return UserModel.fromJson(data['user'] ?? data);
  }

  Future<UserModel?> getMe() async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null || token.isEmpty) return null;
      ApiClient.instance.init(token: token);
      return await _remote.getMe();
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await TokenStorage.clearTokens();
    ApiClient.instance.init();
  }
}
