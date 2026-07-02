// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/recent_service.dart';
import '../../data/models/product_model.dart';
import '../../data/models/review_model.dart';
import '../../data/models/variant_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/follow_provider.dart';
import '../../providers/report_provider.dart';
import '../../routes/route_names.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/shimmer_card.dart';
import '../../shared/widgets/error_screen.dart';
import '../../shared/widgets/countdown_text.dart';
import '../../shared/widgets/safe_input.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const ProductDetailScreen({super.key, required this.id});
  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _imgIndex = 0;
  bool _recorded = false;
  VariantModel? _variant;

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
    if (!_recorded) {
      _recorded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => RecentService.add(p));
    }
    final isFav = ref.watch(favoritesProvider).contains(p.id);
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          backgroundColor: AppColors.bgDark,
          expandedHeight: 340, pinned: true,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? AppColors.error : Colors.white),
              onPressed: () => _toggleFavorite(p.id)),
            IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.white),
              onPressed: () => _share(p)),
            PopupMenuButton<String>(
              color: AppColors.bgElevated,
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (v) { if (v == 'report') _report(p); },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'report',
                    child: Row(children: [
                      Icon(Icons.flag_outlined, color: AppColors.error, size: 18),
                      SizedBox(width: 8),
                      Text('Гузориш додан', style: TextStyle(color: AppColors.textPrimary)),
                    ])),
              ],
            ),
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
              if (p.brandName != null && p.brandName!.isNotEmpty)
                Padding(padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(p.brandName!.toUpperCase(),
                        style: const TextStyle(color: AppColors.info, fontSize: 11, fontWeight: FontWeight.w700)))),
              Text(p.title, style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
              if (p.isFlashSale) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)]),
                    borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 6),
                    const Text('FLASH SALE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                    const Spacer(),
                    const Text('Тамом: ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    CountdownText(endsAt: p.saleEndsAt!,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                  ])),
              ],
              const SizedBox(height: 12),
              Row(children: [
                Text('${((_variant != null && _variant!.price > 0) ? _variant!.price : p.price).toStringAsFixed(0)} сом.',
                    style: const TextStyle(color: AppColors.primary, fontSize: 26, fontWeight: FontWeight.w800)),
                if (p.oldPrice != null) ...[
                  const SizedBox(width: 12),
                  Text('${p.oldPrice!.toStringAsFixed(0)} сом.',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 16,
                          decoration: TextDecoration.lineThrough)),
                ],
              ]),
              if (p.wholesalePrice > 0) ...[
                const SizedBox(height: 4),
                Text('Нархи яклухт: ${p.wholesalePrice.toStringAsFixed(0)} сом.'
                    '${p.minOrderQty > 1 ? ' (аз ${p.minOrderQty} дона)' : ''}',
                    style: const TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
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
              if (p.variants.isNotEmpty) ...[
                const SizedBox(height: 18),
                const Text('Вариантҳо', style: TextStyle(
                    color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: p.variants.map((v) {
                  final sel = _variant?.id == v.id;
                  return GestureDetector(
                    onTap: v.inStock ? () => setState(() => _variant = sel ? null : v) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary.withValues(alpha: 0.15) : AppColors.bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: sel ? AppColors.primary : AppColors.border,
                            width: sel ? 1.4 : 0.6)),
                      child: Text(
                          v.inStock ? v.label : '${v.label} (нест)',
                          style: TextStyle(
                              color: v.inStock ? (sel ? AppColors.primary : AppColors.textPrimary) : AppColors.textMuted,
                              fontSize: 13, fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
                    ),
                  );
                }).toList()),
              ],
              if (p.minOrderQty > 1) ...[
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.inventory_2_outlined, color: AppColors.textMuted, size: 16),
                  const SizedBox(width: 6),
                  Text('Ҳадди ақали фармоиш: ${p.minOrderQty} дона',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ]),
              ],
              const SizedBox(height: 20),
              if (p.sellerName != null) GestureDetector(
                onTap: () => _openSeller(p),
                child: Container(
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
                  _followButton(p),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _openChat(p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 16),
                        SizedBox(width: 6),
                        Text('Паём', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                      ])),
                  ),
                ]))),
              const SizedBox(height: 20),
              const Text('Тавсиф', style: TextStyle(
                  color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(p.description.isEmpty ? 'Тавсифе нест' : p.description,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),

              const SizedBox(height: 28),
              _reviewsSection(p),

              const SizedBox(height: 28),
              _qaSection(p),

              const SizedBox(height: 28),
              _similarSection(p),
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
          Expanded(child: AppButton(text: 'Харидан', onTap: () => _buyNow(p))),
        ]),
      ),
    );
  }

  void _toggleFavorite(String id) {
    if (!ref.read(authProvider).isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Барои дӯстдошта ворид шавед'),
        backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
      return;
    }
    ref.read(favoritesProvider.notifier).toggle(id);
  }

  void _share(ProductModel p) {
    Clipboard.setData(ClipboardData(text: '${p.title} — ${p.price.toStringAsFixed(0)} сом. | TajikShop'));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Нусха гирифта шуд 📋'),
      backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
  }

  Future<void> _buyNow(ProductModel p) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!ref.read(authProvider).isAuthenticated) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Барои харид ворид шавед'),
        backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
      return;
    }
    try {
      await ref.read(cartProvider.notifier).addToCart(p.id);
      if (!mounted) return;
      context.go(RouteNames.cart);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Хато ҳангоми илова ба сабад'),
        backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    }
  }

  // ── Чат бо фурӯшанда ───────────────────────────────────────────────────────
  void _openChat(ProductModel p) {
    if (!ref.read(authProvider).isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Барои паём навиштан ворид шавед'),
        backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
      return;
    }
    if (p.sellerId.isEmpty) return;
    final name = Uri.encodeComponent(p.sellerName ?? 'Фурӯшанда');
    context.push('${RouteNames.chat}/${p.sellerId}?name=$name');
  }

  void _report(ProductModel p) {
    if (!ref.read(authProvider).isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Барои гузориш ворид шавед'),
        backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
      return;
    }
    const reasons = ['Қалбакӣ / фиребгар', 'Нархи нодуруст', 'Мӯҳтавои номатлуб', 'Спам', 'Дигар'];
    showModalBottomSheet(context: context, backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          const Text('Сабаби гузориш', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...reasons.map((r) => ListTile(
            leading: const Icon(Icons.flag_outlined, color: AppColors.error, size: 20),
            title: Text(r, style: const TextStyle(color: AppColors.textPrimary)),
            onTap: () async {
              Navigator.pop(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ReportService.send(targetType: 'product', targetId: p.id, reason: r);
                messenger.showSnackBar(const SnackBar(
                  content: Text('Гузориш фиристода шуд. Раҳмат!'),
                  backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
              } catch (_) {
                messenger.showSnackBar(const SnackBar(
                  content: Text('Хато'),
                  backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
              }
            },
          )),
        ])));
  }

  void _openSeller(ProductModel p) {
    if (p.sellerId.isEmpty) return;
    final name = Uri.encodeComponent(p.sellerName ?? 'Фурӯшанда');
    context.push('/seller/${p.sellerId}?name=$name');
  }

  // ── Тугмаи пайгирӣ (follow) ────────────────────────────────────────────────
  Widget _followButton(ProductModel p) {
    if (p.sellerId.isEmpty) return const SizedBox.shrink();
    final following = ref.watch(followProvider).contains(p.sellerId);
    return GestureDetector(
      onTap: () {
        if (!ref.read(authProvider).isAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Барои пайгирӣ ворид шавед'),
            backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
          return;
        }
        HapticFeedback.selectionClick();
        ref.read(followProvider.notifier).toggle(p.sellerId);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: following ? Colors.transparent : AppColors.primary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary)),
        child: Text(following ? 'Пайгирӣ шуд' : 'Пайгирӣ',
            style: TextStyle(
                color: following ? AppColors.primary : Colors.white,
                fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    );
  }

  // ── Бахши шарҳҳо ───────────────────────────────────────────────────────────
  Widget _reviewsSection(ProductModel p) {
    final reviews = ref.watch(productReviewsProvider(p.id));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Шарҳҳо', style: TextStyle(
            color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        const Spacer(),
        TextButton.icon(
          onPressed: () => _openAddReview(p),
          icon: const Icon(Icons.rate_review_outlined, size: 18, color: AppColors.primary),
          label: const Text('Шарҳ навиштан',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))),
      ]),
      const SizedBox(height: 4),
      reviews.when(
        loading: () => const Padding(padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))),
        error: (e, _) => _ratingSummary(p, 0, const SizedBox()),
        data: (list) {
          if (list.isEmpty) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _ratingSummary(p, 0, const SizedBox()),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Ҳоло шарҳе нест. Аввалин шуда шарҳ нависед!',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13))),
            ]);
          }
          final avg = list.fold<int>(0, (s, r) => s + r.rating) / list.length;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _ratingSummary(p, avg, Text('${list.length} шарҳ',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12))),
            const SizedBox(height: 8),
            ...list.take(5).map((r) => _ReviewTile(review: r)),
            if (list.length > 5)
              Padding(padding: const EdgeInsets.only(top: 4),
                child: Text('ва боз ${list.length - 5} шарҳ...',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12))),
          ]);
        },
      ),
    ]);
  }

  Widget _ratingSummary(ProductModel p, double avg, Widget trailing) {
    final value = avg > 0 ? avg : p.rating;
    return Row(children: [
      Text(value.toStringAsFixed(1),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w800)),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: List.generate(5, (i) => Icon(
            i < value.round() ? Icons.star_rounded : Icons.star_border_rounded,
            color: AppColors.warning, size: 16))),
        const SizedBox(height: 2),
        trailing,
      ]),
    ]);
  }

  // ── Q&A (савол-ҷавоб) ───────────────────────────────────────────────────────
  Widget _qaSection(ProductModel p) {
    final qa = ref.watch(productQuestionsProvider(p.id));
    final isSeller = ref.watch(authProvider).user?.id == p.sellerId;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Савол ва ҷавоб', style: TextStyle(
            color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        const Spacer(),
        TextButton.icon(
          onPressed: () => _askQuestion(p),
          icon: const Icon(Icons.help_outline_rounded, size: 18, color: AppColors.primary),
          label: const Text('Савол додан', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))),
      ]),
      qa.when(
        loading: () => const SizedBox(),
        error: (_, __) => const SizedBox(),
        data: (list) {
          if (list.isEmpty) {
            return const Padding(padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Ҳоло саволе нест. Аввалин шуда пурсед!',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)));
          }
          return Column(children: list.take(6).map((q) {
            final answer = q['answer']?.toString() ?? '';
            final qid = q['id']?.toString() ?? '';
            return Container(
              margin: const EdgeInsets.only(top: 10), padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 0.5)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('С: ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13)),
                  Expanded(child: Text(q['question']?.toString() ?? '',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
                ]),
                if (answer.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Ҷ: ', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 13)),
                    Expanded(child: Text(answer,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4))),
                  ]),
                ] else if (isSeller) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _answerQuestion(p, qid),
                    child: const Text('↳ Ҷавоб додан',
                        style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600))),
                ] else ...[
                  const SizedBox(height: 4),
                  const Text('Ҳанӯз ҷавоб нест', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ]),
            );
          }).toList());
        },
      ),
    ]);
  }

  void _askQuestion(ProductModel p) {
    if (!ref.read(authProvider).isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Барои савол додан ворид шавед'),
        backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
      return;
    }
    _textPrompt(title: 'Саволи худро нависед', hint: 'Масалан: Кафолат дорад?', action: 'Фиристодан',
      onSubmit: (text) async {
        try {
          await ReviewService.ask(p.id, text);
          ref.invalidate(productQuestionsProvider(p.id));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Савол фиристода шуд ✅'),
              backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
          }
        } catch (_) {}
      });
  }

  void _answerQuestion(ProductModel p, String questionId) {
    _textPrompt(title: 'Ҷавоби шумо', hint: 'Ҷавобро нависед...', action: 'Ҷавоб додан',
      onSubmit: (text) async {
        try {
          await ReviewService.answer(questionId, text);
          ref.invalidate(productQuestionsProvider(p.id));
        } catch (_) {}
      });
  }

  void _textPrompt({required String title, required String hint, required String action, required Function(String) onSubmit}) {
    final ctrl = TextEditingController();
    showModalBottomSheet(context: context, backgroundColor: AppColors.bgCard, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.5)),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SafeInput(controller: ctrl, maxLines: 3, autofocus: true,
              hint: hint,
              textColor: AppColors.textPrimary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          AppButton(text: action, onTap: () {
            final t = ctrl.text.trim();
            if (t.isEmpty) return;
            Navigator.pop(ctx);
            onSubmit(t);
          }),
        ]),
      ));
  }

  void _openAddReview(ProductModel p) {
    if (!ref.read(authProvider).isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Барои шарҳ навиштан ворид шавед'),
        backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddReviewSheet(
        productId: p.id,
        onDone: () => ref.invalidate(productReviewsProvider(p.id))),
    );
  }

  // ── Маҳсулоти монанд ───────────────────────────────────────────────────────
  Widget _similarSection(ProductModel p) {
    if (p.categoryId == null || p.categoryId!.isEmpty) return const SizedBox.shrink();
    final similar = ref.watch(similarProductsProvider(p.categoryId!));
    return similar.when(
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
      data: (list) {
        final others = list.where((e) => e.id != p.id).take(10).toList();
        if (others.isEmpty) return const SizedBox.shrink();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Маҳсулоти монанд', style: TextStyle(
              color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: others.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => SizedBox(width: 150, child: ProductCard(product: others[i])),
            ),
          ),
        ]);
      },
    );
  }
}

