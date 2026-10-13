import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/app_l10n.dart';
import '../../core/l10n/order_steps_l10n.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../shared/widgets/fade_slide_in.dart';

/// Маълумоти ҳимояи харидор + қадамҳои фармоиш (аз `/orders/:id/timeline`).
final orderTimelineProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  final res = await ApiClient.instance.dio.get('/orders/$id/timeline');
  final raw = res.data;
  final map = raw is Map ? (raw['data'] is Map ? raw['data'] as Map : raw) : {};
  return Map<String, dynamic>.from(map);
});

/// Қадамҳои фармоиш — ҳамеша ҳамин тартиб нишон дода мешавад, то харидор
/// бидонад дар кадом марҳила аст ва баъд чӣ мешавад (мисли Alibaba).
const _steps = <String>['pending', 'processing', 'shipped', 'delivered', 'completed'];

/// `paid` (пардохт аз ҳамён) марҳилаи расонидан нест — он дар ҳамон
/// зинаи «қабул шуд» меистад. Бе ин харидори бо ҳамён пардохткарда
/// ягон зинаи фаъол намебинад.
int _stepIndex(String status) =>
    status == 'paid' ? 0 : _steps.indexOf(status);



IconData _stepIcon(String s) => switch (s) {
      'pending' => FeatherIcons.fileText,
      'processing' => FeatherIcons.package,
      'shipped' => FeatherIcons.truck,
      'delivered' => FeatherIcons.home,
      'completed' => FeatherIcons.checkCircle,
      _ => FeatherIcons.circle,
    };

/// Корти «Ҳимояи харидор» + қадамҳои фармоиш.
class OrderProtectionCard extends ConsumerWidget {
  final String orderId;
  const OrderProtectionCard({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(orderTimelineProvider(orderId));
    return async.maybeWhen(
      data: (d) => _body(context, d),
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _body(BuildContext context, Map<String, dynamic> d) {
    final pal = context.pal;
    final l = AppL10n.of(context);
    final status = (d['status'] ?? 'pending').toString();
    final tracking = (d['tracking_code'] ?? '').toString();
    final daysLeft = (d['days_left'] as num?)?.toInt() ?? 0;
    final protectionActive = d['protection_active'] == true;
    final protectionDays = (d['protection_days'] as num?)?.toInt() ?? 7;
    final events = (d['events'] is List) ? (d['events'] as List) : const [];
    final sellers = (d['sellers'] is List)
        ? (d['sellers'] as List)
            .whereType<Map>()
            .map((m) => m.cast<String, dynamic>())
            .toList()
        : const <Map<String, dynamic>>[];

    // Вақти ҳар қадам аз рӯйдодҳо (агар бошад).
    final times = <String, DateTime>{};
    for (final e in events) {
      if (e is Map) {
        final s = e['status']?.toString();
        final t = DateTime.tryParse(e['created_at']?.toString() ?? '');
        if (s != null && t != null) times[s] = t.toLocal();
      }
    }

    final currentIdx = _stepIndex(status);
    final cancelled = status == 'cancelled';

    return FadeSlideIn(
      child: Container(
        // Ҷойгиршавии уфуқиро волид муайян мекунад (ListView-и падари он
        // аллакай padding дорад) — вагарна фосила дукарата мешавад.
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: pal.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: pal.border, width: 0.6),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Сарлавҳаи ҳимоя ──
          Row(children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(FeatherIcons.shield,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.buyerProtection,
                        style: TextStyle(
                            color: pal.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                        protectionActive
                            ? 'Пули шумо ҳифз аст — $daysLeft рӯз боқӣ'
                            : 'Пул то тасдиқи гирифтани мол ҳифз мешавад',
                        style:
                            TextStyle(color: pal.textSecondary, fontSize: 12.5)),
                  ]),
            ),
          ]),

          if (protectionActive) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: protectionDays > 0
                    ? (1 - (daysLeft / protectionDays)).clamp(0.0, 1.0)
                    : 0,
                minHeight: 7,
                backgroundColor: pal.surface,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            const SizedBox(height: 6),
            Text(
                'Агар мол мувофиқ набошад, дар ин муддат бозгашт талаб карда метавонед.',
                style: TextStyle(color: pal.textMuted, fontSize: 11.5)),
          ],

          if (tracking.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                  color: pal.surface,
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(FeatherIcons.hash, size: 15, color: pal.textMuted),
                const SizedBox(width: 8),
                Text(l.trackingCodeLabel,
                    style: TextStyle(color: pal.textMuted, fontSize: 12.5)),
                Expanded(
                  child: Text(tracking,
                      style: TextStyle(
                          color: pal.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace')),
                ),
              ]),
            ),
          ],

