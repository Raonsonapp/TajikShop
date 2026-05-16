import 'package:dio/dio.dart';
import 'interceptors.dart';
import '../storage/token_storage.dart';
import '../constants/app_strings.dart';

/// TajikShop API Client
/// _TokenInjector reads token from SharedPreferences before EVERY request.
/// This guarantees token is sent even after app restart or hot-reload.
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal() { _setup(); }

  late Dio dio;

  void _setup() {
    dio = Dio(BaseOptions(
      baseUrl:        AppStrings.baseUrl,
      // FIX: Timeout кам шуд — ANR (Application Not Responding) ислоҳ
      // receiveTimeout 30s → 8s: Dio 30s block мекард → Android freeze
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      sendTimeout:    const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ));
    dio.interceptors.addAll([
      _TokenInjector(),  // ← reads token fresh every request
      RetryInterceptor(dio),
      ErrorInterceptor(),
      LoggingInterceptor(),
    ]);
  }

  /// Called after login/register - now just saves token, no need to rebuild dio
  void init({String? token}) {
    if (token != null && token.isNotEmpty) {
      TokenStorage.saveTokens(accessToken: token);
    }
  }

  static ApiClient get instance => _instance;
}

/// Reads Authorization token from SharedPreferences before EVERY request.
/// Fixes 401 after hot-restart, app reopen, or navigation.
class _TokenInjector extends Interceptor {
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await TokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
