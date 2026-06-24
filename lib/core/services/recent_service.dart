import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/product_model.dart';

/// Маҳсулоти бознигаристашуда — маҳаллӣ (shared_preferences), бе backend.
class RecentService {
  static const _key = 'recently_viewed_v1';
  static const _max = 12;

  static Future<void> add(ProductModel p) async {
    if (p.id.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.removeWhere((e) {
      try {
        return jsonDecode(e)['id'] == p.id;
      } catch (_) {
        return false;
      }
    });
    list.insert(0, jsonEncode({
      'id': p.id,
      'title': p.title,
      'price': p.price,
      'image': p.mainImage,
    }));
    await prefs.setStringList(_key, list.take(_max).toList());
  }

  static Future<List<Map<String, dynamic>>> get() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list
        .map((e) {
          try {
            return Map<String, dynamic>.from(jsonDecode(e));
          } catch (_) {
            return <String, dynamic>{};
          }
        })
        .where((m) => m.isNotEmpty)
        .toList();
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
