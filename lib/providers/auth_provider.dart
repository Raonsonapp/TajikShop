import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/storage/token_storage.dart';
import '../data/models/user_model.dart';

// ─── Self-contained Auth — no separate repository needed ──────────────────
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  const AuthState({this.user, this.isLoading = false, this.error, this.isAuthenticated = false});
  AuthState copyWith({UserModel? user, bool? isLoading, String? error, bool? isAuthenticated}) =>
      AuthState(user: user ?? this.user, isLoading: isLoading ?? this.isLoading,
          error: error, isAuthenticated: isAuthenticated ?? this.isAuthenticated);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Dio get _dio => ApiClient.instance.dio;

  // ── Restore session on app open ──────────────────────────────────────────
  Future<void> checkAuth() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      state = const AuthState();
      return;
    }
    try {
      final user = await _fetchMe();
      state = AuthState(user: user, isAuthenticated: true);
    } catch (_) {
      state = const AuthState();
    }
  }

  // ── Login ────────────────────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _dio.post(ApiEndpoints.login,
          data: {'email': email, 'password': password});
      final data = res.data as Map<String, dynamic>;
      final token = data['access_token']?.toString() ?? '';
      if (token.isEmpty) throw Exception('Token гирифта нашуд');
      await TokenStorage.saveTokens(accessToken: token);
      final user = await _fetchMe();
      state = AuthState(user: user, isAuthenticated: true);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false,
          error: e.message ?? 'Хатои пайвастшавӣ');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false,
          error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  // ── Register ─────────────────────────────────────────────────────────────
  Future<bool> register(String email, String password, String fullName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _dio.post(ApiEndpoints.register,
          data: {'name': fullName, 'email': email, 'password': password});
      final data = res.data as Map<String, dynamic>;
      final token = data['access_token']?.toString() ?? '';
      if (token.isEmpty) throw Exception('Token гирифта нашуд');
      await TokenStorage.saveTokens(accessToken: token);
      final user = await _fetchMe();
      state = AuthState(user: user, isAuthenticated: true);
      return true;
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ??
          e.message ?? 'Хатои пайвастшавӣ';
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false,
          error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  // ── Logout ───────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await TokenStorage.clearTokens();
    state = const AuthState();
  }

  // ── Fetch /users/me ──────────────────────────────────────────────────────
  Future<UserModel> _fetchMe() async {
    final res = await _dio.get(ApiEndpoints.me);
    final data = res.data;
    final map = data is Map<String, dynamic>
        ? (data['user'] as Map<String, dynamic>? ?? data)
        : data as Map<String, dynamic>;
    return UserModel.fromJson(map);
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
