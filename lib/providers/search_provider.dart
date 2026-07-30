import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/product_model.dart';
import '../data/models/category_model.dart';
import '../data/datasources/remote/search_remote.dart';
import '../core/services/recent_service.dart';
import '../core/services/search_history_service.dart';

// Таърихи ҷустуҷӯ (маҳаллӣ)
final searchHistoryProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  return SearchHistoryService.get();
});

// Маҳсулоти бознигаристашуда (маҳаллӣ)
final recentlyViewedProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return RecentService.get();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

// null = пешфарз (нав); price_asc | price_desc | popular
final searchSortProvider = StateProvider<String?>((ref) => null);

// ── Филтрҳои иловагӣ (нарх, баҳо, категория) ──
final searchMinPriceProvider = StateProvider<double?>((ref) => null);
final searchMaxPriceProvider = StateProvider<double?>((ref) => null);
final searchMinRatingProvider = StateProvider<double?>((ref) => null);
final searchCategoryFilterProvider = StateProvider<String?>((ref) => null);

final searchResultsProvider =
    FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final sort = ref.watch(searchSortProvider);
  final minPrice = ref.watch(searchMinPriceProvider);
  final maxPrice = ref.watch(searchMaxPriceProvider);
  final minRating = ref.watch(searchMinRatingProvider);
  final categoryId = ref.watch(searchCategoryFilterProvider);

  final hasQuery = query.trim().isNotEmpty;
  final hasFilter = minPrice != null ||
      maxPrice != null ||
      minRating != null ||
      (categoryId != null && categoryId.isNotEmpty);
  // Ҳатто бе матн, агар ягон филтр фаъол бошад — натиҷаҳо бор мешаванд.
  if (!hasQuery && !hasFilter) return [];

  await Future.delayed(const Duration(milliseconds: 400)); // debounce
  return SearchRemote().search(
    query.trim(),
    sort: sort,
    minPrice: minPrice,
    maxPrice: maxPrice,
    minRating: minRating,
    categoryId: categoryId,
  );
});

final categoriesProvider =
    FutureProvider<List<CategoryModel>>((ref) async {
  return SearchRemote().getCategories();
});
