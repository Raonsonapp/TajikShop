import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_l10n.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/verification_l10n.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/verification_provider.dart';
import '../../shared/widgets/fade_slide_in.dart';

/// Рейтинги фурӯшанда (1–10) — дар профили худи фурӯшанда.
///
/// Харидор пас аз гирифтани мол баҳо мегузорад; ин ҷо фурӯшанда баҳои миёна,
/// шумораи баҳоҳо ва шарҳҳои охиринро мебинад.
class SellerRatingCard extends ConsumerWidget {
  final String sellerId;
  const SellerRatingCard({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pal = context.pal;
    final l = AppL10n.of(context);
    final async = ref.watch(sellerRatingProvider(sellerId));

    return async.when(
      loading: () => _shell(
        pal,
        child: const SizedBox(
          height: 54,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2.2),
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        final avg = (data['average'] as num?)?.toDouble() ?? 0;
        final count = (data['count'] as num?)?.toInt() ?? 0;
        final reviews = (data['reviews'] is List)
            ? (data['reviews'] as List).whereType<Map>().toList()
            : const <Map>[];

        if (count == 0) {
          return _shell(
            pal,
            child: Row(children: [
              _iconBox(FeatherIcons.star, pal),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.ratingNone,
                          style: TextStyle(
                              color: pal.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(l.ratingNoneHint,
                          style: TextStyle(
                              color: pal.textMuted, fontSize: 11.5, height: 1.3)),
                    ]),
              ),
            ]),
          );
        }

        return _shell(
          pal,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _iconBox(FeatherIcons.award, pal),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.ratingTitle,
                          style: TextStyle(
                              color: pal.textMuted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Row(crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(avg.toStringAsFixed(1),
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(width: 5),
                            Text(l.ratingOutOf10,
                                style: TextStyle(
                                    color: pal.textMuted, fontSize: 12)),
                          ]),
                    ]),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(l.ratingCount(count),
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700)),
              ),
            ]),

            // Хатти пур — баҳо аз 10 чӣ қадар аст.
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (avg / 10).clamp(0.0, 1.0),
                minHeight: 7,
                backgroundColor: pal.surface,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),

            if (reviews.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(l.ratingReviews.toUpperCase(),
                  style: TextStyle(
                      color: pal.textMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7)),
              const SizedBox(height: 8),
              for (var i = 0; i < reviews.length && i < 5; i++)
                FadeSlideIn(
                  delay: Duration(milliseconds: 50 * i),
                  child: _review(pal, Map<String, dynamic>.from(reviews[i])),
                ),
            ],
          ]),
        );
      },
    );
  }

  Widget _review(AppPalette pal, Map<String, dynamic> r) {
    final score = (r['score'] as num?)?.toInt() ?? 0;
    final comment = (r['comment'] ?? '').toString().trim();
    final name = (r['buyer_name'] ?? '').toString().trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 34,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _scoreColor(score).withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('$score',
              style: TextStyle(
                  color: _scoreColor(score),
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (name.isNotEmpty)
              Text(name,
                  style: TextStyle(
                      color: pal.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600)),
            if (comment.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(comment,
                    style: TextStyle(
                        color: pal.textSecondary, fontSize: 12, height: 1.3)),
              ),
          ]),
        ),
      ]),
    );
  }

  static Color _scoreColor(int score) {
    if (score >= 8) return AppColors.success;
    if (score >= 5) return AppColors.warning;
    return AppColors.error;
  }

  Widget _iconBox(IconData icon, AppPalette pal) => Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      );

  Widget _shell(AppPalette pal, {required Widget child}) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: pal.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: pal.border),
        ),
        child: child,
      );
}
