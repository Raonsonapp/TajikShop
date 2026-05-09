// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/shimmer_card.dart';
import '../../shared/widgets/error_screen.dart';

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
      loading: () => Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(backgroundColor: AppColors.bgDark,
            iconTheme: const IconThemeData(color: AppColors.textPrimary)),
        body: Column(children: [
          ShimmerCard(height: 350, radius: 0),
          const SizedBox(height: 20),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: [
              ShimmerCard(height: 24, radius: 6),
              const SizedBox(height: 12),
              ShimmerCard(height: 18, width: 120, radius: 6),
            ])),
        ])),
      error: (e, _) => ErrorScreen(
        message: e.toString(),
        onRetry: () => ref.invalidate(productDetailProvider(widget.id))),
      data: (p) => _build(p),
    );
  }

  Widget _build(ProductModel p) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          backgroundColor: AppColors.bgDark,
          expandedHeight: 340, pinned: true,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(icon: const Icon(Icons.favorite_border, color: Colors.white), onPressed: () {}),
            IconButton(icon: const Icon(Icons.share_outlined, color: Colors.white), onPressed: () {}),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(children: [
              p.images.isNotEmpty
                  ? PageView.builder(
                      itemCount: p.images.length,
                      onPageChanged: (i) => setState(() => _imgIndex = i),
                      itemBuilder: (_, i) => CachedNetworkImage(
                        imageUrl: p.images[i], fit: BoxFit.cover, width: double.infinity,
                        placeholder: (_, __) => Container(color: AppColors.bgSurface),
                        errorWidget: (_, __, ___) => Container(color: AppColors.bgSurface,
                          child: const Icon(Icons.image_outlined, color: AppColors.textMuted, size: 60))))
                  : Container(color: AppColors.bgSurface,
                      child: const Icon(Icons.image_outlined, color: AppColors.textMuted, size: 60)),
              if (p.images.length > 1)
                Positioned(bottom: 12, left: 0, right: 0,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(p.images.length, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _imgIndex == i ? 16 : 6, height: 6,
                      decoration: BoxDecoration(
                        color: _imgIndex == i ? AppColors.primary : Colors.white54,
                        borderRadius: BorderRadius.circular(3)))))),
              if (p.computedDiscount > 0)
                Positioned(top: 80, left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(8)),
                    child: Text('-${p.computedDiscount}%',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))),
            ])),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.title, style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Row(children: [
                Text('${p.price.toStringAsFixed(0)} сом.',
                    style: const TextStyle(color: AppColors.primary, fontSize: 26, fontWeight: FontWeight.w800)),
                if (p.oldPrice != null) ...[
                  const SizedBox(width: 12),
                  Text('${p.oldPrice!.toStringAsFixed(0)} сом.',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 16,
                          decoration: TextDecoration.lineThrough)),
                ],
              ]),
              const SizedBox(height: 16),
              Row(children: [
                _Chip(icon: Icons.star_rounded, value: p.rating.toStringAsFixed(1), color: AppColors.warning),
                const SizedBox(width: 10),
                _Chip(icon: Icons.chat_bubble_outline, value: '${p.reviewCount} шарҳ', color: AppColors.info),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: p.inStock ? const Color(0x1A00BFA5) : const Color(0x1AFF5252),
                    borderRadius: BorderRadius.circular(20)),
                  child: Text(p.inStock ? '✓ Мавҷуд' : '✗ Нест',
                      style: TextStyle(
                          color: p.inStock ? AppColors.success : AppColors.error,
                          fontSize: 12, fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 20),
              if (p.sellerName != null) Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 0.5)),
                child: Row(children: [
                  const CircleAvatar(radius: 20, backgroundColor: Color(0x1A00E5FF),
                    child: Icon(Icons.store_outlined, color: AppColors.primary, size: 20)),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.sellerName!, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    const Text('Фурӯшанда', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ]),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
                ])),
              const SizedBox(height: 20),
              const Text('Тавсиф', style: TextStyle(
                  color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(p.description.isEmpty ? 'Тавсифе нест' : p.description,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
            ])),
        ),
      ]),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: const BoxDecoration(color: AppColors.bgCard,
            border: Border(top: BorderSide(color: AppColors.border))),
        child: Row(children: [
          Expanded(child: AppButton(
            text: 'Ба сабад', isOutlined: true, icon: Icons.shopping_bag_outlined,
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref.read(cartProvider.notifier).addToCart(p.id);
                messenger.showSnackBar(SnackBar(
                  content: const Text('✅ Ба сабад илова шуд'),
                  backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
              } catch (_) {
                messenger.showSnackBar(const SnackBar(
                  content: Text('Барои харид ворид шавед'),
                  backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
              }
            })),
          const SizedBox(width: 12),
          Expanded(child: AppButton(text: 'Харидан', onTap: () {})),
        ]),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon; final String value; final Color color;
  const _Chip({required this.icon, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: Color.fromRGBO(color.red, color.green, color.blue, 0.1),
        borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 14), const SizedBox(width: 4),
      Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    ]));
}
