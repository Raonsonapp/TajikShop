// ignore_for_file: depend_on_referenced_packages
// ignore_for_file: curly_braces_in_flow_control_structures
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/product_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/shimmer_card.dart';
import '../../data/models/product_model.dart';
import '../../data/models/category_model.dart';
import '../../main.dart' show AppL10n; // ← ИЛОВА ШУД

// ─── Notification count provider ──────────────────────────────────────────────
final _notifCountProvider = FutureProvider<int>((ref) async {
  try {
    final auth = ref.watch(authProvider);
    if (!auth.isAuthenticated) return 0;
    return 0;
  } catch (_) { return 0; }
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _scroll        = ScrollController();
  final _searchCtrl    = TextEditingController();
  final _bannerCtrl    = PageController();
  bool  _searchActive  = false;
  int   _bannerIdx     = 0;
  Timer? _bannerTimer;
  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  String? _selectedCatId;

  static const _banners = [
    _Banner('🛍️ TajikShop',   'Бозори Тоҷикистон — харед ва бифурӯшед',
        Color(0xFF00D084), Color(0xFF00A3FF)),
    _Banner('🔥 Фурӯши Баҳор', 'То -50% тахфиф барои ҳама маҳсулотҳо',
        Color(0xFF6C63FF), Color(0xFFE040FB)),
    _Banner('🚚 Доставка ройгон', 'Барои харид аз 200 сомонӣ',
        Color(0xFFFF6B2C), Color(0xFFFF416C)),
    _Banner('⭐ Фурӯшандаи нав?', 'Ройгон ба фурӯш оғоз кунед',
        Color(0xFFFFB800), Color(0xFFFF6B2C)),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productsProvider.notifier).loadProducts(refresh: true);
      ref.read(productsProvider.notifier).loadTrending();
    });

    _scroll.addListener(_onScroll);

    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_bannerIdx + 1) % _banners.length;
      _bannerCtrl.animateToPage(next,
          duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    });
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300)
      ref.read(productsProvider.notifier).loadProducts();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _bannerCtrl.dispose();
    _bannerTimer?.cancel();
    _searchCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _search(String q) {
    if (q.trim().isEmpty) return;
    setState(() => _searchActive = false);
    _searchCtrl.clear();
    context.push('${RouteNames.search}?q=${Uri.encodeComponent(q.trim())}');
  }

  void _selectCat(String? id) {
    setState(() => _selectedCatId = id);
    ref.read(productsProvider.notifier).loadProducts(refresh: true, categoryId: id);
  }

  @override
  Widget build(BuildContext context) {
    final ps   = ref.watch(productsProvider);
    final cats = ref.watch(categoriesProvider);
    final auth = ref.watch(authProvider);
    final l    = AppL10n.of(context); // ← ИСЛОҲ: context аз build гирифта мешавад

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          controller: _scroll,
          physics: const BouncingScrollPhysics(),
          slivers: [

            // ════════════════════════════════════════════════════
            // APP BAR
            // ════════════════════════════════════════════════════
            SliverAppBar(
              backgroundColor: AppColors.bgDark,
              surfaceTintColor: Colors.transparent,
              floating: true, snap: true, pinned: false, elevation: 0,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              title: _searchActive
                  ? _SearchField(ctrl: _searchCtrl, onSubmit: _search,
                      onClose: () { setState(() => _searchActive = false); _searchCtrl.clear(); })
                  : Row(children: [
                      Container(width: 36, height: 36,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(11),
                          boxShadow: [BoxShadow(
                            color: AppColors.primary.withOpacity(0.4), blurRadius: 10)]),
                        child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 20)),
                      const SizedBox(width: 10),
                      const Text('TajikShop',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800,
                              fontSize: 22, letterSpacing: -0.5)),
                    ]),
              actions: _searchActive ? [] : [
                _AppBarBtn(icon: Icons.search_rounded,
                    onTap: () => setState(() => _searchActive = true)),
                _NotifBtn(),
                GestureDetector(
                  onTap: () => context.push(RouteNames.profile),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: CircleAvatar(radius: 16,
                      backgroundColor: AppColors.bgCard,
                      backgroundImage: auth.user?.avatar != null && auth.user!.avatar!.isNotEmpty
                          ? CachedNetworkImageProvider(auth.user!.avatar!) : null,
                      child: auth.user?.avatar == null || auth.user!.avatar!.isEmpty
                          ? const Icon(Icons.person_rounded, color: AppColors.textSecondary, size: 18) : null))),
              ],
            ),

            SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ══════════════════════════════════════════════════
              // SEARCH BAR
              // ══════════════════════════════════════════════════
              if (!_searchActive)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                  child: GestureDetector(
                    onTap: () => setState(() => _searchActive = true),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 0.8)),
                      child: Row(children: [
                        const SizedBox(width: 12),
                        const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                        const SizedBox(width: 8),
                        // ← ИСЛОҲ: const хорӣ шуд, l.searchHint аз build() гирифта мешавад
                        Expanded(child: Text(l.searchHint,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 13))),
                        Container(margin: const EdgeInsets.all(6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(8)),
                          child: const Text('Ёбед',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
                      ])))),

              // ══════════════════════════════════════════════════
              // BANNER CAROUSEL
              // ══════════════════════════════════════════════════
              const SizedBox(height: 12),
              SizedBox(
                height: 170,
                child: PageView.builder(
                  controller: _bannerCtrl,
                  onPageChanged: (i) => setState(() => _bannerIdx = i),
                  itemCount: _banners.length,
                  itemBuilder: (_, i) => _BannerCard(banner: _banners[i])),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 6),
                child: Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_banners.length, (i) =>
                    AnimatedContainer(duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _bannerIdx == i ? 24 : 6, height: 6,
                      decoration: BoxDecoration(
                        gradient: _bannerIdx == i ? AppColors.primaryGradient : null,
                        color: _bannerIdx == i ? null : AppColors.textMuted.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(3)))))),

              // ══════════════════════════════════════════════════
              // PROMO CHIPS
              // ══════════════════════════════════════════════════
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                child: Row(children: [
                  _PromoChip(icon: Icons.local_shipping_rounded,
                      label: 'Доставка', color: const Color(0xFF00A3FF)),
                  const SizedBox(width: 8),
                  _PromoChip(icon: Icons.verified_rounded,
                      label: 'Тасдиқшуда', color: const Color(0xFF00D084)),
                  const SizedBox(width: 8),
                  _PromoChip(icon: Icons.replay_rounded,
                      label: 'Бозгашт', color: const Color(0xFFFF6B2C)),
                  const SizedBox(width: 8),
                  _PromoChip(icon: Icons.headset_mic_rounded,
                      label: 'Дастгирӣ', color: const Color(0xFFE040FB)),
                ])),

              // ══════════════════════════════════════════════════
              // CATEGORIES
              // ══════════════════════════════════════════════════
              _SectionHeader(title: l.categories,
                  onSeeAll: () => context.push(RouteNames.categories)),
              SizedBox(height: 100,
                child: cats.when(
                  loading: () => _catShimmer(),
                  error: (_, __) => const SizedBox(),
                  data: (list) => ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: list.length + 1,
                    itemBuilder: (_, i) {
                      if (i == 0) return _CatChip(
                        id: null, name: 'Ҳама', emoji: '🏪',
                        selected: _selectedCatId == null,
                        onTap: () => _selectCat(null));
                      final c = list[i - 1];
                      return _CatChip(
                        id: c.id, name: c.name, emoji: _catEmoji(c.name),
                        selected: _selectedCatId == c.id,
                        onTap: () => _selectCat(c.id));
                    }))),

              // ══════════════════════════════════════════════════
              // TRENDING
              // ══════════════════════════════════════════════════
              if (ps.trending.isNotEmpty) ...[
                _SectionHeader(title: l.trending, onSeeAll: null),
                SizedBox(height: 250,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                    itemCount: ps.trending.length,
                    itemBuilder: (_, i) => SizedBox(width: 160,
                      child: Padding(padding: const EdgeInsets.only(right: 12),
                        child: ProductCard(product: ps.trending[i]))))),
              ],

              // ══════════════════════════════════════════════════
              // FLASH SALE
              // ══════════════════════════════════════════════════
              Builder(builder: (_) {
                final sale = ps.products.where((p) => p.computedDiscount > 0).toList();
                if (sale.isEmpty) return const SizedBox();
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _SectionHeader(title: l.flashSale, onSeeAll: null),
                  SizedBox(height: 250,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                      itemCount: sale.take(10).length,
                      itemBuilder: (_, i) => SizedBox(width: 160,
                        child: Padding(padding: const EdgeInsets.only(right: 12),
                          child: ProductCard(product: sale[i]))))),
                ]);
              }),

              // ══════════════════════════════════════════════════
              // ALL PRODUCTS header
              // ══════════════════════════════════════════════════
              _SectionHeader(title: l.allProducts, onSeeAll: null),
              if (ps.error != null)
                Padding(padding: const EdgeInsets.all(20),
                  child: Center(child: Column(children: [
                    const Icon(Icons.wifi_off_rounded, color: AppColors.textMuted, size: 40),
                    const SizedBox(height: 8),
                    Text(ps.error!, style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => ref.read(productsProvider.notifier).loadProducts(refresh: true),
                      icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                      label: const Text('Дубора', style: TextStyle(color: AppColors.primary))),
                  ]))),
            ])),

            // ══════════════════════════════════════════════════
            // PRODUCTS GRID
            // ══════════════════════════════════════════════════
            ps.isLoading && ps.products.isEmpty
                ? SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, crossAxisSpacing: 12,
                          mainAxisSpacing: 12, childAspectRatio: 0.58),
                      delegate: SliverChildBuilderDelegate(
                          (_, __) => const ShimmerCard(), childCount: 6)))
                : ps.products.isEmpty && !ps.isLoading
                    ? const SliverToBoxAdapter(child: _EmptyState())
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2, crossAxisSpacing: 12,
                              mainAxisSpacing: 12, childAspectRatio: 0.58),
                          delegate: SliverChildBuilderDelegate((_, i) {
                            if (i == ps.products.length) {
                              return ps.isLoading
                                  ? const Center(child: Padding(padding: EdgeInsets.all(20),
                                      child: CircularProgressIndicator(
                                          color: AppColors.primary, strokeWidth: 2)))
                                  : const SizedBox();
                            }
                            return ProductCard(product: ps.products[i]);
                          }, childCount: ps.products.length + (ps.isLoading ? 1 : 0)))),
          ],
        ),
      ),
    );
  }

  Widget _catShimmer() => ListView.builder(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    itemCount: 7,
    itemBuilder: (_, __) => Padding(padding: const EdgeInsets.only(right: 10),
      child: Column(children: [
        ShimmerCard(width: 60, height: 60, radius: 18),
        const SizedBox(height: 6),
        ShimmerCard(width: 48, height: 10, radius: 4)])));

  String _catEmoji(String name) {
    final n = name.toLowerCase();
    if (n.contains('телефон') || n.contains('техника') || n.contains('электр')) return '📱';
    if (n.contains('кийим') || n.contains('либос') || n.contains('мода')) return '👗';
    if (n.contains('хона') || n.contains('хонагӣ') || n.contains('мебел')) return '🏠';
    if (n.contains('бозӣ') || n.contains('game')) return '🎮';
    if (n.contains('китоб') || n.contains('таълим')) return '📚';
    if (n.contains('косметик') || n.contains('зебоӣ')) return '💄';
    if (n.contains('ғизо') || n.contains('хурок')) return '🍎';
    if (n.contains('мошин') || n.contains('авто')) return '🚗';
    if (n.contains('варзиш') || n.contains('спорт')) return '⚽';
    if (n.contains('тилло') || n.contains('зевар')) return '💍';
    if (n.contains('кӯдак') || n.contains('бача')) return '🧸';
    if (n.contains('боғ') || n.contains('растан')) return '🌱';
    return '🛍️';
  }
}

