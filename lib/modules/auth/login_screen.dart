import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';
import '../../shared/widgets/dark_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Email ва паролро ворид кунед');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final ok = await ref.read(authProvider.notifier).login(email, pass);
      if (!mounted) return;
      if (ok) {
        context.go(RouteNames.home);
      } else {
        setState(() { _loading = false; _error = ref.read(authProvider).error ?? 'Хато'; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pal.scaffold,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 64),
              Center(child: Container(
                width: 92, height: 92,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 48),
              )),
              const SizedBox(height: 22),
              const Text('TajikShop',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.primary, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Text('Хуш омадед! 👋\nБа ҳисоби худ ворид шавед',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.pal.textSecondary, fontSize: 15, height: 1.4)),
              const SizedBox(height: 36),

              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(13),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0x22FF3B5C),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                  ]),
                ),

              DarkTextField(controller: _emailCtrl, hint: 'Email', icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 14),
              DarkTextField(controller: _passCtrl, hint: 'Парол', icon: Icons.lock_outline_rounded,
                  obscure: _obscure,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _loading ? null : _login(),
                  suffix: GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    child: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: context.pal.textMuted, size: 20))),
              const SizedBox(height: 26),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(width: 24, height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Ворид шавед',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: () => context.go(RouteNames.register),
                child: const Text('Ҳисоб надоред? Сабтном',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

}
