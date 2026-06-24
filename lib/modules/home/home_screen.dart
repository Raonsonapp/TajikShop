// ignore_for_file: depend_on_referenced_packages
// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/cart_provider.dart';
import '../../routes/route_names.dart';

/// Instagram gradient барои ҳалқаи stories
const _instaRing = SweepGradient(colors: [
  Color(0xFFFEDA77), Color(0xFFF58529), Color(0xFFDD2A7B),
  Color(0xFF8134AF), Color(0xFF515BD4), Color(0xFFFEDA77),
]);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productsProvider.notifier).loadProducts(refresh: true);
      ref.read(productsProvider.notifier).loadTrending();
    });
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    final ps = ref.read(productsProvider);
    if (ps.isLoading || !ps.hasMore) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 600) {
      ref.read(productsProvider.notifier).loadProducts();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(productsProvider.notifier).loadProducts(refresh: true);
    ref.invalidate(categoriesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final ps = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: RefreshIndicator(
        color: Colors.white,
        backgroundColor: AppColors.bgCard,
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _header(),
            SliverToBoxAdapter(child: _StoriesBar()),
            const SliverToBoxAdapter(
                child: Divider(color: AppColors.border, height: 1)),

            // Feed
            if (ps.error != null && ps.products.isEmpty)
              SliverFillRemaining(hasScrollBody: false, child: _errorState(ps.error!))
            else if (ps.isLoading && ps.products.isEmpty)
              SliverList(delegate: SliverChildBuilderDelegate(
                  (_, __) => const _PostShimmer(), childCount: 4))
            else if (ps.products.isEmpty)
              SliverFillRemaining(hasScrollBody: false, child: _emptyState())
            else
              SliverList(delegate: SliverChildBuilderDelegate((_, i) {
                if (i == ps.products.length) {
                  return ps.isLoading
                      ? const Padding(padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)))
                      : const SizedBox(height: 24);
                }
                return _PostCard(product: ps.products[i]);
              }, childCount: ps.products.length + 1)),
          ],
        ),
      ),
    );
  }

  // ── Header (Instagram-style) ──────────────────────────────────────────────
  Widget _header() {
    return SliverAppBar(
      backgroundColor: AppColors.bgDark,
      surfaceTintColor: Colors.transparent,
      floating: true, snap: true, elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleSpacing: 16,
      title: Row(children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: const Icon(Icons.add_box_outlined, color: Colors.white, size: 28),
          onPressed: () => context.go(RouteNames.upload),
        ),
        const Spacer(),
        const Text('TajikShop',
            style: TextStyle(
                color: Colors.white, fontSize: 27, fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic, letterSpacing: -0.5)),
        const Spacer(),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: const Icon(Icons.favorite_border, color: Colors.white, size: 27),
          onPressed: () => context.push(RouteNames.notifications),
        ),
        const SizedBox(width: 18),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: const Icon(Icons.search, color: Colors.white, size: 27),
          onPressed: () => context.push(RouteNames.search),
        ),
      ]),
    );
  }

  Widget _emptyState() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.storefront_outlined, size: 72,
          color: AppColors.textMuted.withValues(alpha: 0.4)),
      const SizedBox(height: 16),
      const Text('Ҳоло маҳсулот нест',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      const Text('Аввалин эълонро шумо гузоред! 🚀',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
    ]),
  );

  Widget _errorState(String e) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.wifi_off_rounded, color: AppColors.textMuted, size: 48),
      const SizedBox(height: 12),
      Text(e, textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
      const SizedBox(height: 14),
      TextButton.icon(
        onPressed: _refresh,
        icon: const Icon(Icons.refresh_rounded, color: Colors.white),
        label: const Text('Дубора', style: TextStyle(color: Colors.white))),
    ]),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// STORIES BAR — категорияҳо бо ҳалқаи градиентии Instagram
// ════════════════════════════════════════════════════════════════════════════
class _StoriesBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider);
    final user = ref.watch(authProvider).user;

    return SizedBox(
      height: 104,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        children: [
          // Your story
          _StoryItem(
            label: 'Шумо',
            avatar: user?.avatar,
            isOwn: true,
            onTap: () => context.go(RouteNames.upload),
          ),
          ...cats.when(
            data: (list) => list.map((c) => _StoryItem(
              label: c.name,
              imageUrl: c.image,
              onTap: () {
                ref.read(searchQueryProvider.notifier).state = c.name;
                context.push(RouteNames.search);
              },
            )),
            loading: () => List.generate(6, (_) => const _StoryShimmer()),
            error: (_, __) => const <Widget>[],
          ),
        ],
      ),
    );
  }
}

