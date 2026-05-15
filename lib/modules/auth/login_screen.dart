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
  final _emailCtrl = TextEditingController(text: '');
  final _passCtrl  = TextEditingController(text: '');
  bool _obscure    = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) return;
    final ok = await ref.read(authProvider.notifier).login(email, pass);
    if (ok && mounted) context.go(RouteNames.home);
  }

  // TextField-ро бо Container wrap кун — filled:false
  // FIX: Material3 filled:true fillColor-ро ignore мекунад дар light theme
  Widget _field({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141420),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF252538)),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF6B6E82)),
          prefixIcon: Icon(icon, color: const Color(0xFF6B6E82)),
          suffixIcon: suffix,
          filled: false,          // FIX: false — Container ранг медиҳад
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Logo
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00D084), Color(0xFF00A3FF)]),
                    borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.shopping_bag_rounded,
                      color: Colors.white, size: 24)),
                const SizedBox(width: 10),
                const Text('TajikShop',
                    style: TextStyle(color: Colors.white,
                        fontSize: 24, fontWeight: FontWeight.w800)),
              ]),

              const SizedBox(height: 40),
              const Text('Хуш омадед! 👋',
                  style: TextStyle(color: Colors.white,
                      fontSize: 26, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text('Ба ҳисоби худ ворид шавед',
                  style: TextStyle(color: Color(0xFFAAADBE), fontSize: 14)),
              const SizedBox(height: 32),

              // Email
              _field(
                ctrl: _emailCtrl,
                hint: 'Почтаи электронӣ',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 14),

              // Password
              _field(
                ctrl: _passCtrl,
                hint: 'Парол',
                icon: Icons.lock_outline,
                obscure: _obscure,
                suffix: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off_outlined
                             : Icons.visibility_outlined,
                    color: const Color(0xFF6B6E82)),
                  onPressed: () => setState(() => _obscure = !_obscure)),
              ),

              // Error
              if (state.error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B5C).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFFF3B5C).withValues(alpha: 0.3))),
                  child: Text(state.error!,
                      style: const TextStyle(
                          color: Color(0xFFFF3B5C), fontSize: 13))),
              ],

              const SizedBox(height: 24),

              // Login button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D084),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0),
                  child: state.isLoading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : const Text('Ворид шавед',
                          style: TextStyle(color: Colors.white,
                              fontSize: 15, fontWeight: FontWeight.w700)))),

              const SizedBox(height: 20),

              // Register
              Center(child: GestureDetector(
                onTap: () => context.go(RouteNames.register),
                child: RichText(text: const TextSpan(
                  text: 'Ҳисоб надоред?  ',
                  style: TextStyle(color: Color(0xFFAAADBE), fontSize: 14),
                  children: [TextSpan(
                    text: 'Сабтном',
                    style: TextStyle(color: Color(0xFF00D084),
                        fontWeight: FontWeight.w700))])))),
            ],
          ),
        ),
      ),
    );
  }
}
