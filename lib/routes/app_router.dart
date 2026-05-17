import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../modules/splash/splash_screen.dart';
import '../modules/auth/login_screen.dart';
import '../modules/auth/register_screen.dart';
import '../modules/auth/phone_auth_screen.dart';
import '../modules/home/home_screen.dart';
import '../modules/profile/profile_screen.dart';
import '../shared/widgets/main_scaffold.dart';
import 'route_names.dart';

// ✅ FIXED: Only imports EXISTING modules - no deleted directories referenced
final _goRouter = GoRouter(
  initialLocation: RouteNames.splash,
  errorBuilder: (_, __) => const Scaffold(
    backgroundColor: Color(0xFF0A0A0F),
    body: Center(
      child: Text('Саҳифа ёфт нашуд',
          style: TextStyle(color: Colors.white)))),
  routes: [
    GoRoute(path: RouteNames.splash,   builder: (_, __) => const SplashScreen()),
    GoRoute(path: RouteNames.login,    builder: (_, __) => const LoginScreen()),
    GoRoute(path: RouteNames.register, builder: (_, __) => const RegisterScreen()),
    GoRoute(path: RouteNames.phoneAuth, builder: (_, __) => const PhoneAuthScreen()),
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(path: RouteNames.home,
            pageBuilder: (_, __) => const NoTransitionPage(child: HomeScreen())),
        GoRoute(path: RouteNames.profile,
            pageBuilder: (_, __) => const NoTransitionPage(child: ProfileScreen())),
      ],
    ),
  ],
);

final routerProvider = Provider<GoRouter>((ref) => _goRouter);