// ── Add review bottom sheet ────────────────────────────────────────────────────
class _AddReviewSheet extends ConsumerStatefulWidget {
  final String productId;
  final VoidCallback onDone;
  const _AddReviewSheet({required this.productId, required this.onDone});
  @override
  ConsumerState<_AddReviewSheet> createState() => _AddReviewSheetState();
}

class _AddReviewSheetState extends ConsumerState<_AddReviewSheet> {
  int _rating = 5;
  final _ctrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ReviewService.submit(
          productId: widget.productId, rating: _rating, comment: _ctrl.text.trim());
      widget.onDone();
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(
        content: Text('Шарҳи шумо илова шуд ✅'),
        backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      messenger.showSnackBar(const SnackBar(
        content: Text('Хато ҳангоми фиристодани шарҳ'),
        backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        const Text('Баҳои худро гузоред', style: TextStyle(
            color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Center(child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (i) =>
          GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _rating = i + 1); },
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(i < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: AppColors.warning, size: 40)))))),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: SafeInput(
            controller: _ctrl,
            maxLines: 3,
            hint: 'Фикри худро нависед (ихтиёрӣ)...',
            textColor: AppColors.textPrimary, fontSize: 14),
        ),
        const SizedBox(height: 20),
        AppButton(text: 'Фиристодан', onTap: _submit, isLoading: _loading),
      ]),
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

