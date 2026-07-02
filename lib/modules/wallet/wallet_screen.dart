import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
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
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text('Ҳамёни ман', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => ref.invalidate(walletProvider))],
      ),
      body: wallet.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorScreen(message: e.toString(), onRetry: () => ref.invalidate(walletProvider)),
        data: (data) {
          final balance = (data['balance'] as num?)?.toDouble() ?? 0;
          final txs = (data['transactions'] as List?) ?? [];
          return ListView(padding: const EdgeInsets.all(16), children: [
            // Balance card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 20),
                  SizedBox(width: 8),
                  Text('Тавозун', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ]),
                const SizedBox(height: 10),
                Text('${balance.toStringAsFixed(0)} сом.',
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
              ]),
            ),
            const SizedBox(height: 16),
            AppButton(text: '➕ Пополнение кардан', onTap: () => _topUp(context, ref)),
            const SizedBox(height: 24),
            const Text('Таърихи амалиётҳо',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (txs.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('Ҳоло амалиёте нест', style: TextStyle(color: AppColors.textMuted))))
            else
              ...txs.whereType<Map>().map((t) => _txTile(Map<String, dynamic>.from(t))),
          ]);
        },
      ),
    );
  }

  Widget _txTile(Map<String, dynamic> t) {
    final amount = (t['amount'] as num?)?.toDouble() ?? 0;
    final type = t['type']?.toString() ?? '';
    final status = t['status']?.toString() ?? '';
    final positive = amount >= 0;
    DateTime? date;
    if (t['created_at'] != null) date = DateTime.tryParse(t['created_at'].toString());
    final labels = {'topup': 'Пополнение', 'purchase': 'Харид', 'refund': 'Бозгашт'};
    final statusLabels = {'pending': 'Интизор', 'completed': 'Иҷрошуда', 'rejected': 'Радшуда'};
    return Container(
      margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5)),
      child: Row(children: [
        Container(width: 38, height: 38,
          decoration: BoxDecoration(
            color: (positive ? AppColors.success : AppColors.error).withValues(alpha: 0.15),
            shape: BoxShape.circle),
          child: Icon(positive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: positive ? AppColors.success : AppColors.error, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(labels[type] ?? type,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          if (date != null)
            Text(DateFormat('dd.MM.yyyy • HH:mm').format(date),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${positive ? '+' : ''}${amount.toStringAsFixed(0)} сом.',
              style: TextStyle(color: positive ? AppColors.success : AppColors.error,
                  fontSize: 14, fontWeight: FontWeight.w700)),
          Text(statusLabels[status] ?? status,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
        ]),
      ]),
    );
  }

  void _topUp(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.bgCard,
      title: const Text('Пополнение', style: TextStyle(color: AppColors.textPrimary)),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Маблағро ворид кунед. Баъди тасдиқи админ ба ҳамён илова мешавад.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 12),
        SafeInput(controller: ctrl, autofocus: true, keyboardType: TextInputType.number,
          hint: 'Маблағ (сом.)',
          textColor: AppColors.textPrimary),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
            child: const Text('Бекор', style: TextStyle(color: AppColors.textMuted))),
        TextButton(
          onPressed: () async {
            final amount = double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0;
            if (amount <= 0) return;
            Navigator.pop(ctx);
            final messenger = ScaffoldMessenger.of(context);
            try {
              await WalletService.topUp(amount);
              ref.invalidate(walletProvider);
              messenger.showSnackBar(const SnackBar(
                content: Text('Дархост фиристода шуд. Интизори тасдиқи админ.'),
                backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
            } catch (_) {
              messenger.showSnackBar(const SnackBar(
                content: Text('Хато'),
                backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
            }
          },
          child: const Text('Фиристодан', style: TextStyle(color: AppColors.primary))),
      ],
    ));
  }
}
