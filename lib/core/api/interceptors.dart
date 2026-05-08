import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  final String? token;
  AuthInterceptor({this.token});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (token != null && token!.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String message;
    switch (err.response?.statusCode) {
      case 400: message = 'Дархости нодуруст'; break;
      case 401: message = 'Иҷозат нест. Лутфан дубора ворид шавед'; break;
      case 403: message = 'Дастрасӣ манъ аст'; break;
      case 404: message = 'Ёфт нашуд'; break;
      case 422: message = _extract422(err.response?.data); break;
      case 429: message = 'Хеле зиёд дархост. Каме сабр кунед'; break;
      case 500: message = 'Хатои сервер. Баъдтар кӯшиш кунед'; break;
      default:
        if (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout) {
          message = 'Пайвастшавӣ вақт гузашт. Интернетро санҷед';
        } else if (err.type == DioExceptionType.connectionError) {
          message = 'Пайвастшавӣ имконпазир нест. Интернетро санҷед';
        } else {
          message = err.response?.data?['message'] ??
              err.response?.data?['error'] ?? 'Хатои номаълум';
        }
    }
    handler.next(DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: message,
      message: message,
    ));
  }

  String _extract422(dynamic data) {
    if (data == null) return 'Маълумоти нодуруст';
    if (data is Map) {
      return data['message'] ?? data['error'] ?? 'Маълумоти нодуруст';
    }
    return 'Маълумоти нодуруст';
  }
}

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // ignore: avoid_print
    print('→ ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // ignore: avoid_print
    print('← ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // ignore: avoid_print
    print('✗ ${err.response?.statusCode} ${err.requestOptions.path}: ${err.message}');
    handler.next(err);
  }
}
