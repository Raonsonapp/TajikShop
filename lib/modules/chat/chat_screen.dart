import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Паём фиристода нашуд'),
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
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.canPop(context) ? Navigator.pop(context) : context.go(RouteNames.home)),
        titleSpacing: 0,
        title: Row(children: [
          CircleAvatar(radius: 16, backgroundColor: AppColors.bgSurface,
            child: Text(widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(widget.userName, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
            const Text('Фурӯшанда', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ])),
        ]),
        actions: [IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
          onPressed: () => ref.invalidate(conversationProvider(widget.userId)))],
      ),
      body: Column(children: [
        Expanded(child: convo.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => _emptyChat('Паёмҳо бор нашуд'),
          data: (msgs) {
            if (msgs.isEmpty) return _emptyChat('Ҳоло паёме нест.\nАввалин шуда паём нависед!');
            _jumpToBottom();
            return ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
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
      const Icon(Icons.forum_outlined, size: 64, color: AppColors.textMuted),
      const SizedBox(height: 12),
      Text(text, textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
    ]),
  );

  Widget _bubble(String text, bool mine, DateTime time) => Align(
    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 7),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
      decoration: BoxDecoration(
        color: mine ? AppColors.primary : AppColors.bgCard,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(mine ? 16 : 4),
          bottomRight: Radius.circular(mine ? 4 : 16)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
        Text(text, style: TextStyle(
            color: mine ? Colors.white : AppColors.textPrimary, fontSize: 14.5, height: 1.3)),
        const SizedBox(height: 2),
        Text(DateFormat('HH:mm').format(time),
            style: TextStyle(color: mine ? Colors.white70 : AppColors.textMuted, fontSize: 10)),
      ]),
    ),
  );

  Widget _inputBar() => Container(
    padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
    decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5))),
    child: Row(children: [
      Expanded(child: Container(
        decoration: BoxDecoration(
            color: AppColors.bgSurface, borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SafeInput(
          controller: _ctrl,
          minLines: 1, maxLines: 4,
          textColor: AppColors.textPrimary,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _send(),
          hint: 'Паём нависед...',
        ),
      )),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: _sending ? null : _send,
        child: Container(
          width: 44, height: 44,
          decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient, shape: BoxShape.circle),
          child: _sending
              ? const Padding(padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
        ),
      ),
    ]),
  );
}
