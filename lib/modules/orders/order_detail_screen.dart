import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/api/api_client.dart';
import '../../data/models/order_model.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/return_provider.dart';
import '../../routes/route_names.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/error_screen.dart';
import '../../shared/widgets/safe_input.dart';
import 'orders_screen.dart';

final orderDetailProvider =
    FutureProvider.autoDispose.family<OrderModel, String>((ref, id) async {
  final res = await ApiClient.instance.dio.get('/orders/$id');
  final raw = res.data;
  final map = raw is Map
      ? (raw['data'] is Map ? raw['data'] as Map : raw)
      : <String, dynamic>{};
  return OrderModel.fromJson(Map<String, dynamic>.from(map));
});

// Марҳилаҳои расонидан бо тартиб
const _steps = [
  ('pending', 'Қабул шуд', Icons.receipt_long_rounded),
  ('payment_uploaded', 'Пардохт тасдиқ', Icons.payments_rounded),
  ('processing', 'Дар коркард', Icons.inventory_2_rounded),
  ('shipped', 'Фиристода шуд', Icons.local_shipping_rounded),
  ('delivered', 'Расонида шуд', Icons.check_circle_rounded),
];

int _statusIndex(String status) {
  final i = _steps.indexWhere((s) => s.$1 == status.toLowerCase());
  if (status.toLowerCase() == 'cancelled') return -1;
  return i < 0 ? 0 : i;
}

