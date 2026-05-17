import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLangKey = 'app_language';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
    (ref) => LocaleNotifier());

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('tg')) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_kLangKey) ?? 'tg';
      if (mounted) state = Locale(code);
    } catch (_) {}
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLangKey, locale.languageCode);
    } catch (_) {}
  }

  static const supported = [Locale('tg'), Locale('ru'), Locale('en')];

  static String langName(String code) {
    switch (code) {
      case 'tg': return '🇹🇯 Тоҷикӣ';
      case 'ru': return '🇷🇺 Русский';
      case 'en': return '🇬🇧 English';
      default:   return code;
    }
  }
}
