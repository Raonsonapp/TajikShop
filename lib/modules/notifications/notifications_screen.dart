import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../data/models/notification_model.dart';
import '../../shared/widgets/shimmer_card.dart';

final notificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
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
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Огоҳиномаҳо',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await ApiClient.instance.dio.post(ApiEndpoints.readNotifications);
                ref.invalidate(notificationsProvider);
              } catch (_) {}
            },
            child: const Text('Ҳама хонда', style: TextStyle(color: AppColors.primary, fontSize: 13)),
          ),
        ],
      ),
      body: notifs.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 8,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              ShimmerCard(width: 44, height: 44, radius: 22),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ShimmerCard(height: 14, radius: 4),
                const SizedBox(height: 6),
                ShimmerCard(height: 12, width: 200, radius: 4),
              ])),
            ]),
          ),
        ),
        error: (_, __) => const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.notifications_off_outlined, size: 80, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text('Огоҳиноме нест', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          ]),
        ),
        data: (list) => list.isEmpty
            ? const Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.notifications_none_rounded, size: 80, color: AppColors.textMuted),
                  SizedBox(height: 16),
                  Text('Огоҳиноме нест', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Огоҳиномаҳои нав дар ин ҷо пайдо мешаванд',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13), textAlign: TextAlign.center),
                ]),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1),
                itemBuilder: (_, i) => _NotifTile(notif: list[i]),
              ),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NotificationModel notif;
  const _NotifTile({required this.notif});

  IconData _icon() {
    switch (notif.type) {
      case 'order': return Icons.receipt_long_outlined;
      case 'payment': return Icons.payment_outlined;
      case 'promo': return Icons.local_offer_outlined;
      case 'message': return Icons.message_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  Color _color() {
    switch (notif.type) {
      case 'order': return AppColors.primary;
      case 'payment': return AppColors.warning;
      case 'promo': return AppColors.error;
      case 'message': return AppColors.info;
      default: return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      color: notif.isRead ? Colors.transparent : AppColors.primary.withOpacity(0.04),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(_icon(), color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(notif.title,
                    style: TextStyle(
                      color: AppColors.textPrimary, fontSize: 14,
                      fontWeight: notif.isRead ? FontWeight.w400 : FontWeight.w600)),
              ),
              if (!notif.isRead)
                Container(width: 8, height: 8,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
            ]),
            const SizedBox(height: 4),
            Text(notif.body,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            Text(DateFormat('dd.MM.yyyy HH:mm').format(notif.createdAt),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }
}
