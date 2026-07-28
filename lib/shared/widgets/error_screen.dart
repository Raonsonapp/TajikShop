import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/app_l10n.dart';
import '../../core/l10n/admin_l10n.dart';

class ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorScreen({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Scaffold(
      backgroundColor: context.pal.scaffold,
      appBar: AppBar(backgroundColor: context.pal.scaffold,
          iconTheme: IconThemeData(color: context.pal.textPrimary)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(FeatherIcons.wifiOff, size: 72, color: context.pal.textMuted),
            const SizedBox(height: 20),
            Text(l.noConnection,
                style: TextStyle(color: context.pal.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(l.checkInternet,
                style: TextStyle(color: context.pal.textSecondary, fontSize: 14),
                textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(FeatherIcons.refreshCw),
                label: Text(l.tryAgain),
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
