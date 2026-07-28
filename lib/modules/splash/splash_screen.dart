import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/app_l10n.dart';
import '../../core/l10n/extra_l10n.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _scale = Tween<double>(begin: 0.85, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
    _initApp();
  }

  Future<void> _initApp() async {
    final minDelay = Future.delayed(const Duration(seconds: 2));

    // ✅ TIMEOUT 10с — на 60с! Агар сервер ҷавоб надиҳад, ба login меравад
    final authCheck = ref
        .read(authProvider.notifier)
        .checkAuth()
        .timeout(const Duration(seconds: 10), onTimeout: () {})
        .catchError((_) {});

    await Future.wait([minDelay, authCheck]);

    if (!mounted) return;
    final s = ref.read(authProvider);
    context.go(s.isAuthenticated ? RouteNames.home : RouteNames.login);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 30, spreadRadius: 5,
                    )],
                  ),
                  child: const Icon(FeatherIcons.shoppingBag, color: Colors.white, size: 52),
                ),
                const SizedBox(height: 24),
                ShaderMask(
                  shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
                  child: const Text('TajikShop', style: TextStyle(
                      color: Colors.white, fontSize: 38,
                      fontWeight: FontWeight.w800, letterSpacing: -1)),
                ),
                const SizedBox(height: 8),
                Text(AppL10n.of(context).marketplaceTagline, style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 16)),
                const SizedBox(height: 24),
                const SizedBox(width: 24, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
