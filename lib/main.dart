import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/services/network_service.dart';
import 'core/services/server_wakeup_service.dart';
import 'core/services/user_session.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'routes/app_router.dart';
import 'core/app_l10n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light));
  try { await UserSession.loadCachedData(); } catch (_) {}
  try { NetworkService.instance.init(); } catch (_) {}
  try { ServerWakeupService.instance.wakeUp(); } catch (_) {}
  try { ServerWakeupService.instance.startKeepAlive(); } catch (_) {}
  runApp(const ProviderScope(child: TajikShopApp()));
}

class TajikShopApp extends ConsumerWidget {
  const TajikShopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router    = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);
    final locale    = ref.watch(localeProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'TajikShop',
      theme:     AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale:    locale,
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: LocaleNotifier.supported,
    );
  }
}
