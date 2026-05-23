import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
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
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favs = ref.watch(favoritesProvider);
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(backgroundColor: AppColors.bgDark,
        title: const Text('Дӯстдоштаҳо', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => ref.invalidate(favoritesProvider))]),
      body: favs.when(
        loading: () => GridView.builder(padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.68),
          itemCount: 6, itemBuilder: (_, __) => const ShimmerCard()),
        error: (e, _) => ErrorScreen(message: e.toString(), onRetry: () => ref.invalidate(favoritesProvider)),
        data: (list) => list.isEmpty
            ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.favorite_outline, size: 80, color: AppColors.textMuted),
                SizedBox(height: 16),
                Text('Дӯстдоштаҳо нест', style: TextStyle(color: AppColors.textSecondary, fontSize: 16))]))
            : GridView.builder(padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.68),
                itemCount: list.length,
                itemBuilder: (_, i) => _FavCard(product: list[i], onRemove: () async {
                  try {
                    await ApiClient.instance.dio.delete(ApiEndpoints.favoriteItem(list[i].id));
                    ref.invalidate(favoritesProvider);
                  } catch (_) {}
                })),
      ),
    );
  }
}

class _FavCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onRemove;
  const _FavCard({required this.product, required this.onRemove});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push('/product/${product.id}'),
    child: Container(
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Stack(children: [
          ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: product.mainImage.isNotEmpty
                ? CachedNetworkImage(imageUrl: product.mainImage, width: double.infinity, fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.bgSurface),
                    errorWidget: (_, __, ___) => Container(color: AppColors.bgSurface,
                        child: const Icon(Icons.image_outlined, color: AppColors.textMuted)))
                : Container(color: AppColors.bgSurface,
                    child: const Icon(Icons.image_outlined, color: AppColors.textMuted))),
          Positioned(top: 8, right: 8, child: GestureDetector(onTap: onRemove,
            child: Container(padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
              child: const Icon(Icons.favorite, color: Colors.white, size: 14)))),
        ])),
        Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(product.title, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('${product.price.toStringAsFixed(0)} сом.',
              style: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700)),
        ])),
      ]),
    ));
}
