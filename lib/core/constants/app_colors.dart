import 'package:flutter/material.dart';

/// Палитраи бренди TajikShop — сабзи эмералд/ҷангалӣ.
///
/// Deep Forest Green заминаи асосии темаи торик, Emerald Green ранги бренд,
/// ва Neon Green барои таъкидҳои махсус (нишонҳо, тахфифҳо). Ранги кабуд ва
/// норинҷӣ дар палитра истифода намешавад.
class AppColors {
  // Бренд
  static const primary = Color(0xFF00D084);      // эмералд
  static const primaryDark = Color(0xFF00A86B);  // эмералди амиқ
  static const emerald = Color(0xFF2ECC71);      // сабзи барг
  static const neon = Color(0xFF39FF88);         // таъкиди неон
  static const accent = Color(0xFF39FF88);       // таъкид (сабз, на норинҷӣ)

  // Сатҳҳои темаи торик (аз сабзи ҷангалӣ гирифта шуда)
  static const bgDark = Color(0xFF04120B);
  static const bgCard = Color(0xFF0C1F16);
  static const bgSurface = Color(0xFF122A1E);
  static const bgElevated = Color(0xFF173625);
  static const bgLight = Color(0xFFF5FAF6);
  static const bgCardLight = Color(0xFFFFFFFF);

  // Матн
  static const textPrimary = Color(0xFFF4FBF6);
  static const textSecondary = Color(0xFFAFC8BA);
  static const textMuted = Color(0xFF7C9686);
  static const textDark = Color(0xFF0B1D14);

  // Семантикӣ
  static const success = Color(0xFF2ECC71);
  static const warning = Color(0xFFE5C94D);
  static const error = Color(0xFFE5484D);
  static const info = Color(0xFF4DA6E5);

  static const divider = Color(0xFF1E3A2B);
  static const border = Color(0xFF1E3A2B);
  static const shimmerBase = Color(0xFF122A1E);
  static const shimmerHighlight = Color(0xFF1B3B29);

  // Нарх / тахфиф
  static const priceOld = Color(0xFF8A9C92);
  static const discountBadgeBg = Color(0xFF163B27);
  static const discountBadgeText = Color(0xFF39FF88);

  /// Градиенти асосӣ барои тугмаҳо ва banner-ҳо — комилан сабз (бе кабуд).
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00D084), Color(0xFF00A86B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Градиенти hero — аз сабзи амиқ то эмералд (услуби Marketplace).
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF06170F), Color(0xFF2ECC71)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF122A1E), Color(0xFF0C1F16)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
