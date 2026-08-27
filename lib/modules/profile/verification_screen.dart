import 'dart:io';

import 'package:dio/dio.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_client.dart';
import '../../core/app_l10n.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/verification_l10n.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/auth_provider.dart';
import '../../providers/verification_provider.dart';
import '../../shared/widgets/fade_slide_in.dart';

/// Харидани галочкаи тасдиқ.
///
/// Ҷараён: корбар маблағро ба корти TajikShop мегузаронад → расми чекро
/// замима мекунад → админ як пахш тасдиқ мекунад → `is_verified=true`.
///
/// Нарх ва рақами корт аз сервер меоянд (`settings`), пас барои иваз кардани
/// нарх релизи нави барнома лозим нест.
class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  XFile? _receipt;
  bool _sending = false;

  Future<void> _pickReceipt() async {
    final xf = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (xf == null) return;
    setState(() => _receipt = xf);
  }

  Future<void> _send() async {
    final l = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (_receipt == null) {
      messenger.showSnackBar(SnackBar(
          content: Text(l.verifyNeedReceipt),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _sending = true);
    try {
      final form = FormData.fromMap(
          {'receipt': await MultipartFile.fromFile(_receipt!.path)});
      await ApiClient.instance.dio.post('/users/me/verification', data: form);
      if (!mounted) return;
      setState(() => _receipt = null);
      ref.invalidate(myVerificationProvider);
      messenger.showSnackBar(SnackBar(
          content: Text(l.verifySent),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating));
    } on DioException catch (e) {
      final d = e.response?.data;
      final msg = (d is Map ? d['error'] : null)?.toString();
      messenger.showSnackBar(SnackBar(
          content: Text(msg ?? l.verifyFailed),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating));
    } catch (_) {
      messenger.showSnackBar(SnackBar(
          content: Text(l.verifyFailed),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _copyCard(String card) async {
    final l = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: card.replaceAll(' ', '')));
    messenger.showSnackBar(SnackBar(
        content: Text(l.verifyCardCopied),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final l = AppL10n.of(context);
    final async = ref.watch(myVerificationProvider);

    return Scaffold(
      backgroundColor: pal.scaffold,
      appBar: AppBar(
        backgroundColor: pal.scaffold,
        elevation: 0,
        iconTheme: IconThemeData(color: pal.textPrimary),
        title: Text(l.verifyTitle,
            style: TextStyle(
                color: pal.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17)),
      ),
      body: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => Center(
            child: Text(l.verifyFailed,
                style: TextStyle(color: pal.textMuted, fontSize: 13))),
        data: (data) {
          final verified = data['is_verified'] == true ||
              ref.watch(authProvider).user?.isVerified == true;
          final req = data['request'] is Map
              ? Map<String, dynamic>.from(data['request'] as Map)
              : null;
          final status = (req?['status'] ?? '').toString();
          final price = (data['price'] as num?)?.toDouble() ?? 0;
          final card = (data['card'] ?? '').toString();
          final holder = (data['card_holder'] ?? '').toString();

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(myVerificationProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                FadeSlideIn(child: _hero(pal, l, verified)),
                const SizedBox(height: 20),

                if (verified) ...[
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 60),
                    child: _banner(
                      pal,
                      icon: FeatherIcons.checkCircle,
                      color: AppColors.success,
                      title: l.verifyApproved,
                      body: l.verifyApprovedHint,
                    ),
                  ),
                ] else if (status == 'pending') ...[
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 60),
                    child: _banner(
                      pal,
                      icon: FeatherIcons.clock,
                      color: AppColors.warning,
                      title: l.verifyPending,
                      body: l.verifyPendingHint,
                    ),
                  ),
                ] else ...[
                  if (status == 'rejected')
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 60),
                      child: _banner(
                        pal,
                        icon: FeatherIcons.alertCircle,
                        color: AppColors.error,
                        title: l.verifyRejected,
                        body: (req?['note'] ?? '').toString(),
                      ),
                    ),
                  const SizedBox(height: 6),
                  FadeSlideIn(
                      delay: const Duration(milliseconds: 90),
                      child: _benefits(pal, l)),
                  const SizedBox(height: 16),
                  FadeSlideIn(
                      delay: const Duration(milliseconds: 120),
                      child: _payCard(pal, l, price, card, holder)),
                  const SizedBox(height: 16),
                  FadeSlideIn(
                      delay: const Duration(milliseconds: 150),
                      child: _receiptBlock(pal, l)),
                  const SizedBox(height: 18),
                  _sendButton(l, status == 'rejected'),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Сарлавҳа бо галочкаи калон ────────────────────────────────────────────
  Widget _hero(AppPalette pal, AppL10n l, bool verified) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.16),
              AppColors.primary.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Column(children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient, shape: BoxShape.circle),
            child: Icon(
                verified ? FeatherIcons.check : FeatherIcons.award,
                color: Colors.white,
                size: 30),
          ),
          const SizedBox(height: 14),
          Text(l.verifyTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: pal.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(l.verifySubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: pal.textSecondary, fontSize: 13, height: 1.4)),
        ]),
      );

  Widget _banner(AppPalette pal,
          {required IconData icon,
          required Color color,
          required String title,
          required String body}) =>
      Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 11),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(
                      color: pal.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800)),
              if (body.trim().isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(body,
                    style: TextStyle(
                        color: pal.textSecondary, fontSize: 12.5, height: 1.35)),
              ],
            ]),
          ),
        ]),
      );

  Widget _benefits(AppPalette pal, AppL10n l) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: pal.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: pal.border),
        ),
        child: Column(children: [
          _benefitRow(pal, FeatherIcons.checkCircle, l.verifyBenefit1),
          const SizedBox(height: 11),
          _benefitRow(pal, FeatherIcons.trendingUp, l.verifyBenefit2),
          const SizedBox(height: 11),
          _benefitRow(pal, FeatherIcons.shield, l.verifyBenefit3),
        ]),
      );

  Widget _benefitRow(AppPalette pal, IconData icon, String text) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: AppColors.primary, size: 16),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(text,
                style: TextStyle(
                    color: pal.textSecondary, fontSize: 13, height: 1.3)),
          ),
        ),
      ]);

  // ── Нарх + корт ───────────────────────────────────────────────────────────
  Widget _payCard(AppPalette pal, AppL10n l, double price, String card,
      String holder) {
    final pretty = _formatCard(card);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: pal.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(l.verifyPriceLabel,
              style: TextStyle(
                  color: pal.textMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('${price.toStringAsFixed(0)} сом.',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 16),
        Text(l.verifyCardLabel,
            style: TextStyle(
                color: pal.textMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        PressableScale(
          onTap: card.isEmpty ? null : () => _copyCard(card),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(FeatherIcons.creditCard,
                  color: AppColors.primary, size: 19),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pretty.isEmpty ? '—' : pretty,
                          style: TextStyle(
                              color: pal.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1)),
                      if (holder.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(holder,
                            style: TextStyle(
                                color: pal.textMuted, fontSize: 11.5)),
                      ],
                    ]),
              ),
              const Icon(FeatherIcons.copy, color: AppColors.primary, size: 17),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        _step(pal, '1', l.verifyStep1),
        _step(pal, '2', l.verifyStep2),
        _step(pal, '3', l.verifyStep3),
      ]),
    );
  }

  // ── Чек ───────────────────────────────────────────────────────────────────
  Widget _receiptBlock(AppPalette pal, AppL10n l) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: pal.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: pal.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.verifyAttachReceipt,
              style: TextStyle(
                  color: pal.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          PressableScale(
            onTap: _pickReceipt,
            child: _receipt == null
                ? DottedBox(pal: pal)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(children: [
                      Image.file(File(_receipt!.path),
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 11, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(FeatherIcons.refreshCw,
                                color: Colors.white, size: 12),
                            const SizedBox(width: 6),
                            Text(l.verifyChangePhoto,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ),
                    ]),
                  ),
          ),
        ]),
      );

  Widget _sendButton(AppL10n l, bool retry) => PressableScale(
        onTap: _sending ? null : _send,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.32),
                  blurRadius: 18,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Center(
            child: _sending
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.2))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(FeatherIcons.send, color: Colors.white, size: 17),
                    const SizedBox(width: 9),
                    Text(retry ? l.verifyRetry : l.verifySend,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                  ]),
          ),
        ),
      );

  Widget _step(AppPalette pal, String n, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 19,
            height: 19,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.16),
                shape: BoxShape.circle),
            child: Text(n,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(text,
                style: TextStyle(color: pal.textSecondary, fontSize: 12.5)),
          ),
        ]),
      );
}

/// Ҷои холии чек — то корбар фаҳмад, ки ин ҷо расм гузошта мешавад.
class DottedBox extends StatelessWidget {
  final AppPalette pal;
  const DottedBox({super.key, required this.pal});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: pal.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(FeatherIcons.camera,
              color: AppColors.primary, size: 21),
        ),
        const SizedBox(height: 10),
        Text(l.verifyAttachReceipt,
            style: TextStyle(
                color: pal.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

/// `9762000199757344` → `9762 0001 9975 7344`
String _formatCard(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i != 0 && i % 4 == 0) buf.write(' ');
    buf.write(digits[i]);
  }
  return buf.toString();
}
