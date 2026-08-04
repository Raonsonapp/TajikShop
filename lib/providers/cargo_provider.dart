import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';

/// Маълумоти карго — суроғаи анбори Хитой + тарифҳо (сом/кг). GET /cargo/info
final cargoInfoProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  const fallback = <String, dynamic>{
    'warehouse': '',
    'rate_tj': 0,
    'rate_ru': 0,
    'phone': '',
  };
  try {
    final res = await ApiClient.instance.dio.get('/cargo/info');
    final raw = res.data;
    final data = raw is Map
        ? (raw['data'] is Map ? raw['data'] as Map : raw)
        : <String, dynamic>{};
    return {...fallback, ...Map<String, dynamic>.from(data)};
  } catch (_) {
    return fallback;
  }
});

/// Посылкаҳои корбар. GET /cargo
final myCargoProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    final res = await ApiClient.instance.dio.get('/cargo');
    final raw = res.data;
    final list = raw is List ? raw : (raw is Map ? (raw['data'] ?? []) : []);
    return (list as List).whereType<Map<String, dynamic>>().toList();
  } catch (_) {
    return const [];
  }
});

class CargoService {
  static Future<void> create({
    required String description,
    String productLink = '',
    String destination = 'tj',
    String trackCode = '',
  }) async {
    await ApiClient.instance.dio.post('/cargo', data: {
      'description': description,
      'product_link': productLink,
      'destination': destination,
      'track_code': trackCode,
    });
  }
}
