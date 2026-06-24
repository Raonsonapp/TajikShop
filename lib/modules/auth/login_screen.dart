import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';

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
        setState(() {
          _loading = false;
          _error = ref.read(authProvider).error ?? 'Хато';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        // Гарму равшан — градиенти мулоим бо дурахши сабз-кабуд
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF10241F), Color(0xFF0C1430), Color(0xFF0A0A0F)],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: Stack(children: [
          // Дурахши болоӣ
          Positioned(top: -90, left: -40,
            child: _glow(const Color(0xFF00D084), 260)),
          Positioned(top: 40, right: -60,
            child: _glow(const Color(0xFF00A3FF), 220)),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 70),

                  // Лого
                  Center(child: Container(
                    width: 96, height: 96,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.45),
                        blurRadius: 32, spreadRadius: 2)],
                    ),
                    child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 50),
                  )),
                  const SizedBox(height: 22),

                  ShaderMask(
                    shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
                    child: const Text('TajikShop',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1)),
                  ),
                  const SizedBox(height: 8),
                  const Text('Хуш омадед! 👋\nБа ҳисоби худ ворид шавед',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.4)),
                  const SizedBox(height: 38),

                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(13),
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                      ]),
                    ),

                  _field(
                    controller: _emailCtrl,
                    hint: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    action: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: _passCtrl,
                    hint: 'Парол',
                    icon: Icons.lock_outline_rounded,
                    obscure: _obscure,
                    action: TextInputAction.done,
                    onSubmitted: (_) => _loading ? null : _login(),
                    suffix: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textMuted, size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Тугмаи градиентӣ
                  GestureDetector(
                    onTap: _loading ? null : _login,
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 18, offset: const Offset(0, 8))],
                      ),
                      alignment: Alignment.center,
                      child: _loading
                          ? const SizedBox(width: 24, height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('Ворид шавед',
                              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(height: 22),

                  Center(child: TextButton(
                    onPressed: () => context.go(RouteNames.register),
                    child: RichText(text: const TextSpan(children: [
                      TextSpan(text: 'Ҳисоб надоред?  ', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                      TextSpan(text: 'Сабтном', style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700)),
                    ])),
                  )),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _glow(Color c, double size) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [c.withValues(alpha: 0.22), Colors.transparent]),
    ),
  );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    TextInputAction action = TextInputAction.next,
    Widget? suffix,
    void Function(String)? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: action,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF161622),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 21),
        suffixIcon: suffix,
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(vertical: 17, horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFF2A2A3E), width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.6)),
      ),
    );
  }
}
