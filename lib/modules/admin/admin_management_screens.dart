import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../providers/search_provider.dart';
import '../../shared/widgets/error_screen.dart';

// ════════════════════════════════════════════════════════════════════════════
// КОРБАРОН
// ════════════════════════════════════════════════════════════════════════════
class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(adminUsersProvider);
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(backgroundColor: AppColors.bgDark,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text('Корбарон', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => ref.invalidate(adminUsersProvider))]),
      body: users.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorScreen(message: e.toString(), onRetry: () => ref.invalidate(adminUsersProvider)),
        data: (list) => list.isEmpty
            ? const Center(child: Text('Корбар нест', style: TextStyle(color: AppColors.textSecondary)))
            : ListView.builder(padding: const EdgeInsets.all(16), itemCount: list.length,
                itemBuilder: (_, i) => _UserCard(user: list[i],
                    onChanged: () => ref.invalidate(adminUsersProvider))),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onChanged;
  const _UserCard({required this.user, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final id = user['id']?.toString() ?? '';
    final name = user['name']?.toString() ?? user['full_name']?.toString() ?? 'Корбар';
    final email = user['email']?.toString() ?? '';
    final role = user['role']?.toString() ?? 'buyer';
    final banned = user['is_banned'] == true;
    final verified = user['is_verified'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5)),
      child: Row(children: [
        CircleAvatar(radius: 20, backgroundColor: AppColors.bgSurface,
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600))),
            if (verified) const Padding(padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.verified_rounded, color: AppColors.info, size: 14)),
          ]),
          Text(email, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 4),
          Row(children: [
            _chip(role, AppColors.primary),
            if (banned) ...[const SizedBox(width: 6), _chip('Манъшуда', AppColors.error)],
          ]),
        ])),
        PopupMenuButton<String>(
          color: AppColors.bgElevated,
          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
          onSelected: (v) async {
            final messenger = ScaffoldMessenger.of(context);
            try {
              if (v == 'ban') await AdminService.banUser(id);
              if (v == 'unban') await AdminService.unbanUser(id);
              if (v == 'verify') await AdminService.verifySeller(id);
              onChanged();
              messenger.showSnackBar(const SnackBar(content: Text('Иҷро шуд ✅'),
                  backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
            } catch (_) {
              messenger.showSnackBar(const SnackBar(content: Text('Хато'),
                  backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
            }
          },
          itemBuilder: (_) => [
            if (!verified) const PopupMenuItem(value: 'verify',
                child: Text('Тасдиқи фурӯшанда', style: TextStyle(color: AppColors.textPrimary))),
            if (!banned) const PopupMenuItem(value: 'ban',
                child: Text('Манъ кардан', style: TextStyle(color: AppColors.error)))
            else const PopupMenuItem(value: 'unban',
                child: Text('Кушодан', style: TextStyle(color: AppColors.success))),
          ],
        ),
      ]),
    );
  }

  Widget _chip(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
    child: Text(t, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w600)));
}

// ════════════════════════════════════════════════════════════════════════════
// ФАРМОИШҲО
// ════════════════════════════════════════════════════════════════════════════
const _orderStatuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];
const _statusLabels = {
  'pending': 'Дар интизор', 'processing': 'Коркард', 'shipped': 'Фиристода шуд',
  'delivered': 'Расид', 'cancelled': 'Бекор', 'payment_uploaded': 'Пардохт тасдиқ',
};

