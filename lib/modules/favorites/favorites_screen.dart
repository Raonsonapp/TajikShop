import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_colors.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../data/models/product_model.dart';
import '../../shared/widgets/shimmer_card.dart';

final favoritesProvider = FutureProvider<List<ProductModel>>((ref) async {
  final res = await ApiClient.instance.dio.get(ApiEndpoints.favorites);
  final data = res.data;
  List items = data is List ? data : (data['favorites'] ?? data['items'] ?? []);
  return items.map<ProductModel>((e) {
    final product = e['product'] ?? e;
    return ProductModel.fromJson(product as Map<String, dynamic>);
  }).toList();
});

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favs = ref.watch(favoritesProvider);
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        title: const Text('Дӯстдоштаҳо',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => ref.invalidate(favoritesProvider),
          ),
        ],
      ),
      body: favs.when(
        loading: () => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.68),
          itemCount: 6,
          itemBuilder: (_, __) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ShimmerCard(height: 150, radius: 16),
            const SizedBox(height: 8),
            ShimmerCard(height: 14, width: 120, radius: 4),
            const SizedBox(height: 4),
            ShimmerCard(height: 14, width: 80, radius: 4),
          ]),
        ),
        error: (_, __) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.favorite_outline, size: 80, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text('Дӯстдоштаҳо нест', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Маҳсулотҳоро ба дӯстдоштаҳо илова кунед',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13), textAlign: TextAlign.center),
          ]),
        ),
        data: (list) => list.isEmpty
            ? const Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.favorite_outline, size: 80, color: AppColors.textMuted),
                  SizedBox(height: 16),
                  Text('Дӯстдоштаҳо нест', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Маҳсулотҳоро ба дӯстдоштаҳо илова кунед',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13), textAlign: TextAlign.center),
                ]),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${list.length} маҳсулот',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Ҳамаро ба сабад',
                              style: TextStyle(color: AppColors.primary, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.68),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _FavCard(product: list[i], onRemove: () async {
                        try {
                          await ApiClient.instance.dio.delete(ApiEndpoints.favoriteItem(list[i].id));
                          ref.invalidate(favoritesProvider);
                        } catch (_) {}
                      }),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _FavCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onRemove;
  const _FavCard({required this.product, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Stack(children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: product.mainImage.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.mainImage,
                        width: double.infinity, fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppColors.bgSurface),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.bgSurface,
                          child: const Icon(Icons.image_outlined, color: AppColors.textMuted, size: 40)),
                      )
                    : Container(color: AppColors.bgSurface,
                        child: const Icon(Icons.image_outlined, color: AppColors.textMuted, size: 40)),
              ),
              Positioned(
                top: 8, right: 8,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.9), shape: BoxShape.circle),
                    child: const Icon(Icons.favorite, color: Colors.white, size: 14),
                  ),
                ),
              ),
              if (product.discountPercent > 0)
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(6)),
                    child: Text('-${product.discountPercent}%',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.star_rounded, size: 12, color: AppColors.warning),
                const SizedBox(width: 2),
                Text(product.rating.toStringAsFixed(1),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
              ]),
              const SizedBox(height: 6),
              Text('${product.price.toStringAsFixed(0)} сом.',
                  style: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
      ),
    );
  }
}
