// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../routes/route_names.dart';
import '../../core/l10n/app_l10n.dart';

// SMS верификация — Firebase тайёр шавад баъд фаъол мешавад
// Ҳозир барои email/password login истифода кунед
class PhoneAuthScreen extends ConsumerWidget {
  const PhoneAuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            onPressed: () => context.go(RouteNames.login))),
      body: Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('📱', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 24),
          const Text('SMS верификация',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const Text('Ин функсия тез фаъол мешавад.\nҲозир бо Email ворид шавед.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go(RouteNames.login),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: Text(l.login,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)))),
        ]))));
  }
}

class PhoneOtpScreen extends ConsumerWidget {
  final String verificationId;
  final String phone;
  const PhoneOtpScreen({super.key, required this.verificationId, required this.phone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Center(child: Text('OTP', style: TextStyle(color: Colors.white))));
  }
}
