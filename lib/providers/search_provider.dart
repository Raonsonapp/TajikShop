import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/product_model.dart';
import '../data/models/category_model.dart';
import '../data/datasources/remote/search_remote.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  return SearchRemote().search(query);
});

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  return SearchRemote().getCategories();
});