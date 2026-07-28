// ignore_for_file: depend_on_referenced_packages
import 'package:cached_network_image/cached_network_image.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_l10n.dart';
import '../../core/l10n/shop_l10n.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/product_provider.dart';
import '../../providers/search_provider.dart';
import '../../routes/route_names.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/shimmer_card.dart';

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
              const SliverToBoxAdapter(child: _HeroBanner()),

              // Categories
              SliverToBoxAdapter(
                child: _sectionHeader(
                  AppL10n.of(context).categories,
                  () => context.push(RouteNames.categories),
                ),
              ),
              const SliverToBoxAdapter(child: _CategoriesStrip()),

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
                const Text(
                  'TajikShop',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
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
    return Padding(
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
                        child: _CategoryImage(image: c.image),
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
  const _CategoryImage({required this.image});

  @override
  Widget build(BuildContext context) {
    if (image == null || image!.isEmpty) return const _CategoryFallback();
    return CachedNetworkImage(
      imageUrl: _mediaUrl(image!),
      fit: BoxFit.cover,
      placeholder: (_, __) => const SizedBox.shrink(),
      errorWidget: (_, __, ___) => const _CategoryFallback(),
    );
  }
}

class _CategoryFallback extends StatelessWidget {
  const _CategoryFallback();

  @override
  Widget build(BuildContext context) => const Center(
        child: Icon(FeatherIcons.grid, color: AppColors.primary, size: 26),
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
