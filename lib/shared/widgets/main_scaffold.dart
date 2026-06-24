import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  int _index(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc == RouteNames.favorites) return 1;
    if (loc == RouteNames.upload)    return 2;
    if (loc == RouteNames.cart)      return 3;
    if (loc == RouteNames.profile)   return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx = _index(context);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgDark,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 52,
            child: Row(
              children: [
                _tab(context, 0, idx, Icons.home, Icons.home_outlined, RouteNames.home),
                _tab(context, 1, idx, Icons.favorite, Icons.favorite_border, RouteNames.favorites),
                _tab(context, 2, idx, Icons.add_box, Icons.add_box_outlined, RouteNames.upload),
                _tab(context, 3, idx, Icons.shopping_bag, Icons.shopping_bag_outlined, RouteNames.cart),
                _profileTab(context, idx == 4, user?.avatar),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, int i, int current,
      IconData active, IconData inactive, String path) {
    final sel = i == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => context.go(path),
        behavior: HitTestBehavior.opaque,
        child: Icon(sel ? active : inactive, color: Colors.white, size: 28),
      ),
    );
  }

  // Профил ҳамчун аватар (мисли Instagram)
  Widget _profileTab(BuildContext context, bool sel, String? avatar) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.go(RouteNames.profile),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Container(
            width: 30, height: 30,
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: sel ? Colors.white : Colors.transparent, width: 1.6),
            ),
            child: CircleAvatar(
              radius: 13,
              backgroundColor: AppColors.bgSurface,
              backgroundImage: (avatar != null && avatar.isNotEmpty)
                  ? CachedNetworkImageProvider(avatar) : null,
              child: (avatar == null || avatar.isEmpty)
                  ? const Icon(Icons.person, color: AppColors.textMuted, size: 18)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
