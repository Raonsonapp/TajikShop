import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../storage/token_storage.dart';

/// Қабули `tajikshop://sso?code=…` аз барномаҳои шарик (Raonson).
///
/// Ҷараён аз тарафи дигар: Raonson `POST /sso/code {target_app:"tajikshop"}`
/// мекунад, TajikShop-ро бо коди якдафъаина мекушояд, ва ин ҷо он код ба
/// сессия иваз мешавад — корбар бе парол ва бе бақайдгирии нав ворид
/// мешавад.
///
/// Худи код дар URL меравад, на токен: он як бор кор мекунад, пас аз 2
/// дақиқа мемирад ва дар сервер танҳо ҳэшаш нигоҳ дошта мешавад. Тафсилот
/// дар `docs/SSO_RAONSON.md`.
class SsoLinkService {
  SsoLinkService._();
  static final instance = SsoLinkService._();

  final _links = AppLinks();
  StreamSubscription<Uri>? _sub;
  bool _started = false;

  /// Вақте ки вуруд муваффақ шуд — барнома профилро нав мекунад ва ба
  /// саҳифаи асосӣ меравад.
  void Function()? onSignedIn;

  Future<void> init() async {
    if (_started) return;
    _started = true;

    // Барнома метавонад МАҲЗ бо ҳамин линк оғоз шуда бошад.
    try {
      final first = await _links.getInitialLink();
      if (first != null) await _handle(first);
    } catch (e) {
      debugPrint('[SSO] линки аввала хонда нашуд: $e');
    }

    // Ё линк вақте меояд, ки барнома аллакай кушода аст.
    _sub = _links.uriLinkStream.listen(
      (uri) => _handle(uri),
      onError: (e) => debugPrint('[SSO] хатои линк: $e'),
    );
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _started = false;
  }

  Future<void> _handle(Uri uri) async {
    // Танҳо `tajikshop://sso?code=…` — ҳар линки дигарро намегирем.
    if (uri.scheme != 'tajikshop' || uri.host != 'sso') return;
    final code = uri.queryParameters['code']?.trim() ?? '';
    if (code.isEmpty) return;

    debugPrint('[SSO] коди вуруд гирифта шуд');
    try {
      final res = await ApiClient.instance.dio.post('/sso/exchange',
          data: {'code': code, 'app': 'tajikshop'});
      final raw = res.data;
      final data = raw is Map
          ? (raw['data'] is Map ? raw['data'] as Map : raw)
          : const {};
      final access = data['access_token']?.toString();
      final refresh = data['refresh_token']?.toString();
      if (access == null || access.isEmpty) {
        debugPrint('[SSO] сервер токен надод');
        return;
      }
      await TokenStorage.saveTokens(accessToken: access, refreshToken: refresh);
      debugPrint('[SSO] вуруд муваффақ шуд');
      onSignedIn?.call();
    } catch (e) {
      // Коди мӯҳлаташ гузашта ё аллакай истифодашуда — корбар танҳо дар
      // экрани вуруд мемонад, барнома намешиканад.
      debugPrint('[SSO] иваз кардани код нашуд: $e');
    }
  }
}
