import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading    = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text.trim();
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
      backgroundColor: const Color(0xFF0A0A0F),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),

              const Icon(Icons.shopping_bag_rounded,
                  color: Color(0xFF00D084), size: 72),
              const SizedBox(height: 16),

              const Text('TajikShop',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              const Text('Ба ҳисоби худ ворид шавед',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 40),

              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.redAccent)),
                ),

              // ✅ Email — SizedBox бо height
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3A3A5C)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.email_outlined,
                        color: Color(0xFF6B6E82), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: EditableText(
                        controller: _emailCtrl,
                        focusNode: FocusNode(),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 15),
                        cursorColor: const Color(0xFF00D084),
                        backgroundCursorColor: Colors.grey,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ✅ Парол — SizedBox бо height
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3A3A5C)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.lock_outline,
                        color: Color(0xFF6B6E82), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: EditableText(
                        controller: _passCtrl,
                        focusNode: FocusNode(),
                        obscureText: true,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 15),
                        cursorColor: const Color(0xFF00D084),
                        backgroundCursorColor: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D084),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text('Ворид шавед',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () => context.go(RouteNames.register),
                child: const Text('Ҳисоб надоред? Сабтном',
                    style: TextStyle(color: Color(0xFF00D084))),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
