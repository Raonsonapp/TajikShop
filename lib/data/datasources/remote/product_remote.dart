import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../models/product_model.dart';

class ProductRemote {
  Dio get _dio => ApiClient.instance.dio;

  // Server: {"success":true,"data":{"products":[...]}}
  // ё:     {"success":true,"data":[...]}
  List _unwrapList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      final d = raw['data'];
      if (d is List) return d;
      if (d is Map) {
        for (final key in ['products', 'items', 'trending', 'results']) {
          if (d[key] is List) return d[key] as List;
        }
      }
      for (final key in ['products', 'items', 'trending', 'results']) {
        if (raw[key] is List) return raw[key] as List;
      }
    }
    return [];
  }

  Map<String, dynamic> _unwrapMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final d = raw['data'];
      if (d is Map<String, dynamic>) return d['product'] as Map<String, dynamic>? ?? d;
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
      if (categoryId != null && categoryId.isNotEmpty) 'category_id': categoryId,
      if (search != null && search.isNotEmpty) 'search': search,
      if (sort != null) 'sort': sort,
    });
    return _unwrapList(res.data)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProductModel>> getTrending() async {
    final res = await _dio.get(ApiEndpoints.trending);
    return _unwrapList(res.data)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProductModel> getProductById(String id) async {
    final res = await _dio.get(ApiEndpoints.product(id));
    final map = _unwrapMap(res.data);
    if (map.isEmpty) throw Exception('Маҳсулот ёфт нашуд');
    return ProductModel.fromJson(map);
  }
}
