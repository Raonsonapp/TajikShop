import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../core/theme/app_motion.dart';
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
    // Шумораи сабад дар ҳамин ҷо лозим аст.
    //
    // Пештар корбар молро ба сабад мегузошт ва ҳеҷ нишонае намедид —
    // барои фаҳмидани он ки чанд мол дорад, бояд ба варақаи сабад
    // мерафт. Ин дар ҳар бозори ҷиддӣ ҳаст.
    final cartCount = ref.watch(cartProvider).itemCount;

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
                _tab(context, 3, idx, FeatherIcons.shoppingCart,
                    FeatherIcons.shoppingCart, RouteNames.cart,
                    badge: cartCount),
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

  /// Як варақаи панели поёнӣ.
  ///
  /// ЧАРО АЗ НАВ: пештар варақаи фаъол танҳо бо ранг ва нуқтаи 5-пикселӣ
  /// фарқ мекард — дар офтоб ё дар экрани арзон онро намебинӣ. Акнун
  /// заминаи мудаввари сабз зери нишона мебарояд ва нишона каме калон
  /// мешавад: ҳарду ҳаракат, на ранги хушки нав.
  Widget _tab(BuildContext context, int i, int current,
      IconData active, IconData inactive, String path,
      {int badge = 0}) {
    final sel = i == current;
    return Expanded(
      // Калид барои тести воқеӣ дар эмулятор — вагарна тугмаро аз рӯи
      // иконка ёфтан лозим мешуд, ки ҳангоми иваз шудани дизайн мешиканад.
      key: Key('nav_$i'),
      child: GestureDetector(
        onTap: () {
          // Такрори зери варақаи ҳозира ҳаракати бефоида медиҳад.
          if (sel) return;
          HapticFeedback.selectionClick();
          context.go(path);
        },
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: AppMotion.normal,
            curve: AppMotion.enter,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: sel
                  ? AppColors.primary.withValues(alpha: 0.13)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: AnimatedScale(
              scale: sel ? 1.08 : 1,
              duration: AppMotion.normal,
              curve: AppMotion.spring,
              child: _iconWithBadge(context, sel ? active : inactive,
                  sel ? AppColors.primary : context.pal.textMuted, badge),
            ),
          ),
        ),
      ),
    );
  }

  /// Нишона бо шумораи хурди сурх (сабад).
  Widget _iconWithBadge(
      BuildContext context, IconData icon, Color color, int count) {
    final badge = count > 99 ? '99+' : '$count';
    return Stack(clipBehavior: Clip.none, children: [
      Icon(icon, color: color, size: 24),
      // `AnimatedScale` бо `0` — нишона ҳангоми холӣ шудани сабад
      // ғайб мезанад, на фавран нопадид.
      Positioned(
        top: -5,
        right: -8,
        child: AnimatedScale(
          scale: count > 0 ? 1 : 0,
          duration: AppMotion.normal,
          curve: AppMotion.spring,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
            constraints: const BoxConstraints(minWidth: 17),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(9),
              // Ҳошияи ранги замина: бе он рақам ба нишона мечаспад.
              border: Border.all(color: context.pal.scaffold, width: 1.4),
            ),
            child: Text(badge,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    height: 1.25,
                    fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    ]);
  }

  // Профил ҳамчун аватар (мисли Instagram)
  Widget _profileTab(BuildContext context, bool sel, String? avatar) {
    return Expanded(
      key: const Key('nav_4'),
      child: GestureDetector(
        onTap: () {
          if (sel) return;
          HapticFeedback.selectionClick();
          context.go(RouteNames.profile);
        },
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: AppMotion.normal,
            curve: AppMotion.enter,
            width: sel ? 33 : 30,
            height: sel ? 33 : 30,
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: sel ? AppColors.primary : Colors.transparent,
                  width: 1.8),
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
