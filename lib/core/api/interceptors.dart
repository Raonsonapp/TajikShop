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

// Auto-retry up to 2 times on timeout (helps slow internet like H/0.1KB/s)
class RetryInterceptor extends Interceptor {
  final Dio dio;
  RetryInterceptor(this.dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final retries = (options.extra['retries'] as int?) ?? 0;

    // Only retry on timeout/connection errors, max 2 retries
    if (retries < 2 && (
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError)) {
      options.extra['retries'] = retries + 1;
      // Exponential backoff: 2s, 4s
      await Future.delayed(Duration(seconds: 2 * (retries + 1)));
      try {
        final response = await dio.fetch(options);
        return handler.resolve(response);
      } catch (_) {}
    }
    handler.next(err);
  }
}

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String message;
    switch (err.response?.statusCode) {
      case 400: message = err.response?.data?['message'] ?? 'Дархости нодуруст'; break;
      case 401: message = 'Иҷозат нест. Лутфан дубора ворид шавед'; break;
      case 403: message = 'Дастрасӣ манъ аст'; break;
      case 404: message = 'Ёфт нашуд'; break;
      case 422: message = err.response?.data?['message'] ?? 'Маълумоти нодуруст'; break;
      case 429: message = 'Хеле зиёд дархост. Каме сабр кунед'; break;
      case 500: message = 'Хатои сервер. Баъдтар кӯшиш кунед'; break;
      default:
        if (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.sendTimeout) {
          message = 'Интернет суст аст. Дубора кӯшиш кунед';
        } else if (err.type == DioExceptionType.connectionError) {
          message = 'Пайвастшавӣ нест. Интернетро санҷед';
        } else {
          message = err.response?.data?['message'] ??
              err.response?.data?['error'] ?? 'Хатои номаълум';
        }
    }
    handler.next(DioException(
      requestOptions: err.requestOptions, response: err.response,
      type: err.type, error: message, message: message));
  }
}

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions o, RequestInterceptorHandler h) {
    // ignore: avoid_print
    print('→ ${o.method} ${o.path}');
    h.next(o);
  }
  @override
  void onResponse(Response r, ResponseInterceptorHandler h) {
    // ignore: avoid_print
    print('← ${r.statusCode} ${r.requestOptions.path}');
    h.next(r);
  }
  @override
  void onError(DioException e, ErrorInterceptorHandler h) {
    // ignore: avoid_print
    print('✗ ${e.response?.statusCode} ${e.requestOptions.path}: ${e.message}');
    h.next(e);
  }
}
