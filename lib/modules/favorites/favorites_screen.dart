import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/app_l10n.dart';
import '../../core/l10n/extra_l10n.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../data/models/product_model.dart';
import '../../shared/widgets/shimmer_card.dart';
import '../../shared/widgets/error_screen.dart';

final favoritesProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final res = await ApiClient.instance.dio.get(ApiEndpoints.favorites);
  final data = res.data;
  List items = data is List ? data : (data['favorites'] ?? data['items'] ?? []);
  return items.map<ProductModel>((e) => ProductModel.fromJson((e['product'] ?? e) as Map<String, dynamic>)).toList();
});

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  static const _grid = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 0.66);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final favs = ref.watch(favoritesProvider);
    final count = favs.asData?.value.length;
    return Scaffold(
      backgroundColor: context.pal.scaffold,
      body: SafeArea(
        child: Column(children: [
          _header(context, l, count, () => ref.invalidate(favoritesProvider)),
          Expanded(
            child: favs.when(
              loading: () => GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                gridDelegate: _grid,
                itemCount: 6,
                itemBuilder: (_, __) => const ShimmerCard(),
              ),
              error: (e, _) => ErrorScreen(
                  message: e.toString(), onRetry: () => ref.invalidate(favoritesProvider)),
              data: (list) => list.isEmpty
                  ? _empty(context, l)
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      gridDelegate: _grid,
                      itemCount: list.length,
                      itemBuilder: (_, i) => _FavCard(
                        product: list[i],
                        onRemove: () async {
                          try {
                            await ApiClient.instance.dio.delete(ApiEndpoints.favoriteItem(list[i].id));
                            ref.invalidate(favoritesProvider);
                          } catch (_) {}
                        },
                      ),
                    ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _header(BuildContext context, AppL10n l, int? count, VoidCallback onRefresh) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00D084), Color(0xFF00A3FF)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const Icon(FeatherIcons.heart, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                l.favorites,
                style: TextStyle(color: context.pal.textPrimary, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3),
              ),
              if (count != null && count > 0) ...[
                const SizedBox(height: 2),
                Text(
                  '$count',
                  style: TextStyle(color: context.pal.textMuted, fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ],
            ]),
          ),
          IconButton(
            icon: Icon(FeatherIcons.refreshCw, color: context.pal.textSecondary),
            onPressed: onRefresh,
          ),
        ]),
      );

  Widget _empty(BuildContext context, AppL10n l) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.primary.withOpacity(0.16), const Color(0xFF00A3FF).withOpacity(0.16)],
                ),
              ),
              child: const Icon(FeatherIcons.heart, size: 56, color: AppColors.primary),
            ),
            const SizedBox(height: 22),
            Text(
              l.noFavorites,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.pal.textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 50,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () => context.go('/home'),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF00D084), Color(0xFF00A3FF)]),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6))],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 26),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(FeatherIcons.search, color: Colors.white, size: 18),
                        const SizedBox(width: 9),
                        Text(l.goSearch,
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      );
}

class _FavCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onRemove;
  const _FavCard({required this.product, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: context.pal.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.pal.border, width: 0.8),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            flex: 58,
            child: Stack(children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: product.mainImage.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.mainImage,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: context.pal.surface),
                        errorWidget: (_, __, ___) => Container(
                            color: context.pal.surface,
                            child: Icon(FeatherIcons.image, color: context.pal.textMuted)),
                      )
                    : Container(
                        color: context.pal.surface,
                        child: Icon(FeatherIcons.image, color: context.pal.textMuted)),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 1.2),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 10)],
                    ),
                    child: const Icon(FeatherIcons.heart, color: AppColors.primary, size: 16),
                  ),
                ),
              ),
            ]),
          ),
          Expanded(
            flex: 42,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.pal.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.3),
                  ),
                  Row(children: [
                    Expanded(
                      child: Text(
                        '${product.price.toStringAsFixed(0)} ${l.som}',
                        style: const TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF00D084), Color(0xFF00A3FF)]),
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: const Icon(FeatherIcons.chevronRight, color: Colors.white, size: 20),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
