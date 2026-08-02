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

// Гурӯҳҳои ҳолат барои табҳо
enum _OrderTab { all, active, done, cancelled }

bool _matchesTab(_OrderTab tab, String status) {
  final s = status.toLowerCase();
  switch (tab) {
    case _OrderTab.all:
      return true;
    case _OrderTab.active:
      return ['pending', 'paid', 'processing', 'payment_uploaded', 'shipped']
          .contains(s);
    case _OrderTab.done:
      return s == 'delivered' || s == 'completed';
    case _OrderTab.cancelled:
      return s == 'cancelled';
  }
}

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});
  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  _OrderTab _tab = _OrderTab.all;

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    final pal = context.pal;
    return Scaffold(
      backgroundColor: pal.scaffold,
      appBar: AppBar(
        backgroundColor: pal.scaffold,
        elevation: 0,
        iconTheme: IconThemeData(color: pal.textPrimary),
        title: Text(AppL10n.of(context).myOrders,
            style: TextStyle(color: pal.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
              icon: Icon(FeatherIcons.refreshCw, color: pal.textSecondary),
              onPressed: () => ref.invalidate(ordersProvider))
        ],
      ),
      body: Column(
        children: [
          _tabs(pal),
          Expanded(
            child: orders.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => ErrorScreen(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(ordersProvider)),
              data: (all) {
                final list =
                    all.where((o) => _matchesTab(_tab, o.status)).toList();
                if (list.isEmpty) {
                  return Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(FeatherIcons.fileText,
                        size: 80, color: pal.textMuted),
                    const SizedBox(height: 16),
                    Text(AppL10n.of(context).noOrders,
                        style: TextStyle(
                            color: pal.textSecondary, fontSize: 16))
                  ]));
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => ref.invalidate(ordersProvider),
                  child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _OCard(order: list[i])),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabs(AppPalette pal) {
    const labels = {
      _OrderTab.all: 'Ҳама',
      _OrderTab.active: 'Фаъол',
      _OrderTab.done: 'Иҷрошуда',
      _OrderTab.cancelled: 'Бекор',
    };
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          for (final t in _OrderTab.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => setState(() => _tab = t),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _tab == t ? AppColors.primary : pal.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _tab == t ? AppColors.primary : pal.border,
                        width: 0.8),
                  ),
                  child: Center(
                    child: Text(labels[t]!,
                        style: TextStyle(
                            color: _tab == t ? Colors.white : pal.textSecondary,
                            fontSize: 13,
                            fontWeight:
                                _tab == t ? FontWeight.w700 : FontWeight.w500)),
                  ),
                ),
              ),
            ),
        ],
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
