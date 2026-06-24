import '../datasources/remote/product_remote.dart';
import '../models/product_model.dart';

class ProductRepository {
  final ProductRemote _remote = ProductRemote();

  Future<List<ProductModel>> getProducts({
    int page = 1,
    String? categoryId,
    String? search,
    String? sort,
    String? sellerId,
  }) =>
      _remote.getProducts(
          page: page, categoryId: categoryId, search: search, sort: sort, sellerId: sellerId);

  Future<ProductPage> getProductsPage({
    int page = 1,
    int limit = 20,
    String? categoryId,
    String? search,
    String? sort,
    double? minPrice,
    double? maxPrice,
    double? minRating,
  }) =>
      _remote.getProductsPage(page: page, limit: limit, categoryId: categoryId,
          search: search, sort: sort, minPrice: minPrice, maxPrice: maxPrice, minRating: minRating);

  Future<List<ProductModel>> getTrending() => _remote.getTrending();

  Future<ProductModel> getProductById(String id) => _remote.getProductById(id);
}
