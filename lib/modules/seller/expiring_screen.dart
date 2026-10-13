import 'package:cached_network_image/cached_network_image.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_l10n.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/stock_l10n.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/seller_provider.dart';
import '../../shared/widgets/fade_slide_in.dart';

/// Маҳсулоте, ки мӯҳлаташон наздик аст.
///
/// Барои мағозаи хӯрокворӣ ин экран пул аст: моли мӯҳлаташ гузашта зарари
/// тоза аст, вале моли се рӯз мондаро бо тахфиф фурӯхтан мумкин. Сервер
/// фурӯшандаро 3 рӯз пеш огоҳ мекунад — ин ҷо ӯ мебинад, ки кадомаш.
class ExpiringScreen extends ConsumerWidget {
  const ExpiringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pal = context.pal;
    final l = AppL10n.of(context);
    final async = ref.watch(expiringProductsProvider);

    return Scaffold(
      backgroundColor: pal.scaffold,
      appBar: AppBar(
        backgroundColor: pal.scaffold,
        elevation: 0,
        iconTheme: IconThemeData(color: pal.textPrimary),
        title: Text(l.expiryTitle,
            style: TextStyle(
                color: pal.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17)),
      ),
      body: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => Center(
            child: Text(l.expiryEmpty,
                style: TextStyle(color: pal.textMuted, fontSize: 13))),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 84,
                  height: 84,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(FeatherIcons.checkCircle,
                      color: AppColors.success, size: 34),
                ),
                const SizedBox(height: 16),
                Text(l.expiryEmpty,
                    style: TextStyle(
                        color: pal.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ]),
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(expiringProductsProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.32)),
                  ),
                  child: Row(children: [
                    const Icon(FeatherIcons.clock,
                        color: AppColors.warning, size: 19),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(l.expiryHint,
                          style: TextStyle(
                              color: pal.textPrimary,
                              fontSize: 13,
                              height: 1.3)),
                    ),
                  ]),
                ),
                const SizedBox(height: 14),
                for (var i = 0; i < list.length; i++)
                  FadeSlideIn(
                    delay: Duration(milliseconds: 40 * i),
                    child: _card(pal, l, list[i]),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _card(AppPalette pal, AppL10n l, Map<String, dynamic> p) {
    final title = (p['title'] ?? '').toString();
    final image = (p['image'] ?? '').toString();
    final price = (p['price'] as num?)?.toDouble() ?? 0;
    final stock = (p['stock'] as num?)?.toInt() ?? 0;
    final days = (p['days_left'] as num?)?.toInt() ?? 0;
    final expired = p['expired'] == true;

    // Ранг аз рӯи шиддат: гузашт → сурх, 1 рӯз → сурх, то 3 → зард.
    final color = expired || days <= 1
        ? AppColors.error
        : (days <= 3 ? AppColors.warning : AppColors.primary);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: image.isEmpty
              ? Container(
                  width: 56,
                  height: 56,
                  color: pal.surface,
                  child: Icon(FeatherIcons.package,
                      color: pal.textMuted, size: 21))
              : CachedNetworkImage(
                  imageUrl: image,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(width: 56, height: 56, color: pal.surface),
                  errorWidget: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: pal.surface,
                      child: Icon(FeatherIcons.package,
                          color: pal.textMuted, size: 21)),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title.isEmpty ? '—' : title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: pal.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text('${price.toStringAsFixed(0)} сом. · $stock',
                style: TextStyle(color: pal.textMuted, fontSize: 12)),
          ]),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(expired ? l.expiredWord : l.expiryDaysLeft(days),
              style: TextStyle(
                  color: color, fontSize: 11.5, fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }
}
