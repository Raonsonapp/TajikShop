import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLangKey = 'app_language';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('tg')) { _load(); }
  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      if (mounted) state = Locale(p.getString(_kLangKey) ?? 'tg');
    } catch (_) {}
  }
  Future<void> setLocale(Locale locale) async {
    state = locale;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kLangKey, locale.languageCode);
    } catch (_) {}
  }
  static const supported = [Locale('tg'), Locale('ru'), Locale('en')];
  static String langName(String code) {
    switch (code) {
      case 'tg': return '\u{1F1F9}\u{1F1EF} \u0422\u043E\u04B7\u0438\u043A\u04E3';
      case 'ru': return '\u{1F1F7}\u{1F1FA} \u0420\u0443\u0441\u0441\u043A\u0438\u0439';
      case 'en': return '\u{1F1EC}\u{1F1E7} English';
      default: return code;
    }
  }
}
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) => LocaleNotifier());
