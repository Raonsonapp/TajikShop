import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/shimmer_card.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const ProductDetailScreen({super.key, required this.id});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _imgIndex = 0;

  @override
  Widget build(BuildContext context) {
    final product = ref.watch(productDetailProvider(widget.id));
    return product.when(
      loading: () => _buildLoading(),
      error: (e, _) => _buildError(e.toString()),
      data: (p) => _buildProduct(p),
    );
  }

  Widget _buildLoading() => Scaffold(
    backgroundColor: AppColors.bgDark,
    body: Column(children: [
      ShimmerCard(height: 350, radius: 0),
      const SizedBox(height: 20),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(children: [
        ShimmerCard(height: 24, radius: 6),
        const SizedBox(height: 12),
        ShimmerCard(height: 18, width: 120, radius: 6),
      ])),
    ]),
  );

  Widget _buildError(String e) => Scaffold(
    backgroundColor: AppColors.bgDark,
    appBar: AppBar(backgroundColor: AppColors.bgDark),
    body: Center(child: Text(e, style: const TextStyle(color: AppColors.error))),
  );

  Widget _buildProduct(ProductModel p) {
    final cart = ref.watch(cartProvider);
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.bgDark.withOpacity(0.9),
            expandedHeight: 350,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Image
                  p.images.isNotEmpty
                      ? PageView.builder(
                          itemCount: p.images.length,
                          onPageChanged: (i) => setState(() => _imgIndex = i),
                          itemBuilder: (_, i) => CachedNetworkImage(
                            imageUrl: p.images[i],
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: AppColors.bgSurface),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.bgSurface,
                              child: const Icon(Icons.image_not_supported,
                                  color: AppColors.textMuted, size: 60),
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.bgSurface,
                          child: const Icon(Icons.image_not_supported,
                              color: AppColors.textMuted, size: 80),
                        ),
                  // Gradient
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, AppColors.bgDark.withOpacity(0.6)],
                        ),
                      ),
                    ),
                  ),
                  // Dots
                  if (p.images.length > 1)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(p.images.length, (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _imgIndex == i ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _imgIndex == i ? AppColors.primary : Colors.white54,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        )),
                      ),
                    ),
                  // Discount badge
                  if (p.discountPercent > 0)
                    Positioned(
                      top: 80,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('-${p.discountPercent}%',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              color: AppColors.bgDark,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(p.title, style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),

                  // Price Row
                  Row(children: [
                    Text('${p.price.toStringAsFixed(0)} сомонӣ',
                        style: const TextStyle(
                          color: AppColors.primary, fontSize: 26, fontWeight: FontWeight.w800)),
                    if (p.oldPrice != null) ...[
                      const SizedBox(width: 12),
                      Text('${p.oldPrice!.toStringAsFixed(0)} сомонӣ',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 16,
                            decoration: TextDecoration.lineThrough,
                          )),
                    ],
                  ]),
                  const SizedBox(height: 16),

                  // Stats Row
                  Row(children: [
                    _StatChip(icon: Icons.star_rounded, value: p.rating.toStringAsFixed(1),
                        color: AppColors.warning),
                    const SizedBox(width: 12),
                    _StatChip(icon: Icons.reviews_outlined, value: '${p.reviewCount} шарҳ',
                        color: AppColors.info),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: p.inStock
                            ? AppColors.success.withOpacity(0.12)
                            : AppColors.error.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        p.inStock ? '✓ Мавҷуд' : '✗ Нест',
                        style: TextStyle(
                          color: p.inStock ? AppColors.success : AppColors.error,
                          fontSize: 12, fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Seller
                  if (p.sellerName != null) Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        child: Text(p.sellerName![0].toUpperCase(),
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.sellerName!, style: const TextStyle(
                            color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                        const Text('Фурӯшанда', style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                      ]),
                      const Spacer(),
                      Icon(Icons.chevron_right, color: AppColors.textMuted),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  const Text('Тавсиф', style: TextStyle(
                      color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(p.description, style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14, height: 1.6)),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: const BoxDecoration(
          color: AppColors.bgCard,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(children: [
          Expanded(
            child: AppButton(
              text: 'Ба сабад',
              isOutlined: true,
              icon: Icons.shopping_bag_outlined,
              onTap: () async {
                await ref.read(cartProvider.notifier).addToCart(p.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Ба сабад илова шуд ✓'),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton(text: 'Харидан', onTap: () {}),
          ),
        ]),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _StatChip({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
