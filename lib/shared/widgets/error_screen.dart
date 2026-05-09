import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorScreen({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(backgroundColor: AppColors.bgDark,
          iconTheme: const IconThemeData(color: AppColors.textPrimary)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.wifi_off_rounded, size: 72, color: AppColors.textMuted),
            const SizedBox(height: 20),
            const Text('Пайвастшавӣ мавҷуд нест',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('Интернетро санҷед ва дубора кӯшиш кунед',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Такрор кунед'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}
