import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
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
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900));
    _fade  = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _scale = Tween<double>(begin: 0.85, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
    _init();
  }

  Future<void> _init() async {
    // Minimum splash time
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    // FIX: checkAuth бо 6s timeout — сервер бедор нашуд? login га бор
    // ANR сабаб: wakeUp() 100s блок мекард — акнун Splash мунтазир намемонад
    try {
      await ref.read(authProvider.notifier)
          .checkAuth()
          .timeout(const Duration(seconds: 6));
    } catch (_) {
      // Timeout ё хато — login-га бор, offline кэш мехонем
    }

    if (!mounted) return;
    final auth = ref.read(authProvider).isAuthenticated;
    context.go(auth ? RouteNames.home : RouteNames.login);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

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
                      blurRadius: 30, spreadRadius: 5)]),
                  child: const Icon(Icons.shopping_bag_rounded,
                      color: Colors.white, size: 52)),
                const SizedBox(height: 24),
                ShaderMask(
                  shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
                  child: const Text('TajikShop',
                      style: TextStyle(color: Colors.white,
                          fontSize: 38, fontWeight: FontWeight.w800,
                          letterSpacing: -1))),
                const SizedBox(height: 8),
                const Text('Бозори Тоҷикистон',
                    style: TextStyle(color: AppColors.textSecondary,
                        fontSize: 16)),
                const SizedBox(height: 60),
                const SizedBox(width: 28, height: 28,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(AppColors.primary))),
                const SizedBox(height: 16),
                const _Dots(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatefulWidget {
  const _Dots();
  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> {
  int _i = 0;
  late final _t = Stream.periodic(
      const Duration(milliseconds: 500), (i) => i % 4)
      .listen((v) { if (mounted) setState(() => _i = v); });

  @override void dispose() { _t.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Text(
    'Пайваст мешавем${'.' * (_i + 1)}',
    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12));
}
