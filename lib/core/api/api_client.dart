import 'package:dio/dio.dart';
import 'interceptors.dart';
import '../storage/token_storage.dart';
import '../constants/app_strings.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal() { _setup(); }

  late Dio dio;

  void _setup() {
    dio = Dio(BaseOptions(
      baseUrl:        AppStrings.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout:    const Duration(minutes: 3),
      headers: {'Accept': 'application/json'},
    ));
    dio.interceptors.addAll([
      _TokenInjector(),
      RetryInterceptor(dio),
      ErrorInterceptor(),
      LoggingInterceptor(),
    ]);
  }

  // backward compat — called after login/register but no longer needed
  void init({String? token}) {}

  static ApiClient get instance => _instance;
}

/// Reads token fresh from SharedPreferences before EVERY request.
/// This fixes 401 after hot-restart or app reopen.
class _TokenInjector extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await TokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
