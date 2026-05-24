import 'package:dio/dio.dart';
import 'interceptors.dart';
import '../storage/token_storage.dart';
import '../constants/app_strings.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal() {
    _setup();
  }

  late Dio dio;

  void _setup() {
    dio = Dio(BaseOptions(
      baseUrl: AppStrings.baseUrl,
      // ✅ HuggingFace: 30с кофӣ аст
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));
    dio.interceptors.addAll([
      _TokenInjector(),
      RetryInterceptor(dio),
      ErrorInterceptor(),
      LoggingInterceptor(),
    ]);
  }

  void init({String? token}) {
    if (token != null && token.isNotEmpty) {
      TokenStorage.saveTokens(accessToken: token);
    }
  }

  static ApiClient get instance => _instance;
}

class _TokenInjector extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await TokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
