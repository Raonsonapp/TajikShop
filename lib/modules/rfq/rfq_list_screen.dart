import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_l10n.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/rfq_l10n.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rfq_provider.dart';
import '../../shared/widgets/fade_slide_in.dart';
import 'rfq_create_sheet.dart';
import 'rfq_detail_screen.dart';

/// Дархостҳои нарх.
///
/// Як экран бо ду табақа:
///   • «Дархостҳои ман» — ҳамеша (ҳар кас харидор аст)
///   • «Дархостҳои кушода» — танҳо барои фурӯшанда
class RFQListScreen extends ConsumerStatefulWidget {
  const RFQListScreen({super.key});
  @override
  ConsumerState<RFQListScreen> createState() => _RFQListScreenState();
}

class _RFQListScreenState extends ConsumerState<RFQListScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabs;
  bool _isSeller = false;

  @override
  void dispose() {
    _tabs?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final l = AppL10n.of(context);
    final user = ref.watch(authProvider).user;
    final isSeller = user?.isSeller == true || user?.role == 'seller';

    // Корбар метавонад дар давоми сессия фурӯшанда шавад — он гоҳ
    // шумораи табақаҳо тағйир меёбад ва controller бояд аз нав сохта
    // шавад, вагарна Flutter хато мепартояд.
    if (_tabs == null || _isSeller != isSeller) {
      _tabs?.dispose();
      _isSeller = isSeller;
      _tabs = TabController(length: isSeller ? 2 : 1, vsync: this);
    }

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
        bottom: isSeller
            ? TabBar(
                controller: _tabs,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: pal.textMuted,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13.5),
                tabs: [
                  Tab(text: l.rfqMyRequests),
                  Tab(text: l.rfqOpenRequests),
                ],
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final created = await showRFQCreateSheet(context);
          if (created == true) ref.invalidate(myRFQsProvider);
        },
        icon: const Icon(FeatherIcons.plus, color: Colors.white, size: 19),
        label: Text(l.rfqNew,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: isSeller
          ? TabBarView(controller: _tabs, children: [
              _list(myRFQsProvider, l.rfqEmptyBuyer, buyer: true),
              _list(openRFQsProvider, l.rfqEmptySeller, buyer: false),
            ])
          : _list(myRFQsProvider, l.rfqEmptyBuyer, buyer: true),
    );
  }

  Widget _list(
    AutoDisposeFutureProvider<List<Map<String, dynamic>>> provider,
    String emptyText, {
    required bool buyer,
  }) {
    final pal = context.pal;
    final l = AppL10n.of(context);
    final async = ref.watch(provider);

    return async.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => _empty(pal, l, emptyText),
      data: (list) {
        if (list.isEmpty) return _empty(pal, l, emptyText);
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => ref.invalidate(provider),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            children: [
              if (buyer)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(l.rfqExplain,
                      style: TextStyle(
                          color: pal.textMuted, fontSize: 12.5, height: 1.35)),
                ),
              for (var i = 0; i < list.length; i++)
                FadeSlideIn(
                  delay: Duration(milliseconds: 40 * i),
                  child: _card(pal, l, list[i], buyer: buyer),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _empty(AppPalette pal, AppL10n l, String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(FeatherIcons.fileText,
                  color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 16),
            Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: pal.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(l.rfqExplain,
                textAlign: TextAlign.center,
                style: TextStyle(color: pal.textMuted, fontSize: 12.5, height: 1.35)),
          ]),
        ),
      );

  Widget _card(AppPalette pal, AppL10n l, Map<String, dynamic> r,
      {required bool buyer}) {
    final status = (r['status'] ?? 'open').toString();
    final isOpen = r['open'] == true;
    final quotes = (r['quotes'] as num?)?.toInt() ?? 0;
    final qty = (r['quantity'] as num?)?.toInt() ?? 0;
    final unit = (r['unit'] ?? '').toString();
    final days = rfqDaysLeft(r);

    final statusColor = switch (status) {
      'open' => AppColors.primary,
      'awarded' => AppColors.success,
      'cancelled' => AppColors.error,
      _ => pal.textMuted,
    };

    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => RFQDetailScreen(rfqId: (r['id'] ?? '').toString())));
        if (!mounted) return;
        ref.invalidate(myRFQsProvider);
        ref.invalidate(openRFQsProvider);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: pal.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: pal.border, width: 0.6),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text((r['title'] ?? '—').toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: pal.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(l.rfqStatus(status),
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 7),
          Row(children: [
            Icon(FeatherIcons.package, size: 13, color: pal.textMuted),
            const SizedBox(width: 6),
            Text('$qty $unit',
                style: TextStyle(color: pal.textMuted, fontSize: 12.5)),
            const SizedBox(width: 14),
            Icon(FeatherIcons.clock, size: 13, color: pal.textMuted),
            const SizedBox(width: 6),
            Text(isOpen ? l.rfqClosesIn(days) : l.rfqStatus(status),
                style: TextStyle(color: pal.textMuted, fontSize: 12.5)),
          ]),
          if (r['destination'] != null) ...[
            const SizedBox(height: 5),
            Row(children: [
              Icon(FeatherIcons.mapPin, size: 13, color: pal.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(r['destination'].toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: pal.textMuted, fontSize: 12.5)),
              ),
            ]),
          ],
          const SizedBox(height: 10),
          Row(children: [
            Icon(
                quotes > 0
                    ? FeatherIcons.messageSquare
                    : FeatherIcons.messageCircle,
                size: 14,
                color: quotes > 0 ? AppColors.primary : pal.textMuted),
            const SizedBox(width: 7),
            Text(
                quotes > 0
                    // Барои фурӯшанда ин «пешниҳоди МАН» аст, на ҳамаи
                    // пешниҳодҳо — сервер нархи рақибонро пинҳон мекунад.
                    ? (buyer ? l.rfqQuotesCount(quotes) : l.rfqEditQuote)
                    : (buyer ? l.rfqNoQuotes : l.rfqSendQuote),
                style: TextStyle(
                    color: quotes > 0 ? AppColors.primary : pal.textMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Icon(FeatherIcons.chevronRight, size: 16, color: pal.textMuted),
          ]),
        ]),
      ),
    );
  }
}
