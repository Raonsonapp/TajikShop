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
  final _scrollController = ScrollController();
  int _bannerIndex = 0;
  final PageController _bannerCtrl = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productsProvider.notifier).loadProducts(refresh: true);
      ref.read(productsProvider.notifier).loadTrending();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(productsProvider.notifier).loadProducts();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _bannerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final products = ref.watch(productsProvider);
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.bgCard,
        onRefresh: () => ref.read(productsProvider.notifier).loadProducts(refresh: true),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // App Bar
            SliverAppBar(
              backgroundColor: AppColors.bgDark,
              floating: true,
              pinned: false,
              elevation: 0,
              toolbarHeight: 64,
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  ShaderMask(
                    shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
                    child: const Text('TajikShop',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        )),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () => context.push(RouteNames.notifications),
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 26),
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),

            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () => context.go(RouteNames.search),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border, width: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text('TajikShop-ро ҷустуҷӯ кунед...',
                                  style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.tune, color: Colors.white, size: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Banner
                  SizedBox(
                    height: 180,
                    child: PageView(
                      controller: _bannerCtrl,
                      onPageChanged: (i) => setState(() => _bannerIndex = i),
                      children: [
                        _buildBanner(
                          'Аксияи калон! 🔥',
                          'То 70% тахфиф',
                          AppColors.primaryGradient,
                          Icons.local_fire_department,
                        ),
                        _buildBanner(
                          'Маҳсулоти нав 🆕',
                          'Охирин маҳсулотҳо',
                          const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)]),
                          Icons.new_releases_rounded,
                        ),
                        _buildBanner(
                          'Фурӯшандагон 🏪',
                          'Беҳтарин дӯконҳо',
                          const LinearGradient(colors: [Color(0xFFFF6B2C), Color(0xFFFFB800)]),
                          Icons.store_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _bannerIndex == i ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _bannerIndex == i ? AppColors.primary : AppColors.textMuted,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    )),
                  ),
                  const SizedBox(height: 24),

                  // Quick Actions
                  SizedBox(
                    height: 90,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _QuickAction(icon: Icons.local_fire_department_rounded, label: 'Тренд', color: const Color(0xFFFF6B2C)),
                        _QuickAction(icon: Icons.discount_outlined, label: 'Тахфиф', color: const Color(0xFF6C63FF)),
                        _QuickAction(icon: Icons.store_rounded, label: 'Дӯконҳо', color: const Color(0xFF00D084)),
                        _QuickAction(icon: Icons.new_releases_rounded, label: 'Нав', color: const Color(0xFF3B82F6)),
                        _QuickAction(icon: Icons.local_shipping_outlined, label: 'Доставка', color: const Color(0xFFFFB800)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Categories
                  categories.when(
                    data: (cats) => cats.isEmpty ? const SizedBox() : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Категорияҳо',
                                  style: TextStyle(color: AppColors.textPrimary,
                                      fontSize: 18, fontWeight: FontWeight.w700)),
                              TextButton(
                                onPressed: () => context.push(RouteNames.categories),
                                child: const Text('Ҳама', style: TextStyle(color: AppColors.primary)),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 48,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: cats.length,
                            itemBuilder: (_, i) => Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: Material(
                                color: AppColors.bgCard,
                                borderRadius: BorderRadius.circular(24),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(24),
                                  onTap: () => ref.read(productsProvider.notifier)
                                      .loadProducts(categoryId: cats[i].id, refresh: true),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    child: Text(cats[i].name,
                                        style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),

                  // Trending
                  if (products.trending.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            const Icon(Icons.local_fire_department_rounded,
                                color: AppColors.accent, size: 20),
                            const SizedBox(width: 6),
                            const Text('Тренд', style: TextStyle(
                                color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                          ]),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Ҳама', style: TextStyle(color: AppColors.primary)),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: products.trending.length,
                        itemBuilder: (_, i) => Container(
                          width: 150,
                          margin: const EdgeInsets.only(right: 12),
                          child: ProductCard(product: products.trending[i]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // All Products title
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Ҳамаи маҳсулот',
                            style: TextStyle(color: AppColors.textPrimary,
                                fontSize: 18, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Products Grid
            if (products.isLoading && products.products.isEmpty)
              const SliverToBoxAdapter(child: ShimmerProductGrid())
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ProductCard(product: products.products[index]),
                    childCount: products.products.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.68,
                  ),
                ),
              ),

            // Loading more
            if (products.isLoading && products.products.isNotEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2,
                    ),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(String title, String subtitle, LinearGradient gradient, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(
                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(subtitle, style: TextStyle(
                    color: Colors.white.withOpacity(0.85), fontSize: 14)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Бузтар кунед', style: TextStyle(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Icon(icon, color: Colors.white.withOpacity(0.3), size: 80),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _QuickAction({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
