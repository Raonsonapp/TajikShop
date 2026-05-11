import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/product_model.dart';
import '../../providers/favorites_provider.dart';

class ProductCard extends ConsumerStatefulWidget {
  final ProductModel product;
  const ProductCard({super.key, required this.product});

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartCtrl;
  late Animation<double> _heartScale;
  late Animation<double> _heartOpacity;

  @override
  void initState() {
    super.initState();
    _heartCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _heartScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _heartCtrl, curve: Curves.elasticOut));
    _heartOpacity = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _heartCtrl, curve: const Interval(0, 0.3)));
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    super.dispose();
  }

  void _toggleFav() {
    HapticFeedback.lightImpact();
    _heartCtrl.forward(from: 0);
    ref.read(favoritesProvider.notifier).toggle(widget.product.id);
  }

  @override
  Widget build(BuildContext context) {
    final p       = widget.product;
    final discount = p.computedDiscount;
    final favIds  = ref.watch(favoritesProvider);
    final isFav   = favIds.contains(p.id);

    return GestureDetector(
      onTap: () => context.push('/product/${p.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.28),
                blurRadius: 16, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Image ──────────────────────────────────────────────────
          Expanded(
            flex: 6,
            child: Stack(children: [
              // Main image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: p.mainImage.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: p.mainImage,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _shimmer(),
                        errorWidget: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),

              // Gradient overlay bottom of image
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.55),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Discount badge
              if (discount > 0)
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)]),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(
                        color: const Color(0xFFFF416C).withOpacity(0.4),
                        blurRadius: 6)]),
                    child: Text('-$discount%',
                        style: const TextStyle(color: Colors.white,
                            fontSize: 10, fontWeight: FontWeight.w800)))),

              // 💚 Favorite button — САБЗ
              Positioned(
                top: 8, right: 8,
                child: GestureDetector(
                  onTap: _toggleFav,
                  child: ScaleTransition(
                    scale: _heartScale,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: isFav
                            ? const Color(0xFF00D084).withOpacity(0.2)
                            : Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: isFav
                                ? const Color(0xFF00D084)
                                : Colors.white24,
                            width: 1.2),
                        boxShadow: isFav
                            ? [BoxShadow(
                                color: const Color(0xFF00D084).withOpacity(0.35),
                                blurRadius: 8)]
                            : null,
                      ),
                      child: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        // 💚 Сабз — AppColors.primary (#00D084)
                        color: isFav ? const Color(0xFF00D084) : Colors.white70,
                        size: 16),
                    ),
                  ),
                ),
              ),

              // Out of stock overlay
              if (!p.inStock)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Container(
                      color: Colors.black.withOpacity(0.6),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white24)),
                        child: const Text('Тамом шуд',
                            style: TextStyle(color: Colors.white60, fontSize: 11,
                                fontWeight: FontWeight.w600))),
                    ),
                  ),
                ),

              // Like + comment row (bottom of image, overlay)
              Positioned(
                bottom: 6, left: 8, right: 8,
                child: Row(children: [
                  // Like count
                  _OverlayChip(
                    icon: Icons.favorite_rounded,
                    color: const Color(0xFF00D084),
                    label: p.reviewCount > 0 ? '${p.reviewCount}' : '',
                  ),
                  const SizedBox(width: 6),
                  // Comment count (review count дар ин ҷо)
                  _OverlayChip(
                    icon: Icons.chat_bubble_rounded,
                    color: const Color(0xFF00A3FF),
                    label: p.reviewCount > 0 ? '${p.reviewCount}' : '',
                  ),
                  const Spacer(),
                  // Views
                  if (p.views > 0)
                    _OverlayChip(
                      icon: Icons.remove_red_eye_rounded,
                      color: Colors.white60,
                      label: p.views > 999 ? '${(p.views / 1000).toStringAsFixed(1)}к' : '${p.views}',
                    ),
                ]),
              ),
            ]),
          ),

          // ── Info ──────────────────────────────────────────────────
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title
                  Text(p.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.3)),

                  // Rating row
                  Row(children: [
                    const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFB800)),
                    const SizedBox(width: 2),
                    Text(p.rating.toStringAsFixed(1),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 10)),
                    if (p.reviewCount > 0) ...[
                      const SizedBox(width: 3),
                      Text('(${p.reviewCount})',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 10)),
                    ],
                  ]),

                  // Price + Cart
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${p.price.toStringAsFixed(0)} сом.',
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800)),
                            if (p.oldPrice != null)
                              Text('${p.oldPrice!.toStringAsFixed(0)} сом.',
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 10,
                                      decoration: TextDecoration.lineThrough)),
                          ],
                        ),
                      ),
                      // Add to cart button
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          // TODO: add to cart
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: [BoxShadow(
                              color: AppColors.primary.withOpacity(0.35),
                              blurRadius: 8, offset: const Offset(0, 3))]),
                          child: const Icon(
                              Icons.add_shopping_cart_rounded,
                              color: Colors.white, size: 14)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _shimmer() => Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(color: AppColors.shimmerBase));

  Widget _placeholder() => Container(
      color: AppColors.bgSurface,
      child: const Center(
          child: Icon(Icons.image_outlined,
              color: AppColors.textMuted, size: 40)));
}

// ── Overlay chip (like/comment/view) ──────────────────────────────────────────
class _OverlayChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _OverlayChip({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        if (label.isNotEmpty) ...[
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(color: color, fontSize: 9,
                  fontWeight: FontWeight.w600)),
        ],
      ]),
    );
  }
}
