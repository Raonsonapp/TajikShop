import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).register(
          _emailCtrl.text.trim(),
          _passCtrl.text.trim(),
          _nameCtrl.text.trim(),
        );
    if (success && mounted) context.go(RouteNames.home);
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                IconButton(
                  onPressed: () => context.go(RouteNames.login),
                  icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 24),
                const Text('Ҳисоб созед 🚀',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('Ба бозори Тоҷикистон хуш омадед',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                const SizedBox(height: 36),

                AppTextField(
                  hint: 'Номи пурра',
                  controller: _nameCtrl,
                  prefixIcon: Icons.person_outline,
                  validator: (v) => v!.isEmpty ? 'Номро ворид кунед' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  hint: 'Почтаи электронӣ',
                  controller: _emailCtrl,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v!.isEmpty ? 'Почтаро ворид кунед' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  hint: 'Парол (камаш 6 рақам)',
                  controller: _passCtrl,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  onSuffixTap: () => setState(() => _obscure = !_obscure),
                  obscure: _obscure,
                  validator: (v) => v!.length < 6 ? 'Парол камаш 6 рақам' : null,
                ),
                const SizedBox(height: 24),

                if (state.error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Text(state.error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                  ),

                AppButton(text: 'Сабтном', onTap: _register, isLoading: state.isLoading),
                const SizedBox(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('Ҳисоб доред?', style: TextStyle(color: AppColors.textSecondary)),
                  TextButton(
                    onPressed: () => context.go(RouteNames.login),
                    child: const Text('Ворид шавед',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
