import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  final Dio dio;
  RetryInterceptor(this.dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final opts = err.requestOptions;
    final retries = (opts.extra['retries'] as int?) ?? 0;
    if (retries < 2 &&
        (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.sendTimeout ||
            err.type == DioExceptionType.connectionError)) {
      opts.extra['retries'] = retries + 1;
      await Future.delayed(Duration(seconds: 2 * (retries + 1)));
      try {
        return handler.resolve(await dio.fetch(opts));
      } catch (_) {}
    }
    handler.next(err);
  }
}

class ErrorInterceptor extends Interceptor {
  // Server returns: {"success": false, "error": "message text"}
  String _extractMsg(dynamic data, String fallback) {
    if (data is Map) {
      return data['error']?.toString() ??
          data['message']?.toString() ??
          fallback;
    }
    return fallback;
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String msg;
    final d = err.response?.data;
    switch (err.response?.statusCode) {
      case 400: msg = _extractMsg(d, 'Дархости нодуруст'); break;
      case 401: msg = _extractMsg(d, 'Email ё парол нодуруст'); break;
      case 403: msg = 'Дастрасӣ манъ аст'; break;
      case 404: msg = 'Ёфт нашуд'; break;
      case 409: msg = 'Ин email аллакай вуҷуд дорад'; break;
      case 422: msg = _extractMsg(d, 'Маълумоти нодуруст'); break;
      case 429: msg = 'Хеле зиёд дархост. Каме сабр кунед'; break;
      case 500: msg = 'Хатои сервер. Баъдтар кӯшиш кунед'; break;
      default:
        if (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.sendTimeout) {
          msg = 'Интернет суст аст. Дубора кӯшиш кунед';
        } else if (err.type == DioExceptionType.connectionError) {
          msg = 'Пайвастшавӣ нест. Интернетро санҷед';
        } else {
          msg = _extractMsg(d, err.message ?? 'Хатои номаълум');
        }
    }
    handler.next(DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: msg,
        message: msg));
  }
}

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // ignore: avoid_print
    print('→ ${options.method} ${options.path}  auth:${options.headers['Authorization'] != null ? "✓" : "✗"}');
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // ignore: avoid_print
    print('✗ ${err.response?.statusCode} ${err.requestOptions.path}: ${err.message}');
    handler.next(err);
  }
}
