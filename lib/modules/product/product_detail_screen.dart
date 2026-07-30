// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/app_l10n.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
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

/// Градиенти сабзи бренд — ҷойгузини `mainButton`-и норинҷии қолаб.
const LinearGradient _greenGradient = LinearGradient(
  colors: [Color(0xFF00D084), Color(0xFF00A3FF)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

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
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final product = ref.watch(productDetailProvider(widget.id));
    return product.when(
      loading: () => Scaffold(
        backgroundColor: context.pal.scaffold,
        appBar: AppBar(
            backgroundColor: context.pal.scaffold,
            iconTheme: IconThemeData(color: context.pal.textPrimary)),
        body: Column(children: [
          ShimmerCard(height: 350, radius: 0),
          const SizedBox(height: 20),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
    final minQty = p.minOrderQty > 1 ? p.minOrderQty : 1;
    if (_qty < minQty) _qty = minQty;

    return Scaffold(
      backgroundColor: context.pal.scaffold,
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _hero(p, isFav),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (p.brandName != null && p.brandName!.isNotEmpty)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: AppColors.info.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(p.brandName!.toUpperCase(),
                              style: const TextStyle(
                                  color: AppColors.info,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)))),
                Text(p.title,
                    style: TextStyle(
                        color: context.pal.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
                if (p.isFlashSale) ...[
                  const SizedBox(height: 12),
                  Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)]),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Icon(FeatherIcons.zap, color: Colors.white, size: 20),
                        const SizedBox(width: 6),
                        const Text('FLASH SALE',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14)),
                        const Spacer(),
                        Text(AppL10n.of(context).endsIn,
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        CountdownText(
                            endsAt: p.saleEndsAt!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14)),
                      ])),
                ],
                const SizedBox(height: 14),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(
                      '${((_variant != null && _variant!.price > 0) ? _variant!.price : p.price).toStringAsFixed(0)} сом.',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 26,
                          fontWeight: FontWeight.w800)),
                  if (p.oldPrice != null) ...[
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text('${p.oldPrice!.toStringAsFixed(0)} сом.',
                          style: TextStyle(
                              color: context.pal.textMuted,
                              fontSize: 16,
                              decoration: TextDecoration.lineThrough)),
                    ),
                  ],
                ]),
                if (p.wholesalePrice > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                      '${AppL10n.of(context).wholesalePriceLabel}: ${p.wholesalePrice.toStringAsFixed(0)} ${AppL10n.of(context).som}'
                      '${p.minOrderQty > 1 ? ' (${AppL10n.of(context).from} ${p.minOrderQty} ${AppL10n.of(context).pcs})' : ''}',
                      style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 16),
                Row(children: [
                  _Chip(
                      icon: FeatherIcons.star,
                      value: p.rating.toStringAsFixed(1),
                      color: AppColors.warning),
                  const SizedBox(width: 10),
                  _Chip(
                      icon: FeatherIcons.messageCircle,
                      value: '${p.reviewCount} ${AppL10n.of(context).reviewsWord}',
                      color: AppColors.info),
                  const SizedBox(width: 10),
                  Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: p.inStock
                              ? const Color(0x1A00BFA5)
                              : const Color(0x1AFF5252),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(
                          p.inStock
                              ? AppL10n.of(context).inStock
                              : AppL10n.of(context).notAvailable,
                          style: TextStyle(
                              color: p.inStock ? AppColors.success : AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w600))),
                ]),
                if (p.variants.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(AppL10n.of(context).variants,
                      style: TextStyle(
                          color: context.pal.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  _variantSelector(p),
                ],
                const SizedBox(height: 20),
                _quantityControl(minQty),
                if (p.minOrderQty > 1) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    Icon(FeatherIcons.package,
                        color: context.pal.textMuted, size: 16),
                    const SizedBox(width: 6),
                    Text(
                        '${AppL10n.of(context).minOrderLabel}: ${p.minOrderQty} ${AppL10n.of(context).pcs}',
                        style: TextStyle(color: context.pal.textSecondary, fontSize: 13)),
                  ]),
                ],
                const SizedBox(height: 22),
                if (p.sellerName != null)
                  GestureDetector(
                      onTap: () => _openSeller(p),
                      child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: context.pal.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: context.pal.border, width: 0.5)),
                          child: Row(children: [
                            const CircleAvatar(
                                radius: 20,
                                backgroundColor: Color(0x1A00E5FF),
                                child: Icon(FeatherIcons.shoppingBag,
                                    color: AppColors.primary, size: 20)),
                            const SizedBox(width: 12),
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(mainAxisSize: MainAxisSize.min, children: [
                                    Flexible(
                                      child: Text(p.sellerName!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              color: context.pal.textPrimary,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    if (p.sellerVerified) ...[
                                      const SizedBox(width: 5),
                                      const Icon(FeatherIcons.checkCircle,
                                          color: AppColors.info, size: 15),
                                    ],
                                  ]),
                                  Text(AppL10n.of(context).seller,
                                      style: TextStyle(
                                          color: context.pal.textMuted, fontSize: 12)),
                                ]),
                            const Spacer(),
                            _followButton(p),
                            const SizedBox(width: 8),
                            GestureDetector(
                                onTap: () => _openChat(p),
                                child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10)),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      const Icon(FeatherIcons.messageCircle,
                                          color: AppColors.primary, size: 16),
                                      const SizedBox(width: 6),
                                      Text(AppL10n.of(context).messageWord,
                                          style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13)),
                                    ]))),
                          ]))),
                const SizedBox(height: 22),
                Text(AppL10n.of(context).description,
                    style: TextStyle(
                        color: context.pal.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                    p.description.isEmpty
                        ? AppL10n.of(context).noDescription
                        : p.description,
                    style: TextStyle(
                        color: context.pal.textSecondary, fontSize: 14, height: 1.6)),
                const SizedBox(height: 28),
                _reviewsSection(p),
                const SizedBox(height: 28),
                _qaSection(p),
                const SizedBox(height: 28),
                _similarSection(p),
              ]),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomBar(p),
    );
  }

  // ── Hero (тарҳи product_display-и қолаб дар сабз) ─────────────────────────
  Widget _hero(ProductModel p, bool isFav) {
    final imgs = p.images;
    final price =
        (_variant != null && _variant!.price > 0) ? _variant!.price : p.price;
    return Container(
      decoration: const BoxDecoration(
        gradient: _greenGradient,
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
              color: Color(0x2600D084), offset: Offset(0, 8), blurRadius: 20),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 420,
          child: Stack(children: [
            // Панели болоӣ: бозгашт + амалҳо
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(children: [
                IconButton(
                    icon: const Icon(FeatherIcons.chevronLeft, color: Colors.white),
                    onPressed: () => Navigator.of(context).maybePop()),
                const Spacer(),
                IconButton(
                    icon: Icon(isFav ? FeatherIcons.heart : FeatherIcons.heart,
                        color: isFav ? AppColors.error : Colors.white),
                    onPressed: () => _toggleFavorite(p.id)),
                IconButton(
                    icon: const Icon(FeatherIcons.share2, color: Colors.white),
                    onPressed: () => _share(p)),
                PopupMenuButton<String>(
                  color: context.pal.elevated,
                  icon: const Icon(FeatherIcons.moreVertical, color: Colors.white),
                  onSelected: (v) {
                    if (v == 'report') _report(p);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                        value: 'report',
                        child: Row(children: [
                          const Icon(FeatherIcons.flag,
                              color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Text(AppL10n.of(context).report,
                              style: TextStyle(color: context.pal.textPrimary)),
                        ])),
                  ],
                ),
              ]),
            ),
            // Расм(ҳо)-и маҳсулот
            Positioned(
              top: 64,
              left: 20,
              right: 20,
              bottom: 42,
              child: imgs.isNotEmpty
                  ? PageView.builder(
                      itemCount: imgs.length,
                      onPageChanged: (i) => setState(() => _imgIndex = i),
                      itemBuilder: (_, i) => Hero(
                        tag: 'product_image_${p.id}_$i',
                        child: CachedNetworkImage(
                          imageUrl: imgs[i],
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const Center(
                              child: SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white70))),
                          errorWidget: (_, __, ___) => const Icon(
                              FeatherIcons.image,
                              color: Colors.white70,
                              size: 60),
                        ),
                      ),
                    )
                  : const Center(
                      child: Icon(FeatherIcons.image,
                          color: Colors.white70, size: 60)),
            ),
            // Тахтаи нарх (мисли product_display, ранги торик собит)
            Positioned(
              top: 92,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 12, 24, 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF202020),
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10)),
                  boxShadow: [
                    BoxShadow(
                        color: Color(0x29000000),
                        offset: Offset(0, 3),
                        blurRadius: 6),
                  ],
                ),
                child: Text('${price.toStringAsFixed(0)} сом.',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 24)),
              ),
            ),
            // Нишонаи тахфиф
            if (p.computedDiscount > 0)
              Positioned(
                top: 64,
                left: 20,
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text('-${p.computedDiscount}%',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700))),
              ),
            // Нуқтаҳои индикатор
            if (imgs.length > 1)
              Positioned(
                bottom: 14,
                left: 0,
                right: 0,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                        imgs.length,
                        (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _imgIndex == i ? 18 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                                color: _imgIndex == i
                                    ? Colors.white
                                    : Colors.white54,
                                borderRadius: BorderRadius.circular(4))))),
              ),
          ]),
        ),
      ),
    );
  }

  // ── Интихоби вариант (тарҳи color_list-и уфуқӣ) ───────────────────────────
  Widget _variantSelector(ProductModel p) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: p.variants.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final v = p.variants[i];
          final sel = _variant?.id == v.id;
          return GestureDetector(
            onTap: v.inStock
                ? () => setState(() => _variant = sel ? null : v)
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: sel
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : context.pal.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: sel ? AppColors.primary : context.pal.border,
                    width: sel ? 1.6 : 0.6),
              ),
              child: Center(
                child: Text(
                    v.inStock
                        ? v.label
                        : '${v.label} (${AppL10n.of(context).notAvailableShort})',
                    style: TextStyle(
                        color: v.inStock
                            ? (sel ? AppColors.primary : context.pal.textPrimary)
                            : context.pal.textMuted,
                        fontSize: 13,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Идораи миқдор ──────────────────────────────────────────────────────────
  Widget _quantityControl(int minQty) {
    return Row(children: [
      Text(AppL10n.of(context).quantity,
          style: TextStyle(
              color: context.pal.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700)),
      const Spacer(),
      Container(
        decoration: BoxDecoration(
            color: context.pal.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.pal.border, width: 0.6)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _qtyBtn(FeatherIcons.minus,
              onTap: _qty > minQty ? () => setState(() => _qty--) : null),
          SizedBox(
            width: 40,
            child: Center(
              child: Text('$_qty',
                  style: TextStyle(
                      color: context.pal.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          _qtyBtn(FeatherIcons.plus, onTap: () => setState(() => _qty++)),
        ]),
      ),
    ]);
  }

  Widget _qtyBtn(IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        child: Icon(icon,
            size: 20,
            color: onTap == null ? context.pal.textMuted : AppColors.primary),
      ),
    );
  }

  // ── Панели поёнӣ: ба сабад + харид ───────────────────────────────────────
  Widget _bottomBar(ProductModel p) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
          color: context.pal.card,
          border: Border(top: BorderSide(color: context.pal.border)),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), offset: Offset(0, -3), blurRadius: 10),
          ]),
      child: Row(children: [
        Expanded(
          child: AppButton(
            text: AppL10n.of(context).addToCart,
            isOutlined: true,
            icon: FeatherIcons.shoppingBag,
            height: 56,
            onTap: () => _addToCart(p),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GradientButton(
            text: AppL10n.of(context).buyNow,
            onTap: () => _buyNow(p),
          ),
        ),
      ]),
    );
  }

  Future<void> _addToCart(ProductModel p) async {
    final l = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(cartProvider.notifier).addToCart(p.id, quantity: _qty);
      messenger.showSnackBar(SnackBar(
          content: Text(l.addedToCart),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    } catch (_) {
      messenger.showSnackBar(SnackBar(
          content: Text(l.loginToBuy),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating));
    }
  }

  void _toggleFavorite(String id) {
    if (!ref.read(authProvider).isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppL10n.of(context).loginToFavorite),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating));
      return;
    }
    ref.read(favoritesProvider.notifier).toggle(id);
  }

  void _share(ProductModel p) {
    Clipboard.setData(ClipboardData(
        text: '${p.title} — ${p.price.toStringAsFixed(0)} сом. | TajikShop'));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppL10n.of(context).copied),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating));
  }

  Future<void> _buyNow(ProductModel p) async {
    final l = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!ref.read(authProvider).isAuthenticated) {
      messenger.showSnackBar(SnackBar(
          content: Text(l.loginToBuy),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating));
      return;
    }
    try {
      await ref.read(cartProvider.notifier).addToCart(p.id, quantity: _qty);
      if (!mounted) return;
      context.go(RouteNames.cart);
    } catch (_) {
      messenger.showSnackBar(SnackBar(
          content: Text(l.errorAddingToCart),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating));
    }
  }

  // ── Чат бо фурӯшанда ───────────────────────────────────────────────────────
  void _openChat(ProductModel p) {
    if (!ref.read(authProvider).isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppL10n.of(context).loginToMessage),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating));
      return;
    }
    if (p.sellerId.isEmpty) return;
    final name =
        Uri.encodeComponent(p.sellerName ?? AppL10n.of(context).seller);
    context.push('${RouteNames.chat}/${p.sellerId}?name=$name');
  }

  void _report(ProductModel p) {
    final l = AppL10n.of(context);
    if (!ref.read(authProvider).isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l.loginToReport),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating));
      return;
    }
    final reasons = [
      l.reportReasonFake,
      l.reportReasonWrongPrice,
      l.reportReasonInappropriate,
      l.reportReasonSpam,
      l.reportReasonOther
    ];
    showModalBottomSheet(
        context: context,
        backgroundColor: context.pal.card,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: context.pal.border,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              Text(l.reportReasonTitle,
                  style: TextStyle(
                      color: context.pal.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...reasons.map((r) => ListTile(
                    leading: const Icon(FeatherIcons.flag,
                        color: AppColors.error, size: 20),
                    title: Text(r, style: TextStyle(color: context.pal.textPrimary)),
                    onTap: () async {
                      Navigator.pop(context);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await ReportService.send(
                            targetType: 'product', targetId: p.id, reason: r);
                        messenger.showSnackBar(SnackBar(
                            content: Text(l.reportSent),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating));
                      } catch (_) {
                        messenger.showSnackBar(SnackBar(
                            content: Text(l.error),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating));
                      }
                    },
                  )),
            ])));
  }

  void _openSeller(ProductModel p) {
    if (p.sellerId.isEmpty) return;
    final name =
        Uri.encodeComponent(p.sellerName ?? AppL10n.of(context).seller);
    context.push('/seller/${p.sellerId}?name=$name');
  }

  // ── Тугмаи пайгирӣ (follow) ────────────────────────────────────────────────
  Widget _followButton(ProductModel p) {
    if (p.sellerId.isEmpty) return const SizedBox.shrink();
    final following = ref.watch(followProvider).contains(p.sellerId);
    return GestureDetector(
      onTap: () {
        if (!ref.read(authProvider).isAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(AppL10n.of(context).loginToFollow),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating));
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
        child: Text(
            following ? AppL10n.of(context).following : AppL10n.of(context).follow,
            style: TextStyle(
                color: following ? AppColors.primary : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
      ),
    );
  }

  // ── Бахши шарҳҳо ───────────────────────────────────────────────────────────
  Widget _reviewsSection(ProductModel p) {
    final reviews = ref.watch(productReviewsProvider(p.id));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(AppL10n.of(context).reviewsTitle,
            style: TextStyle(
                color: context.pal.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const Spacer(),
        TextButton.icon(
            onPressed: () => _openAddReview(p),
            icon: const Icon(FeatherIcons.messageSquare,
                size: 18, color: AppColors.primary),
            label: Text(AppL10n.of(context).writeReview,
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600))),
      ]),
      const SizedBox(height: 4),
      reviews.when(
        loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2))),
        error: (e, _) => _ratingSummary(p, 0, const SizedBox()),
        data: (list) {
          if (list.isEmpty) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _ratingSummary(p, 0, const SizedBox()),
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(AppL10n.of(context).noReviewsYet,
                      style: TextStyle(color: context.pal.textMuted, fontSize: 13))),
            ]);
          }
          final avg = list.fold<int>(0, (s, r) => s + r.rating) / list.length;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _ratingSummary(
                p,
                avg,
                Text('${list.length} ${AppL10n.of(context).reviewsWord}',
                    style: TextStyle(color: context.pal.textMuted, fontSize: 12))),
            const SizedBox(height: 8),
            ...list.take(5).map((r) => _ReviewTile(review: r)),
            if (list.length > 5)
              Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                      '${AppL10n.of(context).andMore} ${list.length - 5} ${AppL10n.of(context).reviewsWord}...',
                      style: TextStyle(color: context.pal.textMuted, fontSize: 12))),
          ]);
        },
      ),
    ]);
  }

  Widget _ratingSummary(ProductModel p, double avg, Widget trailing) {
    final value = avg > 0 ? avg : p.rating;
    return Row(children: [
      Text(value.toStringAsFixed(1),
          style: TextStyle(
              color: context.pal.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800)),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
            children: List.generate(
                5,
                (i) => Icon(
                    i < value.round()
                        ? FeatherIcons.star
                        : FeatherIcons.star,
                    color: AppColors.warning,
                    size: 16))),
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
        Text(AppL10n.of(context).qaTitle,
            style: TextStyle(
                color: context.pal.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const Spacer(),
        TextButton.icon(
            onPressed: () => _askQuestion(p),
            icon: const Icon(FeatherIcons.helpCircle,
                size: 18, color: AppColors.primary),
            label: Text(AppL10n.of(context).askQuestion,
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600))),
      ]),
      qa.when(
        loading: () => const SizedBox(),
        error: (_, __) => const SizedBox(),
        data: (list) {
          if (list.isEmpty) {
            return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(AppL10n.of(context).noQuestionsYet,
                    style: TextStyle(color: context.pal.textMuted, fontSize: 13)));
          }
          return Column(
              children: list.take(6).map((q) {
            final answer = q['answer']?.toString() ?? '';
            final qid = q['id']?.toString() ?? '';
            return Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: context.pal.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.pal.border, width: 0.5)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(AppL10n.of(context).questionShort,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                  Expanded(
                      child: Text(q['question']?.toString() ?? '',
                          style: TextStyle(
                              color: context.pal.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600))),
                ]),
                if (answer.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(AppL10n.of(context).answerShort,
                        style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w800,
                            fontSize: 13)),
                    Expanded(
                        child: Text(answer,
                            style: TextStyle(
                                color: context.pal.textSecondary,
                                fontSize: 13,
                                height: 1.4))),
                  ]),
                ] else if (isSeller) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                      onTap: () => _answerQuestion(p, qid),
                      child: Text('↳ ${AppL10n.of(context).answerAction}',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600))),
                ] else ...[
                  const SizedBox(height: 4),
                  Text(AppL10n.of(context).noAnswerYet,
                      style: TextStyle(color: context.pal.textMuted, fontSize: 12)),
                ],
              ]),
            );
          }).toList());
        },
      ),
    ]);
  }

  void _askQuestion(ProductModel p) {
    final l = AppL10n.of(context);
    if (!ref.read(authProvider).isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l.loginToAsk),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating));
      return;
    }
    _textPrompt(
        title: l.askQuestionTitle,
        hint: l.askQuestionHint,
        action: l.send,
        onSubmit: (text) async {
          try {
            await ReviewService.ask(p.id, text);
            ref.invalidate(productQuestionsProvider(p.id));
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(l.questionSent),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating));
            }
          } catch (_) {}
        });
  }

  void _answerQuestion(ProductModel p, String questionId) {
    final l = AppL10n.of(context);
    _textPrompt(
        title: l.yourAnswer,
        hint: l.writeAnswerHint,
        action: l.answerAction,
        onSubmit: (text) async {
          try {
            await ReviewService.answer(questionId, text);
            ref.invalidate(productQuestionsProvider(p.id));
          } catch (_) {}
        });
  }

  void _textPrompt(
      {required String title,
      required String hint,
      required String action,
      required Function(String) onSubmit}) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
        context: context,
        backgroundColor: context.pal.card,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                        child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                                color: context.pal.border,
                                borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 16),
                    Text(title,
                        style: TextStyle(
                            color: context.pal.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                          color: context.pal.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.pal.border, width: 0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: SafeInput(
                          controller: ctrl,
                          maxLines: 3,
                          autofocus: true,
                          hint: hint,
                          textColor: context.pal.textPrimary,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                        text: action,
                        onTap: () {
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppL10n.of(context).loginToReview),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating));
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: context.pal.card,
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
    if (p.categoryId == null || p.categoryId!.isEmpty) {
      return const SizedBox.shrink();
    }
    final similar = ref.watch(similarProductsProvider(p.categoryId!));
    return similar.when(
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
      data: (list) {
        final others = list.where((e) => e.id != p.id).take(10).toList();
        if (others.isEmpty) return const SizedBox.shrink();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(AppL10n.of(context).similarProducts,
              style: TextStyle(
                  color: context.pal.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: others.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) =>
                  SizedBox(width: 150, child: ProductCard(product: others[i])),
            ),
          ),
        ]);
      },
    );
  }
}

