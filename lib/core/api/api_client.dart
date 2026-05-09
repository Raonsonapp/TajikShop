import 'package:dio/dio.dart';
import 'interceptors.dart';
import '../constants/app_strings.dart';

class ApiClient {
  static final ApiClient _i = ApiClient._internal();
  factory ApiClient() => _i;
  ApiClient._internal() { init(); }
  late Dio dio;

  void init({String? token}) {
    dio = Dio(BaseOptions(
      baseUrl:        AppStrings.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout:    const Duration(minutes: 3),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ));
    dio.interceptors.clear();
    dio.interceptors.add(AuthInterceptor(token: token));
    dio.interceptors.add(RetryInterceptor(dio));
    dio.interceptors.add(ErrorInterceptor());
    dio.interceptors.add(LoggingInterceptor());
  }

  static ApiClient get instance => _i;
}
