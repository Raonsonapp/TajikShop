// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier)
        .login(_emailCtrl.text.trim(), _passCtrl.text.trim());
    if (ok && mounted) context.go(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 60),
              Row(children: [
                Container(width: 48, height: 48,
                  decoration: BoxDecoration(gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 28)),
                const SizedBox(width: 12),
                ShaderMask(
                  shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
                  child: const Text('TajikShop',
                      style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800))),
              ]),
              const SizedBox(height: 48),
              const Text('Хуш омадед! 👋',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Ба ҳисоби худ ворид шавед',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
              const SizedBox(height: 36),
              AppTextField(
                hint: 'Почтаи электронӣ',
                controller: _emailCtrl,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.isEmpty ? 'Почтаро ворид кунед' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                hint: 'Парол',
                controller: _passCtrl,
                prefixIcon: Icons.lock_outline,
                suffixIcon: _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                onSuffixTap: () => setState(() => _obscure = !_obscure),
                obscure: _obscure,
                validator: (v) => v!.length < 6 ? 'Парол камаш 6 рақам' : null,
              ),
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight,
                child: TextButton(onPressed: () {},
                  child: const Text('Паролро фаромӯш кардед?',
                      style: TextStyle(color: AppColors.primary)))),
              if (state.error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3))),
                  child: Text(state.error!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13))),
              const SizedBox(height: 8),
              AppButton(text: 'Ворид шавед', onTap: _login, isLoading: state.isLoading),
              const SizedBox(height: 32),
              Row(children: const [
                Expanded(child: Divider(color: AppColors.divider)),
                Padding(padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('ё', style: TextStyle(color: AppColors.textMuted))),
                Expanded(child: Divider(color: AppColors.divider)),
              ]),
              const SizedBox(height: 32),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Ҳисоб надоред?',
                    style: TextStyle(color: AppColors.textSecondary)),
                TextButton(onPressed: () => context.go(RouteNames.register),
                  child: const Text('Сабтном',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
// END OF FILE - LoginScreen only, no RegisterScreen here
