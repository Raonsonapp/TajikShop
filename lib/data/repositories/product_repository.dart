import '../datasources/remote/product_remote.dart';
import '../models/product_model.dart';

class ProductRepository {
  final ProductRemote _remote = ProductRemote();

  Future<List<ProductModel>> getProducts({
    int page = 1,
    String? categoryId,
    String? search,
    String? sort,
  }) =>
      _remote.getProducts(page: page, categoryId: categoryId, search: search, sort: sort);

  Future<List<ProductModel>> getTrending() => _remote.getTrending();

  Future<ProductModel> getProductById(String id) => _remote.getProductById(id);
}