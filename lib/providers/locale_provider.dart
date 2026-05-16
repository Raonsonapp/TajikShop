import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';

const _kLangKey = 'app_language';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('tg')) {
    // FIX: sharedPrefs аллакай дар main() init шудааст — await нест!
    try {
      final code = sharedPrefs.getString(_kLangKey) ?? 'tg';
      state = Locale(code);
    } catch (_) {
      state = const Locale('tg');
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    try {
      sharedPrefs.setString(_kLangKey, locale.languageCode);
    } catch (_) {}
  }

  static const supported = [
    Locale('tg'),
    Locale('ru'),
    Locale('en'),
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
