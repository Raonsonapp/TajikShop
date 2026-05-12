import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLangKey = 'app_language';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('tg')) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLangKey) ?? 'tg';
    state = Locale(code);
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLangKey, locale.languageCode);
  }

  static const supported = [
    Locale('tg'), // Тоҷикӣ
    Locale('ru'), // Русский
    Locale('en'), // English
  ];

  static String langName(String code) {
    switch (code) {
      case 'tg': return '🇹🇯 Тоҷикӣ';
      case 'ru': return '🇷🇺 Русский';
      case 'en': return '🇬🇧 English';
      default:   return code;
    }
  }
}

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) => LocaleNotifier());
