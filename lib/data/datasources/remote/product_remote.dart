import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../models/product_model.dart';

class ProductRemote {
  Dio get _dio => ApiClient.instance.dio;

  Future<List<ProductModel>> getProducts({
    int page = 1, int limit = 20,
    String? categoryId, String? search, String? sort,
  }) async {
    final res = await _dio.get(ApiEndpoints.products, queryParameters: {
      'page': page, 'limit': limit,
      if (categoryId != null) 'category_id': categoryId,
      if (search != null) 'q': search,
      if (sort != null) 'sort': sort,
    });
    final data = res.data;
    List items = data is List ? data : (data['products'] ?? data['items'] ?? []);
    return items.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ProductModel>> getTrending() async {
    final res = await _dio.get(ApiEndpoints.trending);
    final data = res.data;
    List items = data is List ? data : (data['products'] ?? data['items'] ?? []);
    return items.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ProductModel> getProductById(String id) async {
    final res = await _dio.get(ApiEndpoints.product(id));
    final data = res.data;
    if (data is Map<String, dynamic>) {
      final product = data['product'] ?? data;
      return ProductModel.fromJson(product as Map<String, dynamic>);
    }
    throw Exception('Маҳсулот ёфт нашуд');
  }
}
