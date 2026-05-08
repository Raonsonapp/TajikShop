import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/search_provider.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/shimmer_card.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
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
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Маҳсулотро ҷустуҷӯ кунед...',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                        suffixIcon: query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                                onPressed: () {
                                  _ctrl.clear();
                                  ref.read(searchQueryProvider.notifier).state = '';
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
                      onSubmitted: (v) => ref.read(searchQueryProvider.notifier).state = v,
                    ),
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
                                  child: Text('${list.length} натиҷа барои "$query"',
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
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

  Widget _buildEmptyState(AsyncValue categories) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Popular searches
          const Text('Ҷустуҷӯи маъмул',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: ['iPhone', 'Телевизор', 'Либос', 'Пойафзол', 'Ноутбук', 'Гӯшвора',
                'Смартфон', 'Мебел'].map((tag) => GestureDetector(
              onTap: () {
                _ctrl.text = tag;
                ref.read(searchQueryProvider.notifier).state = tag;
              },
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
          const Text('Категорияҳо',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          categories.when(
            data: (cats) => GridView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.1),
              itemCount: cats.length > 9 ? 9 : cats.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () {
                  _ctrl.text = cats[i].name;
                  ref.read(searchQueryProvider.notifier).state = cats[i].name;
                },
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
