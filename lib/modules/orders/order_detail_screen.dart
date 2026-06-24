import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/api/api_client.dart';
import '../../data/models/order_model.dart';
import '../../providers/wallet_provider.dart';
import '../../routes/route_names.dart';
import '../../shared/widgets/error_screen.dart';
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
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.canPop(context) ? Navigator.pop(context) : context.go(RouteNames.orders)),
        title: const Text('Фармоиш', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
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
      backgroundColor: AppColors.bgCard,
      title: const Text('Бекор кардан?', style: TextStyle(color: AppColors.textPrimary)),
      content: const Text('Фармоиш бекор карда шавад? Агар бо ҳамён пардохт шуда бошад, пул бармегардад.',
          style: TextStyle(color: AppColors.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Не', style: TextStyle(color: AppColors.textMuted))),
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

  Widget _build(BuildContext context, WidgetRef ref, OrderModel o) {
    final cancelled = o.status.toLowerCase() == 'cancelled';
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

      if (_canCancel(o.status)) ...[
        const SizedBox(height: 20),
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
