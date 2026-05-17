import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'core/app_l10n.dart';

// ── Splash ──────────────────────────────────────────────────────
import 'modules/splash/splash_screen.dart';
import 'modules/auth/login_screen.dart';
import 'modules/auth/register_screen.dart';
import 'modules/home/home_screen.dart';
import 'modules/profile/profile_screen.dart';
import 'shared/widgets/main_scaffold.dart';

// FIX: routerProvider мустақиман дар main.dart — import мушкили нест
final _router = GoRouter(
  initialLocation: '/',
  errorBuilder: (_, __) => const Scaffold(
    backgroundColor: Color(0xFF0A0A0F),
    body: Center(child: Text('404', style: TextStyle(color: Colors.white)))),
  routes: [
    GoRoute(path: '/',        builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login',   builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register',builder: (_, __) => const RegisterScreen()),
    ShellRoute(
      builder: (ctx, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(path: '/home',
            pageBuilder: (_, __) => const NoTransitionPage(child: HomeScreen())),
        GoRoute(path: '/profile',
            pageBuilder: (_, __) => const NoTransitionPage(child: ProfileScreen())),
      ],
    ),
  ],
);

final routerProvider = Provider<GoRouter>((ref) => _router);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    final router    = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);
    final locale    = ref.watch(localeProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'TajikShop',
      theme:        AppTheme.lightTheme,
      darkTheme:    AppTheme.darkTheme,
      themeMode:    themeMode,
      locale:       locale,
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
