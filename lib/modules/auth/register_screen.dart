import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading    = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name  = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text;
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

  Widget _field({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A3A5C)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(icon, color: const Color(0xFF6B6E82), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: EditableText(
              controller: ctrl,
              focusNode: FocusNode(),
              obscureText: obscure,
              keyboardType: keyboard,
              inputFormatters: formatters,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              cursorColor: const Color(0xFF00D084),
              backgroundCursorColor: Colors.grey,
            ),
          ),
        ],
      ),
    );
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
              const SizedBox(height: 48),

              // Logo
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF00D084), Color(0xFF00A3FF)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shopping_bag_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Text('TajikShop',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
              ]),

              const SizedBox(height: 32),
              const Text('Ҳисоб созед 🚀',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Ба бозори Тоҷикистон хуш омадед',
                  style: TextStyle(color: Colors.white54, fontSize: 15)),
              const SizedBox(height: 32),

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

              // Ном
              _field(
                ctrl: _nameCtrl,
                hint: 'Номи корбар',
                icon: Icons.person_outline_rounded,
                formatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_.]')),
                  LengthLimitingTextInputFormatter(30),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 4, top: 4, bottom: 12),
                child: Text('Танҳо ҳарфҳои хурд, рақам ва _',
                    style: TextStyle(color: Colors.white38, fontSize: 11)),
              ),

              // Email
              _field(
                ctrl: _emailCtrl,
                hint: 'Email',
                icon: Icons.email_outlined,
                keyboard: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),

              // Парол
              _field(
                ctrl: _passCtrl,
                hint: 'Парол (ҳадди ақал 6)',
                icon: Icons.lock_outline_rounded,
                obscure: true,
              ),
              const SizedBox(height: 24),

              // Тугма
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D084),
                    disabledBackgroundColor: Colors.grey.shade800,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text('Сабтном',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Ҳисоб доред?  ',
                    style: TextStyle(color: Colors.white54)),
                GestureDetector(
                  onTap: () => context.go(RouteNames.login),
                  child: const Text('Ворид шавед',
                      style: TextStyle(
                          color: Color(0xFF00D084),
                          fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
