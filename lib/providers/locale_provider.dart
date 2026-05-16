import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const _key = 'app_theme_mode';
  ThemeNotifier() : super(ThemeMode.dark) {
    _load();
  }
  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      state = p.getString(_key) == 'light' ? ThemeMode.light : ThemeMode.dark;
    } catch (_) {}
  }
  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _save();
  }
  void setDark()  { state = ThemeMode.dark;  _save(); }
  void setLight() { state = ThemeMode.light; _save(); }
  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_key, state == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {}
  }
}
final themeProvider =
    StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) => ThemeNotifier());
