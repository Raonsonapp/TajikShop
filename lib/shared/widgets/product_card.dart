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
  final bool isWide;
  const ProductCard({super.key, required this.product, this.isWide = false});

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.45), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.45, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _toggleFav() {
    HapticFeedback.lightImpact();
    _ctrl.forward(from: 0);
    ref.read(favoritesProvider.notifier).toggle(widget.product.id);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final disc = p.computedDiscount;
    final isFav = ref.watch(favoritesProvider).contains(p.id);

    return GestureDetector(
      onTap: () => context.push('/product/${p.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2A2A3E), width: 0.8),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.35),
                blurRadius: 18, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── IMAGE ZONE ─────────────────────────────────────────
          Expanded(
            flex: 58,
            child: Stack(children: [

              // Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: p.mainImage.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: p.mainImage,
                        width: double.infinity, height: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _shimmer(),
                        errorWidget: (_, __, ___) => _noImage())
                    : _noImage(),
              ),

              // Bottom gradient
              Positioned(bottom: 0, left: 0, right: 0,
                child: Container(height: 60,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.7), Colors.transparent])))),

              // Discount badge
              if (disc > 0)
                Positioned(top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)]),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(
                          color: const Color(0xFFFF416C).withOpacity(0.5), blurRadius: 8)]),
                    child: Text('-$disc%',
                        style: const TextStyle(color: Colors.white,
                            fontSize: 10, fontWeight: FontWeight.w900)))),

              // 💚 Fav button
              Positioned(top: 8, right: 8,
                child: GestureDetector(
                  onTap: _toggleFav,
                  child: ScaleTransition(
                    scale: _scale,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFav
                            ? const Color(0xFF00D084).withOpacity(0.2)
                            : Colors.black.withOpacity(0.55),
                        border: Border.all(
                            color: isFav ? const Color(0xFF00D084) : Colors.white24,
                            width: 1.2),
                        boxShadow: isFav ? [BoxShadow(
                            color: const Color(0xFF00D084).withOpacity(0.4), blurRadius: 10)] : null),
                      child: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFav ? const Color(0xFF00D084) : Colors.white60,
                        size: 15))))),

              // Out of stock
              if (!p.inStock)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Container(color: Colors.black.withOpacity(0.65),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white24)),
                        child: const Text('Тамом шуд',
                            style: TextStyle(color: Colors.white70, fontSize: 11,
                                fontWeight: FontWeight.w700)))))),

              // Like + comment chips (bottom overlay)
              Positioned(bottom: 6, left: 8, right: 8,
                child: Row(children: [
                  _Chip(icon: Icons.favorite_rounded,
                      color: const Color(0xFF00D084),
                      label: p.likeCount > 0 ? '${p.likeCount}' : ''),
                  const SizedBox(width: 5),
                  _Chip(icon: Icons.chat_bubble_rounded,
                      color: const Color(0xFF00A3FF),
                      label: p.reviewCount > 0 ? '${p.reviewCount}' : ''),
                  const Spacer(),
                  if (p.views > 0)
                    _Chip(icon: Icons.remove_red_eye_rounded,
                        color: Colors.white54,
                        label: p.views > 999
                            ? '${(p.views / 1000).toStringAsFixed(1)}к'
                            : '${p.views}'),
                ])),
            ]),
          ),

          // ── INFO ZONE ──────────────────────────────────────────
          Expanded(
            flex: 42,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title
                  Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white,
                          fontSize: 12, fontWeight: FontWeight.w600, height: 1.35)),

                  // Rating
                  Row(children: [
                    const Icon(Icons.star_rounded, size: 11, color: Color(0xFFFFB800)),
                    const SizedBox(width: 2),
                    Text(p.rating.toStringAsFixed(1),
                        style: const TextStyle(color: Color(0xFFAAADBE), fontSize: 10)),
                    if (p.reviewCount > 0) ...[
                      const SizedBox(width: 2),
                      Text('(${p.reviewCount})',
                          style: const TextStyle(color: Color(0xFF6B6E82), fontSize: 10)),
                    ],
                  ]),

                  // Price + cart
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${p.price.toStringAsFixed(0)} сом.',
                              style: const TextStyle(color: Color(0xFF00D084),
                                  fontSize: 14, fontWeight: FontWeight.w800)),
                          if (p.oldPrice != null)
                            Text('${p.oldPrice!.toStringAsFixed(0)} сом.',
                                style: const TextStyle(color: Color(0xFF6B6E82),
                                    fontSize: 10, decoration: TextDecoration.lineThrough)),
                        ])),
                      GestureDetector(
                        onTap: () { HapticFeedback.selectionClick(); },
                        child: Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFF00D084), Color(0xFF00A3FF)]),
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: [BoxShadow(
                                color: const Color(0xFF00D084).withOpacity(0.4),
                                blurRadius: 8, offset: const Offset(0, 3))]),
                          child: const Icon(Icons.add_shopping_cart_rounded,
                              color: Colors.white, size: 14))),
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
      baseColor: AppColors.shimmerBase, highlightColor: AppColors.shimmerHighlight,
      child: Container(color: AppColors.shimmerBase));

  Widget _noImage() => Container(
      color: const Color(0xFF1C1C2E),
      child: const Center(child: Icon(Icons.image_search_rounded,
          color: Color(0xFF6B6E82), size: 36)));
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _Chip({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
    decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(7)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 9, color: color),
      if (label.isNotEmpty) ...[
        const SizedBox(width: 3),
        Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
      ],
    ]));
}
