import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../routes/route_names.dart';

class MainScaffold extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final idx = _index(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgCard,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _tab(context, 0, idx, Icons.home_rounded, Icons.home_outlined, RouteNames.home),
                _tab(context, 1, idx, Icons.favorite_rounded, Icons.favorite_border_rounded, RouteNames.favorites),
                _uploadTab(context),
                _tab(context, 3, idx, Icons.shopping_bag_rounded, Icons.shopping_bag_outlined, RouteNames.cart),
                _tab(context, 4, idx, Icons.person_rounded, Icons.person_outline, RouteNames.profile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, int i, int current, IconData active, IconData inactive, String path) {
    final sel = i == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => context.go(path),
        behavior: HitTestBehavior.opaque,
        child: Icon(sel ? active : inactive,
            color: sel ? AppColors.primary : AppColors.textMuted, size: 26),
      ),
    );
  }

  Widget _uploadTab(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.go(RouteNames.upload),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 12)],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
