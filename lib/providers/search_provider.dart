import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/product_model.dart';
import '../data/models/category_model.dart';
import '../data/datasources/remote/search_remote.dart';
import '../core/services/recent_service.dart';

// Маҳсулоти бознигаристашуда (маҳаллӣ)
final recentlyViewedProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return RecentService.get();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

// null = пешфарз (нав); price_asc | price_desc | popular
final searchSortProvider = StateProvider<String?>((ref) => null);

final searchResultsProvider =
    FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final sort = ref.watch(searchSortProvider);
  if (query.trim().isEmpty) return [];
  await Future.delayed(const Duration(milliseconds: 400)); // debounce
  return SearchRemote().search(query.trim(), sort: sort);
});

final categoriesProvider =
    FutureProvider<List<CategoryModel>>((ref) async {
  return SearchRemote().getCategories();
});
