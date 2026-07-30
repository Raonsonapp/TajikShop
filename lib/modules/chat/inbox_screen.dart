import 'package:cached_network_image/cached_network_image.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/chat_provider.dart';

const String _kMediaHost = 'https://mahmadmurodov-tajikshop.hf.space';
String _mediaUrl(String p) => p.startsWith('http') ? p : '$_kMediaHost$p';

/// Рӯйхати сӯҳбатҳо (Inbox) — ҳамаи мукотибаҳои корбар бо паёми охирин ва
/// нишони хонданашуда. Зеркунӣ сӯҳбатро мекушояд.
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pal = context.pal;
    final async = ref.watch(inboxProvider);

    return Scaffold(
      backgroundColor: pal.scaffold,
      appBar: AppBar(
        backgroundColor: pal.scaffold,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(FeatherIcons.chevronLeft, color: pal.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Паёмҳо',
            style: TextStyle(
                color: pal.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17)),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(inboxProvider),
        child: async.when(
          loading: () => const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2.6)),
          error: (_, __) => _empty(pal),
          data: (convos) {
            if (convos.isEmpty) return _empty(pal);
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: convos.length,
              separatorBuilder: (_, __) => Divider(
                  height: 1, color: pal.border, indent: 82, endIndent: 16),
              itemBuilder: (_, i) => _tile(context, pal, convos[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _empty(AppPalette pal) => ListView(
        children: [
          const SizedBox(height: 120),
          Icon(FeatherIcons.messageCircle, size: 56, color: pal.textMuted),
          const SizedBox(height: 16),
          Center(
            child: Text('Ҳанӯз паёме нест',
                style: TextStyle(color: pal.textSecondary, fontSize: 15)),
          ),
        ],
      );

  Widget _tile(BuildContext context, AppPalette pal, Map<String, dynamic> c) {
    final id = c['partner_id']?.toString() ?? '';
    final name = c['name']?.toString() ?? 'Корбар';
    final avatar = c['avatar_url']?.toString() ?? '';
    final last = c['last_message']?.toString() ?? '';
    final unread = (c['unread'] as num?)?.toInt() ?? 0;
    DateTime? time;
    if (c['created_at'] != null) {
      time = DateTime.tryParse(c['created_at'].toString())?.toLocal();
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () => context.push('/chat/$id?name=${Uri.encodeComponent(name)}'),
      leading: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient, shape: BoxShape.circle),
        child: CircleAvatar(
          radius: 24,
          backgroundColor: pal.card,
          backgroundImage:
              avatar.isNotEmpty ? CachedNetworkImageProvider(_mediaUrl(avatar)) : null,
          child: avatar.isEmpty
              ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w800))
              : null,
        ),
      ),
      title: Text(name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: pal.textPrimary,
              fontSize: 15,
              fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w600)),
      subtitle: Text(last,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: unread > 0 ? pal.textPrimary : pal.textMuted,
              fontSize: 13,
              fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (time != null)
            Text(DateFormat('HH:mm').format(time),
                style: TextStyle(color: pal.textMuted, fontSize: 11)),
          const SizedBox(height: 6),
          if (unread > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$unread',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }
}
