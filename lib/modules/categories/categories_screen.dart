import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../core/app_l10n.dart';
import '../../core/l10n/shop_l10n.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../routes/route_names.dart';
import '../../providers/search_provider.dart';
import '../../data/models/category_model.dart';
import '../../shared/widgets/shimmer_card.dart';

/// Экрани рӯйхати категорияҳо — намуди «staggered» бо аксенти сабз.
/// Тап -> ҷустуҷӯ аз рӯи номи категория (searchQueryProvider + RouteNames.search).
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  // Гардиенти сабз (талаботи accent)
  static const _greenGradient = LinearGradient(
    colors: [Color(0xFF00D084), Color(0xFF00A3FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Баландиҳои гуногун барои намуди staggered
  static const _tileHeights = [210.0, 158.0, 240.0, 176.0, 196.0, 150.0];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: context.pal.scaffold,
      appBar: AppBar(
        backgroundColor: context.pal.scaffold,
        elevation: 0,
        leading: IconButton(
          icon: Icon(FeatherIcons.chevronLeft,
              color: context.pal.textPrimary, size: 20),
          onPressed: () => Navigator.canPop(context)
              ? Navigator.pop(context)
              : context.go(RouteNames.home),
        ),
        title: Text(
          AppL10n.of(context).categories,
          style: TextStyle(
              color: context.pal.textPrimary, fontWeight: FontWeight.w700),
        ),
      ),
      body: cats.when(
        loading: () => _buildLoading(context),
        error: (_, __) => _buildError(context, ref),
        data: (list) {
          if (list.isEmpty) return _buildEmpty(context);
          return MasonryGridView.count(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            itemCount: list.length,
            itemBuilder: (_, i) => _CategoryTile(
              category: list[i],
              height: _tileHeights[i % _tileHeights.length],
              gradient: _greenGradient,
              onTap: () {
                ref.read(searchQueryProvider.notifier).state = list[i].name;
                context.push(RouteNames.search);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoading(BuildContext context) => MasonryGridView.count(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        itemCount: 8,
        itemBuilder: (_, i) => ShimmerCard(
          height: _tileHeights[i % _tileHeights.length],
          radius: 20,
        ),
      );

  Widget _buildError(BuildContext context, WidgetRef ref) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FeatherIcons.wifiOff,
                size: 60, color: context.pal.textMuted),
            const SizedBox(height: 14),
            Text(AppL10n.of(context).error,
                style: TextStyle(color: context.pal.textSecondary, fontSize: 14)),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () => ref.invalidate(categoriesProvider),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                foregroundColor: AppColors.primary,
              ),
              child: Text(AppL10n.of(context).retry),
            ),
          ],
        ),
      );

  Widget _buildEmpty(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FeatherIcons.grid,
                size: 70, color: context.pal.textMuted),
            const SizedBox(height: 14),
            Text(AppL10n.of(context).selectCategory,
                style: TextStyle(color: context.pal.textSecondary, fontSize: 14)),
          ],
        ),
      );
}

class _CategoryTile extends StatelessWidget {
  final CategoryModel category;
  final double height;
  final Gradient gradient;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.height,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: context.pal.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.pal.border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Расм ё гардиенти сабз ҳамчун замина
            _buildImage(context),

            // Overlay-и нарм барои хондани матн
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: height * 0.62,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xE6000000), Color(0x00000000)],
                  ),
                ),
              ),
            ),

            // Нишони теъдоди маҳсулот (аксенти сабз)
            if (category.productCount > 0)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    '${category.productCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

            // Ном + тугмаи «намоиш»
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      AppL10n.of(context).categoryViewAction,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final img = category.image;
    if (img == null || img.isEmpty) return _fallback();
    final url = img.startsWith('http')
        ? img
        : 'https://mahmadmurodov-tajikshop.hf.space$img';
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        decoration: BoxDecoration(gradient: gradient),
      ),
      errorWidget: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() => Container(
        decoration: BoxDecoration(gradient: gradient),
        child: const Center(
          child: Icon(FeatherIcons.grid, color: Colors.white, size: 44),
        ),
      );
}
