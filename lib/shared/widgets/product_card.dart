import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/product_model.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  const ProductCard({
    super.key,
    required this.product,
    this.onFavorite,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    final discount = product.computedDiscount;
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Stack(children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: product.mainImage.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.mainImage,
                          width: double.infinity, fit: BoxFit.cover,
                          placeholder: (_, __) => _shimmer(),
                          errorWidget: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                // Discount badge
                if (discount > 0)
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                          color: AppColors.error, borderRadius: BorderRadius.circular(6)),
                      child: Text('-$discount%',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ),
                // Favorite
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: onFavorite,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: AppColors.bgDark.withOpacity(0.7), shape: BoxShape.circle),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? AppColors.error : AppColors.textSecondary,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ]),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(product.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.star_rounded, size: 12, color: AppColors.warning),
                  const SizedBox(width: 2),
                  Text(product.rating.toStringAsFixed(1),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  const SizedBox(width: 6),
                  if (product.views > 0)
                    Text('${product.views} кӯр.',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                ]),
                const SizedBox(height: 6),
                Text('${product.price.toStringAsFixed(0)} сом.',
                    style: const TextStyle(
                        color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700)),
                if (product.oldPrice != null)
                  Text('${product.oldPrice!.toStringAsFixed(0)} сом.',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11,
                          decoration: TextDecoration.lineThrough)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmer() => Shimmer.fromColors(
        baseColor: AppColors.shimmerBase, highlightColor: AppColors.shimmerHighlight,
        child: Container(color: AppColors.shimmerBase));

  Widget _placeholder() => Container(
        color: AppColors.bgSurface,
        child: const Center(child: Icon(Icons.image_outlined, color: AppColors.textMuted, size: 40)));
}
