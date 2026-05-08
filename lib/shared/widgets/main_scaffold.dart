import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../routes/route_names.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith(RouteNames.search)) return 1;
    if (loc.startsWith(RouteNames.favorites)) return 2;
    if (loc.startsWith(RouteNames.cart)) return 3;
    if (loc.startsWith(RouteNames.profile)) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgCard,
          border: Border(
              top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Хона',
                  index: 0,
                  current: idx,
                  onTap: () => context.go(RouteNames.home),
                ),
                _NavItem(
                  icon: Icons.search_rounded,
                  label: 'Ҷустуҷӯ',
                  index: 1,
                  current: idx,
                  onTap: () => context.go(RouteNames.search),
                ),
                _NavItem(
                  icon: Icons.favorite_border_rounded,
                  label: 'Дӯст',
                  index: 2,
                  current: idx,
                  onTap: () => context.go(RouteNames.favorites),
                ),
                _NavItem(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Сабад',
                  index: 3,
                  current: idx,
                  onTap: () => context.go(RouteNames.cart),
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Профил',
                  index: 4,
                  current: idx,
                  onTap: () => context.go(RouteNames.profile),
                ),
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
  final int index;
  final int current;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color:
                    selected ? AppColors.primary : AppColors.textMuted,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: selected ? AppColors.primary : AppColors.textMuted,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
