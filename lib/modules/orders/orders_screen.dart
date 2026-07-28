import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/app_l10n.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/cart_repository.dart';
import '../../shared/widgets/error_screen.dart';

final ordersProvider = FutureProvider.autoDispose<List<OrderModel>>((ref) async {
  return CartRepository().getOrders();
});

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    return Scaffold(
      backgroundColor: context.pal.scaffold,
      appBar: AppBar(
        backgroundColor: context.pal.scaffold,
        elevation: 0,
        iconTheme: IconThemeData(color: context.pal.textPrimary),
        title: Text(AppL10n.of(context).myOrders,
            style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
              icon: Icon(FeatherIcons.refreshCw, color: context.pal.textSecondary),
              onPressed: () => ref.invalidate(ordersProvider))
        ],
      ),
      body: orders.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorScreen(message: e.toString(), onRetry: () => ref.invalidate(ordersProvider)),
        data: (list) => list.isEmpty
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(FeatherIcons.fileText, size: 80, color: context.pal.textMuted),
                const SizedBox(height: 16),
                Text(AppL10n.of(context).noOrders,
                    style: TextStyle(color: context.pal.textSecondary, fontSize: 16))
              ]))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: list.length,
                itemBuilder: (_, i) => _OCard(order: list[i])),
      ),
    );
  }
}

class _OCard extends StatelessWidget {
  final OrderModel order;
  const _OCard({required this.order});

  Color _c() {
    switch (order.status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'delivered':
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  String _l(BuildContext context) {
    final l = AppL10n.of(context);
    switch (order.status.toLowerCase()) {
      case 'pending':
        return l.statusPending;
      case 'processing':
        return l.statusProcessing;
      case 'shipped':
        return l.statusShipped;
      case 'delivered':
        return l.statusDelivered;
      case 'cancelled':
        return l.statusCancelled;
      default:
        return order.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _c();
    final pal = context.pal;
    final isDark = pal.scaffold.computeLuminance() < 0.5;
    return GestureDetector(
      onTap: () => context.push('/orders/${order.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: pal.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: pal.border, width: 0.6),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, 4),
              blurRadius: 14,
            )
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            // Gradient avatar (green)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(FeatherIcons.shoppingBag, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('#${(order.id.length > 8 ? order.id.substring(0, 8) : order.id).toUpperCase()}',
                    style: TextStyle(
                        color: pal.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text(DateFormat('dd.MM.yyyy • HH:mm').format(order.createdAt),
                    style: TextStyle(color: pal.textMuted, fontSize: 12)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
              child: Text(_l(context),
                  style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 14),
          Divider(color: pal.divider, height: 1),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${order.itemCount} ${AppL10n.of(context).itemsWord}',
                style: TextStyle(color: pal.textSecondary, fontSize: 13)),
            Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Text('${order.total.toStringAsFixed(0)} ',
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 17)),
              Text(AppL10n.of(context).som,
                  style: TextStyle(
                      color: AppColors.primary.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ]),
          ]),
        ]),
      ),
    );
  }
}
