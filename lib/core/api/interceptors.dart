import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  final Dio dio;
  RetryInterceptor(this.dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final opts = err.requestOptions;
    final retries = (opts.extra['retries'] as int?) ?? 0;
    if (retries < 2 && (
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError)) {
      opts.extra['retries'] = retries + 1;
      await Future.delayed(Duration(seconds: 2 * (retries + 1)));
      try { return handler.resolve(await dio.fetch(opts)); } catch (_) {}
    }
    handler.next(err);
  }
}

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String msg;
    switch (err.response?.statusCode) {
      case 400: msg = err.response?.data?['message'] ?? 'Дархости нодуруст'; break;
      case 401: msg = 'Иҷозат нест. Аз нав ворид шавед'; break;
      case 403: msg = 'Дастрасӣ манъ аст'; break;
      case 404: msg = 'Ёфт нашуд'; break;
      case 422: msg = err.response?.data?['message'] ?? 'Маълумоти нодуруст'; break;
      case 500: msg = 'Хатои сервер. Баъдтар кӯшиш кунед'; break;
      default:
        if (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.sendTimeout) {
          msg = 'Интернет суст аст. Дубора кӯшиш кунед';
        } else if (err.type == DioExceptionType.connectionError) {
          msg = 'Пайвастшавӣ нест. Интернетро санҷед';
        } else {
          msg = err.response?.data?['message'] ??
              err.response?.data?['error'] ?? 'Хатои номаълум';
        }
    }
    handler.next(DioException(
      requestOptions: err.requestOptions, response: err.response,
      type: err.type, error: msg, message: msg));
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
  void onError(DioException e, ErrorInterceptorHandler h) {
    // ignore: avoid_print
    print('✗ ${e.response?.statusCode} ${e.requestOptions.path}: ${e.message}');
    h.next(e);
  }
}