class OrderDetailScreen extends ConsumerWidget {
  final String id;
  const OrderDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailProvider(id));
    return Scaffold(
      backgroundColor: context.pal.scaffold,
      appBar: AppBar(
        backgroundColor: context.pal.scaffold,
        iconTheme: IconThemeData(color: context.pal.textPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.canPop(context) ? Navigator.pop(context) : context.go(RouteNames.orders)),
        title: Text('Фармоиш', style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: Icon(Icons.refresh_rounded, color: context.pal.textSecondary),
            onPressed: () => ref.invalidate(orderDetailProvider(id)))],
      ),
      body: order.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorScreen(message: e.toString(), onRetry: () => ref.invalidate(orderDetailProvider(id))),
        data: (o) => _build(context, ref, o),
      ),
    );
  }

  bool _canCancel(String status) {
    const ok = ['pending', 'processing', 'paid', 'payment_uploaded'];
    return ok.contains(status.toLowerCase());
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: context.pal.card,
      title: Text('Бекор кардан?', style: TextStyle(color: context.pal.textPrimary)),
      content: Text('Фармоиш бекор карда шавад? Агар бо ҳамён пардохт шуда бошад, пул бармегардад.',
          style: TextStyle(color: context.pal.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: Text('Не', style: TextStyle(color: context.pal.textMuted))),
        TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Бале, бекор кун', style: TextStyle(color: AppColors.error))),
      ],
    ));
    if (confirm != true) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final res = await ApiClient.instance.dio.post('/orders/$id/cancel');
      final refunded = (res.data is Map && res.data['data'] is Map)
          ? res.data['data']['refunded'] == true : false;
      ref.invalidate(orderDetailProvider(id));
      ref.invalidate(ordersProvider);
      if (refunded) ref.invalidate(walletProvider);
      messenger.showSnackBar(SnackBar(
        content: Text(refunded ? 'Бекор шуд — пул ба ҳамён баргашт ✅' : 'Фармоиш бекор шуд'),
        backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
    } catch (e) {
      final msg = (e is DioException && e.response?.data is Map)
          ? e.response?.data['error']?.toString() : null;
      messenger.showSnackBar(SnackBar(
        content: Text(msg ?? 'Бекор кардан мумкин нашуд'),
        backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    }
  }

  bool _canConfirm(String status) {
    final s = status.toLowerCase();
    return s != 'completed' && s != 'cancelled' && s != 'pending';
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: context.pal.card,
      title: Text('Расидани молро тасдиқ мекунед?', style: TextStyle(color: context.pal.textPrimary)),
      content: Text('Танҳо вақте молро гирифтед тасдиқ кунед. Баъд аз тасдиқ, маблағ ба фурӯшанда дода мешавад.',
          style: TextStyle(color: context.pal.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: Text('Ҳоло не', style: TextStyle(color: context.pal.textMuted))),
        TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Бале, гирифтам', style: TextStyle(color: AppColors.success))),
      ],
    ));
    if (ok != true) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ApiClient.instance.dio.post('/orders/$id/confirm');
      ref.invalidate(orderDetailProvider(id));
      ref.invalidate(ordersProvider);
      messenger.showSnackBar(const SnackBar(
        content: Text('Раҳмат! Фармоиш анҷом ёфт ✅'),
        backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
    } catch (e) {
      final msg = (e is DioException && e.response?.data is Map)
          ? e.response?.data['error']?.toString() : null;
      messenger.showSnackBar(SnackBar(
        content: Text(msg ?? 'Хато'),
        backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    }
  }

  // ── Бозгашт / Иваз ──────────────────────────────────────────────────────────
  Widget _returnSection(BuildContext context, WidgetRef ref, OrderModel o) {
    final s = o.status.toLowerCase();
    if (s != 'delivered' && s != 'completed') return const SizedBox.shrink();
    final ret = ref.watch(orderReturnProvider(o.id));
    return ret.maybeWhen(
      data: (r) {
        if (r != null) {
          final status = r['status']?.toString() ?? 'pending';
          final type = r['type']?.toString() == 'exchange' ? 'Иваз' : 'Бозгашт';
          const labels = {'pending': 'дар интизор', 'approved': 'қабул шуд', 'rejected': 'рад шуд', 'completed': 'анҷом ёфт'};
          final color = status == 'rejected'
              ? AppColors.error
              : (status == 'completed' || status == 'approved' ? AppColors.success : AppColors.warning);
          return Padding(padding: const EdgeInsets.only(top: 16),
            child: Container(padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.3))),
              child: Row(children: [
                Icon(Icons.assignment_return_outlined, color: color, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('$type: ${labels[status] ?? status}',
                    style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600))),
              ])));
        }
        return Padding(padding: const EdgeInsets.only(top: 16),
          child: SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: () => _requestReturn(context, ref, o),
            icon: const Icon(Icons.assignment_return_outlined, size: 18, color: AppColors.warning),
            label: const Text('Бозгашт ё иваз кардан', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.warning),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))));
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  void _requestReturn(BuildContext context, WidgetRef ref, OrderModel o) {
    final reasonCtrl = TextEditingController();
    String type = 'return';
    showModalBottomSheet(context: context, backgroundColor: context.pal.card, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: context.pal.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Бозгашт / Иваз', style: TextStyle(color: context.pal.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Row(children: [
            _typeChip('return', 'Бозгашти пул', type, (v) => setSheet(() => type = v)),
            const SizedBox(width: 10),
            _typeChip('exchange', 'Иваз кардан', type, (v) => setSheet(() => type = v)),
          ]),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.5)),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SafeInput(controller: reasonCtrl, maxLines: 3,
              hint: 'Сабабро нависед...',
              textColor: AppColors.textPrimary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          AppButton(text: 'Фиристодани дархост', onTap: () async {
            final reason = reasonCtrl.text.trim();
            if (reason.isEmpty) return;
            Navigator.pop(ctx);
            final messenger = ScaffoldMessenger.of(context);
            try {
              await ReturnService.request(o.id, type: type, reason: reason);
              ref.invalidate(orderReturnProvider(o.id));
              messenger.showSnackBar(const SnackBar(content: Text('Дархост фиристода шуд ✅'),
                  backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
            } catch (e) {
              final msg = (e is DioException && e.response?.data is Map) ? e.response?.data['error']?.toString() : null;
              messenger.showSnackBar(SnackBar(content: Text(msg ?? 'Хато'),
                  backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
            }
          }),
        ]),
      )));
  }

  Widget _typeChip(String value, String label, String current, Function(String) onTap) {
    final sel = current == value;
    return Expanded(child: GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12), alignment: Alignment.center,
        decoration: BoxDecoration(
          color: sel ? AppColors.primary.withValues(alpha: 0.15) : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? AppColors.primary : AppColors.border, width: sel ? 1.4 : 0.5)),
        child: Text(label, style: TextStyle(color: sel ? AppColors.primary : AppColors.textSecondary,
            fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    ));
  }

  Widget _build(BuildContext context, WidgetRef ref, OrderModel o) {
    final cancelled = o.status.toLowerCase() == 'cancelled';
    final completed = o.status.toLowerCase() == 'completed';
    final current = _statusIndex(o.status);
    return ListView(padding: const EdgeInsets.all(16), children: [
      // Header card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.5)),
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('#${(o.id.length > 8 ? o.id.substring(0, 8) : o.id).toUpperCase()}',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(DateFormat('dd.MM.yyyy • HH:mm').format(o.createdAt),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ]),
          const Spacer(),
          Text('${o.total.toStringAsFixed(0)} сом.',
              style: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.w800)),
        ]),
      ),
      const SizedBox(height: 20),

      // Tracking timeline
      const Text('Ҳолати расонидан',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      if (cancelled)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3))),
          child: const Row(children: [
            Icon(Icons.cancel_rounded, color: AppColors.error),
            SizedBox(width: 10),
            Text('Фармоиш бекор карда шуд', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
          ]))
      else
        Column(children: List.generate(_steps.length, (i) {
          final done = i <= current;
          final isLast = i == _steps.length - 1;
          return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              Container(width: 34, height: 34,
                decoration: BoxDecoration(
                  color: done ? AppColors.primary : AppColors.bgSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: done ? AppColors.primary : AppColors.border, width: 1.5)),
                child: Icon(_steps[i].$3, color: done ? Colors.white : AppColors.textMuted, size: 18)),
              if (!isLast)
                Expanded(child: Container(width: 2,
                    color: i < current ? AppColors.primary : AppColors.border)),
            ]),
            const SizedBox(width: 14),
            Padding(padding: const EdgeInsets.only(top: 6, bottom: 18),
              child: Text(_steps[i].$2, style: TextStyle(
                  color: done ? AppColors.textPrimary : AppColors.textMuted,
                  fontSize: 14, fontWeight: done ? FontWeight.w600 : FontWeight.w400))),
          ]));
        })),

      const SizedBox(height: 12),

      // Payment proof
      if (o.paymentProof != null && o.paymentProof!.isNotEmpty) ...[
        const Text('Чеки пардохт',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        ClipRRect(borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(imageUrl: o.paymentProof!, height: 180, width: double.infinity, fit: BoxFit.cover,
            placeholder: (_, __) => Container(height: 180, color: AppColors.bgSurface),
            errorWidget: (_, __, ___) => Container(height: 180, color: AppColors.bgSurface,
                child: const Icon(Icons.broken_image_outlined, color: AppColors.textMuted)))),
        const SizedBox(height: 20),
      ],

      // Items count + note
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.5)),
        child: Column(children: [
          _row('Маҳсулот', '${o.itemCount}'),
          const SizedBox(height: 8),
          _row('Ҷамъи фармоиш', '${o.total.toStringAsFixed(0)} сом.', bold: true),
          if (o.note != null && o.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _row('Эзоҳ', o.note!),
          ],
        ]),
      ),

      if (completed) ...[
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3))),
          child: const Row(children: [
            Icon(Icons.verified_rounded, color: AppColors.success),
            SizedBox(width: 10),
            Expanded(child: Text('Фармоиш анҷом ёфт ва маблағ ба фурӯшанда дода шуд.',
                style: TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w600))),
          ])),
      ],

      _returnSection(context, ref, o),

      if (_canConfirm(o.status)) ...[
        const SizedBox(height: 20),
        // Ҳимояи escrow
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3))),
          child: const Row(children: [
            Icon(Icons.shield_outlined, color: AppColors.info, size: 20),
            SizedBox(width: 10),
            Expanded(child: Text('Ҳимоя: пули шумо то тасдиқи расидани мол нигоҳ дошта мешавад.',
                style: TextStyle(color: AppColors.info, fontSize: 12))),
          ])),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(
          onPressed: () => _confirm(context, ref),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
          label: const Text('Расидани молро тасдиқ мекунам',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)))),
      ],

      if (_canCancel(o.status)) ...[
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: () => _cancel(context, ref),
          icon: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 18),
          label: const Text('Фармоишро бекор кардан', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
      ],
    ]);
  }

  Widget _row(String label, String value, {bool bold = false}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Flexible(child: Text(value, textAlign: TextAlign.right,
            style: TextStyle(color: bold ? AppColors.primary : AppColors.textPrimary,
                fontSize: bold ? 15 : 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w500))),
      ]);
}
