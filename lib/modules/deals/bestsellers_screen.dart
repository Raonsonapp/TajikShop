import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/flash_deals_provider.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/shimmer_card.dart';

/// Саҳифаи «Серхаридортарин» — маҳсулоти аз рӯи фурӯши воқеӣ рейтингшуда,
/// бо рақами ҷойгоҳ (1, 2, 3…) дар кунҷи корт.
class BestsellersScreen extends ConsumerWidget {
  const BestsellersScreen({super.key});

  static const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: 14,
    crossAxisSpacing: 14,
    childAspectRatio: 0.62,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pal = context.pal;
    final async = ref.watch(bestsellersProvider);

    return Scaffold(
      backgroundColor: pal.scaffold,
      appBar: AppBar(
        backgroundColor: pal.scaffold,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(FeatherIcons.chevronLeft, color: pal.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(FeatherIcons.award, color: Color(0xFFFFB800), size: 18),
          const SizedBox(width: 8),
          Text('Серхаридортарин',
              style: TextStyle(
                  color: pal.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 17)),
        ]),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(bestsellersProvider),
        child: async.when(
          loading: () => GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: _gridDelegate,
            itemCount: 6,
            itemBuilder: (_, __) =>
                const ShimmerCard(height: double.infinity, radius: 20),
          ),
          error: (_, __) => _empty(pal),
          data: (list) {
            if (list.isEmpty) return _empty(pal);
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: _gridDelegate,
              itemCount: list.length,
              itemBuilder: (_, i) => Stack(children: [
                ProductCard(product: list[i]),
                if (i < 3)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i == 0
                            ? const Color(0xFFFFB800)
                            : (i == 1
                                ? const Color(0xFF9AA5B1)
                                : const Color(0xFFCD7F32)),
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(color: Colors.black38, blurRadius: 6),
                        ],
                      ),
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
              ]),
            );
          },
        ),
      ),
    );
  }

  Widget _empty(AppPalette pal) => ListView(
        children: [
          const SizedBox(height: 120),
          Icon(FeatherIcons.award, size: 56, color: pal.textMuted),
          const SizedBox(height: 16),
          Center(
            child: Text('Ҳоло фурӯш нест',
                style: TextStyle(color: pal.textSecondary, fontSize: 15)),
          ),
        ],
      );
}