class _StoryItem extends StatelessWidget {
  final String label;
  final String? avatar;
  final String? imageUrl;
  final bool isOwn;
  final VoidCallback onTap;
  const _StoryItem({required this.label, this.avatar, this.imageUrl,
      this.isOwn = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final img = avatar ?? imageUrl;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(children: [
          Container(
            width: 66, height: 66,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isOwn ? null : _instaRing,
              color: isOwn ? AppColors.border : null,
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.bgDark),
              child: Stack(children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.bgSurface,
                  backgroundImage: (img != null && img.isNotEmpty)
                      ? CachedNetworkImageProvider(img) : null,
                  child: (img == null || img.isEmpty)
                      ? Icon(isOwn ? Icons.person_rounded : Icons.category_rounded,
                          color: AppColors.textMuted, size: 26)
                      : null,
                ),
                if (isOwn)
                  Positioned(bottom: 0, right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.info, shape: BoxShape.circle,
                        border: Border.all(color: AppColors.bgDark, width: 2)),
                      child: const Icon(Icons.add, color: Colors.white, size: 14))),
              ]),
            ),
          ),
          const SizedBox(height: 5),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 11)),
        ]),
      ),
    );
  }
}

class _StoryShimmer extends StatelessWidget {
  const _StoryShimmer();
  @override
  Widget build(BuildContext context) => Container(
    width: 72, margin: const EdgeInsets.symmetric(horizontal: 2),
    child: Shimmer.fromColors(
      baseColor: AppColors.shimmerBase, highlightColor: AppColors.shimmerHighlight,
      child: Column(children: [
        Container(width: 66, height: 66,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.shimmerBase)),
        const SizedBox(height: 6),
        Container(width: 44, height: 9, color: AppColors.shimmerBase),
      ]),
    ),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// POST CARD — маҳсулот ҳамчун пости Instagram
// ════════════════════════════════════════════════════════════════════════════
class _PostCard extends ConsumerStatefulWidget {
  final ProductModel product;
  const _PostCard({required this.product});
  @override
  ConsumerState<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<_PostCard>
    with SingleTickerProviderStateMixin {
  int _imgIndex = 0;
  bool _showBigHeart = false;
  late final AnimationController _heartCtrl;

  @override
  void initState() {
    super.initState();
    _heartCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    final p = widget.product;
    final isFav = ref.read(favoritesProvider).contains(p.id);
    if (!isFav) ref.read(favoritesProvider.notifier).toggle(p.id);
    HapticFeedback.lightImpact();
    setState(() => _showBigHeart = true);
    _heartCtrl.forward(from: 0).then((_) {
      if (mounted) setState(() => _showBigHeart = false);
    });
  }

  void _addToCart() async {
    HapticFeedback.selectionClick();
    final messenger = ScaffoldMessenger.of(context);
    if (!ref.read(authProvider).isAuthenticated) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Барои харид ворид шавед'),
        backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
      return;
    }
    try {
      await ref.read(cartProvider.notifier).addToCart(widget.product.id);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: const Text('✅ Ба сабад илова шуд'),
        backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    } catch (_) {}
  }

