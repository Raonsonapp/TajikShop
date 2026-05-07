import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/search_provider.dart';
import '../../providers/product_provider.dart';
import '../../data/models/category_model.dart';
import '../../shared/widgets/shimmer_card.dart';
import '../../shared/widgets/product_card.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});
  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  CategoryModel? _selected;

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider);
    final products = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _selected?.name ?? 'Категорияҳо',
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
      ),
      body: Row(
        children: [
          // Left: category list
          Container(
            width: 90,
            color: AppColors.bgCard,
            child: cats.when(
              loading: () => ListView.builder(
                itemCount: 8,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.all(8),
                  child: ShimmerCard(height: 70, radius: 12),
                ),
              ),
              error: (_, __) => const SizedBox(),
              data: (list) => ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final isSelected = _selected?.id == list[i].id;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selected = list[i]);
                      ref.read(productsProvider.notifier)
                          .loadProducts(categoryId: list[i].id, refresh: true);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.bgDark : Colors.transparent,
                        border: Border(
                          left: BorderSide(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Column(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.15)
                                : AppColors.bgSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.category_outlined,
                              color: isSelected ? AppColors.primary : AppColors.textMuted,
                              size: 22),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          list[i].name,
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ),
          // Right: products
          Expanded(
            child: _selected == null
                ? const Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.category_outlined, size: 70, color: AppColors.textMuted),
                      SizedBox(height: 14),
                      Text('Категорияро интихоб кунед',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    ]),
                  )
                : products.isLoading && products.products.isEmpty
                    ? GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.68),
                        itemCount: 6,
                        itemBuilder: (_, __) => ShimmerCard(radius: 14),
                      )
                    : products.products.isEmpty
                        ? const Center(
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.inventory_2_outlined, size: 60, color: AppColors.textMuted),
                              SizedBox(height: 12),
                              Text('Маҳсулот нест',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                            ]),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(12),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.68),
                            itemCount: products.products.length,
                            itemBuilder: (_, i) => ProductCard(product: products.products[i]),
                          ),
          ),
        ],
      ),
    );
  }
}
