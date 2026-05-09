import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
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
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(backgroundColor: AppColors.bgDark,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text('Фармоишҳоям', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => ref.invalidate(ordersProvider))]),
      body: orders.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorScreen(message: e.toString(), onRetry: () => ref.invalidate(ordersProvider)),
        data: (list) => list.isEmpty
            ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.receipt_long_outlined, size: 80, color: AppColors.textMuted),
                SizedBox(height: 16),
                Text('Фармоише нест', style: TextStyle(color: AppColors.textSecondary, fontSize: 16))]))
            : ListView.builder(padding: const EdgeInsets.all(16), itemCount: list.length,
                itemBuilder: (_, i) => _OCard(order: list[i])),
      ),
    );
  }
}

class _OCard extends StatelessWidget {
  final OrderModel order;
  const _OCard({required this.order});
  Color _c() { switch (order.status.toLowerCase()) { case 'pending': return AppColors.warning; case 'delivered': return AppColors.success; case 'cancelled': return AppColors.error; default: return AppColors.info; } }
  String _l() { switch (order.status.toLowerCase()) { case 'pending': return 'Дар интизор'; case 'processing': return 'Коркард'; case 'shipped': return 'Фиристода шуд'; case 'delivered': return 'Расид'; case 'cancelled': return 'Бекор'; default: return order.status; } }
  @override
  Widget build(BuildContext context) {
    final c = _c();
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('#${(order.id.length > 8 ? order.id.substring(0,8) : order.id).toUpperCase()}',
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
            child: Text(_l(), style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 10),
        const Divider(color: AppColors.divider),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${order.itemCount} маҳсулот • ${DateFormat('dd.MM.yyyy').format(order.createdAt)}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Text('${order.total.toStringAsFixed(0)} сом.',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 15)),
        ]),
      ]),
    );
  }
}
