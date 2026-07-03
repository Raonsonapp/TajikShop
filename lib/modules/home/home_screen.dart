// ignore_for_file: depend_on_referenced_packages
// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_l10n.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
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
      backgroundColor: context.pal.scaffold,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: context.pal.card,
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _header(),
            SliverToBoxAdapter(child: _CategoryStrip()),
            SliverToBoxAdapter(
                child: Divider(color: context.pal.border, height: 1)),

            // Feed — марказбозори 2-сутуна (grid)
            if (ps.error != null && ps.products.isEmpty)
              SliverFillRemaining(hasScrollBody: false, child: _errorState(ps.error!))
            else if (ps.isLoading && ps.products.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverGrid(
                  gridDelegate: _gridDelegate,
                  delegate: SliverChildBuilderDelegate(
                      (_, __) => const ShimmerCard(height: double.infinity, radius: 20),
                      childCount: 6),
                ),
              )
            else if (ps.products.isEmpty)
              SliverFillRemaining(hasScrollBody: false, child: _emptyState())
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
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
                        child: Center(child: CircularProgressIndicator(
                            color: AppColors.primary, strokeWidth: 2)))
                    : const SizedBox(height: 24),
              ),
            ],
          ],
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

  // ── Header (Instagram-style) ──────────────────────────────────────────────
  Widget _header() {
    final onBg = context.pal.textPrimary;
    return SliverAppBar(
      backgroundColor: context.pal.scaffold,
      surfaceTintColor: Colors.transparent,
      floating: true, snap: true, elevation: 0,
      systemOverlayStyle: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      titleSpacing: 16,
      title: Row(children: [
        Text('TajikShop',
            style: TextStyle(
                color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.w900,
                letterSpacing: -0.5)),
        const Spacer(),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(Icons.search_rounded, color: onBg, size: 27),
          onPressed: () => context.push(RouteNames.search),
        ),
        const SizedBox(width: 16),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(Icons.notifications_none_rounded, color: onBg, size: 27),
          onPressed: () => context.push(RouteNames.notifications),
        ),
        const SizedBox(width: 16),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(Icons.shopping_bag_outlined, color: onBg, size: 26),
          onPressed: () => context.go(RouteNames.cart),
        ),
      ]),
    );
  }

  Widget _emptyState() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.storefront_outlined, size: 72,
          color: context.pal.textMuted.withValues(alpha: 0.4)),
      const SizedBox(height: 16),
      Text(AppL10n.of(context).noProductsYet,
          style: TextStyle(color: context.pal.textSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text(AppL10n.of(context).beFirstToPost,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.pal.textMuted, fontSize: 13)),
    ]),
  );

  Widget _errorState(String e) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.wifi_off_rounded, color: context.pal.textMuted, size: 48),
      const SizedBox(height: 12),
      Text(e, textAlign: TextAlign.center,
          style: TextStyle(color: context.pal.textMuted, fontSize: 13)),
      const SizedBox(height: 14),
      TextButton.icon(
        onPressed: _refresh,
        icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
        label: Text(AppL10n.of(context).retry, style: const TextStyle(color: AppColors.primary))),
    ]),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// CATEGORY STRIP — категорияҳои маркетплейс (chip-ҳо)
// ════════════════════════════════════════════════════════════════════════════
class _CategoryStrip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider);
    return cats.when(
      loading: () => SizedBox(
        height: 46,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          itemCount: 6,
          itemBuilder: (_, __) => Container(
            width: 88,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
                color: context.pal.surface,
                borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) => SizedBox(
        height: 46,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final c = list[i];
            return GestureDetector(
              onTap: () {
                ref.read(searchQueryProvider.notifier).state = c.name;
                context.push(RouteNames.search);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.pal.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.pal.border, width: 0.6),
                ),
                child: Text(c.name,
                    style: TextStyle(
                        color: context.pal.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            );
          },
        ),
      ),
    );
  }
}
