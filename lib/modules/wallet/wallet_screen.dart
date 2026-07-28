import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/app_l10n.dart';
import '../../core/l10n/orders_l10n.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/wallet_provider.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/error_screen.dart';
import '../../shared/widgets/safe_input.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    return Scaffold(
      backgroundColor: context.pal.scaffold,
      appBar: AppBar(
        backgroundColor: context.pal.scaffold,
        elevation: 0,
        iconTheme: IconThemeData(color: context.pal.textPrimary),
        title: Text(AppL10n.of(context).myWallet,
            style: TextStyle(
                color: context.pal.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
              icon: Icon(FeatherIcons.refreshCw, color: context.pal.textSecondary),
              onPressed: () => ref.invalidate(walletProvider))
        ],
      ),
      body: wallet.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorScreen(
            message: e.toString(), onRetry: () => ref.invalidate(walletProvider)),
        data: (data) {
          final balance = (data['balance'] as num?)?.toDouble() ?? 0;
          final txs = (data['transactions'] as List?) ?? [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _balanceCard(context, balance),
              const SizedBox(height: 20),
              AppButton(
                  text: AppL10n.of(context).topUpAction,
                  icon: FeatherIcons.plus,
                  onTap: () => _topUp(context, ref)),
              const SizedBox(height: 28),
              Text(AppL10n.of(context).transactionHistory,
                  style: TextStyle(
                      color: context.pal.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              if (txs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(FeatherIcons.fileText,
                            color: context.pal.textMuted, size: 44),
                        const SizedBox(height: 10),
                        Text(AppL10n.of(context).noTransactions,
                            style: TextStyle(color: context.pal.textMuted)),
                      ],
                    ),
                  ),
                )
              else
                ...txs.whereType<Map>().map(
                    (t) => _txTile(context, Map<String, dynamic>.from(t))),
            ],
          );
        },
      ),
    );
  }

  // ── Корти тавозун (намуди корти пардохт бо градиенти сабз) ──────────────────
  Widget _balanceCard(BuildContext context, double balance) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 28,
              offset: const Offset(0, 12))
        ],
      ),
      child: Stack(
        children: [
          // Ороиши доиравӣ дар кунҷ
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10)),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(FeatherIcons.creditCard,
                          color: Colors.white70, size: 20),
                      const SizedBox(width: 8),
                      Text(AppL10n.of(context).balance,
                          style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                  // «Чипи» корт
                  Container(
                    width: 40,
                    height: 30,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(7)),
                    child: const Icon(FeatherIcons.creditCard,
                        color: Colors.white, size: 20),
                  ),
                ],
              ),
              const Spacer(),
              Text('${balance.toStringAsFixed(0)} ${AppL10n.of(context).som}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(AppL10n.of(context).walletCardTag,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      letterSpacing: 1.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _txTile(BuildContext context, Map<String, dynamic> t) {
    final amount = (t['amount'] as num?)?.toDouble() ?? 0;
    final type = t['type']?.toString() ?? '';
    final status = t['status']?.toString() ?? '';
    final positive = amount >= 0;
    DateTime? date;
    if (t['created_at'] != null) date = DateTime.tryParse(t['created_at'].toString());
    final l = AppL10n.of(context);
    final labels = {'topup': l.txTopup, 'purchase': l.txPurchase, 'refund': l.txRefund};
    final statusLabels = {
      'pending': l.txPending,
      'completed': l.txCompleted,
      'rejected': l.txRejected
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: context.pal.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.pal.border, width: 0.5)),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: (positive ? AppColors.success : AppColors.error)
                    .withValues(alpha: 0.15),
                shape: BoxShape.circle),
            child: Icon(
                positive
                    ? FeatherIcons.arrowDown
                    : FeatherIcons.arrowUp,
                color: positive ? AppColors.success : AppColors.error,
                size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(labels[type] ?? type,
                    style: TextStyle(
                        color: context.pal.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                if (date != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(DateFormat('dd.MM.yyyy • HH:mm').format(date),
                        style: TextStyle(
                            color: context.pal.textMuted, fontSize: 11)),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${positive ? '+' : ''}${amount.toStringAsFixed(0)} ${l.som}',
                  style: TextStyle(
                      color: positive ? AppColors.success : AppColors.error,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(statusLabels[status] ?? status,
                  style: TextStyle(color: context.pal.textMuted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  void _topUp(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.pal.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l.topUpTitle,
            style: TextStyle(color: context.pal.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                l.topUpHintText,
                style:
                    TextStyle(color: context.pal.textSecondary, fontSize: 12)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                  color: context.pal.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.pal.border)),
              child: SafeInput(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                hint: l.amountSomHint,
                textColor: context.pal.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  Text(l.cancel, style: TextStyle(color: context.pal.textMuted))),
          TextButton(
            onPressed: () async {
              final amount = double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0;
              if (amount <= 0) return;
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await WalletService.topUp(amount);
                ref.invalidate(walletProvider);
                messenger.showSnackBar(SnackBar(
                    content:
                        Text(l.topUpRequestSent),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating));
              } catch (_) {
                messenger.showSnackBar(SnackBar(
                    content: Text(l.error),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating));
              }
            },
            child: Text(l.send,
                style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
