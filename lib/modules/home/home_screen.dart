// ignore_for_file: depend_on_referenced_packages
import 'package:card_swiper/card_swiper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_l10n.dart';
import '../../core/l10n/shop_l10n.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../routes/route_names.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/shimmer_card.dart';

// Green accent gradient used everywhere the template used its orange gradient.
const LinearGradient _greenGradient = LinearGradient(
  colors: [Color(0xFF00D084), Color(0xFF00A3FF)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

const List<BoxShadow> _softShadow = [
  BoxShadow(color: Colors.black12, offset: Offset(0, 3), blurRadius: 6),
];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scroll = ScrollController();

  // Template "timeline" selector (Weekly featured / Best of June / Best of 2018).
  List<String> get _timelines {
    final l = AppL10n.of(context);
    return [l.homeTabNew, l.homeTabPopular, l.homeTabDiscount];
  }

  int _selectedTimeline = 0;

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

  // Which list feeds the top carousel, driven by the timeline selector.
  List<ProductModel> _carouselItems(ProductsState ps) {
    List<ProductModel> src;
    if (_selectedTimeline == 0) {
      src = ps.products;
    } else {
      src = ps.trending.isNotEmpty ? ps.trending : ps.products;
    }
    return src.take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ps = ref.watch(productsProvider);
    final carousel = _carouselItems(ps);

    return Scaffold(
      backgroundColor: context.pal.scaffold,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: context.pal.card,
          onRefresh: _refresh,
          child: CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Header (notifications / brand / cart) ──────────────────
              SliverToBoxAdapter(child: _header()),

              // ── Search field ──────────────────────────────────────────
              SliverToBoxAdapter(child: _searchField()),

              // ── Timeline selector (Нав / Оммавӣ / Тахфиф) ─────────────
              SliverToBoxAdapter(child: _timelineHeader()),

              // ── Featured carousel ─────────────────────────────────────
              SliverToBoxAdapter(
                child: (ps.isLoading && carousel.isEmpty)
                    ? _carouselPlaceholder()
                    : (carousel.isEmpty
                        ? const SizedBox.shrink()
                        : _FeaturedCarousel(products: carousel)),
              ),

              // ── Category cards ────────────────────────────────────────
              const SliverToBoxAdapter(child: _CategoryRow()),

              // ── "Recommended" section title ───────────────────────────
              SliverToBoxAdapter(
                  child: _sectionTitle(AppL10n.of(context).homeRecommended)),

              // ── Recommended grid + states ─────────────────────────────
              if (ps.error != null && ps.products.isEmpty)
                SliverFillRemaining(
                    hasScrollBody: false, child: _errorState(ps.error!))
              else if (ps.isLoading && ps.products.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: _gridDelegate,
                    delegate: SliverChildBuilderDelegate(
                        (_, __) =>
                            const ShimmerCard(height: double.infinity, radius: 20),
                        childCount: 6),
                  ),
                )
              else if (ps.products.isEmpty)
                SliverFillRemaining(hasScrollBody: false, child: _emptyState())
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  sliver: SliverGrid(
                    gridDelegate: _gridDelegate,
                    delegate: SliverChildBuilderDelegate(
                        (_, i) => ProductCard(product: ps.products[i]),
                        childCount: ps.products.length),
                  ),
                ),
                SliverToBoxAdapter(
                  child: ps.isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary, strokeWidth: 2)))
                      : const SizedBox(height: 28),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: 0.62,
  );

  // ── Header row ──────────────────────────────────────────────────────────
  Widget _header() {
    final onBg = context.pal.textPrimary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.notifications_none_rounded, color: onBg, size: 27),
            onPressed: () => context.push(RouteNames.notifications),
          ),
          Text('TajikShop',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5)),
          IconButton(
            icon: Icon(Icons.shopping_bag_outlined, color: onBg, size: 26),
            onPressed: () => context.go(RouteNames.cart),
          ),
        ],
      ),
    );
  }

  // ── Search field (tap → search screen) ──────────────────────────────────
  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: GestureDetector(
        onTap: () => context.push(RouteNames.search),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: context.pal.card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _softShadow,
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: context.pal.textMuted, size: 22),
              const SizedBox(width: 10),
              Text(AppL10n.of(context).search,
                  style: TextStyle(
                      color: context.pal.textMuted,
                      fontSize: 15,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Timeline selector row ───────────────────────────────────────────────
  Widget _timelineHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_timelines.length, (i) {
          final selected = i == _selectedTimeline;
          return Flexible(
            child: InkWell(
              onTap: () => setState(() => _selectedTimeline = i),
              child: Text(
                _timelines[i],
                textAlign: i == 0
                    ? TextAlign.left
                    : (i == _timelines.length - 1
                        ? TextAlign.right
                        : TextAlign.center),
                style: TextStyle(
                    fontSize: selected ? 20 : 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? context.pal.textPrimary
                        : context.pal.textSecondary),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _carouselPlaceholder() {
    final h = MediaQuery.of(context).size.height / 2.7;
    return SizedBox(
      height: h,
      child: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width / 1.8,
          child: ShimmerCard(height: h, radius: 24),
        ),
      ),
    );
  }

  // ── Section title (green accent bar + label) ────────────────────────────
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  color: context.pal.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _emptyState() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.storefront_outlined,
              size: 72, color: context.pal.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(AppL10n.of(context).noProductsYet,
              style: TextStyle(
                  color: context.pal.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(AppL10n.of(context).beFirstToPost,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.pal.textMuted, fontSize: 13)),
        ]),
      );

  Widget _errorState(String e) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.wifi_off_rounded, color: context.pal.textMuted, size: 48),
          const SizedBox(height: 12),
          Text(e,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.pal.textMuted, fontSize: 13)),
          const SizedBox(height: 14),
          TextButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
              label: Text(AppL10n.of(context).retry,
                  style: const TextStyle(color: AppColors.primary))),
        ]),
      );
}

