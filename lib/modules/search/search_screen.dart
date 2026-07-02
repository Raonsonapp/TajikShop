import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/app_l10n.dart';
import '../../core/services/search_history_service.dart';
import '../../providers/search_provider.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/shimmer_card.dart';
import '../../shared/widgets/safe_input.dart';

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
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
                  onPressed: () => context.go('/home'),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                    child: Row(children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: SafeInput(
                        controller: _ctrl,
                        focusNode: _focus,
                        hint: AppL10n.of(context).searchProductsHint,
                        textInputAction: TextInputAction.search,
                        fontSize: 14,
                        textColor: AppColors.textPrimary,
                        onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
                        onSubmitted: _search,
                      )),
                      if (query.isNotEmpty) IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                        onPressed: () { _ctrl.clear(); ref.read(searchQueryProvider.notifier).state = ''; },
                      ),
                      const SizedBox(width: 4),
                    ]),
                  ),
                ),
              ]),
            ),

            Expanded(
              child: query.isEmpty
                  ? _buildEmptyState(categories)
                  : results.when(
                      loading: () => GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.68),
                        itemCount: 6,
                        itemBuilder: (_, __) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          ShimmerCard(height: 150, radius: 16),
                          const SizedBox(height: 8),
                          ShimmerCard(height: 14, width: 120, radius: 4),
                          const SizedBox(height: 4),
                          ShimmerCard(height: 14, width: 80, radius: 4),
                        ]),
                      ),
                      error: (e, _) => Center(
                        child: Text('Хато: $e', style: const TextStyle(color: AppColors.error)),
                      ),
                      data: (list) => list.isEmpty
                          ? Center(
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.search_off_rounded, size: 80, color: AppColors.textMuted),
                                const SizedBox(height: 16),
                                Text('"$query" — ёфт нашуд',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                                const SizedBox(height: 8),
                                const Text('Калимаи дигар истифода кунед',
                                    style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                              ]),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                  child: Row(children: [
                                    Expanded(child: Text('${list.length} натиҷа барои "$query"',
                                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13))),
                                    _sortButton(),
                                  ]),
                                ),
                                Expanded(
                                  child: GridView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.68),
                                    itemCount: list.length,
                                    itemBuilder: (_, i) => ProductCard(product: list[i]),
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
    const opts = {
      null: 'Нав', 'price_asc': 'Арзон → Қимат',
      'price_desc': 'Қимат → Арзон', 'popular': 'Машҳур',
    };
    final current = ref.watch(searchSortProvider);
    return PopupMenuButton<String?>(
      color: AppColors.bgElevated,
      onSelected: (v) => ref.read(searchSortProvider.notifier).state = v,
      itemBuilder: (_) => opts.entries.map((e) => PopupMenuItem<String?>(
        value: e.key,
        child: Row(children: [
          if (current == e.key) const Icon(Icons.check, color: AppColors.primary, size: 16)
          else const SizedBox(width: 16),
          const SizedBox(width: 8),
          Text(e.value, style: const TextStyle(color: AppColors.textPrimary)),
        ]))).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 0.5)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.swap_vert_rounded, color: AppColors.primary, size: 16),
          const SizedBox(width: 4),
          Text(opts[current] ?? 'Нав', style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _recentSearches() {
    final history = ref.watch(searchHistoryProvider);
    return history.maybeWhen(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Ҷустуҷӯҳои охирин',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            GestureDetector(
              onTap: () => SearchHistoryService.clear().then((_) => ref.invalidate(searchHistoryProvider)),
              child: const Text('Тоза кардан', style: TextStyle(color: AppColors.primary, fontSize: 12))),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: list.map((q) => GestureDetector(
            onTap: () => _search(q),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 0.5)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.history_rounded, color: AppColors.textMuted, size: 15),
                const SizedBox(width: 6),
                Text(q, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => SearchHistoryService.remove(q).then((_) => ref.invalidate(searchHistoryProvider)),
                  child: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 15)),
              ]),
            ),
          )).toList()),
          const SizedBox(height: 24),
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
          const Text('Бознигаристашуда',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SizedBox(height: 150, child: ListView.separated(
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
                child: SizedBox(width: 100, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ClipRRect(borderRadius: BorderRadius.circular(12),
                    child: image.isNotEmpty
                        ? CachedNetworkImage(imageUrl: image, width: 100, height: 100, fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(width: 100, height: 100, color: AppColors.bgSurface,
                                child: const Icon(Icons.image_outlined, color: AppColors.textMuted)))
                        : Container(width: 100, height: 100, color: AppColors.bgSurface,
                            child: const Icon(Icons.image_outlined, color: AppColors.textMuted))),
                  const SizedBox(height: 4),
                  Text(m['title']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  Text('${price.toStringAsFixed(0)} сом.',
                      style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                ])),
              );
            })),
          const SizedBox(height: 24),
        ]);
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildEmptyState(AsyncValue categories) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _recentSearches(),
          _recentlyViewed(),
          // Popular searches
          Text(AppL10n.of(context).popularSearches,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: ['iPhone', 'Телевизор', 'Либос', 'Пойафзол', 'Ноутбук', 'Гӯшвора',
                'Смартфон', 'Мебел'].map((tag) => GestureDetector(
              onTap: () => _search(tag),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Text(tag, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 28),
          // Categories
          Text(AppL10n.of(context).categories,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          categories.when(
            data: (cats) => GridView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.1),
              itemCount: cats.length > 9 ? 9 : cats.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _search(cats[i].name),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.category_outlined, color: AppColors.primary, size: 28),
                    const SizedBox(height: 6),
                    Text(cats[i].name,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        textAlign: TextAlign.center),
                  ]),
                ),
              ),
            ),
            loading: () => GridView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.1),
              itemCount: 6,
              itemBuilder: (_, __) => ShimmerCard(radius: 14),
            ),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
    );
  }
}
