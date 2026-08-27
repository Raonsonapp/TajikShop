import 'package:cached_network_image/cached_network_image.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/app_l10n.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/verification_l10n.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/verification_provider.dart';
import '../../shared/widgets/fade_slide_in.dart';

/// Баррасии дархостҳои галочка (админ).
///
/// Ин ҷои он «хондани худкори SMS» аст: админ чекро мебинад ва як пахш
/// тасдиқ мекунад — корбар фавран галочка ва огоҳӣ мегирад.
class AdminVerificationScreen extends ConsumerStatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  ConsumerState<AdminVerificationScreen> createState() =>
      _AdminVerificationScreenState();
}

class _AdminVerificationScreenState
    extends ConsumerState<AdminVerificationScreen> {
  String _status = 'pending';
  String? _busy;

  Future<void> _decide(String id, bool approve, {String note = ''}) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = id);
    try {
      await ApiClient.instance.dio.post(
          '/admin/verification-requests/$id/decide',
          data: {'approve': approve, 'note': note});
      ref.invalidate(verificationRequestsProvider(_status));
      messenger.showSnackBar(SnackBar(
          content: Text(approve ? '✅' : '✖'),
          backgroundColor: approve ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Error'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _askReject(String id) async {
    final l = AppL10n.of(context);
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.pal.card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(l.verifyRejectReason,
            style: TextStyle(color: ctx.pal.textPrimary, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: ctx.pal.textPrimary),
          decoration: InputDecoration(
            hintText: '…',
            hintStyle: TextStyle(color: ctx.pal.textMuted),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel,
                  style: TextStyle(color: ctx.pal.textMuted))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.verifyReject,
                  style: const TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok == true) await _decide(id, false, note: ctrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final l = AppL10n.of(context);
    final async = ref.watch(verificationRequestsProvider(_status));

    return Scaffold(
      backgroundColor: pal.scaffold,
      appBar: AppBar(
        backgroundColor: pal.scaffold,
        elevation: 0,
        iconTheme: IconThemeData(color: pal.textPrimary),
        title: Text(l.verifyAdminTitle,
            style: TextStyle(
                color: pal.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17)),
      ),
      body: Column(children: [
        // Филтри ҳолат
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Row(children: [
            for (final s in const ['pending', 'approved', 'rejected'])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: PressableScale(
                  onTap: () => setState(() => _status = s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _status == s
                          ? AppColors.primary
                          : pal.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _status == s
                              ? AppColors.primary
                              : pal.border),
                    ),
                    child: Text(_statusLabel(s),
                        style: TextStyle(
                            color: _status == s
                                ? Colors.white
                                : pal.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
          ]),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
            error: (_, __) => Center(
                child: Text(l.verifyAdminEmpty,
                    style: TextStyle(color: pal.textMuted, fontSize: 13))),
            data: (list) {
              if (list.isEmpty) {
                return Center(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FeatherIcons.inbox,
                            color: pal.textMuted, size: 44),
                        const SizedBox(height: 12),
                        Text(l.verifyAdminEmpty,
                            style: TextStyle(
                                color: pal.textMuted, fontSize: 13.5)),
                      ]),
                );
              }
              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async =>
                    ref.invalidate(verificationRequestsProvider(_status)),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: list.length,
                  itemBuilder: (_, i) => FadeSlideIn(
                    delay: Duration(milliseconds: 40 * i),
                    child: _card(pal, l, list[i]),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  String _statusLabel(String s) => switch (s) {
        'approved' => '✅',
        'rejected' => '✖',
        _ => '⏳',
      };

  Widget _card(AppPalette pal, AppL10n l, Map<String, dynamic> r) {
    final id = (r['id'] ?? '').toString();
    final name = (r['name'] ?? '').toString();
    final username = (r['username'] ?? '').toString();
    final phone = (r['phone'] ?? '').toString();
    final amount = (r['amount'] as num?)?.toDouble() ?? 0;
    final receipt = (r['receipt_url'] ?? '').toString();
    final busy = _busy == id;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: pal.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(FeatherIcons.user,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.isEmpty ? '—' : name,
                        style: TextStyle(
                            color: pal.textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                        [
                          if (username.isNotEmpty) '@$username',
                          if (phone.isNotEmpty) phone,
                        ].join(' · '),
                        style:
                            TextStyle(color: pal.textMuted, fontSize: 11.5)),
                  ]),
            ),
            Text('${amount.toStringAsFixed(0)} сом.',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
          ]),
        ),
        if (receipt.isNotEmpty)
          GestureDetector(
            onTap: () => _openReceipt(receipt),
            child: CachedNetworkImage(
              imageUrl: receipt,
              height: 190,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                  height: 190,
                  color: pal.surface,
                  alignment: Alignment.center,
                  child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2))),
              errorWidget: (_, __, ___) => Container(
                  height: 190,
                  color: pal.surface,
                  alignment: Alignment.center,
                  child: Icon(FeatherIcons.image,
                      color: pal.textMuted, size: 28)),
            ),
          ),
        if (_status == 'pending')
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(
                child: PressableScale(
                  onTap: busy ? null : () => _askReject(id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.35)),
                    ),
                    child: Center(
                      child: Text(l.verifyReject,
                          style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: PressableScale(
                  onTap: busy ? null : () => _decide(id, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Center(
                      child: busy
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.2))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(FeatherIcons.checkCircle,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                Text(l.verifyApprove,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700)),
                              ]),
                    ),
                  ),
                ),
              ),
            ]),
          ),
      ]),
    );
  }

  void _openReceipt(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: InteractiveViewer(
          maxScale: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
