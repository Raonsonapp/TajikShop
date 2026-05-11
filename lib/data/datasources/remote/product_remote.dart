import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../models/product_model.dart';

class ProductRemote {
  Dio get _dio => ApiClient.instance.dio;

  // Server envelope: {"success": true, "data": [...] or {"products": [...]}}
  List _unwrapList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      final inner = raw['data'];
      if (inner is List) return inner;
      if (inner is Map) {
        final products = inner['products'] ?? inner['items'] ?? inner['trending'];
        if (products is List) return products;
      }
      final products = raw['products'] ?? raw['items'] ?? raw['trending'];
      if (products is List) return products;
    }
    return [];
  }

  Map<String, dynamic> _unwrapMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final inner = raw['data'];
      if (inner is Map<String, dynamic>) {
        return inner['product'] as Map<String, dynamic>? ?? inner;
      }
      return raw['product'] as Map<String, dynamic>? ?? raw;
    }
    return {};
  }

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
    final items = _unwrapList(res.data);
    return items.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ProductModel>> getTrending() async {
    final res = await _dio.get(ApiEndpoints.trending);
    final items = _unwrapList(res.data);
    return items.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ProductModel> getProductById(String id) async {
    final res = await _dio.get(ApiEndpoints.product(id));
    final map = _unwrapMap(res.data);
    if (map.isEmpty) throw Exception('Маҳсулот ёфт нашуд');
    return ProductModel.fromJson(map);
  }
}
