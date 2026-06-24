import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/app_l10n.dart';
import 'core/services/network_service.dart'; // ← ИЛОВА КУНЕД
import 'core/services/push_service.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'routes/app_router.dart';
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
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: LocaleNotifier.supported,
      builder: (context, child) => OfflineBanner(child: child ?? const SizedBox()),
    );
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
