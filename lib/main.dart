import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/api/api_client.dart';
import 'core/app_l10n.dart';
import 'core/l10n/fallback_localizations.dart';
import 'core/services/network_service.dart'; // ← ИЛОВА КУНЕД
import 'core/services/push_service.dart';
import 'core/services/sso_authorize.dart';
import 'core/services/sso_link_service.dart';
import 'core/services/user_session.dart';
import 'core/storage/token_storage.dart';
import 'shared/widgets/sso_consent_sheet.dart';
import 'core/ads/ad_service.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'routes/app_router.dart';
import 'routes/route_names.dart';
import 'shared/widgets/offline_banner.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Хатогиҳои Flutter-ро дошта гиред
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('🔴 FLUTTER ERROR: ${details.exceptionAsString()}');
    debugPrint('📍 STACK: ${details.stack}');
  };

  // ✅ Хатогиҳои async-ро дошта гиред
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('🔴 ASYNC ERROR: $error');
    debugPrint('📍 STACK: $stack');
    return true;
  };

  // ✅ NetworkService-ро инициализатсия кунед!
  NetworkService.instance.init();

  // ✅ Push notifications (Firebase) — дар мобайл; web-ро рад мекунад
  PushService.instance.init();

  // ✅ Реклама (Yandex Mobile Ads) — ҳозир бо ID-и демо фаъол
  AdService.instance.init();

  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light));

  runApp(const ProviderScope(child: TajikShopApp()));
}

class TajikShopApp extends ConsumerWidget {
  const TajikShopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    // Агар навсозии токен кӯмак накунад, сессияро пок карда, корбарро ба
    // экрани вуруд мебарорем — вагарна ӯ дар ҳар экран «мӯҳлати сессия
    // гузашт» мебинад ва намедонад, ки чӣ бояд кард.
    ApiClient.onSessionExpired = () async {
      await ref.read(authProvider.notifier).logout();
      router.go(RouteNames.login);
    };

    // SSO: Raonson моро бо `tajikshop://sso?code=…` мекушояд — корбар бе
    // парол ворид мешавад ва фавран ба саҳифаи асосӣ меравад.
    SsoLinkService.instance.onSignedIn = () async {
      await ref.read(authProvider.notifier).checkAuth();
      router.go(RouteNames.home);
    };
    // «Бо TajikShop ворид шавед»: Raonson моро бо
    // `tajikshop://sso/authorize?app=raonson&state=…` мекушояд. Ворид бошад —
    // розигӣ мепурсем; набошад — аввал вуруд, баъд идома.
    SsoLinkService.instance.onAuthorize =
        (req) => _handleSsoAuthorize(ref, router, req);
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.isAuthenticated && !(prev?.isAuthenticated ?? false)) {
        final pending = SsoLinkService.instance.takePendingAuthorize();
        if (pending != null) _handleSsoAuthorize(ref, router, pending);
      }
    });
    SsoLinkService.instance.init();

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'TajikShop',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      routerConfig: router,
      localizationsDelegates: const [
        _AppLocalizationsDelegate(),
        // ⚠️ Пеш аз Global-ҳо: тоҷикӣ дар Flutter нест, бе ин сатрҳо
        // `MaterialLocalizations` бор намешавад ва тугмаи бозгашт,
        // bottom sheet-ҳо ва RefreshIndicator мешикананд.
        fallbackMaterialDelegate,
        fallbackCupertinoDelegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: LocaleNotifier.supported,
      builder: (context, child) => OfflineBanner(child: child ?? const SizedBox()),
    );
  }
}

/// Экранҳое, ки дар онҳо розигиро нишон додан маъно надорад: аз онҳо
/// барнома худаш ба ҷои дигар мегузарад ва sheet-ро пӯшида мемонад.
const _transientRoutes = {
  RouteNames.splash,
  RouteNames.login,
  RouteNames.register,
  RouteNames.phoneAuth,
  RouteNames.phoneOtp,
};

/// То он даме ки барнома аз splash/вуруд ба экрани доимӣ гузарад, интизор
/// мешавад (то 60 с). Вагарна `router.go(home)`-и splash sheet-ро мепӯшад.
Future<BuildContext?> _settledContext(GoRouter router) async {
  final deadline = DateTime.now().add(const Duration(seconds: 60));
  while (DateTime.now().isBefore(deadline)) {
    final path = router.routerDelegate.currentConfiguration.uri.path;
    final ctx = router.routerDelegate.navigatorKey.currentContext;
    if (ctx != null && !_transientRoutes.contains(path)) {
      // Як кадр барои анҷоми гузариш.
      await Future<void>.delayed(const Duration(milliseconds: 350));
      return router.routerDelegate.navigatorKey.currentContext;
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  return null;
}

bool _ssoAuthorizeBusy = false;

Future<void> _handleSsoAuthorize(
    WidgetRef ref, GoRouter router, SsoAuthorizeRequest req) async {
  final token = await TokenStorage.getAccessToken();
  if (token == null || token.isEmpty) {
    // Ворид нест: дархостро нигоҳ медорем ва пас аз вуруд идома медиҳем.
    SsoLinkService.instance.setPendingAuthorize(req);
    router.go(RouteNames.login);
    return;
  }
  if (_ssoAuthorizeBusy) return;
  _ssoAuthorizeBusy = true;
  try {
    final ctx = await _settledContext(router);
    if (ctx == null || !ctx.mounted) return;
    final user = ref.read(authProvider).user;
    final name = (user?.fullName.isNotEmpty ?? false)
        ? user!.fullName
        : (UserSession.fullName ?? '');
    final outcome = await SsoAuthorizeFlow.run(ctx, req, userName: name);
    if (outcome == SsoAuthorizeOutcome.needsLogin) {
      SsoLinkService.instance.setPendingAuthorize(req);
      await ref.read(authProvider.notifier).logout();
      router.go(RouteNames.login);
    }
  } finally {
    _ssoAuthorizeBusy = false;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale l) => ['tg', 'ru', 'en'].contains(l.languageCode);

  @override
  Future<AppL10n> load(Locale l) async => AppL10n(l.languageCode);

  @override
  bool shouldReload(_) => false;
}