// ════════════════════════════════════════════════════════════════════════════
// FEATURED CAROUSEL — mirrors template ProductList (card_swiper)
// ════════════════════════════════════════════════════════════════════════════
class _FeaturedCarousel extends StatelessWidget {
  final List<ProductModel> products;
  const _FeaturedCarousel({required this.products});

  @override
  Widget build(BuildContext context) {
    final cardHeight = MediaQuery.of(context).size.height / 2.7;
    final cardWidth = MediaQuery.of(context).size.width / 1.8;

    return SizedBox(
      height: cardHeight,
      child: Swiper(
        itemCount: products.length,
        loop: false,
        scale: 0.86,
        fade: 0.6,
        viewportFraction: 0.62,
        itemBuilder: (_, index) => _CarouselCard(
          product: products[index],
          height: cardHeight,
          width: cardWidth,
        ),
      ),
    );
  }
}

class _CarouselCard extends ConsumerWidget {
  final ProductModel product;
  final double height;
  final double width;
  const _CarouselCard({
    required this.product,
    required this.height,
    required this.width,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = product;
    final isFav = ref.watch(favoritesProvider).contains(p.id);

    return GestureDetector(
      onTap: () => context.push('/product/${p.id}'),
      child: Stack(
        children: [
          // Green gradient card body
          Container(
            margin: const EdgeInsets.only(left: 30),
            height: height,
            width: width,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(24)),
              gradient: _greenGradient,
              boxShadow: _softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    isFav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(favoritesProvider.notifier).toggle(p.id);
                  },
                ),
                Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          p.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding:
                            const EdgeInsets.fromLTRB(8, 4, 12, 4),
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                              bottomLeft: Radius.circular(10)),
                          color: AppColors.primaryDark,
                        ),
                        child: Text(
                          '${p.price.toStringAsFixed(0)} сом.',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Floating product image
          Positioned(
            top: height * 0.14,
            left: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: height / 1.9,
                width: width / 1.25,
                child: p.mainImage.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: p.mainImage,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: Colors.white24),
                        errorWidget: (_, __, ___) =>
                            _fallback(),
                      )
                    : _fallback(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() => Container(
        color: Colors.white24,
        child: const Center(
          child: Icon(Icons.image_outlined, color: Colors.white70, size: 40),
        ),
      );
}

// ════════════════════════════════════════════════════════════════════════════
// CATEGORY ROW — mirrors template CategoryCard list
// ════════════════════════════════════════════════════════════════════════════
class _CategoryRow extends ConsumerWidget {
  const _CategoryRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider);
    return cats.when(
      loading: () => SizedBox(
        height: 96,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: 5,
          itemBuilder: (_, __) => Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: context.pal.surface,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final c = list[i];
              return GestureDetector(
                onTap: () {
                  ref.read(searchQueryProvider.notifier).state = c.name;
                  context.push(RouteNames.search);
                },
                child: Container(
                  width: 170,
                  decoration: BoxDecoration(
                    color: context.pal.card,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _softShadow,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    children: [
                      // Left: category name
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            c.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: context.pal.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      // Right: green gradient image tile
                      Container(
                        height: 80,
                        width: 80,
                        decoration: const BoxDecoration(gradient: _greenGradient),
                        padding: const EdgeInsets.all(10),
                        child: Center(
                          child: _catImage(c.image),
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

  Widget _catImage(String? image) {
    if (image == null || image.isEmpty) {
      return const Icon(Icons.category_rounded, color: Colors.white, size: 30);
    }
    final url = image.startsWith('http')
        ? image
        : 'https://mahmadmurodov-tajikshop.hf.space$image';
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.contain,
      placeholder: (_, __) => const SizedBox.shrink(),
      errorWidget: (_, __, ___) =>
          const Icon(Icons.category_rounded, color: Colors.white, size: 30),
    );
  }
}
