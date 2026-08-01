// ignore_for_file: depend_on_referenced_packages
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_l10n.dart';
import '../../core/l10n/shop_l10n.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/category_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/product_model.dart';
import '../../data/models/story_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/flash_deals_provider.dart';
import '../../providers/stories_provider.dart';
import '../../providers/search_provider.dart';
import '../../routes/route_names.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/shimmer_card.dart';
import '../../shared/widgets/inline_ad.dart';
import '../stories/story_viewer_screen.dart';

const String _kMediaHost = 'https://mahmadmurodov-tajikshop.hf.space';

// Brand green → blue gradient, reused across the home surface.
const LinearGradient _greenGradient = LinearGradient(
  colors: [Color(0xFF00D084), Color(0xFF00A3FF)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// Resolve a possibly-relative media path to a full URL.
String _mediaUrl(String path) =>
    path.startsWith('http') ? path : '$_kMediaHost$path';

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
    ref.read(productsProvider.notifier).loadTrending();
    ref.invalidate(categoriesProvider);
  }

  static const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: 14,
    crossAxisSpacing: 14,
    childAspectRatio: 0.62,
  );

  @override
  Widget build(BuildContext context) {
    final ps = ref.watch(productsProvider);
    final pal = context.pal;

    return Scaffold(
      backgroundColor: pal.scaffold,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: pal.card,
          onRefresh: _refresh,
          child: CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _header()),
              SliverToBoxAdapter(child: _searchPill()),
              const SliverToBoxAdapter(child: _StoriesRail()),
              const SliverToBoxAdapter(child: _HeroBanner()),
              const SliverToBoxAdapter(child: _NearbyShopsCard()),
              const SliverToBoxAdapter(child: _FlashDealsRail()),
              SliverToBoxAdapter(child: _PopularRail(products: ps.trending)),
              const SliverToBoxAdapter(child: _RecentlyViewedRail()),

              // Categories
              SliverToBoxAdapter(
                child: _sectionHeader(
                  AppL10n.of(context).categories,
                  () => context.push(RouteNames.categories),
                ),
              ),
              const SliverToBoxAdapter(child: _CategoriesStrip()),

              // Реклама (MREC) дар мобайни feed — мисли маркетплейси воқеӣ
              const SliverToBoxAdapter(child: AdMrec()),

              // Products
              SliverToBoxAdapter(
                child: _sectionHeader(
                  AppL10n.of(context).homeRecommended,
                  () => context.push(RouteNames.search),
                ),
              ),

              if (ps.error != null && ps.products.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorState(message: ps.error!, onRetry: _refresh),
                )
              else if (ps.isLoading && ps.products.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  sliver: SliverGrid(
                    gridDelegate: _gridDelegate,
                    delegate: SliverChildBuilderDelegate(
                      (_, __) =>
                          const ShimmerCard(height: double.infinity, radius: 20),
                      childCount: 6,
                    ),
                  ),
                )
              else if (ps.products.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  sliver: SliverGrid(
                    gridDelegate: _gridDelegate,
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => ProductCard(product: ps.products[i]),
                      childCount: ps.products.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: ps.isLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 22),
                          child: Center(
                            child: SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                  color: AppColors.primary, strokeWidth: 2.4),
                            ),
                          ),
                        )
                      : const SizedBox(height: 28),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar: greeting + brand on the left, soft icon buttons on the right ──
  Widget _header() {
    final pal = context.pal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Салом 👋',
                  style: TextStyle(
                    color: pal.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'TajikShop',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('PRO', style: TextStyle(
                          color: Colors.white, fontSize: 11,
                          fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _circleButton(
            icon: FeatherIcons.messageCircle,
            onTap: () => context.push('/messages'),
          ),
          const SizedBox(width: 10),
          _circleButton(
            icon: FeatherIcons.bell,
            onTap: () => context.push(RouteNames.notifications),
            showDot: true,
          ),
          const SizedBox(width: 10),
          _circleButton(
            icon: FeatherIcons.shoppingCart,
            onTap: () => context.go(RouteNames.cart),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    bool showDot = false,
  }) {
    final pal = context.pal;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: pal.card,
          shape: BoxShape.circle,
          border: Border.all(color: pal.border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 20, color: pal.textPrimary),
            if (showDot)
              Positioned(
                top: 12,
                right: 13,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: pal.card, width: 1.6),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Tappable search pill + gradient filter square ──
  Widget _searchPill() {
    final pal = context.pal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => context.push(RouteNames.search),
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: pal.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: pal.border, width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(FeatherIcons.search, size: 20, color: pal.textMuted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppL10n.of(context).searchProductsHint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: pal.textMuted,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.push(RouteNames.search),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: _greenGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(FeatherIcons.sliders,
                  color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section header row: title + "Ҳама >" ──
  Widget _sectionHeader(String title, VoidCallback onSeeAll) {
    final pal = context.pal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: pal.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: Row(
              children: const [
                Text(
                  'Ҳама',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 2),
                Icon(FeatherIcons.chevronRight,
                    color: AppColors.primary, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// HERO BANNER — static green-gradient promo card
// ════════════════════════════════════════════════════════════════════════════
class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/deals'),
      child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        height: 158,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: _greenGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.32),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Decorative soft circles
              Positioned(
                right: -34,
                top: -42,
                child: _circle(150, 0.14),
              ),
              Positioned(
                right: 34,
                bottom: -46,
                child: _circle(120, 0.10),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Тахфифи махсус',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Тарабфурӯшии тобистона',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'То 50% тахфиф ба маҳсулоти интихобшуда',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _circle(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      );
}

// ════════════════════════════════════════════════════════════════════════════
// POPULAR — horizontal rail of trending products (GET /products/trending)
// ════════════════════════════════════════════════════════════════════════════
class _PopularRail extends StatelessWidget {
  final List<ProductModel> products;
  const _PopularRail({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.length < 2) return const SizedBox.shrink();
    final pal = context.pal;
    final items = products.take(10).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(children: [
            Icon(FeatherIcons.trendingUp, color: pal.textPrimary, size: 18),
            const SizedBox(width: 8),
            Text('Машҳуртарин',
                style: TextStyle(
                    color: pal.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3)),
          ]),
        ),
        SizedBox(
          height: 236,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(
              width: 150,
              child: ProductCard(product: items[i]),
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// RECENTLY VIEWED — personal rail of products the user opened (local, no backend)
// ════════════════════════════════════════════════════════════════════════════
class _RecentlyViewedRail extends ConsumerWidget {
  const _RecentlyViewedRail();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recentlyViewedProvider);
    final items = async.maybeWhen(data: (l) => l, orElse: () => const []);
    if (items.length < 2) return const SizedBox.shrink();

    final pal = context.pal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(children: [
            Icon(FeatherIcons.clock, color: pal.textPrimary, size: 17),
            const SizedBox(width: 8),
            Text('Ба наздикӣ дидед',
                style: TextStyle(
                    color: pal.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3)),
          ]),
        ),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final m = items[i] as Map<String, dynamic>;
              final id = m['id']?.toString() ?? '';
              final title = m['title']?.toString() ?? '';
              final image = m['image']?.toString() ?? '';
              final price = (m['price'] as num?)?.toDouble() ?? 0;
              return GestureDetector(
                onTap: () => context.push('/product/$id'),
                child: SizedBox(
                  width: 110,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 110,
                          height: 100,
                          child: image.isEmpty
                              ? Container(
                                  color: pal.surface,
                                  child: Icon(FeatherIcons.image,
                                      color: pal.textMuted, size: 24))
                              : CachedNetworkImage(
                                  imageUrl: _mediaUrl(image),
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) =>
                                      Container(color: pal.surface),
                                  errorWidget: (_, __, ___) => Container(
                                      color: pal.surface,
                                      child: Icon(FeatherIcons.image,
                                          color: pal.textMuted, size: 24)),
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: pal.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                      Text('${price.toStringAsFixed(0)} с',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// STORIES — Instagram-like ring rail of active shop stories (24h)
// ════════════════════════════════════════════════════════════════════════════
class _StoriesRail extends ConsumerStatefulWidget {
  const _StoriesRail();
  @override
  ConsumerState<_StoriesRail> createState() => _StoriesRailState();
}

class _StoriesRailState extends ConsumerState<_StoriesRail> {
  bool _posting = false;

  Future<void> _postStory() async {
    if (_posting) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked =
          await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75);
      if (picked == null) return;
      setState(() => _posting = true);
      final media = await MultipartFile.fromFile(picked.path, filename: picked.name);
      await StoryService.upload(media);
      if (!mounted) return;
      ref.invalidate(storiesProvider);
      messenger.showSnackBar(const SnackBar(
          content: Text('Ҳикоя нашр шуд ✅'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(
          content: Text('Хатогӣ ҳангоми нашри ҳикоя'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  void _openViewer(List<StoryUser> users, int index) async {
    final shopId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) =>
            StoryViewerScreen(users: users, initialUserIndex: index),
      ),
    );
    if (shopId != null && mounted) context.push('/seller/$shopId');
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(storiesProvider);
    final users = async.maybeWhen(
        data: (list) => list, orElse: () => const <StoryUser>[]);
    final isSeller = ref.watch(authProvider).user?.isSeller ?? false;

    // Агар ягон ҳикоя нест ва корбар фурӯшанда нест → чизе нишон намедиҳем
    if (users.isEmpty && !isSeller) return const SizedBox.shrink();

    final pal = context.pal;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        height: 96,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            if (isSeller)
              _StoryRingItem(
                label: 'Ҳикояи ман',
                avatarUrl: ref.watch(authProvider).user?.avatar ?? '',
                isAdd: true,
                busy: _posting,
                onTap: _postStory,
              ),
            for (int i = 0; i < users.length; i++)
              _StoryRingItem(
                label: users[i].userName,
                avatarUrl: users[i].avatarUrl,
                onTap: () => _openViewer(users, i),
              ),
            if (users.isEmpty && isSeller)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 26),
                child: Text('Аввалин ҳикояи худро нашр кунед',
                    style: TextStyle(color: pal.textMuted, fontSize: 12.5)),
              ),
          ],
        ),
      ),
    );
  }
}

class _StoryRingItem extends StatelessWidget {
  final String label;
  final String avatarUrl;
  final bool isAdd;
  final bool busy;
  final VoidCallback onTap;
  const _StoryRingItem({
    required this.label,
    required this.avatarUrl,
    this.isAdd = false,
    this.busy = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        width: 72,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isAdd ? null : _greenGradient,
              color: isAdd ? pal.surface : null,
              border: isAdd
                  ? Border.all(color: pal.border, width: 1.2)
                  : null,
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: pal.scaffold,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: busy
                    ? const Center(
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.4, color: AppColors.primary)))
                    : (avatarUrl.isEmpty
                        ? Container(
                            color: pal.surface,
                            child: Icon(
                                isAdd
                                    ? FeatherIcons.plus
                                    : FeatherIcons.shoppingBag,
                                color: isAdd
                                    ? AppColors.primary
                                    : pal.textMuted,
                                size: 22),
                          )
                        : CachedNetworkImage(
                            imageUrl: _mediaUrl(avatarUrl),
                            fit: BoxFit.cover,
                            width: 56,
                            height: 56,
                            placeholder: (_, __) =>
                                Container(color: pal.surface),
                            errorWidget: (_, __, ___) => Container(
                                color: pal.surface,
                                child: Icon(FeatherIcons.shoppingBag,
                                    color: pal.textMuted, size: 22)),
                          )),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: pal.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// FLASH DEALS — horizontal rail of time-limited discounts with live countdown
// ════════════════════════════════════════════════════════════════════════════
class _FlashDealsRail extends ConsumerStatefulWidget {
  const _FlashDealsRail();
  @override
  ConsumerState<_FlashDealsRail> createState() => _FlashDealsRailState();
}

class _FlashDealsRailState extends ConsumerState<_FlashDealsRail> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Ҳар сония барои навсозии таймерҳо
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(flashDealsProvider);
    final deals = async.maybeWhen(
      data: (list) =>
          list.where((p) => p.isFlashSale && p.inStock).toList(),
      orElse: () => const <ProductModel>[],
    );
    if (deals.isEmpty) return const SizedBox.shrink();

    final pal = context.pal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: _greenGradient,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(FeatherIcons.zap, color: Colors.white, size: 15),
            ),
            const SizedBox(width: 9),
            Text('Тахфифҳои барқӣ',
                style: TextStyle(
                    color: pal.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3)),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push('/deals'),
              child: Row(children: [
                Text('Ҳама',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const Icon(FeatherIcons.chevronRight,
                    color: AppColors.primary, size: 16),
              ]),
            ),
          ]),
        ),
        SizedBox(
          height: 244,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: deals.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _FlashDealCard(product: deals[i]),
          ),
        ),
      ],
    );
  }
}

class _FlashDealCard extends StatelessWidget {
  final ProductModel product;
  const _FlashDealCard({required this.product});

  String _fmt(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final p = product;
    final left = p.saleEndsAt!.difference(DateTime.now());
    final h = left.inHours;
    final m = left.inMinutes % 60;
    final s = left.inSeconds % 60;
    final countdown = '${_fmt(h)}:${_fmt(m)}:${_fmt(s)}';

    return GestureDetector(
      onTap: () => context.push('/product/${p.id}'),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: pal.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: pal.border, width: 0.6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Расм + бейҷи тахфиф
            Stack(children: [
              SizedBox(
                width: double.infinity,
                height: 128,
                child: p.mainImage.isEmpty
                    ? Container(
                        color: pal.surface,
                        child: Icon(FeatherIcons.image,
                            color: pal.textMuted, size: 28))
                    : CachedNetworkImage(
                        imageUrl: _mediaUrl(p.mainImage),
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: pal.surface),
                        errorWidget: (_, __, ___) => Container(
                            color: pal.surface,
                            child: Icon(FeatherIcons.image,
                                color: pal.textMuted, size: 28)),
                      ),
              ),
              if (p.computedDiscount > 0)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('-${p.computedDiscount}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: pal.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Text('${p.price.toStringAsFixed(0)} с',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800)),
                    if (p.oldPrice != null) ...[
                      const SizedBox(width: 6),
                      Text('${p.oldPrice!.toStringAsFixed(0)}',
                          style: TextStyle(
                              color: pal.textMuted,
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough)),
                    ],
                  ]),
                  const SizedBox(height: 8),
                  // Таймери шумориши баръакс
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(FeatherIcons.clock,
                          color: AppColors.error, size: 12),
                      const SizedBox(width: 5),
                      Text(countdown,
                          style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              fontFeatures: [FontFeature.tabularFigures()])),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// NEARBY SHOPS — tappable card → map of local offline businesses
// ════════════════════════════════════════════════════════════════════════════
class _NearbyShopsCard extends StatelessWidget {
  const _NearbyShopsCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GestureDetector(
        onTap: () => context.push(RouteNames.nearbyShops),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: _greenGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(FeatherIcons.mapPin,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      '🗺 Дӯконҳои наздик',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Бизнесҳои маҳаллиро дар харита ёбед',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(FeatherIcons.chevronRight,
                  color: Colors.white, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// CATEGORIES — horizontal circular avatars from categoriesProvider
// ════════════════════════════════════════════════════════════════════════════
class _CategoriesStrip extends ConsumerWidget {
  const _CategoriesStrip();

  static const double _height = 108;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider);
    final pal = context.pal;

    return cats.when(
      loading: () => SizedBox(
        height: _height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 6,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (_, __) => Column(
            children: [
              const ShimmerCard(width: 64, height: 64, radius: 32),
              const SizedBox(height: 8),
              ShimmerCard(width: 48, height: 10, radius: 4),
            ],
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: _height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, i) {
              final c = list[i];
              return GestureDetector(
                onTap: () {
                  ref.read(searchQueryProvider.notifier).state = c.name;
                  context.push(RouteNames.search);
                },
                child: SizedBox(
                  width: 72,
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: pal.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: pal.border, width: 0.8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _CategoryImage(image: c.image, name: c.name),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        c.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: pal.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _CategoryImage extends StatelessWidget {
  final String? image;
  final String? name;
  const _CategoryImage({required this.image, this.name});

  @override
  Widget build(BuildContext context) {
    if (image == null || image!.isEmpty) return _CategoryFallback(name: name);
    return CachedNetworkImage(
      imageUrl: _mediaUrl(image!),
      fit: BoxFit.cover,
      placeholder: (_, __) => const SizedBox.shrink(),
      errorWidget: (_, __, ___) => _CategoryFallback(name: name),
    );
  }
}

class _CategoryFallback extends StatelessWidget {
  final String? name;
  const _CategoryFallback({this.name});

  @override
  Widget build(BuildContext context) => Center(
        child: Icon(categoryIcon(name), color: AppColors.primary, size: 26),
      );
}

// ════════════════════════════════════════════════════════════════════════════
// EMPTY / ERROR states
// ════════════════════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(FeatherIcons.shoppingBag,
              size: 64, color: pal.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 18),
          Text(
            AppL10n.of(context).noProductsYet,
            style: TextStyle(
              color: pal.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppL10n.of(context).beFirstToPost,
            textAlign: TextAlign.center,
            style: TextStyle(color: pal.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(FeatherIcons.wifiOff, size: 52, color: pal.textMuted),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: pal.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
              decoration: BoxDecoration(
                gradient: _greenGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(FeatherIcons.refreshCw,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    AppL10n.of(context).retry,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
