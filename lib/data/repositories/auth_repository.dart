import '../datasources/remote/auth_remote.dart';
import '../models/user_model.dart';
import '../../core/storage/token_storage.dart';

class AuthRepository {
  final AuthRemote _remote = AuthRemote();

  Future<UserModel> login(String email, String password) async {
    final data = await _remote.login(email, password);
    // Backend returns "access_token" not "token"
    final token = data['access_token']?.toString() ?? '';
    final refresh = data['refresh_token']?.toString() ?? '';
    if (token.isEmpty) throw Exception('Token нест — посухи backend нодуруст');
    await TokenStorage.saveTokens(accessToken: token, refreshToken: refresh);
    final userMap = data['user'] as Map<String, dynamic>? ?? {};
    return UserModel.fromJson(userMap);
  }

  Future<UserModel> register(
      String email, String password, String fullName) async {
    final data = await _remote.register(email, password, fullName);
    // Backend returns "access_token" not "token"
    final token = data['access_token']?.toString() ?? '';
    final refresh = data['refresh_token']?.toString() ?? '';
    if (token.isEmpty) throw Exception('Token нест — посухи backend нодуруст');
    await TokenStorage.saveTokens(accessToken: token, refreshToken: refresh);
    // Register doesn't return user object, build minimal one
    return UserModel(
      id: '',
      email: email,
      fullName: fullName,
      role: 'buyer',
      isSeller: false,
      isVerified: false,
      createdAt: DateTime.now(),
    );
  }

  Future<UserModel?> getMe() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.isEmpty) return null;
    try {
      return await _remote.getMe();
    } catch (_) {
      return null; // don't clear token - might be network error
    }
  }

  Future<void> logout() async {
    await TokenStorage.clearTokens();
  }
}
