import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';
import 'inline_ad.dart';

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
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AdBanner(), // реклама (агар фаъол бошад)
          Container(
        decoration: BoxDecoration(
          color: context.pal.scaffold,
          border: Border(top: BorderSide(color: context.pal.border, width: 0.5)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 52,
            child: Row(
              children: [
                _tab(context, 0, idx, FeatherIcons.home, FeatherIcons.home, RouteNames.home),
                _tab(context, 1, idx, FeatherIcons.heart, FeatherIcons.heart, RouteNames.favorites),
                _tab(context, 2, idx, FeatherIcons.plusSquare, FeatherIcons.plusSquare, RouteNames.upload),
                _tab(context, 3, idx, FeatherIcons.shoppingCart, FeatherIcons.shoppingCart, RouteNames.cart),
                _profileTab(context, idx == 4, user?.avatar),
              ],
            ),
          ),
        ),
          ),
        ],
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(sel ? active : inactive,
                color: sel ? AppColors.primary : context.pal.textMuted,
                size: 26),
            const SizedBox(height: 4),
            // Нуқтаи хурди сабз зери tab-и фаъол
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: sel ? 5 : 0,
              height: sel ? 5 : 0,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
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
                  color: sel ? context.pal.textPrimary : Colors.transparent, width: 1.6),
            ),
            child: CircleAvatar(
              radius: 13,
              backgroundColor: context.pal.surface,
              backgroundImage: (avatar != null && avatar.isNotEmpty)
                  ? CachedNetworkImageProvider(avatar) : null,
              child: (avatar == null || avatar.isEmpty)
                  ? const Icon(FeatherIcons.user, color: AppColors.textMuted, size: 18)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
