import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/app_l10n.dart';
import '../../core/l10n/shop_l10n.dart';
import '../../core/services/search_history_service.dart';
import '../../providers/search_provider.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/shimmer_card.dart';
import '../../shared/widgets/safe_input.dart';

/// Градиенти сабз (ecommerce_int2 look, ранги бренди TajikShop).
const LinearGradient _greenGradient = LinearGradient(
  colors: [Color(0xFF00D084), Color(0xFF00A3FF)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Агар аз экрани дигар бо query омада бошем, онро нишон диҳем
      final existing = ref.read(searchQueryProvider);
      if (existing.isNotEmpty) {
        _ctrl.text = existing;
        _ctrl.selection = TextSelection.collapsed(offset: existing.length);
      }
      _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _search(String q) {
    final query = q.trim();
    if (query.isEmpty) return;
    _ctrl.text = query;
    ref.read(searchQueryProvider.notifier).state = query;
    SearchHistoryService.add(query).then((_) {
      if (mounted) ref.invalidate(searchHistoryProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: context.pal.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header (template "Search" title + close) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppL10n.of(context).search,
                    style: TextStyle(
                      color: context.pal.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(FeatherIcons.x,
                        color: context.pal.textPrimary, size: 24),
                    onPressed: () => context.go('/home'),
                  ),
                ],
              ),
            ),

            // ── Prominent rounded search bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(children: [
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: context.pal.surface,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A00D084),
                          offset: Offset(0, 4),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Row(children: [
                      const SizedBox(width: 8),
                      // Градиенти сабз дар иконаи ҷустуҷӯ
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: _greenGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(FeatherIcons.search,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SafeInput(
                          controller: _ctrl,
                          focusNode: _focus,
                          hint: AppL10n.of(context).searchProductsHint,
                          textInputAction: TextInputAction.search,
                          fontSize: 15,
                          textColor: context.pal.textPrimary,
                          onChanged: (v) =>
                              ref.read(searchQueryProvider.notifier).state = v,
                          onSubmitted: _search,
                        ),
                      ),
                      if (query.isNotEmpty)
                        IconButton(
                          icon: Icon(FeatherIcons.x,
                              color: context.pal.textMuted, size: 20),
                          onPressed: () {
                            _ctrl.clear();
                            ref.read(searchQueryProvider.notifier).state = '';
                          },
                        ),
                      const SizedBox(width: 4),
                    ]),
                  ),
                ),
                const SizedBox(width: 12),
                _filterButton(),
              ]),
            ),

            Expanded(
              child: (query.isEmpty && !_hasActiveFilter())
                  ? _buildEmptyState(categories)
                  : results.when(
                      loading: () => GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.68),
                        itemCount: 6,
                        itemBuilder: (_, __) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerCard(height: 150, radius: 16),
                              const SizedBox(height: 8),
                              ShimmerCard(height: 14, width: 120, radius: 4),
                              const SizedBox(height: 4),
                              ShimmerCard(height: 14, width: 80, radius: 4),
                            ]),
                      ),
                      error: (e, _) => Center(
                        child: Text('${AppL10n.of(context).error}: $e',
                            style: const TextStyle(color: AppColors.error)),
                      ),
                      data: (list) => list.isEmpty
                          ? Center(
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(FeatherIcons.search,
                                        size: 80, color: context.pal.textMuted),
                                    const SizedBox(height: 16),
                                    Text(
                                        query.isEmpty
                                            ? AppL10n.of(context).searchNotFound
                                            : '"$query" — ${AppL10n.of(context).searchNotFound}',
                                        style: TextStyle(
                                            color: context.pal.textSecondary,
                                            fontSize: 15)),
                                    const SizedBox(height: 8),
                                    Text(AppL10n.of(context).searchTryAnother,
                                        style: TextStyle(
                                            color: context.pal.textMuted,
                                            fontSize: 13)),
                                  ]),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      20, 0, 20, 12),
                                  child: Row(children: [
                                    Expanded(
                                        child: Text(
                                            query.isEmpty
                                                ? '${list.length} ${AppL10n.of(context).resultsForWord}'
                                                : '${list.length} ${AppL10n.of(context).resultsForWord} "$query"',
                                            style: TextStyle(
                                                color: context.pal.textMuted,
                                                fontSize: 13))),
                                    _sortButton(),
                                  ]),
                                ),
                                Expanded(
                                  child: GridView.builder(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 12,
                                            childAspectRatio: 0.68),
                                    itemCount: list.length,
                                    itemBuilder: (_, i) =>
                                        ProductCard(product: list[i]),
                                  ),
                                ),
                              ],
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sortButton() {
    final l = AppL10n.of(context);
    final opts = <String?, String>{
      null: l.sortNewest,
      'price_asc': l.sortPriceAsc,
      'price_desc': l.sortPriceDesc,
      'popular': l.sortPopular,
    };
    final current = ref.watch(searchSortProvider);
    return PopupMenuButton<String?>(
      color: context.pal.elevated,
      onSelected: (v) => ref.read(searchSortProvider.notifier).state = v,
      itemBuilder: (_) => opts.entries
          .map((e) => PopupMenuItem<String?>(
              value: e.key,
              child: Row(children: [
                if (current == e.key)
                  const Icon(FeatherIcons.check, color: AppColors.primary, size: 16)
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 8),
                Text(e.value,
                    style: TextStyle(color: context.pal.textPrimary)),
              ])))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: context.pal.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.pal.border, width: 0.5)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(FeatherIcons.sliders,
              color: AppColors.primary, size: 16),
          const SizedBox(width: 4),
          Text(opts[current] ?? l.sortNewest,
              style: TextStyle(color: context.pal.textPrimary, fontSize: 12)),
        ]),
      ),
    );
  }

  bool _hasActiveFilter() {
    return ref.watch(searchMinPriceProvider) != null ||
        ref.watch(searchMaxPriceProvider) != null ||
        ref.watch(searchMinRatingProvider) != null ||
        ref.watch(searchCategoryFilterProvider) != null ||
        ref.watch(searchSortProvider) != null;
  }

  Widget _filterButton() {
    final active = _hasActiveFilter();
    return GestureDetector(
      onTap: _openFilterSheet,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: context.pal.surface,
          borderRadius: BorderRadius.circular(18),
          border: active
              ? Border.all(color: AppColors.primary, width: 1.5)
              : Border.all(color: context.pal.border, width: 0.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A00D084),
              offset: Offset(0, 4),
              blurRadius: 16,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(FeatherIcons.sliders,
                color: AppColors.primary, size: 22),
            if (active)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openFilterSheet() {
    _focus.unfocus();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FilterSheet(),
    );
  }

  Widget _recentSearches() {
    final history = ref.watch(searchHistoryProvider);
    return history.maybeWhen(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(AppL10n.of(context).recentSearches,
                style: TextStyle(
                    color: context.pal.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            GestureDetector(
                onTap: () => SearchHistoryService.clear()
                    .then((_) => ref.invalidate(searchHistoryProvider)),
                child: Text(AppL10n.of(context).clearAll,
                    style: const TextStyle(
                        color: AppColors.primary, fontSize: 12))),
          ]),
          const SizedBox(height: 12),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: list
                  .map((q) => GestureDetector(
                        onTap: () => _search(q),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(14, 9, 10, 9),
                          decoration: BoxDecoration(
                              color: context.pal.card,
                              borderRadius: BorderRadius.circular(45),
                              border: Border.all(
                                  color: context.pal.border, width: 0.5)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(FeatherIcons.clock,
                                color: context.pal.textMuted, size: 15),
                            const SizedBox(width: 6),
                            Text(q,
                                style: TextStyle(
                                    color: context.pal.textSecondary,
                                    fontSize: 13)),
                            const SizedBox(width: 6),
                            GestureDetector(
                                onTap: () => SearchHistoryService.remove(q).then(
                                    (_) =>
                                        ref.invalidate(searchHistoryProvider)),
                                child: Icon(FeatherIcons.x,
                                    color: context.pal.textMuted, size: 15)),
                          ]),
                        ),
                      ))
                  .toList()),
          const SizedBox(height: 28),
        ]);
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _recentlyViewed() {
    final recent = ref.watch(recentlyViewedProvider);
    return recent.maybeWhen(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(AppL10n.of(context).recentlyViewed,
              style: TextStyle(
                  color: context.pal.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
              height: 150,
              child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final m = list[i];
                    final id = m['id']?.toString() ?? '';
                    final image = m['image']?.toString() ?? '';
                    final price = (m['price'] as num?)?.toDouble() ?? 0;
                    return GestureDetector(
                      onTap: () => context.push('/product/$id'),
                      child: SizedBox(
                          width: 100,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: image.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: image,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) => Container(
                                                width: 100,
                                                height: 100,
                                                color: context.pal.surface,
                                                child: Icon(
                                                    FeatherIcons.image,
                                                    color:
                                                        context.pal.textMuted)))
                                        : Container(
                                            width: 100,
                                            height: 100,
                                            color: context.pal.surface,
                                            child: Icon(FeatherIcons.image,
                                                color: context.pal.textMuted))),
                                const SizedBox(height: 4),
                                Text(m['title']?.toString() ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: context.pal.textSecondary,
                                        fontSize: 11)),
                                Text('${price.toStringAsFixed(0)} сом.',
                                    style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                              ])),
                    );
                  })),
          const SizedBox(height: 28),
        ]);
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildEmptyState(AsyncValue categories) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _recentSearches(),
          _recentlyViewed(),
          // Popular searches
          Text(AppL10n.of(context).popularSearches,
              style: TextStyle(
                  color: context.pal.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'iPhone',
              'Телевизор',
              'Либос',
              'Пойафзол',
              'Ноутбук',
              'Гӯшвора',
              'Смартфон',
              'Мебел'
            ].map((tag) {
              final active = ref.watch(searchQueryProvider) == tag;
              return GestureDetector(
                onTap: () => _search(tag),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: active ? _greenGradient : null,
                    color: active ? null : context.pal.card,
                    borderRadius: BorderRadius.circular(45),
                    border: Border.all(color: context.pal.border, width: 0.5),
                  ),
                  child: Text(tag,
                      style: TextStyle(
                          color: active
                              ? Colors.white
                              : context.pal.textSecondary,
                          fontSize: 13,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.normal)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          // Categories
          Text(AppL10n.of(context).categories,
              style: TextStyle(
                  color: context.pal.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          categories.when(
            data: (cats) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.1),
              itemCount: cats.length > 9 ? 9 : cats.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _search(cats[i].name),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.pal.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.pal.border, width: 0.5),
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: _greenGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(FeatherIcons.grid,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(cats[i].name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: context.pal.textSecondary,
                                fontSize: 11),
                            textAlign: TextAlign.center),
                      ]),
                ),
              ),
            ),
            loading: () => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.1),
              itemCount: 6,
              itemBuilder: (_, __) => ShimmerCard(radius: 18),
            ),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
    );
  }
}

