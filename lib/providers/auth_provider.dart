import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/storage/token_storage.dart';
import '../core/services/user_session.dart';
import '../data/models/user_model.dart';

// ─── Auth State ───────────────────────────────────────────────────────────────
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) =>
      AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      );
}

// ─── Auth Notifier ────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Dio get _dio => ApiClient.instance.dio;

  // ── Unwrap server envelope: {"success": true, "data": {...}} ─────────────
  Map<String, dynamic> _unwrap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw['data'] as Map<String, dynamic>? ?? raw;
    }
    return <String, dynamic>{};
  }

  // ── Сессияро вақти кушодани барнома барқарор кун ────────────────────────
  // ── Офлайн режим: Splash токенро санҷид ва HOME-га фиристод ─────────────
  void setOfflineUser(UserModel user) {
    state = AuthState(user: user, isAuthenticated: true);
    // Фон: сервер бедор шавад → маълумотро навсоз
    Future.delayed(const Duration(seconds: 3), () async {
      try {
        final fresh = await _fetchMe().timeout(const Duration(seconds: 10));
        await _persistSession(fresh);
        state = AuthState(user: fresh, isAuthenticated: true);
      } catch (_) { /* Офлайн — кэш кор мекунад */ }
    });
  }

  Future<void> checkAuth() async {
    // Аввал кэшро бор кун — UI фавран нишон медиҳад
    await UserSession.loadCachedData();

    final token = await TokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      state = const AuthState();
      return;
    }
    try {
      final user = await _fetchMe();
      await _persistSession(user);
      state = AuthState(user: user, isAuthenticated: true);
    } catch (_) {
      // Агар сервер нест — кэшро нишон деҳ
      final cached = UserSession.userId;
      if (cached != null && cached.isNotEmpty) {
        // Офлайн режим: ба Home бур
        state = AuthState(
          user: UserModel(
            id: cached,
            email: UserSession.email ?? '',
            fullName: UserSession.fullName ?? 'Корбар',
            avatar: UserSession.avatar,
            role: UserSession.role,
            isSeller: UserSession.role == 'seller' || UserSession.role == 'admin',
            isVerified: false,
            createdAt: DateTime.now(),
          ),
          isAuthenticated: true,
        );
      } else {
        state = const AuthState();
      }
    }
  }

  // ── Login ────────────────────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _dio.post(ApiEndpoints.login,
          data: {'email': email, 'password': password});
      final data = _unwrap(res.data);
      final token   = data['access_token']?.toString() ?? '';
      final refresh = data['refresh_token']?.toString();
      if (token.isEmpty) throw Exception('Token гирифта нашуд');
      await TokenStorage.saveTokens(accessToken: token, refreshToken: refresh);
      final user = await _fetchMe();
      await _persistSession(user);
      state = AuthState(user: user, isAuthenticated: true);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
          isLoading: false, error: e.message ?? 'Хатои пайвастшавӣ');
      return false;
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
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
      final data = _unwrap(res.data);
      final token   = data['access_token']?.toString() ?? '';
      final refresh = data['refresh_token']?.toString();
      if (token.isEmpty) throw Exception('Token гирифта нашуд');
      await TokenStorage.saveTokens(accessToken: token, refreshToken: refresh);
      final user = await _fetchMe();
      await _persistSession(user);
      state = AuthState(user: user, isAuthenticated: true);
      return true;
    } on DioException catch (e) {
      final msg = _unwrap(e.response?.data)['error']?.toString() ??
          e.message ?? 'Хатои пайвастшавӣ';
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  // ── Login with Firebase Phone ─────────────────────────────────────────────
  Future<bool> loginWithPhone(String firebaseIdToken, {String name = ''}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _dio.post('/auth/phone-verify',
          data: {'id_token': firebaseIdToken, 'name': name});
      final data = _unwrap(res.data);
      final token   = data['access_token']?.toString() ?? '';
      final refresh = data['refresh_token']?.toString();
      if (token.isEmpty) throw Exception('Token нест');
      await TokenStorage.saveTokens(accessToken: token, refreshToken: refresh);
      final user = await _fetchMe();
      await _persistSession(user);
      state = AuthState(user: user, isAuthenticated: true);
      return true;
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
  Future<bool> becomeSeller() async {
    try {
      final res = await _dio.post(ApiEndpoints.becomeSeller);
      final data = _unwrap(res.data);
      // Backend нав токен медиҳад — захира кун
      final newAccess  = data['access_token']?.toString();
      final newRefresh = data['refresh_token']?.toString();
      if (newAccess != null && newAccess.isNotEmpty) {
        await TokenStorage.saveTokens(
            accessToken: newAccess, refreshToken: newRefresh);
      }
      // Маълумоти корбарро аз сервер навсоз
      final user = await _fetchMe();
      await _persistSession(user);
      state = AuthState(user: user, isAuthenticated: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Logout ───────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await TokenStorage.clearTokens();
    await UserSession.clear();
    state = const AuthState();
  }

  // ── Fetch /users/me ──────────────────────────────────────────────────────
  Future<UserModel> _fetchMe() async {
    final res = await _dio.get(ApiEndpoints.me);
    final body = _unwrap(res.data);
    final map  = body['user'] as Map<String, dynamic>? ?? body;
    return UserModel.fromJson(map);
  }

  // ── Маълумоти корбарро кэш кун ──────────────────────────────────────────
  Future<void> _persistSession(UserModel user) async {
    await UserSession.saveAll(
      id:        user.id,
      userEmail: user.email,
      name:      user.fullName,
      avatarUrl: user.avatar ?? '',
      userRole:  user.role,
    );
    await TokenStorage.saveUserId(user.id);
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
