import '../datasources/remote/auth_remote.dart';
import '../models/user_model.dart';
import '../../core/storage/token_storage.dart';

class AuthRepository {
  final _remote = AuthRemote();

  Future<void> login(String email, String password) async {
    final data = await _remote.login(email, password);
    final token   = data['access_token']?.toString() ?? '';
    final refresh = data['refresh_token']?.toString() ?? '';
    if (token.isEmpty) throw Exception('Token гирифта нашуд');
    await TokenStorage.saveTokens(accessToken: token, refreshToken: refresh);
  }

  Future<void> register(
      String email, String password, String fullName) async {
    final data = await _remote.register(email, password, fullName);
    final token   = data['access_token']?.toString() ?? '';
    final refresh = data['refresh_token']?.toString() ?? '';
    if (token.isEmpty) throw Exception('Token гирифта нашуд');
    await TokenStorage.saveTokens(accessToken: token, refreshToken: refresh);
  }

  Future<UserModel?> getMe() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.isEmpty) return null;
    try {
      return await _remote.getMe();
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await TokenStorage.clearTokens();
  }
}
