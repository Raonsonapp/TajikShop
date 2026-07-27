import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../core/app_l10n.dart';
import '../../core/l10n/orders_l10n.dart';
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
  ('pending', Icons.receipt_long_rounded),
  ('payment_uploaded', Icons.payments_rounded),
  ('processing', Icons.inventory_2_rounded),
  ('shipped', Icons.local_shipping_rounded),
  ('delivered', Icons.check_circle_rounded),
];

String _stepLabel(AppL10n l, int i) {
  switch (i) {
    case 0:
      return l.stepAccepted;
    case 1:
      return l.stepPaymentConfirmed;
    case 2:
      return l.stepProcessingStage;
    case 3:
      return l.stepShippedStage;
    default:
      return l.stepDeliveredStage;
  }
}

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
        elevation: 0,
        iconTheme: IconThemeData(color: context.pal.textPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.canPop(context) ? Navigator.pop(context) : context.go(RouteNames.orders)),
        title: Text(AppL10n.of(context).orderTitle, style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w700)),
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
    final l = AppL10n.of(context);
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: context.pal.card,
      title: Text(l.cancelQuestion, style: TextStyle(color: context.pal.textPrimary)),
      content: Text(l.cancelOrderConfirmBody,
          style: TextStyle(color: context.pal.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.noWord, style: TextStyle(color: context.pal.textMuted))),
        TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.yesCancel, style: const TextStyle(color: AppColors.error))),
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
        content: Text(refunded ? l.cancelledRefunded : l.orderCancelledMsg),
        backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
    } catch (e) {
      final msg = (e is DioException && e.response?.data is Map)
          ? e.response?.data['error']?.toString() : null;
      messenger.showSnackBar(SnackBar(
        content: Text(msg ?? l.cancelFailed),
        backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    }
  }

  bool _canConfirm(String status) {
    final s = status.toLowerCase();
    return s != 'completed' && s != 'cancelled' && s != 'pending';
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final l = AppL10n.of(context);
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: context.pal.card,
      title: Text(l.confirmReceiptQuestion, style: TextStyle(color: context.pal.textPrimary)),
      content: Text(l.confirmReceiptBody,
          style: TextStyle(color: context.pal.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.notNow, style: TextStyle(color: context.pal.textMuted))),
        TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.yesReceived, style: const TextStyle(color: AppColors.success))),
      ],
    ));
    if (ok != true) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ApiClient.instance.dio.post('/orders/$id/confirm');
      ref.invalidate(orderDetailProvider(id));
      ref.invalidate(ordersProvider);
      messenger.showSnackBar(SnackBar(
        content: Text(l.thanksOrderCompleted),
        backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
    } catch (e) {
      final msg = (e is DioException && e.response?.data is Map)
          ? e.response?.data['error']?.toString() : null;
      messenger.showSnackBar(SnackBar(
        content: Text(msg ?? l.error),
        backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    }
  }

  // ── Бозгашт / Иваз ──────────────────────────────────────────────────────────
  Widget _returnSection(BuildContext context, WidgetRef ref, OrderModel o) {
    final s = o.status.toLowerCase();
    if (s != 'delivered' && s != 'completed') return const SizedBox.shrink();
    final l = AppL10n.of(context);
    final ret = ref.watch(orderReturnProvider(o.id));
    return ret.maybeWhen(
      data: (r) {
        if (r != null) {
          final status = r['status']?.toString() ?? 'pending';
          final type = r['type']?.toString() == 'exchange' ? l.exchangeWord : l.returnWord;
          final labels = {'pending': l.retStatusPending, 'approved': l.retStatusApproved, 'rejected': l.retStatusRejected, 'completed': l.retStatusCompleted};
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
            icon: const Icon(Icons.assignment_return_outlined, size: 18, color: AppColors.primary),
            label: Text(l.returnOrExchange, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))));
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  void _requestReturn(BuildContext context, WidgetRef ref, OrderModel o) {
    final l = AppL10n.of(context);
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
          Text(l.returnExchangeTitle, style: TextStyle(color: context.pal.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Row(children: [
            _typeChip('return', l.refundMoney, type, (v) => setSheet(() => type = v)),
            const SizedBox(width: 10),
            _typeChip('exchange', l.exchangeAction, type, (v) => setSheet(() => type = v)),
          ]),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(color: context.pal.surface, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.pal.border, width: 0.5)),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SafeInput(controller: reasonCtrl, maxLines: 3,
              hint: l.writeReasonHint,
              textColor: context.pal.textPrimary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          AppButton(text: l.sendRequest, onTap: () async {
            final reason = reasonCtrl.text.trim();
            if (reason.isEmpty) return;
            Navigator.pop(ctx);
            final messenger = ScaffoldMessenger.of(context);
            try {
              await ReturnService.request(o.id, type: type, reason: reason);
              ref.invalidate(orderReturnProvider(o.id));
              messenger.showSnackBar(SnackBar(content: Text(l.requestSent),
                  backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
            } catch (e) {
              final msg = (e is DioException && e.response?.data is Map) ? e.response?.data['error']?.toString() : null;
              messenger.showSnackBar(SnackBar(content: Text(msg ?? l.error),
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
    final l = AppL10n.of(context);
    final pal = context.pal;
    final cancelled = o.status.toLowerCase() == 'cancelled';
    final completed = o.status.toLowerCase() == 'completed';
    final current = _statusIndex(o.status);
    final isDark = pal.scaffold.computeLuminance() < 0.5;
    return ListView(padding: const EdgeInsets.all(16), children: [
      // Header card — tracking hero with green gradient accent
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.30),
              offset: const Offset(0, 8),
              blurRadius: 20,
            )
          ],
        ),
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('#${(o.id.length > 8 ? o.id.substring(0, 8) : o.id).toUpperCase()}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(DateFormat('dd.MM.yyyy • HH:mm').format(o.createdAt),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
          ]),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${o.total.toStringAsFixed(0)} ${l.som}',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          ]),
        ]),
      ),
      const SizedBox(height: 24),

      // Tracking timeline
      Text(l.deliveryStatus,
          style: TextStyle(color: pal.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 14),
      if (cancelled)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3))),
          child: Row(children: [
            const Icon(Icons.cancel_rounded, color: AppColors.error),
            const SizedBox(width: 10),
            Text(l.orderWasCancelled, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
          ]))
      else
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: pal.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: pal.border, width: 0.6),
          ),
          child: Column(children: List.generate(_steps.length, (i) {
            final done = i <= current;
            final isLast = i == _steps.length - 1;
            return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Column(children: [
                Container(width: 36, height: 36,
                  decoration: BoxDecoration(
                    gradient: done ? AppColors.primaryGradient : null,
                    color: done ? null : pal.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: done ? Colors.transparent : pal.border, width: 1.5)),
                  child: Icon(_steps[i].$2, color: done ? Colors.white : pal.textMuted, size: 18)),
                if (!isLast)
                  Expanded(child: Container(width: 2,
                      color: i < current ? AppColors.primary : pal.border)),
              ]),
              const SizedBox(width: 14),
              Padding(padding: const EdgeInsets.only(top: 8, bottom: 20),
                child: Text(_stepLabel(AppL10n.of(context), i), style: TextStyle(
                    color: done ? pal.textPrimary : pal.textMuted,
                    fontSize: 14, fontWeight: done ? FontWeight.w600 : FontWeight.w400))),
            ]));
          })),
        ),

      const SizedBox(height: 20),

      // Payment proof
      if (o.paymentProof != null && o.paymentProof!.isNotEmpty) ...[
        Text(l.paymentReceipt,
            style: TextStyle(color: pal.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        ClipRRect(borderRadius: BorderRadius.circular(14),
          child: CachedNetworkImage(imageUrl: o.paymentProof!, height: 180, width: double.infinity, fit: BoxFit.cover,
            placeholder: (_, __) => Container(height: 180, color: pal.surface),
            errorWidget: (_, __, ___) => Container(height: 180, color: pal.surface,
                child: Icon(Icons.broken_image_outlined, color: pal.textMuted)))),
        const SizedBox(height: 20),
      ],

      // Items count + totals
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: pal.card, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: pal.border, width: 0.6)),
        child: Column(children: [
          _row(context, l.productsWord, '${o.itemCount}'),
          const SizedBox(height: 10),
          _row(context, l.orderTotalLabel, '${o.total.toStringAsFixed(0)} ${l.som}', bold: true),
          if (o.note != null && o.note!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _row(context, l.noteWord, o.note!),
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
          child: Row(children: [
            const Icon(Icons.verified_rounded, color: AppColors.success),
            const SizedBox(width: 10),
            Expanded(child: Text(l.orderCompletedNote,
                style: const TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w600))),
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
          child: Row(children: [
            const Icon(Icons.shield_outlined, color: AppColors.info, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(l.escrowProtection,
                style: const TextStyle(color: AppColors.info, fontSize: 12))),
          ])),
        const SizedBox(height: 12),
        // Green gradient confirm button
        _GradientButton(
          onTap: () => _confirm(context, ref),
          icon: Icons.check_circle_outline_rounded,
          label: l.confirmReceiptButton,
        ),
      ],

      if (_canCancel(o.status)) ...[
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: () => _cancel(context, ref),
          icon: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 18),
          label: Text(l.cancelOrderButton, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
      ],
    ]);
  }

  Widget _row(BuildContext context, String label, String value, {bool bold = false}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: context.pal.textSecondary, fontSize: 13)),
        Flexible(child: Text(value, textAlign: TextAlign.right,
            style: TextStyle(color: bold ? AppColors.primary : context.pal.textPrimary,
                fontSize: bold ? 15 : 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w500))),
      ]);
}

class _GradientButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  const _GradientButton({required this.onTap, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.30),
              offset: const Offset(0, 6),
              blurRadius: 16,
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(label,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ),
    );
  }
}