// ── Тугмаи калони градиенти сабз (тарҳи «View Product»-и қолаб) ─────────────
class _GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const _GradientButton({required this.text, this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: _greenGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: Color(0x2900D084), offset: Offset(0, 5), blurRadius: 10),
          ],
        ),
        child: Center(
          child: Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
        ),
      ),
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
  final List<XFile> _photos = [];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    if (_photos.length >= 5) return;
    try {
      final picked = await ImagePicker().pickMultiImage(imageQuality: 70);
      if (picked.isEmpty) return;
      setState(() {
        for (final x in picked) {
          if (_photos.length < 5) _photos.add(x);
        }
      });
    } catch (_) {}
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    final l = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      List<String> urls = const [];
      if (_photos.isNotEmpty) {
        final files = <MultipartFile>[];
        for (final x in _photos) {
          files.add(await MultipartFile.fromFile(x.path, filename: x.name));
        }
        urls = await ReviewService.uploadImages(files);
      }
      await ReviewService.submit(
          productId: widget.productId,
          rating: _rating,
          comment: _ctrl.text.trim(),
          images: urls);
      widget.onDone();
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(
          content: Text(l.reviewAdded),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating));
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      messenger.showSnackBar(SnackBar(
          content: Text(l.errorSendingReview),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: context.pal.border,
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(AppL10n.of(context).rateThis,
                style: TextStyle(
                    color: context.pal.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Center(
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                        5,
                        (i) => GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _rating = i + 1);
                            },
                            child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                    i < _rating
                                        ? FeatherIcons.star
                                        : FeatherIcons.star,
                                    color: AppColors.warning,
                                    size: 40)))))),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                  color: context.pal.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.pal.border, width: 0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: SafeInput(
                  controller: _ctrl,
                  maxLines: 3,
                  hint: AppL10n.of(context).reviewHint,
                  textColor: context.pal.textPrimary,
                  fontSize: 14),
            ),
            const SizedBox(height: 16),
            // ── Расмҳо (photo review) ──
            SizedBox(
              height: 68,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (int i = 0; i < _photos.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(File(_photos[i].path),
                            width: 64, height: 64, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _photos.removeAt(i)),
                          child: Container(
                            decoration: const BoxDecoration(
                                color: Colors.black54, shape: BoxShape.circle),
                            padding: const EdgeInsets.all(3),
                            child: const Icon(FeatherIcons.x,
                                color: Colors.white, size: 12),
                          ),
                        ),
                      ),
                    ]),
                  ),
                if (_photos.length < 5)
                  GestureDetector(
                    onTap: _pickPhotos,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: context.pal.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.pal.border, width: 0.8),
                      ),
                      child: Icon(FeatherIcons.camera,
                          color: context.pal.textMuted, size: 22),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 20),
            AppButton(
                text: AppL10n.of(context).send, onTap: _submit, isLoading: _loading),
          ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _Chip({required this.icon, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: Color.fromRGBO(color.red, color.green, color.blue, 0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppL10n.of(context).loginToVote),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() {
      _busy = true;
      _liked = !_liked;
      _count += _liked ? 1 : -1;
    });
    try {
      final c = await ReviewService.toggleHelpful(widget.review.id);
      if (mounted) setState(() => _count = c);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openPhoto(BuildContext context, List<String> images, int index) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Stack(children: [
          PageView.builder(
            controller: PageController(initialPage: index),
            itemCount: images.length,
            itemBuilder: (_, i) => InteractiveViewer(
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: images[i],
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) =>
                      const Icon(FeatherIcons.image, color: Colors.white54, size: 48),
                ),
              ),
            ),
          ),
          Positioned(
            top: 44,
            right: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: const Icon(FeatherIcons.x, color: Colors.white, size: 26),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.review;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
              radius: 14,
              backgroundColor: context.pal.surface,
              backgroundImage: (r.userAvatar != null && r.userAvatar!.isNotEmpty)
                  ? CachedNetworkImageProvider(r.userAvatar!)
                  : null,
              child: (r.userAvatar == null || r.userAvatar!.isEmpty)
                  ? Icon(FeatherIcons.user, size: 16, color: context.pal.textMuted)
                  : null),
          const SizedBox(width: 8),
          Expanded(
              child: Text(
                  r.userName?.isNotEmpty == true
                      ? r.userName!
                      : AppL10n.of(context).userWord,
                  style: TextStyle(
                      color: context.pal.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600))),
          Text(DateFormat('dd.MM.yyyy').format(r.createdAt),
              style: TextStyle(color: context.pal.textMuted, fontSize: 11)),
        ]),
        const SizedBox(height: 4),
        Row(
            children: List.generate(
                5,
                (i) => Icon(
                    i < r.rating
                        ? FeatherIcons.star
                        : FeatherIcons.star,
                    color: AppColors.warning,
                    size: 13))),
        if (r.comment.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(r.comment,
              style: TextStyle(
                  color: context.pal.textSecondary, fontSize: 13, height: 1.4)),
        ],
        if (r.images.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: r.images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _openPhoto(context, r.images, i),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: r.images[i],
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: context.pal.surface),
                    errorWidget: (_, __, ___) => Container(
                        color: context.pal.surface,
                        child: Icon(FeatherIcons.image,
                            size: 20, color: context.pal.textMuted)),
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _toggle,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
                _liked
                    ? FeatherIcons.thumbsUp
                    : FeatherIcons.thumbsUp,
                size: 15,
                color: _liked ? AppColors.primary : context.pal.textMuted),
            const SizedBox(width: 5),
            Text('${AppL10n.of(context).helpful}${_count > 0 ? ' ($_count)' : ''}',
                style: TextStyle(
                    color: _liked ? AppColors.primary : context.pal.textMuted,
                    fontSize: 12)),
          ]),
        ),
      ]),
    );
  }
}
