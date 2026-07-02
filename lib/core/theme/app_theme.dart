import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'app_palette.dart';

class AppTheme {
  // ── DARK ────────────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgDark,
    primaryColor: AppColors.primary,
    extensions: const [AppPalette.dark],
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary, secondary: AppColors.accent,
      surface: AppColors.bgCard, error: AppColors.error,
      onPrimary: Colors.white, onSecondary: Colors.white,
      onSurface: AppColors.textPrimary, onError: Colors.white,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 20),
      titleMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
      bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 16),
      bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      bodySmall: TextStyle(color: AppColors.textMuted, fontSize: 12),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgDark, elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
      titleTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
    ),
    inputDecorationTheme: _inputTheme(AppColors.border),
    cardTheme: CardTheme(color: AppColors.bgCard, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    elevatedButtonTheme: _elevatedBtn,
    dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
    useMaterial3: false,
  );

  // ── LIGHT ───────────────────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppPalette.light.scaffold,
    primaryColor: AppColors.primary,
    extensions: const [AppPalette.light],
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary, secondary: AppColors.accent,
      surface: Color(0xFFFFFFFF), error: AppColors.error,
      onPrimary: Colors.white, onSecondary: Colors.white,
      onSurface: Color(0xFF0D0D1A), onError: Colors.white,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(color: Color(0xFF0D0D1A), fontWeight: FontWeight.w700, fontSize: 20),
      titleMedium: TextStyle(color: Color(0xFF0D0D1A), fontWeight: FontWeight.w600, fontSize: 16),
      bodyLarge: TextStyle(color: Color(0xFF0D0D1A), fontSize: 16),
      bodyMedium: TextStyle(color: Color(0xFF5A5D70), fontSize: 14),
      bodySmall: TextStyle(color: Color(0xFF8A8DA0), fontSize: 12),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF4F6FA), elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF0D0D1A)),
      titleTextStyle: TextStyle(color: Color(0xFF0D0D1A), fontSize: 20, fontWeight: FontWeight.w700),
    ),
    inputDecorationTheme: _inputTheme(const Color(0xFFE2E5EE)),
    cardTheme: CardTheme(color: const Color(0xFFFFFFFF), elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    elevatedButtonTheme: _elevatedBtn,
    dividerTheme: const DividerThemeData(color: Color(0xFFE2E5EE), thickness: 1),
    useMaterial3: false,
  );

  static InputDecorationTheme _inputTheme(Color border) => InputDecorationTheme(
    filled: false,
    fillColor: Colors.transparent,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border, width: 0.5)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  static final ElevatedButtonThemeData _elevatedBtn = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary, foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
    ),
  );
}