          const SizedBox(height: 16),
          Divider(color: pal.divider, height: 1),
          const SizedBox(height: 14),

          // ── Қадамҳо ──
          if (cancelled)
            Row(children: [
              const Icon(FeatherIcons.xCircle, color: AppColors.error, size: 20),
              const SizedBox(width: 10),
              Text(l.orderStep('cancelled'),
                  style: TextStyle(
                      color: pal.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ])
          else
            for (int i = 0; i < _steps.length; i++)
              _stepRow(
                pal: pal,
                l: l,
                step: _steps[i],
                done: currentIdx >= 0 && i <= currentIdx,
                active: i == currentIdx,
                last: i == _steps.length - 1,
                at: times[_steps[i]],
              ),

          // ── Пешрафти ҳар фурӯшанда ──
          //
          // Танҳо вақте нишон дода мешавад, ки фармоиш моли ЧАНД
          // фурӯшанда дошта бошад. Бе ин харидор як ҳолат мебинад ва
          // намедонад, кадом мол дар роҳ аст ва кадомаш ҳанӯз не.
          if (sellers.length > 1) _sellersBlock(pal, l, sellers),
        ]),
      ),
    );
  }

  Widget _sellersBlock(AppPalette pal, AppL10n l, List<Map<String, dynamic>> sellers) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 6),
      Divider(color: pal.divider, height: 1),
      const SizedBox(height: 12),
      Row(children: [
        Icon(FeatherIcons.users, size: 15, color: pal.textMuted),
        const SizedBox(width: 8),
        Text(l.sellersWord,
            style: TextStyle(color: pal.textMuted, fontSize: 12.5,
                fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 10),
      for (final s in sellers) _sellerRow(pal, l, s),
    ]);
  }

  Widget _sellerRow(AppPalette pal, AppL10n l, Map<String, dynamic> s) {
    final status = (s['status'] ?? 'pending').toString();
    final name = (s['seller_name'] ?? '').toString();
    final items = (s['items'] as num?)?.toInt() ?? 0;
    final subtotal = (s['subtotal'] as num?)?.toDouble() ?? 0;

    final done = status == 'delivered' || status == 'completed';
    final cancelled = status == 'cancelled';
    final color = cancelled
        ? AppColors.error
        : (done ? AppColors.success : AppColors.primary);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(
          cancelled
              ? FeatherIcons.xCircle
              : (done ? FeatherIcons.checkCircle : _stepIcon(status)),
          size: 16,
          color: color,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name.isEmpty ? '—' : name,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: pal.textPrimary, fontSize: 13,
                    fontWeight: FontWeight.w600)),
            Text('${l.itemsCount(items)} · ${subtotal.toStringAsFixed(0)} сом.',
                style: TextStyle(color: pal.textMuted, fontSize: 11.5)),
          ]),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(l.orderStep(status),
              style: TextStyle(color: color, fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  Widget _stepRow({
    required AppPalette pal,
    required AppL10n l,
    required String step,
    required bool done,
    required bool active,
    required bool last,
    DateTime? at,
  }) {
    final color = done ? AppColors.primary : pal.textMuted;
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: done
                  ? AppColors.primary.withValues(alpha: active ? 0.20 : 0.12)
                  : pal.surface,
              shape: BoxShape.circle,
              border: Border.all(
                  color: active ? AppColors.primary : Colors.transparent,
                  width: 2),
            ),
            child: Icon(_stepIcon(step), size: 14, color: color),
          ),
          if (!last)
            Expanded(
              child: Container(
                width: 2,
                margin: const EdgeInsets.symmetric(vertical: 2),
                color: done ? AppColors.primary.withValues(alpha: 0.35) : pal.divider,
              ),
            ),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : 16, top: 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.orderStep(step),
                  style: TextStyle(
                      color: done ? pal.textPrimary : pal.textMuted,
                      fontSize: 13.5,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
              if (at != null) ...[
                const SizedBox(height: 2),
                Text(DateFormat('dd.MM.yyyy • HH:mm').format(at),
                    style: TextStyle(color: pal.textMuted, fontSize: 11.5)),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}
