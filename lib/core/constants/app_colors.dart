import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF00D084);
  static const primaryDark = Color(0xFF00A86B);
  static const accent = Color(0xFFFF6B2C);
  static const bgDark = Color(0xFF0A0A0F);
  static const bgCard = Color(0xFF141420);
  static const bgSurface = Color(0xFF1C1C2E);
  static const bgElevated = Color(0xFF252538);
  static const bgLight = Color(0xFFF4F6FA);
  static const bgCardLight = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFAAADBE);
  static const textMuted = Color(0xFF6B6E82);
  static const textDark = Color(0xFF0D0D1A);
  static const success = Color(0xFF00D084);
  static const warning = Color(0xFFFFB800);
  static const error = Color(0xFFFF3B5C);
  static const info = Color(0xFF3B82F6);
  static const divider = Color(0xFF252538);
  static const border = Color(0xFF252538);
  static const shimmerBase = Color(0xFF1E1E30);
  static const shimmerHighlight = Color(0xFF2A2A40);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00D084), Color(0xFF00A3FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1C1C2E), Color(0xFF141420)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
