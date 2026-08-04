import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/cargo_provider.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/safe_input.dart';

const _greenGradient = LinearGradient(
  colors: [Color(0xFF00D084), Color(0xFF00A3FF)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// «Карго» — доставка аз Хитой → Тоҷикистон/Русия.
/// Суроғаи анбор, тарифҳо, дархости интиқол ва пайгирии посылка.
class CargoScreen extends ConsumerWidget {
  const CargoScreen({super.key});

  static const _statuses = ['new', 'received', 'shipped', 'arrived', 'delivered'];
  static const _statusLabels = {
    'new': 'Қабул шуд',
    'received': 'Ба анбори Хитой расид',
    'shipped': 'Фиристода шуд',
    'arrived': 'Ба кишвар расид',
    'delivered': 'Супорида шуд',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pal = context.pal;
    final info = ref.watch(cargoInfoProvider);
    final mine = ref.watch(myCargoProvider);

    return Scaffold(
      backgroundColor: pal.scaffold,
      appBar: AppBar(
        backgroundColor: pal.scaffold,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(FeatherIcons.chevronLeft, color: pal.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(FeatherIcons.package, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Text('Карго — доставка аз Хитой',
              style: TextStyle(
                  color: pal.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => _newRequest(context, ref),
        icon: const Icon(FeatherIcons.plus, color: Colors.white),
        label: const Text('Дархости нав',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(cargoInfoProvider);
          ref.invalidate(myCargoProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
          children: [
            // ── Тарифҳо ──
            info.when(
              loading: () => const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
              error: (_, __) => const SizedBox.shrink(),
              data: (d) => _infoCard(context, d),
            ),
            const SizedBox(height: 22),
            Row(children: [
              Icon(FeatherIcons.truck, color: pal.textPrimary, size: 18),
              const SizedBox(width: 8),
              Text('Посылкаҳои ман',
                  style: TextStyle(
                      color: pal.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 12),
            mine.when(
              loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
              error: (_, __) => _emptyParcels(pal),
              data: (list) => list.isEmpty
                  ? _emptyParcels(pal)
                  : Column(children: [for (final p in list) _parcel(context, p)]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(BuildContext context, Map<String, dynamic> d) {
    final pal = context.pal;
    final warehouse = (d['warehouse'] ?? '').toString();
    final rateTj = (d['rate_tj'] as num?)?.toDouble() ?? 0;
    final rateRu = (d['rate_ru'] as num?)?.toDouble() ?? 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: _greenGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(FeatherIcons.mapPin, color: Colors.white, size: 16),
          SizedBox(width: 6),
          Text('Суроғаи анбор (Хитой)',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        Text(warehouse.isEmpty ? 'Ба зудӣ илова мешавад' : warehouse,
            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
        if (warehouse.isNotEmpty) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: warehouse));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Суроға нусхабардорӣ шуд ✅'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(FeatherIcons.copy, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text('Нусхабардорӣ',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Container(height: 1, color: Colors.white.withValues(alpha: 0.25)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _rateBox('🇹🇯 Тоҷикистон', rateTj)),
          const SizedBox(width: 12),
          Expanded(child: _rateBox('🇷🇺 Русия', rateRu)),
        ]),
        const SizedBox(height: 6),
        Text('Нарх аз рӯи вазн (сом/кг) ҳисоб мешавад',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11)),
      ]),
    );
  }

  Widget _rateBox(String label, double rate) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('${rate.toStringAsFixed(0)} сом/кг',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        ]),
      );

  Widget _emptyParcels(AppPalette pal) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(children: [
          Icon(FeatherIcons.package, size: 48, color: pal.textMuted),
          const SizedBox(height: 12),
          Text('Ҳоло посылка нест',
              style: TextStyle(color: pal.textSecondary, fontSize: 14)),
          const SizedBox(height: 4),
          Text('«Дархости нав» → интиқолро оғоз кунед',
              style: TextStyle(color: pal.textMuted, fontSize: 12)),
        ]),
      );

  Widget _parcel(BuildContext context, Map<String, dynamic> p) {
    final pal = context.pal;
    final status = (p['status'] ?? 'new').toString();
    final desc = (p['description'] ?? '').toString();
    final track = (p['track_code'] ?? '').toString();
    final dest = (p['destination'] ?? 'tj').toString();
    final weight = (p['weight'] as num?)?.toDouble() ?? 0;
    final cost = (p['cost'] as num?)?.toDouble() ?? 0;
    final stepIndex = _statuses.indexOf(status);
    DateTime? date;
    if (p['created_at'] != null) {
      date = DateTime.tryParse(p['created_at'].toString())?.toLocal();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: pal.border, width: 0.6),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(desc,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: pal.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8)),
            child: Text(dest == 'ru' ? '🇷🇺 РУ' : '🇹🇯 ТҶ',
                style: const TextStyle(
                    color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
        if (track.isNotEmpty) ...[
          const SizedBox(height: 5),
          Row(children: [
            Icon(FeatherIcons.hash, size: 12, color: pal.textMuted),
            const SizedBox(width: 4),
            Text(track, style: TextStyle(color: pal.textSecondary, fontSize: 12)),
          ]),
        ],
        const SizedBox(height: 12),
        // ── Progress steps ──
        Row(children: [
          for (int i = 0; i < _statuses.length; i++) ...[
            _dot(i <= stepIndex),
            if (i < _statuses.length - 1)
              Expanded(child: Container(height: 2, color: i < stepIndex ? AppColors.primary : pal.border)),
          ],
        ]),
        const SizedBox(height: 8),
        Text(_statusLabels[status] ?? status,
            style: const TextStyle(
                color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
              weight > 0 ? 'Вазн: ${weight.toStringAsFixed(1)} кг' : 'Вазн: ҳанӯз номаълум',
              style: TextStyle(color: pal.textSecondary, fontSize: 12)),
          if (cost > 0)
            Text('${cost.toStringAsFixed(0)} сом',
                style: const TextStyle(
                    color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w800)),
        ]),
        if (date != null) ...[
          const SizedBox(height: 4),
          Text(DateFormat('dd.MM.yyyy').format(date),
              style: TextStyle(color: pal.textMuted, fontSize: 11)),
        ],
      ]),
    );
  }

  Widget _dot(bool active) => Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
              color: active ? AppColors.primary : const Color(0xFF9AA5B1), width: 1.5),
        ),
        child: active
            ? const Icon(FeatherIcons.check, color: Colors.white, size: 8)
            : null,
      );

  void _newRequest(BuildContext context, WidgetRef ref) {
    final descCtrl = TextEditingController();
    final linkCtrl = TextEditingController();
    final trackCtrl = TextEditingController();
    String dest = 'tj';
    showModalBottomSheet(
      context: context,
      backgroundColor: context.pal.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        bool loading = false;
        return StatefulBuilder(builder: (ctx, setSheet) {
          Widget field(String label, TextEditingController c, {int maxLines = 1}) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                      color: context.pal.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.pal.border, width: 0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: SafeInput(controller: c, hint: label, maxLines: maxLines, fontSize: 14),
                ),
              );
          Widget destChip(String value, String label) {
            final sel = dest == value;
            return Expanded(
              child: GestureDetector(
                onTap: () => setSheet(() => dest = value),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary.withValues(alpha: 0.12) : context.pal.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: sel ? AppColors.primary : context.pal.border,
                        width: sel ? 1.3 : 0.5),
                  ),
                  child: Text(label,
                      style: TextStyle(
                          color: sel ? AppColors.primary : context.pal.textSecondary,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
                ),
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                              color: context.pal.border,
                              borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  Text('Дархости интиқол',
                      style: TextStyle(
                          color: context.pal.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  field('Тавсифи мол (номаш, миқдор…)', descCtrl, maxLines: 2),
                  field('Линки мол (Taobao/1688/Pinduoduo…) — ихтиёрӣ', linkCtrl),
                  field('Track-коди посылка — ихтиёрӣ', trackCtrl),
                  const SizedBox(height: 4),
                  Text('Самт',
                      style: TextStyle(
                          color: context.pal.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(children: [destChip('tj', '🇹🇯 Тоҷикистон'), destChip('ru', '🇷🇺 Русия')]),
                  const SizedBox(height: 16),
                  AppButton(
                    text: 'Фиристодан',
                    isLoading: loading,
                    onTap: () async {
                      if (descCtrl.text.trim().isEmpty) return;
                      setSheet(() => loading = true);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await CargoService.create(
                          description: descCtrl.text.trim(),
                          productLink: linkCtrl.text.trim(),
                          destination: dest,
                          trackCode: trackCtrl.text.trim(),
                        );
                        ref.invalidate(myCargoProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                        messenger.showSnackBar(const SnackBar(
                            content: Text('Дархост фиристода шуд ✅'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating));
                      } catch (_) {
                        setSheet(() => loading = false);
                        messenger.showSnackBar(const SnackBar(
                            content: Text('Хатогӣ — дубора кӯшиш кунед'),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating));
                      }
                    },
                  ),
                ]),
          );
        });
      },
    );
  }
}
