import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/app_l10n.dart';
import '../../core/l10n/misc_l10n.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../routes/route_names.dart';
import '../../shared/widgets/safe_input.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  const ChatScreen({super.key, required this.userId, this.userName = 'Фурӯшанда'});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _ctrl.clear();
    HapticFeedback.lightImpact();
    try {
      await ChatService.send(widget.userId, text);
      ref.invalidate(conversationProvider(widget.userId));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppL10n.of(context).messageNotSent),
          backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
        _ctrl.text = text;
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = ref.watch(authProvider).user?.id ?? '';
    final convo = ref.watch(conversationProvider(widget.userId));

    return Scaffold(
      backgroundColor: context.pal.scaffold,
      appBar: AppBar(
        backgroundColor: context.pal.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: context.pal.textPrimary),
        leading: IconButton(
          icon: const Icon(FeatherIcons.chevronLeft, size: 20),
          onPressed: () => Navigator.canPop(context) ? Navigator.pop(context) : context.go(RouteNames.home)),
        titleSpacing: 0,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient, shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: context.pal.card,
              child: Text(widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(widget.userName, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.pal.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
            Row(children: [
              Container(width: 7, height: 7,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(AppL10n.of(context).seller, style: TextStyle(color: context.pal.textMuted, fontSize: 11)),
            ]),
          ])),
        ]),
        actions: [IconButton(
          icon: Icon(FeatherIcons.refreshCw, color: context.pal.textSecondary),
          onPressed: () => ref.invalidate(conversationProvider(widget.userId)))],
      ),
      body: Column(children: [
        Expanded(child: convo.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => _emptyChat(AppL10n.of(context).messagesLoadFailed),
          data: (msgs) {
            if (msgs.isEmpty) return _emptyChat(AppL10n.of(context).noMessagesYet);
            _jumpToBottom();
            return ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              itemCount: msgs.length,
              itemBuilder: (_, i) {
                final m = msgs[i];
                final mine = m.senderId == myId;
                return _bubble(m.content, mine, m.createdAt);
              },
            );
          },
        )),
        _inputBar(),
      ]),
    );
  }

  Widget _emptyChat(String text) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 96, height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [
            AppColors.primary.withOpacity(0.16),
            const Color(0xFF00A3FF).withOpacity(0.16),
          ]),
        ),
        child: const Icon(FeatherIcons.messageCircle, size: 44, color: AppColors.primary),
      ),
      const SizedBox(height: 16),
      Text(text, textAlign: TextAlign.center,
          style: TextStyle(color: context.pal.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
    ]),
  );

  Widget _bubble(String text, bool mine, DateTime time) => Align(
    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 7),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
      decoration: BoxDecoration(
        gradient: mine ? AppColors.primaryGradient : null,
        color: mine ? null : context.pal.surface,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(mine ? 18 : 4),
          bottomRight: Radius.circular(mine ? 4 : 18)),
        boxShadow: [BoxShadow(
          color: mine ? AppColors.primary.withOpacity(0.25) : Colors.black.withOpacity(0.10),
          blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
        Text(text, style: TextStyle(
            color: mine ? Colors.white : context.pal.textPrimary, fontSize: 14.5, height: 1.3)),
        const SizedBox(height: 2),
        Text(DateFormat('HH:mm').format(time),
            style: TextStyle(color: mine ? Colors.white70 : context.pal.textMuted, fontSize: 10)),
      ]),
    ),
  );

  Widget _inputBar() => Container(
    padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
    decoration: BoxDecoration(
        color: context.pal.card,
        border: Border(top: BorderSide(color: context.pal.border, width: 0.5))),
    child: Row(children: [
      Expanded(child: Container(
        decoration: BoxDecoration(
            color: context.pal.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.pal.border, width: 0.6)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: SafeInput(
          controller: _ctrl,
          minLines: 1, maxLines: 4,
          textColor: context.pal.textPrimary,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _send(),
          hint: AppL10n.of(context).writeMessageHint,
        ),
      )),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: _sending ? null : _send,
        child: Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 12, offset: const Offset(0, 4))]),
          child: _sending
              ? const Padding(padding: EdgeInsets.all(13),
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(FeatherIcons.send, color: Colors.white, size: 21),
        ),
      ),
    ]),
  );
}
