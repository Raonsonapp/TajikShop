/// «Бо TajikShop ворид шавед» — дархост аз барномаи шарик (Raonson).
///
/// Raonson TajikShop-ро бо
///
///     tajikshop://sso/authorize?app=raonson&state=<тасодуфӣ>
///
/// мекушояд. Агар корбар ворид бошад, TajikShop мепурсад «Ба Raonson ҳамчун
/// <ном> идома медиҳед?», баъд `POST /sso/code {target_app:"raonson"}`
/// мекунад ва Raonson-ро бо `raonson://sso?code=…&state=<ҳамон>` бармегардонад.
/// Raonson `state`-ро бо он чи худаш фиристода буд муқоиса мекунад — пас
/// барномаи бегона наметавонад корбарро ба ҳисоби каси дигар ворид кунад.
///
/// Ин файл танҳо мантиқи тоза дорад (бе UI ва шабака) — пас тестшаванда аст.
library;

class SsoAuthorizeRequest {
  const SsoAuthorizeRequest({required this.app, this.state});

  /// id-и барномаи шарик (масалан `raonson`), ҳамеша бо ҳарфи хурд.
  final String app;

  /// Қимати тасодуфии Raonson; бе тағйир баргардонида мешавад.
  final String? state;

  static final _appRe = RegExp(r'^[a-z0-9][a-z0-9_-]{1,31}$');

  /// base64url / hex / uuid — ҳама мегузаранд; фосила, `&`, `#` не.
  static final _stateRe = RegExp(r'^[A-Za-z0-9._~-]{8,256}$');

  /// `tajikshop://sso/authorize?app=…&state=…` → дархост; ҳар чизи дигар → null.
  ///
  /// Линки нодуруст (барномаи холӣ, `state`-и шубҳанок, худи TajikShop)
  /// рад мешавад — беҳтар аст ҳеҷ кор накунем, назар ба он ки кодро ба
  /// ҷои нодуруст фиристем.
  static SsoAuthorizeRequest? tryParse(Uri uri) {
    if (uri.scheme.toLowerCase() != 'tajikshop') return null;
    if (uri.host.toLowerCase() != 'sso') return null;
    final path = uri.path.endsWith('/')
        ? uri.path.substring(0, uri.path.length - 1)
        : uri.path;
    if (path != '/authorize') return null;

    final Map<String, String> q;
    try {
      q = uri.queryParameters;
    } catch (_) {
      return null; // percent-encoding-и вайрон
    }
    final app = (q['app'] ?? '').trim().toLowerCase();
    if (!_appRe.hasMatch(app) || app == 'tajikshop') return null;

    final rawState = q['state'];
    String? state;
    if (rawState != null && rawState.isNotEmpty) {
      if (!_stateRe.hasMatch(rawState)) return null;
      state = rawState;
    }
    return SsoAuthorizeRequest(app: app, state: state);
  }

  static SsoAuthorizeRequest? tryParseString(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final uri = Uri.tryParse(raw.trim());
    return uri == null ? null : tryParse(uri);
  }

  /// Линки бозгашт: `deep_link`-и сервер + `state`.
  ///
  /// Схемаи линк бояд ҳамон схемаи барнома дар `/sso/apps` бошад — код ба
  /// ягон барномаи дигар намеравад, ҳатто агар сервер чизи аҷиб баргардонад.
  static Uri? buildReturnLink({
    required String deepLink,
    required String expectedScheme,
    String? state,
  }) {
    final u = Uri.tryParse(deepLink.trim());
    if (u == null || expectedScheme.isEmpty) return null;
    if (u.scheme.toLowerCase() != expectedScheme.toLowerCase()) return null;
    if (state == null || state.isEmpty) return u;
    final q = Map<String, String>.of(u.queryParameters)..['state'] = state;
    return u.replace(queryParameters: q);
  }

  @override
  bool operator ==(Object other) =>
      other is SsoAuthorizeRequest && other.app == app && other.state == state;

  @override
  int get hashCode => Object.hash(app, state);

  @override
  String toString() => 'SsoAuthorizeRequest(app: $app, state: ${state == null ? '-' : '…'})';
}

/// Барномаи шарик аз `GET /sso/apps`.
class SsoPartnerApp {
  const SsoPartnerApp({
    required this.id,
    required this.name,
    required this.scheme,
    this.fallback = '',
  });

  final String id;
  final String name;
  final String scheme;
  final String fallback;

  /// Ҷавоби `/sso/apps` (бо ё бе `{success, data}`) → рӯйхат.
  static List<SsoPartnerApp> listFrom(Object? raw) {
    final data = raw is Map ? raw['data'] : raw;
    if (data is! List) return const [];
    return [
      for (final e in data)
        if (e is Map && (e['id'] ?? '').toString().isNotEmpty)
          SsoPartnerApp(
            id: e['id'].toString().toLowerCase(),
            name: (e['name'] ?? e['id']).toString(),
            scheme: (e['scheme'] ?? '').toString(),
            fallback: (e['fallback'] ?? '').toString(),
          ),
    ];
  }

  static SsoPartnerApp? find(List<SsoPartnerApp> apps, String id) {
    final want = id.trim().toLowerCase();
    for (final a in apps) {
      if (a.id == want && a.scheme.isNotEmpty) return a;
    }
    return null;
  }
}
