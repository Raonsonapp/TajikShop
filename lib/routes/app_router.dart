import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../modules/splash/splash_screen.dart';
import '../modules/auth/login_screen.dart';
import '../modules/auth/register_screen.dart';
import '../modules/auth/phone_auth_screen.dart';
import '../modules/home/home_screen.dart';
import '../modules/upload/upload_screen.dart';
import '../modules/categories/categories_screen.dart';
import '../modules/product/product_detail_screen.dart';
import '../modules/cart/cart_screen.dart';
import '../modules/orders/orders_screen.dart';
import '../modules/orders/order_detail_screen.dart';
import '../modules/favorites/favorites_screen.dart';
import '../modules/notifications/notifications_screen.dart';
import '../modules/profile/profile_screen.dart';
import '../modules/seller/seller_dashboard_screen.dart';
import '../modules/seller/add_product_screen.dart';
import '../modules/seller/my_products_screen.dart';
import '../modules/admin/admin_dashboard_screen.dart';
import '../modules/admin/admin_management_screens.dart';
import '../modules/search/search_screen.dart';
import '../modules/chat/chat_screen.dart';
import '../modules/chat/inbox_screen.dart';
import '../modules/deals/deals_screen.dart';
import '../modules/deals/bestsellers_screen.dart';
import '../modules/seller/seller_orders_screen.dart';
import '../modules/wallet/wallet_screen.dart';
import '../modules/address/addresses_screen.dart';
import '../modules/shops/nearby_shops_screen.dart';
import '../modules/seller/seller_profile_screen.dart';
import '../shared/widgets/main_scaffold.dart';
import '../providers/auth_provider.dart';
import 'route_names.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.splash,
    routes: [
      GoRoute(path: RouteNames.splash,    builder: (_, __) => const SplashScreen()),
      GoRoute(path: RouteNames.login,     builder: (_, __) => const LoginScreen()),
      GoRoute(path: RouteNames.register,  builder: (_, __) => const RegisterScreen()),
      GoRoute(path: RouteNames.phoneAuth, builder: (_, __) => const PhoneAuthScreen()),
      GoRoute(path: '/product/:id',
          builder: (_, s) => ProductDetailScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/messages', builder: (_, __) => const InboxScreen()),
      GoRoute(path: '/deals', builder: (_, __) => const DealsScreen()),
      GoRoute(path: '/bestsellers', builder: (_, __) => const BestsellersScreen()),
      GoRoute(path: '/seller/orders', builder: (_, __) => const SellerOrdersScreen()),
      GoRoute(path: '/chat/:id',
          builder: (_, s) => ChatScreen(
                userId: s.pathParameters['id']!,
                userName: s.uri.queryParameters['name'] ?? 'Фурӯшанда',
              )),
      GoRoute(path: RouteNames.orders,          builder: (_, __) => const OrdersScreen()),
      GoRoute(path: '/orders/:id',              builder: (_, s) => OrderDetailScreen(id: s.pathParameters['id']!)),
      GoRoute(path: RouteNames.notifications,   builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: RouteNames.categories,      builder: (_, __) => const CategoriesScreen()),
      GoRoute(path: RouteNames.search,          builder: (_, __) => const SearchScreen()),
      GoRoute(path: RouteNames.sellerDashboard, builder: (_, __) => const SellerDashboardScreen()),
      GoRoute(path: RouteNames.seller,          builder: (_, __) => const SellerDashboardScreen()),
      GoRoute(path: RouteNames.addProduct,      builder: (_, __) => const AddProductScreen()),
      GoRoute(path: RouteNames.myProducts,      builder: (_, __) => const MyProductsScreen()),
      GoRoute(path: RouteNames.wallet,          builder: (_, __) => const WalletScreen()),
      GoRoute(path: RouteNames.addresses,       builder: (_, __) => const AddressesScreen()),
      GoRoute(path: RouteNames.nearbyShops,     builder: (_, __) => const NearbyShopsScreen()),
      GoRoute(path: '/seller/:id',
          builder: (_, s) => SellerProfileScreen(
                id: s.pathParameters['id']!,
                name: s.uri.queryParameters['name'] ?? 'Фурӯшанда')),
      GoRoute(path: RouteNames.admin,           builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(path: RouteNames.adminUsers,      builder: (_, __) => const AdminUsersScreen()),
      GoRoute(path: RouteNames.adminOrders,     builder: (_, __) => const AdminOrdersScreen()),
      GoRoute(path: RouteNames.adminCategories, builder: (_, __) => const AdminCategoriesScreen()),
      GoRoute(path: RouteNames.adminCoupons,    builder: (_, __) => const AdminCouponsScreen()),
      GoRoute(path: RouteNames.adminWallet,     builder: (_, __) => const AdminWalletScreen()),
      GoRoute(path: RouteNames.adminReports,    builder: (_, __) => const AdminReportsScreen()),
      GoRoute(path: RouteNames.adminReturns,    builder: (_, __) => const AdminReturnsScreen()),
      GoRoute(path: RouteNames.sellerRequests,  builder: (_, __) => const AdminSellerRequestsScreen()),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: RouteNames.home,
              pageBuilder: (_, __) => const NoTransitionPage(child: HomeScreen())),
          GoRoute(path: RouteNames.favorites,
              pageBuilder: (_, __) => const NoTransitionPage(child: FavoritesScreen())),
          GoRoute(path: RouteNames.upload,
              pageBuilder: (_, __) => const NoTransitionPage(child: UploadScreen())),
          GoRoute(path: RouteNames.cart,
              pageBuilder: (_, __) => const NoTransitionPage(child: CartScreen())),
          GoRoute(path: RouteNames.profile,
              pageBuilder: (_, __) => const NoTransitionPage(child: ProfileScreen())),
        ],
      ),
    ],
  );
});
