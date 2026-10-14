import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_motion.dart';
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
import '../modules/cargo/cargo_screen.dart';
import '../modules/rfq/rfq_list_screen.dart';
import '../modules/suppliers/suppliers_screen.dart';
import '../modules/seller/seller_orders_screen.dart';
import '../modules/wallet/wallet_screen.dart';
import '../modules/address/addresses_screen.dart';
import '../modules/shops/nearby_shops_screen.dart';
import '../modules/seller/seller_profile_screen.dart';
import '../modules/profile/verification_screen.dart';
import '../modules/admin/admin_verification_screen.dart';
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
          pageBuilder: (_, s) => DeepPage(
              key: s.pageKey,
              child: ProductDetailScreen(id: s.pathParameters['id']!))),
      GoRoute(path: '/messages', builder: (_, __) => const InboxScreen()),
      GoRoute(path: '/deals', builder: (_, __) => const DealsScreen()),
      GoRoute(path: '/bestsellers', builder: (_, __) => const BestsellersScreen()),
      GoRoute(path: '/cargo', builder: (_, __) => const CargoScreen()),
      // Дархости нарх (RFQ) — савдои яклухт.
      GoRoute(path: RouteNames.rfq, builder: (_, __) => const RFQListScreen()),
      // Ҷустуҷӯи таъминкунанда — барои савдои яклухт.
      GoRoute(path: RouteNames.suppliers,
          builder: (_, __) => const SuppliersScreen()),
      GoRoute(path: '/seller/orders', builder: (_, __) => const SellerOrdersScreen()),
      GoRoute(path: '/chat/:id',
          builder: (_, s) => ChatScreen(
                userId: s.pathParameters['id']!,
                userName: s.uri.queryParameters['name'] ?? 'Фурӯшанда',
              )),
      GoRoute(path: RouteNames.orders,          builder: (_, __) => const OrdersScreen()),
      GoRoute(path: '/orders/:id',
          pageBuilder: (_, s) =>
              DeepPage(key: s.pageKey, child: OrderDetailScreen(id: s.pathParameters['id']!))),
      GoRoute(path: RouteNames.notifications,   builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: RouteNames.categories,
          pageBuilder: (_, s) =>
              DeepPage(key: s.pageKey, child: const CategoriesScreen())),
      GoRoute(path: RouteNames.search,
          pageBuilder: (_, s) =>
              DeepPage(key: s.pageKey, child: const SearchScreen())),
      GoRoute(path: RouteNames.sellerDashboard, builder: (_, __) => const SellerDashboardScreen()),
      GoRoute(path: RouteNames.seller,          builder: (_, __) => const SellerDashboardScreen()),
      GoRoute(path: RouteNames.addProduct,
          pageBuilder: (_, s) =>
              SheetPage(key: s.pageKey, child: const AddProductScreen())),
      GoRoute(path: RouteNames.myProducts,      builder: (_, __) => const MyProductsScreen()),
      GoRoute(path: RouteNames.wallet,          builder: (_, __) => const WalletScreen()),
      GoRoute(path: RouteNames.addresses,       builder: (_, __) => const AddressesScreen()),
      GoRoute(path: RouteNames.nearbyShops,     builder: (_, __) => const NearbyShopsScreen()),
      GoRoute(path: RouteNames.verification,
          pageBuilder: (_, s) =>
              SheetPage(key: s.pageKey, child: const VerificationScreen())),
      GoRoute(path: RouteNames.adminVerification, builder: (_, __) => const AdminVerificationScreen()),
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
      GoRoute(path: RouteNames.adminCargo,      builder: (_, __) => const AdminCargoScreen()),
      GoRoute(path: RouteNames.sellerRequests,  builder: (_, __) => const AdminSellerRequestsScreen()),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          // Пештар ин ҷо `NoTransitionPage` буд — варақаҳо ФАВРАН
          // иваз мешуданд, бе ҳеҷ ҳаракат. Маҳз ҳаминро корбар ҳамчун
          // «барнома бе аниматсия» мебинад.
          //
          // «Fade through», на лағжиш: «Асосӣ» ва «Профил» зинаи
          // баробар доранд, ва лағжиш «ақиб/пеш» мегуфт — маънои
          // нодуруст.
          GoRoute(path: RouteNames.home,
              pageBuilder: (_, s) =>
                  FadeThroughPage(key: s.pageKey, child: const HomeScreen())),
          GoRoute(path: RouteNames.favorites,
              pageBuilder: (_, s) => FadeThroughPage(
                  key: s.pageKey, child: const FavoritesScreen())),
          GoRoute(path: RouteNames.upload,
              pageBuilder: (_, s) =>
                  FadeThroughPage(key: s.pageKey, child: const UploadScreen())),
          GoRoute(path: RouteNames.cart,
              pageBuilder: (_, s) =>
                  FadeThroughPage(key: s.pageKey, child: const CartScreen())),
          GoRoute(path: RouteNames.profile,
              pageBuilder: (_, s) =>
                  FadeThroughPage(key: s.pageKey, child: const ProfileScreen())),
        ],
      ),
    ],
  );
});
