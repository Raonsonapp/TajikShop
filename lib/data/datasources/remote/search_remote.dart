import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';

class SearchRemote {
  Dio get _dio => ApiClient.instance.dio;

  Future<List<ProductModel>> search(String query) async {
    final res = await _dio.get(ApiEndpoints.products, queryParameters: {'q': query, 'limit': 30});
    final data = res.data;
    List items = data is List ? data : (data['products'] ?? data['items'] ?? []);
    return items.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<CategoryModel>> getCategories() async {
    final res = await _dio.get(ApiEndpoints.categories);
    final data = res.data;
    List items = data is List ? data : (data['categories'] ?? []);
    return items.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
