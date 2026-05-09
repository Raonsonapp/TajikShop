import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/product_provider.dart';
import '../../providers/search_provider.dart';
import '../../routes/route_names.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/shimmer_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scroll = ScrollController();
  int _banner = 0;
  final _bannerCtrl = PageController();

  final _banners = [
    {'title': 'TajikShop', 'sub': 'Бозори Тоҷикистон', 'color': AppColors.primary},
    {'title': 'Фурӯши Баҳор 🌸', 'sub': 'То -50% тахфиф', 'color': Color(0xFF6C63FF)},
    {'title': 'Доставка ройгон', 'sub': 'Барои харид аз 200 сом.', 'color': Color(0xFF00BFA5)},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productsProvider.notifier).loadProducts(refresh: true);
      ref.read(productsProvider.notifier).loadTrending();
    });
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
        ref.read(productsProvider.notifier).loadProducts();
      }
    });
  }

  @override
  void dispose() { _scroll.dispose(); _bannerCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final cats = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          // App Bar
          SliverAppBar(
            backgroundColor: AppColors.bgDark,
            floating: true, snap: true, pinned: false,
            title: Row(children: [
              Container(width: 32, height: 32,
                decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 18)),
              const SizedBox(width: 8),
              const Text('TajikShop', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20)),
            ]),
            actions: [
              IconButton(icon: const Icon(Icons.search_rounded, color: AppColors.textPrimary),
                  onPressed: () => context.go(RouteNames.search)),
              IconButton(icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                  onPressed: () => context.push(RouteNames.notifications)),
            ],
          ),

          SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Banner
            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: _bannerCtrl,
                onPageChanged: (i) => setState(() => _banner = i),
                itemCount: _banners.length,
                itemBuilder: (_, i) => Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [(_banners[i]['color'] as Color), (_banners[i]['color'] as Color).withValues(alpha: 0.7)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20)),
                  child: Padding(padding: const EdgeInsets.all(20), child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_banners[i]['title'] as String,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(_banners[i]['sub'] as String,
                          style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ])),
                ),
              ),
            ),
            // Banner dots
            Padding(padding: const EdgeInsets.only(top: 10),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_banners.length,
                (i) => AnimatedContainer(duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _banner == i ? 20 : 6, height: 6,
                  decoration: BoxDecoration(
                    color: _banner == i ? AppColors.primary : AppColors.textMuted,
                    borderRadius: BorderRadius.circular(3)))))),

            // Categories
            const Padding(padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Text('Категорияҳо', style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700))),
            SizedBox(height: 90, child: cats.when(
              loading: () => ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: 6, itemBuilder: (_, __) => Padding(padding: const EdgeInsets.only(right: 10),
                  child: Column(children: [ShimmerCard(width: 56, height: 56, radius: 16), const SizedBox(height: 6), ShimmerCard(height: 10, width: 50, radius: 4)]))),
              error: (_, __) => const SizedBox(),
              data: (list) => ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: list.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => context.push(RouteNames.categories),
                  child: Container(margin: const EdgeInsets.only(right: 10), width: 70,
                    child: Column(children: [
                      Container(width: 56, height: 56,
                        decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.category_outlined, color: AppColors.primary, size: 26)),
                      const SizedBox(height: 6),
                      Text(list[i].name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                    ])),
                )),
            )),

            // Trending
            if (products.trending.isNotEmpty) ...[
              const Padding(padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Text('🔥 Маъруб', style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700))),
              SizedBox(height: 230, child: ListView.builder(scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: products.trending.length,
                itemBuilder: (_, i) => SizedBox(width: 150, child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ProductCard(product: products.trending[i]))))),
            ],

            // All products title
            const Padding(padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Text('Ҳамаи маҳсулотҳо', style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700))),
          ])),

          // Products Grid
          products.isLoading && products.products.isEmpty
              ? SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.68),
                    delegate: SliverChildBuilderDelegate((_, i) => const ShimmerCard(), childCount: 6)))
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.68),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        if (i == products.products.length) {
                          return products.isLoading
                              ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                              : const SizedBox();
                        }
                        return ProductCard(product: products.products[i]);
                      },
                      childCount: products.products.length + (products.isLoading ? 1 : 0),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
