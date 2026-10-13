import 'package:dio/dio.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/app_l10n.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/rfq_l10n.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/rfq_provider.dart';
import '../../shared/widgets/fade_slide_in.dart';
import 'rfq_quote_sheet.dart';

/// Як дархости нарх бо пешниҳодҳо.
///
/// Ҳамон экран ба харидор ва фурӯшанда чизи ГУНОГУН нишон медиҳад —
/// вале ин қарори СЕРВЕР аст, на ин ҷо. Сервер ба фурӯшанда танҳо
/// пешниҳоди худашро мефиристад, пас ҳатто агар ин ҷо хато бошад, нархи
/// рақибон лу намешавад.
class RFQDetailScreen extends ConsumerWidget {
  final String rfqId;
  const RFQDetailScreen({super.key, required this.rfqId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pal = context.pal;
    final l = AppL10n.of(context);
    final async = ref.watch(rfqDetailProvider(rfqId));

    return Scaffold(
      backgroundColor: pal.scaffold,
      appBar: AppBar(
        backgroundColor: pal.scaffold,
        elevation: 0,
        iconTheme: IconThemeData(color: pal.textPrimary),
        title: Text(l.rfqTitle,
            style: TextStyle(
                color: pal.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17)),
      ),
      body: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => Center(
            child: Text(l.rfqEmptyBuyer,
                style: TextStyle(color: pal.textMuted, fontSize: 13))),
        data: (r) => _body(context, ref, pal, l, r),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, AppPalette pal, AppL10n l,
      Map<String, dynamic> r) {
    final isBuyer = r['is_buyer'] == true;
    final isOpen = r['open'] == true;
    final status = (r['status'] ?? 'open').toString();
    final qty = (r['quantity'] as num?)?.toInt() ?? 0;
    final unit = (r['unit'] ?? '').toString();
    final quotes = (r['quotes'] is List)
        ? (r['quotes'] as List)
            .whereType<Map>()
            .map((m) => m.cast<String, dynamic>())
            .toList()
        : const <Map<String, dynamic>>[];

    // Пешниҳоди фаъоли худи фурӯшанда — то тугма «иваз кардан» шавад.
    final myActive = !isBuyer
        ? quotes.firstWhere((q) => q['status'] == 'active',
            orElse: () => const {})
        : const <String, dynamic>{};

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => ref.invalidate(rfqDetailProvider(rfqId)),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _head(pal, l, r, status, qty, unit),
          const SizedBox(height: 16),

          // Фурӯшанда: тугмаи пешниҳод.
          if (!isBuyer && isOpen) ...[
            _rivalsNote(pal, l),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  final sent = await showRFQQuoteSheet(context,
                      rfqId: rfqId, quantity: qty, unit: unit);
                  if (sent == true) ref.invalidate(rfqDetailProvider(rfqId));
                },
                icon: const Icon(FeatherIcons.tag,
                    color: Colors.white, size: 18),
                label: Text(
                    myActive.isEmpty ? l.rfqSendQuote : l.rfqEditQuote,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
            ),
            const SizedBox(height: 18),
          ],

          Row(children: [
            Icon(FeatherIcons.messageSquare, size: 15, color: pal.textMuted),
            const SizedBox(width: 8),
            Text(l.rfqQuotes,
                style: TextStyle(
                    color: pal.textMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 10),

          if (quotes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(l.rfqNoQuotes,
                    style: TextStyle(color: pal.textMuted, fontSize: 13)),
              ),
            )
          else
            for (var i = 0; i < quotes.length; i++)
              FadeSlideIn(
                delay: Duration(milliseconds: 40 * i),
                child: _quoteCard(context, ref, pal, l, quotes[i],
                    isBuyer: isBuyer, rfqOpen: isOpen),
              ),

          // Харидор: пӯшидани дархост.
          if (isBuyer && isOpen) ...[
            const SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                onPressed: () => _close(context, ref, l),
                icon: const Icon(FeatherIcons.xCircle,
                    size: 15, color: AppColors.error),
                label: Text(l.rfqClose,
                    style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _head(AppPalette pal, AppL10n l, Map<String, dynamic> r,
      String status, int qty, String unit) {
    final days = rfqDaysLeft(r);
    final isOpen = r['open'] == true;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: pal.border, width: 0.6),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text((r['title'] ?? '—').toString(),
            style: TextStyle(
                color: pal.textPrimary,
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                height: 1.25)),
        if ((r['description'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(r['description'].toString(),
              style: TextStyle(color: pal.textMuted, fontSize: 13, height: 1.4)),
        ],
        const SizedBox(height: 12),
        _row(pal, FeatherIcons.package, '$qty $unit'),
        if (r['target_price'] != null)
          _row(pal, FeatherIcons.tag,
              '${l.rfqTargetPrice.split('(').first.trim()}: '
              '${(r['target_price'] as num).toStringAsFixed(0)} сом.'),
        if (r['destination'] != null)
          _row(pal, FeatherIcons.mapPin, r['destination'].toString()),
        if (r['needed_by'] != null)
          _row(pal, FeatherIcons.calendar, r['needed_by'].toString()),
        _row(pal, FeatherIcons.clock,
            isOpen ? l.rfqClosesIn(days) : l.rfqStatus(status)),
      ]),
    );
  }

  Widget _row(AppPalette pal, IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Icon(icon, size: 13.5, color: pal.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(color: pal.textPrimary, fontSize: 13)),
          ),
        ]),
      );

  /// Тавзеҳи он, ки чаро фурӯшанда нархи рақибонро намебинад.
  ///
  /// Инро гуфтан лозим аст: вагарна фурӯшанда фикр мекунад, ки хато аст
  /// ё маълумот бор нашуд.
  Widget _rivalsNote(AppPalette pal, AppL10n l) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.info.withValues(alpha: 0.24)),
        ),
        child: Row(children: [
          const Icon(FeatherIcons.eyeOff, size: 16, color: AppColors.info),
          const SizedBox(width: 10),
          Expanded(
            child: Text(l.rfqRivalsHidden,
                style: TextStyle(
                    color: pal.textPrimary, fontSize: 12, height: 1.35)),
          ),
        ]),
      );

  Widget _quoteCard(BuildContext context, WidgetRef ref, AppPalette pal,
      AppL10n l, Map<String, dynamic> q,
      {required bool isBuyer, required bool rfqOpen}) {
    final status = (q['status'] ?? '').toString();
    final usable = q['usable'] == true;
    final cheapest = q['cheapest'] == true;
    final total = (q['total'] as num?)?.toDouble() ?? 0;
    final unitPrice = (q['unit_price'] as num?)?.toDouble() ?? 0;
    final shipping = (q['shipping_cost'] as num?)?.toDouble() ?? 0;
    final leadDays = (q['lead_days'] as num?)?.toInt() ?? 0;
    final version = (q['version'] as num?)?.toInt() ?? 1;

    final border = cheapest
        ? AppColors.success
        : (usable ? pal.border : pal.border.withValues(alpha: 0.4));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: border, width: cheapest ? 1.4 : 0.6),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (cheapest) ...[
          Row(children: [
            const Icon(FeatherIcons.award, size: 14, color: AppColors.success),
            const SizedBox(width: 6),
            Text(l.rfqCheapest,
                style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 8),
        ],

        // Номи фурӯшанда танҳо ба харидор меояд — сервер онро ба
        // фурӯшанда умуман намефиристад.
        if (isBuyer && q['seller_name'] != null)
          Row(children: [
            Expanded(
              child: Text(q['seller_name'].toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: pal.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ),
            if (q['seller_verified'] == true)
              const Icon(FeatherIcons.checkCircle,
                  size: 14, color: AppColors.info),
          ]),

        if (!isBuyer)
          Text(l.rfqVersion(version),
              style: TextStyle(
                  color: pal.textMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600)),

        const SizedBox(height: 8),
        // Ҷамъ аз ҳама муҳим аст — маҳз аз рӯи он муқоиса мешавад.
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${total.toStringAsFixed(0)} сом.',
              style: TextStyle(
                  color: usable ? AppColors.primary : pal.textMuted,
                  fontSize: 19,
                  fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          Text(l.rfqTotal,
              style: TextStyle(color: pal.textMuted, fontSize: 11.5)),
        ]),
        const SizedBox(height: 6),
        Text(
            '${l.rfqUnitPrice}: ${unitPrice.toStringAsFixed(2)} сом.'
            '${shipping > 0 ? '  ·  ${l.rfqShipping}: ${shipping.toStringAsFixed(0)} сом.' : ''}',
            style: TextStyle(color: pal.textMuted, fontSize: 12)),
        if (leadDays > 0)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text('${l.rfqLeadDays}: $leadDays',
                style: TextStyle(color: pal.textMuted, fontSize: 12)),
          ),
        if ((q['payment_terms'] ?? '').toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
                '${l.rfqPaymentTerms}: ${q['payment_terms']}',
                style: TextStyle(color: pal.textMuted, fontSize: 12)),
          ),
        if ((q['note'] ?? '').toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(q['note'].toString(),
                style: TextStyle(
                    color: pal.textPrimary, fontSize: 12.5, height: 1.35)),
          ),

        if (!usable) ...[
          const SizedBox(height: 8),
          Row(children: [
            Icon(FeatherIcons.clock, size: 13, color: pal.textMuted),
            const SizedBox(width: 6),
            Text(
                status == 'accepted'
                    ? l.rfqAccepted
                    : (status == 'revised'
                        ? l.rfqVersion(version)
                        : l.rfqExpiredQuote),
                style: TextStyle(color: pal.textMuted, fontSize: 11.5)),
          ]),
        ],

        // Тугмаҳо.
        if (isBuyer && usable && rfqOpen) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () =>
                  _accept(context, ref, l, (q['id'] ?? '').toString()),
              icon: const Icon(FeatherIcons.check,
                  color: Colors.white, size: 17),
              label: Text(l.rfqAccept,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5)),
            ),
          ),
        ],
        if (!isBuyer && status == 'active') ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () =>
                  _withdraw(context, ref, l, (q['id'] ?? '').toString()),
              icon: const Icon(FeatherIcons.xCircle,
                  size: 14, color: AppColors.error),
              label: Text(l.rfqWithdraw,
                  style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ]),
    );
  }

  Future<void> _accept(BuildContext context, WidgetRef ref, AppL10n l,
      String quoteId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: context.pal.card,
        title: Text(l.rfqAccept,
            style: TextStyle(color: context.pal.textPrimary, fontSize: 16)),
        content: Text(l.rfqAccepted,
            style: TextStyle(color: context.pal.textMuted, fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(l.cancel,
                  style: TextStyle(color: context.pal.textMuted))),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(l.rfqAccept,
                  style: const TextStyle(
                      color: AppColors.success, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok != true) return;
    await _post(context, ref, l, '/quotes/$quoteId/accept', l.rfqAccepted);
  }

  Future<void> _withdraw(BuildContext context, WidgetRef ref, AppL10n l,
          String quoteId) =>
      _post(context, ref, l, '/quotes/$quoteId/withdraw', l.rfqWithdraw);

  Future<void> _close(BuildContext context, WidgetRef ref, AppL10n l) =>
      _post(context, ref, l, '/rfqs/$rfqId/close', l.rfqClose);

  Future<void> _post(BuildContext context, WidgetRef ref, AppL10n l,
      String path, String okText) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ApiClient.instance.dio.post(path);
      ref.invalidate(rfqDetailProvider(rfqId));
      messenger.showSnackBar(SnackBar(
        content: Text(okText),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    } on DioException catch (e) {
      final d = e.response?.data;
      // Паёми сервер нишон дода мешавад: он мегӯяд КАДОМ қоида халал
      // расонд (мӯҳлат гузашт, аллакай қабул шуд ва ғайра).
      messenger.showSnackBar(SnackBar(
        content: Text((d is Map ? d['error']?.toString() : null) ??
            l.rfqExpiredQuote),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}