// ─── Banner model ─────────────────────────────────────────────────────────────
class _Banner {
  final String title, sub;
  final Color c1, c2;
  const _Banner(this.title, this.sub, this.c1, this.c2);
}

// ─── Banner Card ──────────────────────────────────────────────────────────────
class _BannerCard extends StatelessWidget {
  final _Banner banner;
  const _BannerCard({super.key, required this.banner});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(14, 0, 14, 0),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [banner.c1, banner.c2],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(22),
      boxShadow: [BoxShadow(
          color: banner.c1.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 6))]),
    child: Stack(children: [
      Positioned(right: -25, top: -25,
        child: Container(width: 130, height: 130,
          decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08)))),
      Positioned(right: 30, bottom: -35,
        child: Container(width: 100, height: 100,
          decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.06)))),
      Positioned(left: -10, bottom: -20,
        child: Container(width: 80, height: 80,
          decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05)))),
      Padding(padding: const EdgeInsets.all(22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(banner.title,
              style: const TextStyle(color: Colors.white,
                  fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          const SizedBox(height: 5),
          Text(banner.sub,
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.35))),
            child: const Text('Бештар →',
                style: TextStyle(color: Colors.white,
                    fontSize: 12, fontWeight: FontWeight.w700))),
        ])),
    ]));
}

