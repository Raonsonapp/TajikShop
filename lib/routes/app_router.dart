import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: false,
    errorBuilder: (_, __) => const Scaffold(
      backgroundColor: Color(0xFF0A0A0F),
      body: Center(
        child: Text('Саҳифа ёфт нашуд',
            style: TextStyle(color: Colors.white)),
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
        path: RouteNames.categories,
        builder: (_, __) => const CategoriesScreen(),
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
      // Shell with bottom nav - LAST
      ShellRoute(
        builder: (context, state, child) =>
            MainScaffold(child: child),
        routes: [
          GoRoute(
            path: RouteNames.home,
            pageBuilder: (_, __) => const NoTransitionPage(
                child: HomeScreen()),
          ),
          GoRoute(
            path: RouteNames.search,
            pageBuilder: (_, __) => const NoTransitionPage(
                child: SearchScreen()),
          ),
          GoRoute(
            path: RouteNames.favorites,
            pageBuilder: (_, __) => const NoTransitionPage(
                child: FavoritesScreen()),
          ),
          GoRoute(
            path: RouteNames.cart,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: CartScreen()),
          ),
          GoRoute(
            path: RouteNames.profile,
            pageBuilder: (_, __) => const NoTransitionPage(
                child: ProfileScreen()),
          ),
        ],
      ),
    ],
  );
});
