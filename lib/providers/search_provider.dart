import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/product_model.dart';
import '../data/models/category_model.dart';
import '../data/datasources/remote/search_remote.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider =
    FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];
  await Future.delayed(const Duration(milliseconds: 400)); // debounce
  return SearchRemote().search(query.trim());
});

final categoriesProvider =
    FutureProvider<List<CategoryModel>>((ref) async {
  return SearchRemote().getCategories();
});
