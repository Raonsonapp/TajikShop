import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';

class SearchRemote {
  Dio get _dio => ApiClient.instance.dio;

  // Server: {"success":true,"data":{"products":[...]}} ё {"success":true,"data":[...]}
  List<dynamic> _unwrapList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      final d = raw['data'];
      if (d is List) return d;
      if (d is Map) {
        for (final k in ['products', 'items', 'results', 'categories']) {
          if (d[k] is List) return d[k] as List;
        }
      }
      for (final k in ['products', 'items', 'categories']) {
        if (raw[k] is List) return raw[k] as List;
      }
    }
    return const [];
  }

  Future<List<ProductModel>> search(
    String query, {
    String? sort,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? categoryId,
  }) async {
    final res = await _dio.get(ApiEndpoints.products, queryParameters: {
      'q': query,
      'limit': 30,
      if (sort != null && sort.isNotEmpty) 'sort': sort,
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
      if (minRating != null) 'min_rating': minRating,
      if (categoryId != null && categoryId.isNotEmpty)
        'category_id': categoryId,
    });
    return _unwrapList(res.data)
        .whereType<Map<String, dynamic>>()
        .map(ProductModel.fromJson)
        .toList();
  }

  Future<List<CategoryModel>> getCategories() async {
    final res = await _dio.get(ApiEndpoints.categories);
    return _unwrapList(res.data)
        .whereType<Map<String, dynamic>>()
        .map(CategoryModel.fromJson)
        .toList();
  }
}