class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(adminOrdersProvider);
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(backgroundColor: AppColors.bgDark,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text('Ҳамаи фармоишҳо', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => ref.invalidate(adminOrdersProvider))]),
      body: orders.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorScreen(message: e.toString(), onRetry: () => ref.invalidate(adminOrdersProvider)),
        data: (list) => list.isEmpty
            ? const Center(child: Text('Фармоиш нест', style: TextStyle(color: AppColors.textSecondary)))
            : ListView.builder(padding: const EdgeInsets.all(16), itemCount: list.length,
                itemBuilder: (_, i) => _OrderCard(order: list[i],
                    onChanged: () => ref.invalidate(adminOrdersProvider))),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onChanged;
  const _OrderCard({required this.order, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final id = order['id']?.toString() ?? '';
    final status = order['status']?.toString() ?? 'pending';
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    DateTime? created;
    if (order['created_at'] != null) created = DateTime.tryParse(order['created_at'].toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('#${(id.length > 8 ? id.substring(0, 8) : id).toUpperCase()}',
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
          const Spacer(),
          Text('${total.toStringAsFixed(0)} сом.',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 15)),
        ]),
        const SizedBox(height: 4),
        if (created != null)
          Text(DateFormat('dd.MM.yyyy • HH:mm').format(created),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 10),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
            child: Text(_statusLabels[status] ?? status,
                style: const TextStyle(color: AppColors.info, fontSize: 12, fontWeight: FontWeight.w600))),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _changeStatus(context),
            icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
            label: const Text('Статус', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))),
        ]),
      ]),
    );
  }

  void _changeStatus(BuildContext context) {
    final id = order['id']?.toString() ?? '';
    showModalBottomSheet(context: context, backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          const Text('Статуси нав', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ..._orderStatuses.map((s) => ListTile(
            leading: const Icon(Icons.circle, size: 10, color: AppColors.primary),
            title: Text(_statusLabels[s] ?? s, style: const TextStyle(color: AppColors.textPrimary)),
            onTap: () async {
              Navigator.pop(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await AdminService.updateOrderStatus(id, s);
                onChanged();
                messenger.showSnackBar(const SnackBar(content: Text('Статус навсозӣ шуд ✅'),
                    backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
              } catch (_) {
                messenger.showSnackBar(const SnackBar(content: Text('Хато'),
                    backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
              }
            },
          )),
        ]),
      ));
  }
}

// ════════════════════════════════════════════════════════════════════════════
// КАТЕГОРИЯҲО
// ════════════════════════════════════════════════════════════════════════════
class AdminCategoriesScreen extends ConsumerWidget {
  const AdminCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider);
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(backgroundColor: AppColors.bgDark,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text('Категорияҳо', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700))),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => _addCategory(context, ref),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Илова', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
      body: cats.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorScreen(message: e.toString(), onRetry: () => ref.invalidate(categoriesProvider)),
        data: (list) => list.isEmpty
            ? const Center(child: Text('Категория нест', style: TextStyle(color: AppColors.textSecondary)))
            : ListView.builder(padding: const EdgeInsets.all(16), itemCount: list.length,
                itemBuilder: (_, i) => Container(
                  margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 0.5)),
                  child: Row(children: [
                    const Icon(Icons.category_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Text(list[i].name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                  ]))),
      ),
    );
  }

  void _addCategory(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.bgCard,
      title: const Text('Категорияи нав', style: TextStyle(color: AppColors.textPrimary)),
      content: TextField(controller: ctrl, autofocus: true,
        style: const TextStyle(color: AppColors.textPrimary),
        cursorColor: AppColors.primary,
        decoration: const InputDecoration(hintText: 'Номи категория',
            hintStyle: TextStyle(color: AppColors.textMuted))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
            child: const Text('Бекор', style: TextStyle(color: AppColors.textMuted))),
        TextButton(
          onPressed: () async {
            final name = ctrl.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(ctx);
            final messenger = ScaffoldMessenger.of(context);
            final slug = name.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
            try {
              await AdminService.createCategory(name, slug);
              ref.invalidate(categoriesProvider);
              messenger.showSnackBar(const SnackBar(content: Text('Категория илова шуд ✅'),
                  backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
            } catch (_) {
              messenger.showSnackBar(const SnackBar(content: Text('Хато'),
                  backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
            }
          },
          child: const Text('Илова', style: TextStyle(color: AppColors.primary))),
      ],
    ));
  }
}