// ─── Category Chip ────────────────────────────────────────────────────────────
class _CatChip extends StatelessWidget {
  final String? id;
  final String name, emoji;
  final bool selected;
  final VoidCallback onTap;
  const _CatChip({this.id, required this.name, required this.emoji,
      required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 10),
      width: 72,
      child: Column(children: [
        AnimatedContainer(duration: const Duration(milliseconds: 220),
          width: 62, height: 62,
          decoration: BoxDecoration(
            gradient: selected ? AppColors.primaryGradient : null,
            color: selected ? null : AppColors.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: selected ? Colors.transparent : AppColors.border, width: 0.8),
            boxShadow: selected ? [BoxShadow(
                color: AppColors.primary.withOpacity(0.4), blurRadius: 10)] : [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6)]),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26)))),
        const SizedBox(height: 6),
        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? AppColors.primary : AppColors.textSecondary,
              fontSize: 10, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
      ])));
}

// ─── Promo Chip ───────────────────────────────────────────────────────────────
class _PromoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _PromoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600),
            maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
      ])));
}

// ─── Section Header ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: const TextStyle(color: Colors.white,
          fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
      if (onSeeAll != null)
        GestureDetector(onTap: onSeeAll,
          child: Row(children: const [
            Text('Ҳама', style: TextStyle(color: AppColors.primary,
                fontSize: 13, fontWeight: FontWeight.w600)),
            Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 18),
          ])),
    ]));
}

