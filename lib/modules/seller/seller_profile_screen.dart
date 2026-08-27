import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/business_types.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/seller_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/follow_provider.dart';
import '../../routes/route_names.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/shimmer_card.dart';
import '../../core/app_l10n.dart';
import '../../core/l10n/seller_l10n.dart';
import 'seller_rating_card.dart';
import 'package:latlong2/latlong.dart';
import '../address/map_picker_screen.dart';

/// Градиенти сабз (ecommerce_int2 look, ранги бренди TajikShop).
const LinearGradient _greenGradient = LinearGradient(
  colors: [Color(0xFF00D084), Color(0xFF00A86B)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class SellerProfileScreen extends ConsumerWidget {
  final String id;
  final String name;
  const SellerProfileScreen({super.key, required this.id, this.name = 'Фурӯшанда'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final info = ref.watch(sellerPublicProvider(id));
    final products = ref.watch(sellerProductsProvider(id));
    final following = ref.watch(followProvider).contains(id);

    return Scaffold(
      backgroundColor: context.pal.scaffold,
      appBar: AppBar(
        backgroundColor: context.pal.scaffold,
        elevation: 0,
        iconTheme: IconThemeData(color: context.pal.textPrimary),
        title: Text(info.maybeWhen(data: (d) {
              final sn = d['shop_name']?.toString() ?? '';
              return sn.isNotEmpty ? sn : (d['name']?.toString() ?? name);
            }, orElse: () => name),
            style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w800)),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async { ref.invalidate(sellerPublicProvider(id)); ref.invalidate(sellerProductsProvider(id)); },
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: info.when(
            loading: () => const Padding(padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
            error: (_, __) => const SizedBox(height: 40),
            data: (d) => _header(context, ref, d, following),
          )),
          // Баҳои харидорон (1–10) — нишони эътимод пеш аз харид.
          SliverToBoxAdapter(child: SellerRatingCard(sellerId: id)),
          products.when(
            loading: () => SliverPadding(padding: const EdgeInsets.all(20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.58),
                delegate: SliverChildBuilderDelegate((_, __) => const ShimmerCard(), childCount: 4))),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
            data: (list) => list.isEmpty
                ? SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(vertical: 50),
                    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(FeatherIcons.package, size: 64, color: context.pal.textMuted),
                      const SizedBox(height: 12),
                      Text(l.noProducts, style: TextStyle(color: context.pal.textMuted)),
                    ]))))
                : SliverPadding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.58),
                      delegate: SliverChildBuilderDelegate(
                          (_, i) => ProductCard(product: list[i]), childCount: list.length))),
          ),
        ]),
      ),
    );
  }

  Widget _header(BuildContext context, WidgetRef ref, Map<String, dynamic> d, bool following) {
    final l = AppL10n.of(context);
    // Оё ин профили худи корбар аст?
    final isMe = ref.watch(authProvider).user?.id == id;
    final avatar = d['avatar_url']?.toString() ?? '';
    final verified = d['is_verified'] == true;
    final rating = (d['rating'] as num?)?.toDouble() ?? 0;
    final followers = (d['followers'] as num?)?.toInt() ?? 0;
    final products = (d['products'] as num?)?.toInt() ?? 0;
    final bio = d['bio']?.toString() ?? '';
    final shopName  = d['shop_name']?.toString() ?? '';
    final shopDesc  = d['shop_desc']?.toString() ?? '';
    final shopPhone = d['shop_phone']?.toString() ?? '';
    final shopHours = d['shop_hours']?.toString() ?? '';
    final bizType   = d['business_type']?.toString() ?? 'shop';
    final storeLat  = (d['store_lat'] as num?)?.toDouble() ?? 0;
    final storeLng  = (d['store_lng'] as num?)?.toDouble() ?? 0;
    final displayName = shopName.isNotEmpty
        ? shopName
        : (d['name']?.toString() ?? l.seller);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Shop cover (green gradient banner) ──
        Container(
          height: 96,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: _greenGradient,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Stack(children: [
            Positioned(right: -10, bottom: -14,
              child: Icon(FeatherIcons.shoppingBag,
                  size: 96, color: Colors.white.withValues(alpha: 0.16))),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: Text(displayName,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 20,
                      fontWeight: FontWeight.w900, letterSpacing: -0.3)),
            ),
          ]),
        ),
        // ── Template profile card ──
        Container(
          decoration: BoxDecoration(
            color: context.pal.card,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
            border: Border.all(color: context.pal.border, width: 0.6),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              // Avatar with green gradient ring
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: _greenGradient),
                child: CircleAvatar(radius: 38, backgroundColor: context.pal.surface,
                  backgroundImage: avatar.isNotEmpty ? CachedNetworkImageProvider(avatar) : null,
                  child: avatar.isEmpty ? const Icon(FeatherIcons.shoppingBag, color: Colors.white, size: 34) : null),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(displayName,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.pal.textPrimary, fontSize: 19, fontWeight: FontWeight.w900))),
                  if (verified) const Padding(padding: EdgeInsets.only(left: 6),
                      child: Icon(FeatherIcons.checkCircle, color: AppColors.info, size: 20)),
                ]),
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(bio, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.pal.textSecondary, fontSize: 13, height: 1.35)),
                ],
              ])),
            ]),
            const SizedBox(height: 18),
            // Stats row (template mini-cards)
            Row(children: [
              _stat(context, '$products', l.productsWord),
              const SizedBox(width: 10),
              _stat(context, '$followers', l.sellerFollowers),
              const SizedBox(width: 10),
              _stat(context, rating > 0 ? rating.toStringAsFixed(1) : '—', l.sellerRating,
                  icon: FeatherIcons.star),
            ]),
            const SizedBox(height: 16),
            // Actions — дар профили ХУДАТ «Пайгирӣ» ва «Паём» маъно надоранд:
            // касе худашро пайгирӣ намекунад ва ба худаш паём наменависад.
            // Ба ҷои онҳо роҳи кӯтоҳ ба панели фурӯшанда мемонад.
            if (isMe)
              GestureDetector(
                onTap: () => context.push(RouteNames.sellerDashboard),
                child: Container(
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: context.pal.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary, width: 1.4)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(FeatherIcons.grid,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 7),
                    Text(l.sellerDashboard,
                        style: const TextStyle(
                            color: AppColors.primary, fontWeight: FontWeight.w800)),
                  ]),
                ),
              )
            else
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () {
                  if (!ref.read(authProvider).isAuthenticated) return;
                  HapticFeedback.selectionClick();
                  ref.read(followProvider.notifier).toggle(id);
                },
                child: Container(
                  height: 46, alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: following ? null : _greenGradient,
                    color: following ? Colors.transparent : null,
                    borderRadius: BorderRadius.circular(14),
                    border: following ? Border.all(color: AppColors.primary, width: 1.5) : null,
                    boxShadow: following ? null : const [
                      BoxShadow(color: Color(0x4D00D084), offset: Offset(0, 4), blurRadius: 12),
                    ]),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(following ? FeatherIcons.check : FeatherIcons.userPlus,
                        color: following ? AppColors.primary : Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(following ? l.following : l.sellerFollowAction,
                        style: TextStyle(color: following ? AppColors.primary : Colors.white,
                            fontWeight: FontWeight.w800)),
                  ]),
                ),
              )),
              const SizedBox(width: 10),
              Expanded(child: GestureDetector(
                onTap: () => context.push('${RouteNames.chat}/$id?name=${Uri.encodeComponent(d['name']?.toString() ?? l.seller)}'),
                child: Container(
                  height: 46, alignment: Alignment.center,
                  decoration: BoxDecoration(color: context.pal.surface, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.pal.border, width: 1)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(FeatherIcons.messageCircle, color: context.pal.textPrimary, size: 18),
                    const SizedBox(width: 6),
                    Text(l.messageWord, style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w800)),
                  ]),
                ),
              )),
            ]),
          ]),
        ),

        // ── Тавсифи бизнес ──
        if (shopDesc.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.pal.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.pal.border, width: 0.6),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(FeatherIcons.fileText, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Text('Дар бораи мағоза', style: TextStyle(
                    color: context.pal.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 10),
              Text(shopDesc, style: TextStyle(
                  color: context.pal.textSecondary, fontSize: 14, height: 1.45)),
            ]),
          ),
        ],

        // ── Info rows (навъи бизнес, соатҳо, телефон, ҷойгиршавӣ) ──
        ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              color: context.pal.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.pal.border, width: 0.6),
            ),
            child: Column(children: [
              _infoRow(context, businessTypeFor(bizType).icon, 'Навъи бизнес',
                  businessTypeFor(bizType).label),
              if (shopHours.isNotEmpty)
                _infoRow(context, FeatherIcons.clock, 'Соатҳои корӣ', shopHours),
              if (shopPhone.isNotEmpty)
                _infoRow(context, FeatherIcons.phone, 'Занг задан', shopPhone, onTap: () {
                  Clipboard.setData(ClipboardData(text: shopPhone));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Рақам нусхабардорӣ шуд'),
                      backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
                }),
              if (storeLat != 0 && storeLng != 0)
                _infoRow(context, FeatherIcons.mapPin, 'Ҷойгиршавии мағоза',
                    '${storeLat.toStringAsFixed(4)}, ${storeLng.toStringAsFixed(4)}',
                    onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => MapPickerScreen(initial: LatLng(storeLat, storeLng)),
                  ));
                }),
            ]),
          ),
        ],

        const SizedBox(height: 22),
        // Section header
        Row(children: [
          Container(width: 4, height: 20,
              decoration: BoxDecoration(gradient: _greenGradient, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Text(l.sellerStoreProducts,
              style: TextStyle(color: context.pal.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 14),
      ]),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value,
      {VoidCallback? onTap}) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(children: [
          Container(width: 38, height: 38, alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.primary, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: context.pal.textMuted,
                fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.pal.textPrimary,
                    fontSize: 15, fontWeight: FontWeight.w700)),
          ])),
          if (onTap != null)
            Icon(FeatherIcons.chevronRight, color: context.pal.textMuted, size: 20),
        ]),
      ),
    ),
  );

  Widget _stat(BuildContext context, String value, String label, {IconData? icon}) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: context.pal.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.pal.border, width: 0.5),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.warning, size: 16),
            const SizedBox(width: 3),
          ],
          Text(value, style: TextStyle(color: context.pal.textPrimary, fontSize: 17, fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 3),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.pal.textMuted, fontSize: 11)),
      ]),
    ),
  );
}
