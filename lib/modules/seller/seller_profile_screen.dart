import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/seller_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/follow_provider.dart';
import '../../routes/route_names.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/shimmer_card.dart';

class SellerProfileScreen extends ConsumerWidget {
  final String id;
  final String name;
  const SellerProfileScreen({super.key, required this.id, this.name = 'Фурӯшанда'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(sellerPublicProvider(id));
    final products = ref.watch(sellerProductsProvider(id));
    final following = ref.watch(followProvider).contains(id);

    return Scaffold(
      backgroundColor: context.pal.scaffold,
      appBar: AppBar(
        backgroundColor: context.pal.scaffold,
        iconTheme: IconThemeData(color: context.pal.textPrimary),
        title: Text(info.maybeWhen(data: (d) => d['name']?.toString() ?? name, orElse: () => name),
            style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w700)),
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
          products.when(
            loading: () => SliverPadding(padding: const EdgeInsets.all(14),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.58),
                delegate: SliverChildBuilderDelegate((_, __) => const ShimmerCard(), childCount: 4))),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
            data: (list) => list.isEmpty
                ? SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(vertical: 50),
                    child: Center(child: Text('Маҳсулоте нест', style: TextStyle(color: context.pal.textMuted)))))
                : SliverPadding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
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
    final avatar = d['avatar_url']?.toString() ?? '';
    final verified = d['is_verified'] == true;
    final rating = (d['rating'] as num?)?.toDouble() ?? 0;
    final followers = (d['followers'] as num?)?.toInt() ?? 0;
    final products = (d['products'] as num?)?.toInt() ?? 0;
    final bio = d['bio']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient),
            child: CircleAvatar(radius: 36, backgroundColor: context.pal.surface,
              backgroundImage: avatar.isNotEmpty ? CachedNetworkImageProvider(avatar) : null,
              child: avatar.isEmpty ? const Icon(Icons.store_rounded, color: Colors.white, size: 32) : null),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _stat('$products', 'Маҳсулот'),
              _stat('$followers', 'Пайравон'),
              _stat(rating > 0 ? rating.toStringAsFixed(1) : '—', 'Баҳо'),
            ]),
          ])),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Text(d['name']?.toString() ?? 'Фурӯшанда',
              style: TextStyle(color: context.pal.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
          if (verified) const Padding(padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.verified_rounded, color: AppColors.info, size: 18)),
        ]),
        if (bio.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(bio, style: TextStyle(color: context.pal.textSecondary, fontSize: 13)),
        ],
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: () {
              if (!ref.read(authProvider).isAuthenticated) return;
              HapticFeedback.selectionClick();
              ref.read(followProvider.notifier).toggle(id);
            },
            child: Container(
              height: 42, alignment: Alignment.center,
              decoration: BoxDecoration(
                color: following ? Colors.transparent : AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary)),
              child: Text(following ? 'Пайгирӣ шуд' : 'Пайгирӣ кардан',
                  style: TextStyle(color: following ? AppColors.primary : Colors.white, fontWeight: FontWeight.w700)),
            ),
          )),
          const SizedBox(width: 10),
          Expanded(child: GestureDetector(
            onTap: () => context.push('${RouteNames.chat}/$id?name=${Uri.encodeComponent(d['name']?.toString() ?? 'Фурӯшанда')}'),
            child: Container(
              height: 42, alignment: Alignment.center,
              decoration: BoxDecoration(color: context.pal.card, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.pal.border)),
              child: Text('Паём', style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w700)),
            ),
          )),
        ]),
        const SizedBox(height: 16),
        Divider(color: context.pal.border, height: 1),
        const SizedBox(height: 8),
        Text('Маҳсулоти дӯкон',
            style: TextStyle(color: context.pal.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _stat(String value, String label) => Column(children: [
    Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
  ]);
}