// ─── AppBar Button ────────────────────────────────────────────────────────────
class _AppBarBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _AppBarBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
    icon: Icon(icon, color: Colors.white, size: 24), onPressed: onTap);
}

// ─── Notification Bell ────────────────────────────────────────────────────────
class _NotifBtn extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(_notifCountProvider).value ?? 0;
    return Stack(children: [
      IconButton(
        icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
        onPressed: () => context.push(RouteNames.notifications)),
      if (count > 0)
        Positioned(top: 8, right: 8,
          child: Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFFF3B5C), shape: BoxShape.circle))),
    ]);
  }
}

// ─── Search Field ─────────────────────────────────────────────────────────────
class _SearchField extends StatelessWidget {
  final TextEditingController ctrl;
  final ValueChanged<String> onSubmit;
  final VoidCallback onClose;
  const _SearchField({required this.ctrl, required this.onSubmit, required this.onClose});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.5))),
      child: TextField(
        controller: ctrl, autofocus: true,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'Маҳсулот ёбед...',
          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted, size: 18),
          contentPadding: EdgeInsets.symmetric(vertical: 9)),
        onSubmitted: onSubmit,
        textInputAction: TextInputAction.search))),
    const SizedBox(width: 8),
    GestureDetector(onTap: onClose,
      child: const Text('Бекор',
          style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600))),
  ]);
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 60),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.storefront_outlined, size: 72,
          color: AppColors.textMuted.withOpacity(0.35)),
      const SizedBox(height: 16),
      const Text('Ҳоло маҳсулот нест',
          style: TextStyle(color: AppColors.textMuted, fontSize: 16,
              fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      const Text('Аввалин маҳсулотро шумо гузоред! 🚀',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
    ]));
}
