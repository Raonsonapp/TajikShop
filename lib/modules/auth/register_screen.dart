import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';
import '../../shared/widgets/dark_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Ҳамаи майдонҳоро пур кунед');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Парол ҳадди ақал 6 аломат');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final ok = await ref.read(authProvider.notifier).register(email, pass, name);
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
              const SizedBox(height: 48),
              Center(child: Container(
                width: 76, height: 76,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 38),
              )),
              const SizedBox(height: 18),
              Text('Ҳисоб созед 🚀',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.pal.textPrimary, fontSize: 27, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text('Ба бозори Тоҷикистон хуш омадед',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.pal.textSecondary, fontSize: 15)),
              const SizedBox(height: 30),

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

              DarkTextField(controller: _nameCtrl, hint: 'Номи корбар', icon: Icons.person_outline_rounded,
                  formatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_.]')),
                    LengthLimitingTextInputFormatter(30),
                  ]),
              Padding(
                padding: const EdgeInsets.only(left: 6, top: 6, bottom: 12),
                child: Text('Танҳо ҳарфҳои хурд, рақам ва _',
                    style: TextStyle(color: context.pal.textMuted, fontSize: 11)),
              ),
              DarkTextField(controller: _emailCtrl, hint: 'Email', icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 14),
              DarkTextField(controller: _passCtrl, hint: 'Парол (ҳадди ақал 6)', icon: Icons.lock_outline_rounded,
                  obscure: _obscure,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _loading ? null : _register(),
                  suffix: GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    child: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: context.pal.textMuted, size: 20))),
              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(width: 24, height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Сабтном',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go(RouteNames.login),
                child: const Text('Ҳисоб доред? Ворид шавед',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

}
