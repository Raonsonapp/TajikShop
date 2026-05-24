import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // ✅ ИЛОВА ШУД (барои compute)
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../models/product_model.dart';

// ✅ Top-level функсия барои parse дар isolate-и дигар
// ⚠️ БОЯД берун аз class бошад!
List<ProductModel> _parseProductList(List<dynamic> rawList) {
  return rawList
      .whereType<Map<String, dynamic>>()
      .map(ProductModel.fromJson)
      .toList();
}

class ProductRemote {
  Dio get _dio => ApiClient.instance.dio;

  // Server: {"success":true,"data":{"products":[...]}}
  // ё:     {"success":true,"data":[...]}
  List<dynamic> _unwrapList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      final d = raw['data'];
      if (d is List) return d;
      if (d is Map) {
        for (final key in ['products', 'items', 'trending', 'results']) {
          if (d[key] is List) return d[key] as List<dynamic>;
        }
      }
      for (final key in ['products', 'items', 'trending', 'results']) {
        if (raw[key] is List) return raw[key] as List<dynamic>;
      }
    }
    return [];
  }

  Map<String, dynamic> _unwrapMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final d = raw['data'];
      if (d is Map<String, dynamic>) {
        return d['product'] as Map<String, dynamic>? ?? d;
      }
      return raw['product'] as Map<String, dynamic>? ?? raw;
    }
    return {};
  }

  Future<List<ProductModel>> getProducts({
    int page = 1,
    int limit = 20,
    String? categoryId,
    String? search,
    String? sort,
  }) async {
    final res = await _dio.get(ApiEndpoints.products, queryParameters: {
      'page': page,
      'limit': limit,
      if (categoryId != null && categoryId.isNotEmpty) 'category_id': categoryId,
      if (search != null && search.isNotEmpty) 'search': search,
      if (sort != null) 'sort': sort,
    });
    final rawList = _unwrapList(res.data);
    // ✅ Парсинг дар isolate-и дигар → UI блок намешавад!
    return await compute(_parseProductList, rawList);
  }

  Future<List<ProductModel>> getTrending() async {
    final res = await _dio.get(ApiEndpoints.trending);
    final rawList = _unwrapList(res.data);
    // ✅ Парсинг дар isolate-и дигар → UI блок намешавад!
    return await compute(_parseProductList, rawList);
  }

  Future<ProductModel> getProductById(String id) async {
    final res = await _dio.get(ApiEndpoints.product(id));
    final map = _unwrapMap(res.data);
    if (map.isEmpty) throw Exception('Маҳсулот ёфт нашуд');
    // ✅ 1 объект → compute лозим нест (<1ms)
    return ProductModel.fromJson(map);
  }
}
