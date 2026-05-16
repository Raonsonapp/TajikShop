import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const _key = 'app_theme_mode';

  ThemeNotifier() : super(ThemeMode.dark) {
    // FIX: sharedPrefs аллакай дар main() init шудааст — await нест!
    try {
      final saved = sharedPrefs.getString(_key);
      state = saved == 'light' ? ThemeMode.light : ThemeMode.dark;
    } catch (_) {
      state = ThemeMode.dark;
    }
  }

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _persist(state);
  }

  void setDark() { state = ThemeMode.dark; _persist(state); }
  void setLight() { state = ThemeMode.light; _persist(state); }

  void _persist(ThemeMode mode) {
    try {
      sharedPrefs.setString(_key, mode == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {}
  }
}

final themeProvider =
    StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) => ThemeNotifier());
