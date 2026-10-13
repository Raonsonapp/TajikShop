/// Як зинаи нархи яклухт: «аз $minQty дона — $price сом.».
///
/// Савдои яклухти воқеӣ бо зинаҳо кор мекунад:
///
///     1–9 дона    → 100 сом.
///     10–49 дона  →  90 сом.
///     50+ дона    →  80 сом.
///
/// Муҳим: нархро СЕРВЕР ҳисоб мекунад (`backend/.../price_tiers.go`).
/// Барнома зинаҳоро танҳо НИШОН медиҳад ва нархи омадаро истифода
/// мебарад. Агар барнома ҳисоби худашро медошт, рӯзе ду ҳисоб аз ҳам
/// фарқ мекард — ва харидор дар экран як рақам, дар ҳисобнома рақами
/// дигар мебинад.
class PriceTier {
  final int minQty;
  final double price;
  const PriceTier({required this.minQty, required this.price});

  factory PriceTier.fromJson(Map<String, dynamic> j) => PriceTier(
        minQty: (j['min_qty'] as num?)?.toInt() ?? 0,
        price: (j['price'] as num?)?.toDouble() ?? 0,
      );
}
