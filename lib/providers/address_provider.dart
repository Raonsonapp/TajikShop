import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../data/models/address_model.dart';

// ── Суроғаҳои корбар (GET /addresses) ────────────────────────────────────────
final addressesProvider = FutureProvider.autoDispose<List<AddressModel>>((ref) async {
  final res = await ApiClient.instance.dio.get('/addresses');
  final raw = res.data;
  final list = raw is List ? raw : (raw is Map ? (raw['data'] ?? []) : []);
  return (list as List)
      .whereType<Map<String, dynamic>>()
      .map(AddressModel.fromJson)
      .toList();
});

class AddressService {
  static Future<void> add({
    required String title,
    required String city,
    required String street,
    String zip = '',
  }) async {
    await ApiClient.instance.dio.post('/addresses', data: {
      'title': title,
      'city': city,
      'street': street,
      'zip': zip,
    });
  }

  static Future<void> remove(String id) async {
    await ApiClient.instance.dio.delete('/addresses/$id');
  }
}