  void _share() {
    final p = widget.product;
    Clipboard.setData(ClipboardData(
        text: '${p.title} — ${p.price.toStringAsFixed(0)} сом. | TajikShop'));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Нусха гирифта шуд 📋'),
      backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final isFav = ref.watch(favoritesProvider).contains(p.id);
    final images = p.images.isNotEmpty ? p.images : [''];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Header ────────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: _instaRing),
            child: const CircleAvatar(radius: 16,
              backgroundColor: AppColors.bgSurface,
              child: Icon(Icons.store_rounded, color: Colors.white, size: 17)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.sellerName?.isNotEmpty == true ? p.sellerName! : 'tajikshop',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            if (p.categoryName?.isNotEmpty == true)
              Text(p.categoryName!,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ])),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
            onPressed: () => _share()),
        ]),
      ),

      // ── Image (double-tap to like) ────────────────────────────
      GestureDetector(
        onDoubleTap: _onDoubleTap,
        onTap: () => context.push('/product/${p.id}'),
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(alignment: Alignment.center, children: [
            PageView.builder(
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _imgIndex = i),
              itemBuilder: (_, i) => images[i].isEmpty
                  ? Container(color: AppColors.bgSurface,
                      child: const Icon(Icons.image_outlined, color: AppColors.textMuted, size: 60))
                  : CachedNetworkImage(
                      imageUrl: images[i], fit: BoxFit.cover,
                      width: double.infinity, height: double.infinity,
                      placeholder: (_, __) => Container(color: AppColors.bgSurface),
                      errorWidget: (_, __, ___) => Container(color: AppColors.bgSurface,
                          child: const Icon(Icons.image_outlined, color: AppColors.textMuted, size: 60))),
            ),
            // image counter
            if (images.length > 1)
              Positioned(top: 12, right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                      color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                  child: Text('${_imgIndex + 1}/${images.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)))),
            // discount badge
            if (p.computedDiscount > 0)
              Positioned(top: 12, left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppColors.error, borderRadius: BorderRadius.circular(8)),
                  child: Text('-${p.computedDiscount}%',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)))),
            // big heart on double-tap
            if (_showBigHeart)
              ScaleTransition(
                scale: TweenSequence([
                  TweenSequenceItem(tween: Tween(begin: 0.4, end: 1.2).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
                  TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 20),
                  TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 20),
                  TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
                ]).animate(_heartCtrl),
                child: const Icon(Icons.favorite, color: Colors.white, size: 110),
              ),
          ]),
        ),
      ),

      // ── Action row ────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
        child: Row(children: [
          _IconBtn(
            icon: isFav ? Icons.favorite : Icons.favorite_border,
            color: isFav ? AppColors.error : Colors.white,
            onTap: () { HapticFeedback.lightImpact(); ref.read(favoritesProvider.notifier).toggle(p.id); }),
          _IconBtn(icon: Icons.chat_bubble_outline, onTap: () => context.push('/product/${p.id}')),
          _IconBtn(icon: Icons.send_outlined, onTap: _share),
          const Spacer(),
          _IconBtn(icon: Icons.shopping_bag_outlined, onTap: _addToCart),
        ]),
      ),

      // ── Likes / caption / price ───────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (p.likeCount > 0)
            Text('${p.likeCount} писанд',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          RichText(maxLines: 2, overflow: TextOverflow.ellipsis,
            text: TextSpan(children: [
              TextSpan(text: '${p.sellerName?.isNotEmpty == true ? p.sellerName! : "tajikshop"}  ',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              TextSpan(text: p.title,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
            ])),
          const SizedBox(height: 5),
          Row(children: [
            Text('${p.price.toStringAsFixed(0)} сом.',
                style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w800)),
            if (p.oldPrice != null) ...[
              const SizedBox(width: 8),
              Text('${p.oldPrice!.toStringAsFixed(0)} сом.',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12,
                      decoration: TextDecoration.lineThrough)),
            ],
            const Spacer(),
            if (p.rating > 0) ...[
              const Icon(Icons.star_rounded, color: AppColors.warning, size: 15),
              const SizedBox(width: 2),
              Text(p.rating.toStringAsFixed(1),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ]),
          if (p.reviewCount > 0) ...[
            const SizedBox(height: 3),
            Text('Ҳамаи ${p.reviewCount} шарҳро бубинед',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
          const SizedBox(height: 10),
        ]),
      ),
    ]);
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, this.color = Colors.white, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Icon(icon, color: color, size: 27)),
  );
}

// ── Post shimmer placeholder ──────────────────────────────────────────────────
class _PostShimmer extends StatelessWidget {
  const _PostShimmer();
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: AppColors.shimmerBase, highlightColor: AppColors.shimmerHighlight,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.all(12),
        child: Row(children: [
          const CircleAvatar(radius: 16, backgroundColor: AppColors.shimmerBase),
          const SizedBox(width: 10),
          Container(width: 120, height: 12, color: AppColors.shimmerBase),
        ])),
      AspectRatio(aspectRatio: 1, child: Container(color: AppColors.shimmerBase)),
      Padding(padding: const EdgeInsets.all(12),
        child: Container(width: 160, height: 12, color: AppColors.shimmerBase)),
    ]),
  );
}