// ── Review tile бо тугмаи «фоиданок» ────────────────────────────────────────────
class _ReviewTile extends ConsumerStatefulWidget {
  final ReviewModel review;
  const _ReviewTile({required this.review});
  @override
  ConsumerState<_ReviewTile> createState() => _ReviewTileState();
}

class _ReviewTileState extends ConsumerState<_ReviewTile> {
  late int _count = widget.review.helpfulCount;
  bool _liked = false;
  bool _busy = false;

  Future<void> _toggle() async {
    if (_busy) return;
    if (!ref.read(authProvider).isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Барои овоз додан ворид шавед'),
        backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() { _busy = true; _liked = !_liked; _count += _liked ? 1 : -1; });
    try {
      final c = await ReviewService.toggleHelpful(widget.review.id);
      if (mounted) setState(() => _count = c);
    } catch (_) {} finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.review;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 14, backgroundColor: AppColors.bgSurface,
            backgroundImage: (r.userAvatar != null && r.userAvatar!.isNotEmpty)
                ? CachedNetworkImageProvider(r.userAvatar!) : null,
            child: (r.userAvatar == null || r.userAvatar!.isEmpty)
                ? const Icon(Icons.person, size: 16, color: AppColors.textMuted) : null),
          const SizedBox(width: 8),
          Expanded(child: Text(r.userName?.isNotEmpty == true ? r.userName! : 'Корбар',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
          Text(DateFormat('dd.MM.yyyy').format(r.createdAt),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ]),
        const SizedBox(height: 4),
        Row(children: List.generate(5, (i) => Icon(
            i < r.rating ? Icons.star_rounded : Icons.star_border_rounded,
            color: AppColors.warning, size: 13))),
        if (r.comment.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(r.comment, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
        ],
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _toggle,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(_liked ? Icons.thumb_up_alt_rounded : Icons.thumb_up_off_alt_rounded,
                size: 15, color: _liked ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: 5),
            Text('Фоиданок${_count > 0 ? ' ($_count)' : ''}',
                style: TextStyle(color: _liked ? AppColors.primary : AppColors.textMuted, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }
}
