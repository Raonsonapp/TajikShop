import 'package:shared_preferences/shared_preferences.dart';

/// Таърихи ҷустуҷӯ — маҳаллӣ (shared_preferences).
class SearchHistoryService {
  static const _key = 'search_history_v1';
  static const _max = 10;

  static Future<void> add(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.removeWhere((e) => e.toLowerCase() == q.toLowerCase());
    list.insert(0, q);
    await prefs.setStringList(_key, list.take(_max).toList());
  }

  static Future<List<String>> get() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<void> remove(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.removeWhere((e) => e.toLowerCase() == query.toLowerCase());
    await prefs.setStringList(_key, list);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
