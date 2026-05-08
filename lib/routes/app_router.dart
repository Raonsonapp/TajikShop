import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../modules/splash/splash_screen.dart';
import '../modules/auth/login_screen.dart';
import '../modules/auth/register_screen.dart';
import '../modules/home/home_screen.dart';
import '../modules/search/search_screen.dart';
import '../modules/categories/categories_screen.dart';
import '../modules/product/product_detail_screen.dart';
import '../modules/cart/cart_screen.dart';
import '../modules/orders/orders_screen.dart';
import '../modules/favorites/favorites_screen.dart';
import '../modules/notifications/notifications_screen.dart';
import '../modules/profile/profile_screen.dart';
import '../modules/seller/seller_dashboard_screen.dart';
import '../modules/seller/add_product_screen.dart';
import '../modules/admin/admin_dashboard_screen.dart';
import '../shared/widgets/main_scaffold.dart';
import 'route_names.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    redirect: (context, state) {
      final isAuth = authState.isAuthenticated;
      final loc = state.matchedLocation;
      final isSplash = loc == RouteNames.splash;
      final isAuthPage =
          loc == RouteNames.login || loc == RouteNames.register;

      if (isSplash) return null;
      if (!isAuth && !isAuthPage) return RouteNames.login;
      if (isAuth && isAuthPage) return RouteNames.home;
      return null;
    },
    errorBuilder: (_, state) => Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Center(
        child: Text(
          'Саҳифа ёфт нашуд\n${state.error}',
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    ),
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (_, __) => const RegisterScreen(),
      ),

      // Main shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: RouteNames.home,
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: RouteNames.search,
            builder: (_, __) => const SearchScreen(),
          ),
          GoRoute(
            path: RouteNames.favorites,
            builder: (_, __) => const FavoritesScreen(),
          ),
          GoRoute(
            path: RouteNames.cart,
            builder: (_, __) => const CartScreen(),
          ),
          GoRoute(
            path: RouteNames.profile,
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),

      // Push routes (no bottom nav)
      GoRoute(
        path: RouteNames.categories,
        builder: (_, __) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (_, state) =>
            ProductDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RouteNames.orders,
        builder: (_, __) => const OrdersScreen(),
      ),
      GoRoute(
        path: RouteNames.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: RouteNames.seller,
        builder: (_, __) => const SellerDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.addProduct,
        builder: (_, __) => const AddProductScreen(),
      ),
      GoRoute(
        path: RouteNames.admin,
        builder: (_, __) => const AdminDashboardScreen(),
      ),
    ],
  );
});