/// Варақаи поёнии филтрҳо (нарх, баҳо, категория, тартиб).
class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();
  double? _minRating;
  String? _categoryId;
  String? _sort;

  static const _sortOpts = <String?, String>{
    null: 'Нав',
    'price_asc': 'Арзон',
    'price_desc': 'Гарон',
    'popular': 'Оммавӣ',
  };

  @override
  void initState() {
    super.initState();
    final min = ref.read(searchMinPriceProvider);
    final max = ref.read(searchMaxPriceProvider);
    if (min != null) _minCtrl.text = min.toStringAsFixed(0);
    if (max != null) _maxCtrl.text = max.toStringAsFixed(0);
    _minRating = ref.read(searchMinRatingProvider);
    _categoryId = ref.read(searchCategoryFilterProvider);
    _sort = ref.read(searchSortProvider);
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    final min = double.tryParse(_minCtrl.text.trim());
    final max = double.tryParse(_maxCtrl.text.trim());
    ref.read(searchMinPriceProvider.notifier).state = min;
    ref.read(searchMaxPriceProvider.notifier).state = max;
    ref.read(searchMinRatingProvider.notifier).state = _minRating;
    ref.read(searchCategoryFilterProvider.notifier).state = _categoryId;
    ref.read(searchSortProvider.notifier).state = _sort;
    Navigator.of(context).pop();
  }

  void _clear() {
    ref.read(searchMinPriceProvider.notifier).state = null;
    ref.read(searchMaxPriceProvider.notifier).state = null;
    ref.read(searchMinRatingProvider.notifier).state = null;
    ref.read(searchCategoryFilterProvider.notifier).state = null;
    ref.read(searchSortProvider.notifier).state = null;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    return Container(
      decoration: BoxDecoration(
        color: context.pal.scaffold,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Дастак
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: context.pal.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(children: [
              Text('Филтрҳо',
                  style: TextStyle(
                      color: context.pal.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              GestureDetector(
                onTap: _clear,
                child: const Text('Тоза',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 20),

            // ── Нарх ──
            _sectionTitle('Нарх (сомонӣ)'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _priceField(_minCtrl, 'Аз')),
              const SizedBox(width: 12),
              Expanded(child: _priceField(_maxCtrl, 'То')),
            ]),
            const SizedBox(height: 20),

            // ── Баҳо ──
            _sectionTitle('Баҳои камтарин'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [1, 2, 3, 4, 5].map((r) {
                final active = _minRating == r.toDouble();
                return GestureDetector(
                  onTap: () => setState(() =>
                      _minRating = active ? null : r.toDouble()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: active ? null : context.pal.card,
                      gradient: active ? _greenGradient : null,
                      borderRadius: BorderRadius.circular(45),
                      border:
                          Border.all(color: context.pal.border, width: 0.5),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(FeatherIcons.star,
                          size: 14,
                          color: active
                              ? Colors.white
                              : context.pal.textSecondary),
                      const SizedBox(width: 4),
                      Text('$r+',
                          style: TextStyle(
                              color: active
                                  ? Colors.white
                                  : context.pal.textSecondary,
                              fontSize: 13,
                              fontWeight: active
                                  ? FontWeight.w600
                                  : FontWeight.normal)),
                    ]),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Категория ──
            _sectionTitle('Категория'),
            const SizedBox(height: 10),
            categories.when(
              data: (cats) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _categoryChip('Ҳама', null),
                  ...cats.map((c) => _categoryChip(c.name, c.id)),
                ],
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary)),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),

            // ── Тартиб ──
            _sectionTitle('Тартиб'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sortOpts.entries.map((e) {
                final active = _sort == e.key;
                return GestureDetector(
                  onTap: () => setState(() => _sort = e.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: active ? null : context.pal.card,
                      gradient: active ? _greenGradient : null,
                      borderRadius: BorderRadius.circular(45),
                      border:
                          Border.all(color: context.pal.border, width: 0.5),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (active) ...[
                        const Icon(FeatherIcons.check,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                      ],
                      Text(e.value,
                          style: TextStyle(
                              color: active
                                  ? Colors.white
                                  : context.pal.textSecondary,
                              fontSize: 13,
                              fontWeight: active
                                  ? FontWeight.w600
                                  : FontWeight.normal)),
                    ]),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── Татбиқ ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: _greenGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextButton(
                  onPressed: _apply,
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Татбиқ',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: TextStyle(
          color: context.pal.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600));

  Widget _priceField(TextEditingController ctrl, String hint) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: context.pal.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.pal.border, width: 0.5),
      ),
      child: SafeInput(
        controller: ctrl,
        hint: hint,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        textInputAction: TextInputAction.done,
        fontSize: 15,
        textColor: context.pal.textPrimary,
      ),
    );
  }

  Widget _categoryChip(String label, String? id) {
    final active = _categoryId == id;
    return GestureDetector(
      onTap: () => setState(() => _categoryId = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: active ? null : context.pal.card,
          gradient: active ? _greenGradient : null,
          borderRadius: BorderRadius.circular(45),
          border: Border.all(color: context.pal.border, width: 0.5),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : context.pal.textSecondary,
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}
