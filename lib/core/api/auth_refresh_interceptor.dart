import 'package:dio/dio.dart';

import '../constants/app_strings.dart';
import '../storage/token_storage.dart';

/// Навсозии ХУДКОРИ токен.
///
/// ⚠️ Хатои «invalid token», ки дар экрани нашри маҳсулот пайдо мешуд, маҳз
/// аз ин ҷо буд. Токени дастрасӣ ҳамагӣ **24 соат** зинда аст, вале барнома
/// ҳеҷ гоҳ `/auth/refresh`-ро даъват намекард — гарчанде токени навсозӣ
/// (30-рӯза) дар хотира буд ва сервер ин роҳро дошт.
///
/// Дар натиҷа пас аз як шабонарӯз ҲАР дархости бо ворид (нашри маҳсулот,
/// сабад, профил) 401 мегирифт ва корбар матни хушки англисии «invalid
/// token»-ро мебинад — бе ҳеҷ ишора ба он ки танҳо аз нав ворид шудан лозим
/// аст.
///
/// Акнун: 401 → як бор токен нав карда мешавад → дархости аввала такрор
/// мешавад. Агар навсозӣ ҳам нашавад → сессия пок мешавад ва барнома ба
/// экрани вуруд мебарад.
class AuthRefreshInterceptor extends Interceptor {
  AuthRefreshInterceptor(this._dio, {required this.onSessionExpired});

  final Dio _dio;

  /// Вақте ки навсозӣ ғайриимкон шуд (токени навсозӣ низ мӯҳлаташ гузашт,
  /// бекор карда шуд, ё калиди сервер иваз шуд).
  final void Function() onSessionExpired;

  /// Барои он ки даҳ дархости баробар даҳ маротиба навсозӣ накунанд.
  static Future<String?>? _inFlight;

  static const _retriedFlag = '__auth_retried';

  /// Роҳҳое, ки 401-и онҳо маънои «сессия тамом шуд»-ро НАДОРАД: ин ҷо 401
  /// яъне «парол нодуруст» — онро набояд ҳамчун мӯҳлати токен фаҳмид.
  static bool _isAuthEndpoint(String path) =>
      path.contains('/auth/login') ||
      path.contains('/auth/register') ||
      path.contains('/auth/refresh');

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final opts = err.requestOptions;
    final is401 = err.response?.statusCode == 401;

    if (!is401 ||
        _isAuthEndpoint(opts.path) ||
        opts.extra[_retriedFlag] == true) {
      handler.next(err);
      return;
    }

    final fresh = await _refreshOnce();
    if (fresh == null || fresh.isEmpty) {
      await TokenStorage.clearTokens();
      onSessionExpired();
      handler.next(err);
      return;
    }

    // Дархости аввалро бо токени нав як бор такрор мекунем.
    opts.extra[_retriedFlag] = true;
    opts.headers['Authorization'] = 'Bearer $fresh';
    try {
      handler.resolve(await _dio.fetch(opts));
    } catch (e) {
      handler.next(e is DioException ? e : err);
    }
  }

  /// Токенро нав мекунад; дархостҳои баробар ҳамон як натиҷаро мегиранд.
  Future<String?> _refreshOnce() {
    return _inFlight ??= _doRefresh().whenComplete(() => _inFlight = null);
  }

  Future<String?> _doRefresh() async {
    final refresh = await TokenStorage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) return null;
    try {
      // Dio-и тоза — бе interceptor-ҳо, вагарна 401-и худи навсозӣ
      // боз навсозиро оғоз мекунад ва ҳалқаи бепоён месозад.
      final bare = Dio(BaseOptions(
        baseUrl: AppStrings.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Accept': 'application/json'},
      ));
      final res = await bare.post('/auth/refresh',
          data: {'refresh_token': refresh});
      final raw = res.data;
      final data = raw is Map
          ? (raw['data'] is Map ? raw['data'] as Map : raw)
          : const {};
      final access = data['access_token']?.toString();
      if (access == null || access.isEmpty) return null;
      // Сервер танҳо токени дастрасиро бармегардонад — токени навсозӣ
      // ҳамон мемонад.
      await TokenStorage.saveTokens(accessToken: access);
      return access;
    } catch (_) {
      return null;
    }
  }
}
