import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
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
      backgroundColor: context.pal.scaffold,
      appBar: AppBar(
        backgroundColor: context.pal.scaffold,
        elevation: 0,
        iconTheme: IconThemeData(color: context.pal.textPrimary),
        title: Text(
          'Огоҳиномаҳо',
          style: TextStyle(
            color: context.pal.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () async {
                try {
                  await ApiClient.instance.dio.post(ApiEndpoints.readNotifications);
                  ref.invalidate(notificationsProvider);
                } catch (_) {}
              },
              icon: const Icon(Icons.done_all_rounded, size: 18, color: AppColors.primary),
              label: const Text(
                'Ҳама хонда',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: notifs.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorScreen(message: e.toString(), onRetry: () => ref.invalidate(notificationsProvider)),
        data: (list) => list.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_none_rounded,
                          size: 48, color: AppColors.primary),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Огоҳиноме нест',
                      style: TextStyle(
                        color: context.pal.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: list.length,
                itemBuilder: (_, i) => _NTile(n: list[i]),
              ),
      ),
    );
  }
}

class _NTile extends StatelessWidget {
  final NotificationModel n;
  const _NTile({required this.n});

  IconData get _icon => n.type == 'order'
      ? Icons.receipt_long_outlined
      : n.type == 'payment'
          ? Icons.payment_outlined
          : Icons.notifications_outlined;

  @override
  Widget build(BuildContext context) {
    final unread = !n.isRead;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.pal.card,
        borderRadius: BorderRadius.circular(16),
        border: unread
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1)
            : Border.all(color: context.pal.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: unread ? AppColors.primaryGradient : null,
              color: unread ? null : AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _icon,
              color: unread ? Colors.white : AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        n.title,
                        style: TextStyle(
                          color: context.pal.textPrimary,
                          fontSize: 14.5,
                          fontWeight: unread ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (unread)
                      Container(
                        width: 9,
                        height: 9,
                        margin: const EdgeInsets.only(left: 8, top: 4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  n.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.pal.textSecondary,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 12, color: context.pal.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd.MM.yyyy HH:mm').format(n.createdAt),
                      style: TextStyle(color: context.pal.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
