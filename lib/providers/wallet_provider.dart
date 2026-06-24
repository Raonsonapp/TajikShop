import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';

// ── Ҳамён (GET /wallet) → {balance, transactions[]} ─────────────────────────
final walletProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ApiClient.instance.dio.get('/wallet');
  final raw = res.data;
  final data = raw is Map
      ? (raw['data'] is Map ? raw['data'] as Map : raw)
      : <String, dynamic>{};
  return Map<String, dynamic>.from(data);
});

class WalletService {
  static Future<void> topUp(double amount) async {
    await ApiClient.instance.dio.post('/wallet/topup', data: {'amount': amount});
  }

  // Купонро тафтиш мекунад; фоизи тахфифро бармегардонад ё null
  static Future<int?> validateCoupon(String code) async {
    try {
      final res = await ApiClient.instance.dio.get('/coupons/validate',
          queryParameters: {'code': code});
      final raw = res.data;
      final data = raw is Map ? (raw['data'] is Map ? raw['data'] as Map : raw) : {};
      final pct = (data['discount_percent'] as num?)?.toInt();
      return pct;
    } catch (_) {
      return null;
    }
  }
}
