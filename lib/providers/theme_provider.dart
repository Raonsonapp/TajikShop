import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kKey = 'app_theme_mode';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark) {
    _load();
  }
  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      if (mounted) state = p.getString(_kKey) == 'light' ? ThemeMode.light : ThemeMode.dark;
    } catch (_) {}
  }
  void toggle() { state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark; _save(); }
  void setDark()  { state = ThemeMode.dark;  _save(); }
  void setLight() { state = ThemeMode.light; _save(); }
  void _save() {
    SharedPreferences.getInstance().then((p) =>
        p.setString(_kKey, state == ThemeMode.dark ? 'dark' : 'light'));
  }
}
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) => ThemeNotifier());
