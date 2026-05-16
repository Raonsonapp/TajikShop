import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';

// ══════════════════════════════════════════════════
// DEBUG — ҳамаи хатогиҳоро дар экран нишон медиҳад
// ══════════════════════════════════════════════════
final _logs = <String>[];
void _log(String msg) {
  final t = DateTime.now().toString().substring(11, 19);
  _logs.add('[$t] $msg');
  if (_logs.length > 40) _logs.removeAt(0);
  debugPrint('🔴 $msg');
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure   = true;
  bool _showDebug = true; // DEBUG ФАЪОЛ АСТ

  @override
  void initState() {
    super.initState();
    _log('=== LoginScreen INIT ===');
    _log('Brightness: ${WidgetsBinding.instance.platformDispatcher.platformBrightness}');

    // Ҳамаи Flutter хатогиҳоро сайд кун
    final prev = FlutterError.onError;
    FlutterError.onError = (details) {
      _log('❌ FlutterError: ${details.exception}');
      for (final line in details.stack.toString().split('\n').take(4)) {
        _log('   $line');
      }
      if (mounted) setState(() {});
      prev?.call(details);
    };

    // Zone хатогиҳо
    runZonedGuarded(() {}, (e, st) {
      _log('❌ Zone: $e');
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    _log('--- Login boshlandi ---');
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text.trim();
    _log('Email: $email | Pass: ${pass.isEmpty ? "BOŠ" : "***"}');
    if (email.isEmpty || pass.isEmpty) {
      _log('⚠️ Email ё парол холист');
      return;
    }
    try {
      _log('API ga so\'rov...');
      final ok = await ref.read(authProvider.notifier).login(email, pass);
      _log('Natija: $ok');
      if (ok && mounted) context.go(RouteNames.home);
    } catch (e, st) {
      _log('❌ Login xato: $e');
      _log('Stack: ${st.toString().split('\n').take(2).join(' ')}');
      if (mounted) setState(() {});
    }
  }

  // TextField — filled:false (FIX Material3 grey bug)
  Widget _field({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboard,
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
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF6B6E82)),
          prefixIcon: Icon(icon, color: const Color(0xFF6B6E82)),
          suffixIcon: suffix,
          filled: false, // FIX: Material3 fillColor-ро ignore мекунад
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // BUILD ЛОГЛАР
    _log('build() — theme: ${Theme.of(context).brightness}');
    _log('scaffoldBg: #${Theme.of(context).scaffoldBackgroundColor.value.toRadixString(16)}');
    _log('inputFillColor: #${Theme.of(context).inputDecorationTheme.fillColor?.value.toRadixString(16) ?? "NULL"}');

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
                keyboard: TextInputType.emailAddress,
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

              // Auth error
              if (state.error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red)),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(state.error!,
                        style: const TextStyle(color: Colors.red, fontSize: 13))),
                  ])),
              ],

              const SizedBox(height: 24),

              // Login button
              SizedBox(
                width: double.infinity, height: 52,
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

              const SizedBox(height: 24),

              // ════════════════════════════════════════
              // 🔴 DEBUG ПАНЕЛ — хатогиҳо дар экран
              // ════════════════════════════════════════
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A0000),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red, width: 1.5)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.bug_report, color: Colors.red, size: 14),
                      const SizedBox(width: 6),
                      const Text('🔴 DEBUG LOG',
                          style: TextStyle(color: Colors.red,
                              fontWeight: FontWeight.w800, fontSize: 12)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _logs.clear()),
                        child: const Text('тоза',
                            style: TextStyle(color: Colors.orange, fontSize: 11))),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => setState(() => _showDebug = !_showDebug),
                        child: Text(_showDebug ? 'пинҳон' : 'нишон',
                            style: const TextStyle(
                                color: Colors.orange, fontSize: 11))),
                    ]),

                    if (_showDebug) ...[
                      const SizedBox(height: 8),
                      const Divider(color: Colors.red, height: 1),
                      const SizedBox(height: 8),
                      ..._logs.reversed.map((l) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(l,
                            style: TextStyle(
                                color: l.contains('❌')
                                    ? Colors.red
                                    : l.contains('⚠️')
                                        ? Colors.orange
                                        : Colors.white70,
                                fontSize: 9.5,
                                fontFamily: 'monospace')))),
                    ],
                  ])),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
