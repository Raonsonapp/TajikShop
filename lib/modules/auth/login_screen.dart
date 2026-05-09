import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 40),
            Row(children: [
              Container(width: 44, height: 44,
                decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 24)),
              const SizedBox(width: 12),
              const Text('TajikShop', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 32),
            const Text('Ҳисоб созед 🚀',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Ба бозори Тоҷикистон хуш омадед',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
            const SizedBox(height: 32),

            // Username - lowercase only
            AppTextField(
              hint: 'Номи корбар (масалан: ali_99)',
              controller: _nameCtrl,
              prefixIcon: Icons.person_outline_rounded,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_.]')),
                LengthLimitingTextInputFormatter(30),
              ],
              onChanged: (v) {
                final lower = v.toLowerCase();
                if (v != lower) {
                  _nameCtrl.value = _nameCtrl.value.copyWith(
                      text: lower,
                      selection: TextSelection.collapsed(offset: lower.length));
                }
              },
            ),
            const Padding(
              padding: EdgeInsets.only(left: 4, top: 4, bottom: 12),
              child: Text('Танҳо ҳарфҳои хурд, рақам ва _ (масалан: ali_dushanbe)',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ),

            AppTextField(
              hint: 'Email',
              controller: _emailCtrl,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),

            // Password with toggle using suffixWidget
            AppTextField(
              hint: 'Парол (ҳадди ақал 6)',
              controller: _passCtrl,
              prefixIcon: Icons.lock_outline_rounded,
              obscure: _obscure,
              suffixWidget: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.textMuted, size: 20),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            const SizedBox(height: 24),

            if (auth.error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3))),
                child: Text(auth.error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),

            AppButton(
              text: 'Сабтном',
              isLoading: auth.isLoading,
              onTap: () async {
                if (_nameCtrl.text.trim().isEmpty ||
                    _emailCtrl.text.trim().isEmpty ||
                    _passCtrl.text.isEmpty) return;
                final ok = await ref.read(authProvider.notifier)
                    .register(_emailCtrl.text.trim(), _passCtrl.text, _nameCtrl.text.trim());
                if (ok && context.mounted) context.go(RouteNames.home);
              },
            ),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('Ҳисоб доред?  ', style: TextStyle(color: AppColors.textSecondary)),
              GestureDetector(
                onTap: () => context.go(RouteNames.login),
                child: const Text('Ворид шавед',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))),
            ]),
          ]),
        ),
      ),
    );
  }
}
