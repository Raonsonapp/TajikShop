import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/product_model.dart';
import '../data/repositories/product_repository.dart';

class ProductsState {
  final List<ProductModel> products;
  final List<ProductModel> trending;
  final bool isLoading;
  final String? error;
  final int page;
  final bool hasMore;
  final int total;

  const ProductsState({
    this.products = const [],
    this.trending = const [],
    this.isLoading = false,
    this.error,
    this.page = 1,
    this.hasMore = true,
    this.total = 0,
  });

  ProductsState copyWith({
    List<ProductModel>? products,
    List<ProductModel>? trending,
    bool? isLoading,
    String? error,
    int? page,
    bool? hasMore,
    int? total,
  }) =>
      ProductsState(
        products: products ?? this.products,
        trending: trending ?? this.trending,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
        total: total ?? this.total,
      );

  ProductsState clearError() => ProductsState(
        products: products,
        trending: trending,
        isLoading: isLoading,
        page: page,
        hasMore: hasMore,
        total: total,
      );
}

class ProductsNotifier extends StateNotifier<ProductsState> {
  final ProductRepository _repo = ProductRepository();
  ProductsNotifier() : super(const ProductsState());

  Future<void> loadProducts({
    String? categoryId,
    String? search,
    bool refresh = false,
  }) async {
    if (!refresh && (!state.hasMore || state.isLoading)) return;

    if (refresh) {
      state = ProductsState(isLoading: true);
    } else {
      state = state.copyWith(isLoading: true);
    }

    try {
      final page = refresh ? 1 : state.page;
      final res = await _repo.getProductsPage(
        page: page,
        categoryId: categoryId,
        search: search,
      ).timeout(const Duration(seconds: 10),
          onTimeout: () => throw Exception('Вақт гузашт. Дубора кӯшиш кунед'));
      state = state.copyWith(
        products: refresh ? res.items : [...state.products, ...res.items],
        isLoading: false,
        page: page + 1,
        hasMore: res.hasMore,
        total: res.total,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadTrending() async {
    try {
      final trending = await _repo.getTrending()
          .timeout(const Duration(seconds: 8), onTimeout: () => []);
      state = state.copyWith(trending: trending);
    } catch (_) {}
  }
}

final productsProvider =
    StateNotifierProvider<ProductsNotifier, ProductsState>((ref) {
  return ProductsNotifier();
});

final productDetailProvider =
    FutureProvider.family<ProductModel, String>((ref, id) async {
  return ProductRepository().getProductById(id);
});
