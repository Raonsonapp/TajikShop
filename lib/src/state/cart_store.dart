part of '../../main.dart';

class AlmazCartStore {
  static const _key = 'almaz_cart_v1';
  static final ValueNotifier<int> count = ValueNotifier<int>(0);
  static Future<List<Map<String, dynamic>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonDecode(prefs.getString(_key) ?? '[]');
    if (raw is! List) {
      count.value = 0;
      return [];
    }
    final items = raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    count.value = items.fold<int>(0, (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 1));
    return items;
  }
  static Future<void> _save(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items));
    count.value = items.fold<int>(0, (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 1));
  }
  static Future<void> add(Map<String, dynamic> product) async {
    final id = (product['id'] ?? product['product_id'] ?? '').toString();
    if (id.isEmpty) throw Exception('Маҳсулот ID надорад; ба сабад илова карда намешавад.');
    final items = await load();
    final index = items.indexWhere((e) => (e['id'] ?? e['product_id']).toString() == id);
    if (index >= 0) {
      items[index]['quantity'] = ((items[index]['quantity'] as num?)?.toInt() ?? 1) + 1;
    } else {
      items.add({...product, 'id': id, 'quantity': 1});
    }
    await _save(items);
  }
  static Future<void> setQuantity(String id, int quantity) async {
    final items = await load();
    if (quantity <= 0) {
      items.removeWhere((e) => (e['id'] ?? e['product_id']).toString() == id);
    } else {
      for (final item in items) {
        if ((item['id'] ?? item['product_id']).toString() == id) item['quantity'] = quantity;
      }
    }
    await _save(items);
  }
  static Future<void> remove(String id) async {
    final items = await load();
    items.removeWhere((e) => (e['id'] ?? e['product_id']).toString() == id);
    await _save(items);
  }
}
