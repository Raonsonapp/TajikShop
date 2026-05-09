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
    if (loc == RouteNames.upload) return 2;
    if (loc == RouteNames.cart) return 3;
    if (loc == RouteNames.profile) return 4;
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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_rounded, label: 'Хона',
                    index: 0, current: idx, onTap: () => context.go(RouteNames.home)),
                _NavItem(icon: Icons.favorite_border_rounded, label: 'Лайк',
                    index: 1, current: idx, onTap: () => context.go(RouteNames.favorites)),
                // Upload center button
                GestureDetector(
                  onTap: () => context.go(RouteNames.upload),
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 12, spreadRadius: 1)],
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                _NavItem(icon: Icons.shopping_bag_outlined, label: 'Сабад',
                    index: 3, current: idx, onTap: () => context.go(RouteNames.cart)),
                _NavItem(icon: Icons.person_outline_rounded, label: 'Профил',
                    index: 4, current: idx, onTap: () => context.go(RouteNames.profile)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index, current;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label,
      required this.index, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sel = index == current;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: sel ? AppColors.primary : AppColors.textMuted, size: 24),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(
            fontSize: 10,
            color: sel ? AppColors.primary : AppColors.textMuted,
            fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
        ]),
      ),
    );
  }
}
