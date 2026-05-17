import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const _key = 'app_theme_mode';

  ThemeNotifier() : super(ThemeMode.dark) {
    // FIX: async — main thread блок намекунад
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    try {
      // FIX: getInstance() async аст — main thread блок намекунад
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (mounted) {
        state = saved == 'light' ? ThemeMode.light : ThemeMode.dark;
      }
    } catch (_) {}
  }

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _persist(state);
  }

  void setDark()  { state = ThemeMode.dark;  _persist(state); }
  void setLight() { state = ThemeMode.light; _persist(state); }

  Future<void> _persist(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {}
  }
}

final themeProvider =
    StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) => ThemeNotifier());
