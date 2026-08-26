import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Палитраи вобаста ба тема (равшан/торик).
///
/// Ҳамаи ранҳои «сатҳӣ» (замина, корт, матн, ҳошия) аз ин ҷо гирифта мешаванд,
/// то тугмаи равшан/торик воқеан кор кунад. Рангҳои бренд (primary, accent,
/// success, error, warning) дар ҳарду тема якхелаанд ва аз `AppColors` меоянд.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color scaffold;   // заминаи асосии экран
  final Color card;       // корт/лист
  final Color surface;    // майдонҳо, chip-ҳо
  final Color elevated;   // сатҳи баландтар
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color divider;
  final Color shimmerBase;
  final Color shimmerHighlight;

  const AppPalette({
    required this.scaffold,
    required this.card,
    required this.surface,
    required this.elevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.divider,
    required this.shimmerBase,
    required this.shimmerHighlight,
  });

  static const dark = AppPalette(
    scaffold: AppColors.bgDark,
    card: AppColors.bgCard,
    surface: AppColors.bgSurface,
    elevated: AppColors.bgElevated,
    textPrimary: AppColors.textPrimary,       // сафед
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    border: AppColors.border,
    divider: AppColors.divider,
    shimmerBase: AppColors.shimmerBase,
    shimmerHighlight: AppColors.shimmerHighlight,
  );

  static const light = AppPalette(
    scaffold: Color(0xFFF5FAF6),              // сафеди сабзтоб
    card: Color(0xFFFFFFFF),
    surface: Color(0xFFEDF4EF),
    elevated: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF0B1D14),           // сиёҳи сабзтоб
    textSecondary: Color(0xFF4A5F52),
    textMuted: Color(0xFF7C9686),
    border: Color(0xFFDCEAE0),
    divider: Color(0xFFDCEAE0),
    shimmerBase: Color(0xFFE4F0E8),
    shimmerHighlight: Color(0xFFF5FAF6),
  );

  @override
  AppPalette copyWith({
    Color? scaffold,
    Color? card,
    Color? surface,
    Color? elevated,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? border,
    Color? divider,
    Color? shimmerBase,
    Color? shimmerHighlight,
  }) =>
      AppPalette(
        scaffold: scaffold ?? this.scaffold,
        card: card ?? this.card,
        surface: surface ?? this.surface,
        elevated: elevated ?? this.elevated,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textMuted: textMuted ?? this.textMuted,
        border: border ?? this.border,
        divider: divider ?? this.divider,
        shimmerBase: shimmerBase ?? this.shimmerBase,
        shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
      );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      scaffold: Color.lerp(scaffold, other.scaffold, t)!,
      card: Color.lerp(card, other.card, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      elevated: Color.lerp(elevated, other.elevated, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
    );
  }
}

/// Дастрасии осон: `context.pal.scaffold`, `context.pal.textPrimary`, ...
extension AppPaletteX on BuildContext {
  AppPalette get pal =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}
