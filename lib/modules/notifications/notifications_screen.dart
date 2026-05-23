import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../data/models/notification_model.dart';
import '../../shared/widgets/error_screen.dart';

final notificationsProvider = FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  final res = await ApiClient.instance.dio.get(ApiEndpoints.notifications);
  final data = res.data;
  List items = data is List ? data : (data['notifications'] ?? []);
  return items.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifs = ref.watch(notificationsProvider);
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(backgroundColor: AppColors.bgDark,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text('Огоҳиномаҳо', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          TextButton(onPressed: () async {
            try { await ApiClient.instance.dio.post(ApiEndpoints.readNotifications); ref.invalidate(notificationsProvider); } catch (_) {}
          }, child: const Text('Ҳама хонда', style: TextStyle(color: AppColors.primary, fontSize: 13))),
        ]),
      body: notifs.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorScreen(message: e.toString(), onRetry: () => ref.invalidate(notificationsProvider)),
        data: (list) => list.isEmpty
            ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.notifications_none_rounded, size: 80, color: AppColors.textMuted),
                SizedBox(height: 16),
                Text('Огоҳиноме нест', style: TextStyle(color: AppColors.textSecondary, fontSize: 16))]))
            : ListView.separated(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1),
                itemBuilder: (_, i) => _NTile(n: list[i])),
      ),
    );
  }
}

class _NTile extends StatelessWidget {
  final NotificationModel n;
  const _NTile({required this.n});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 42, height: 42,
        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: Icon(n.type == 'order' ? Icons.receipt_long_outlined :
            n.type == 'payment' ? Icons.payment_outlined : Icons.notifications_outlined,
            color: AppColors.primary, size: 20)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(n.title, style: TextStyle(color: AppColors.textPrimary, fontSize: 14,
              fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w600))),
          if (!n.isRead) Container(width: 8, height: 8,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
        ]),
        const SizedBox(height: 4),
        Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(DateFormat('dd.MM.yyyy HH:mm').format(n.createdAt),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ])),
    ]));
}
