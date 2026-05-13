// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../main.dart' show AppL10n;

// ─── STEP 1: Рақами телефон ──────────────────────────────────────────────────
class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});
  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() { _phoneCtrl.dispose(); super.dispose(); }

  Future<void> _sendOTP() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty || phone.length < 9) {
      setState(() => _error = 'Рақами телефонро дуруст ворид кунед');
      return;
    }

    // Формат: +992XXXXXXXXX
    String formatted = phone;
    if (!phone.startsWith('+')) formatted = '+992$phone';

    setState(() { _loading = true; _error = null; });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: formatted,
      timeout: const Duration(seconds: 60),

      // ── Автоматӣ (Android) ─────────────────────────────────────
      verificationCompleted: (PhoneAuthCredential cred) async {
        await _signInWithCred(cred);
      },

      // ── SMS рамз нодуруст ─────────────────────────────────────
      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          _loading = false;
          _error = e.code == 'invalid-phone-number'
              ? 'Рақами телефон нодуруст аст'
              : 'Хато: ${e.message}';
        });
      },

      // ── SMS фиристода шуд — OTP экран ─────────────────────────
      codeSent: (String verificationId, int? resendToken) {
        setState(() => _loading = false);
        if (context.mounted) {
          context.push('/phone-otp', extra: {
            'verificationId': verificationId,
            'phone': formatted,
          });
        }
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        setState(() => _loading = false);
      },
    );
  }

  Future<void> _signInWithCred(PhoneAuthCredential cred) async {
    try {
      final result = await FirebaseAuth.instance.signInWithCredential(cred);
      final idToken = await result.user?.getIdToken();
      if (idToken == null) throw Exception('Token нест');
      final ok = await ref.read(authProvider.notifier).loginWithPhone(idToken);
      if (ok && mounted) context.go(RouteNames.home);
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            const SizedBox(height: 40),
            // Logo
            Row(children: [
              Container(width: 48, height: 48,
                decoration: BoxDecoration(gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 28)),
              const SizedBox(width: 12),
              ShaderMask(shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
                child: const Text('TajikShop',
                    style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800))),
            ]),

            const SizedBox(height: 48),
            const Text('📱 Тасдиқи рақам',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Рақами телефони худро ворид кунед\nSMS рамз фиристода мешавад',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5)),

            const SizedBox(height: 32),

            // Phone prefix + input
            Row(children: [
              // +992 prefix
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border)),
                child: const Text('🇹🇯 +992',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600))),
              const SizedBox(width: 10),
              Expanded(child: AppTextField(
                hint: 'XXXXXXXXX',
                controller: _phoneCtrl,
                prefixIcon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
              )),
            ]),

            const SizedBox(height: 8),
            const Text('Мисол: 935 123 456',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.3))),
                child: Row(children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13))),
                ])),
            ],

            const SizedBox(height: 32),
            AppButton(
              text: 'SMS рамз гирифтан 📨',
              isLoading: _loading,
              onTap: _sendOTP,
            ),

            const SizedBox(height: 24),
            // Divider
            Row(children: const [
              Expanded(child: Divider(color: AppColors.divider)),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('ё', style: TextStyle(color: AppColors.textMuted))),
              Expanded(child: Divider(color: AppColors.divider)),
            ]),
            const SizedBox(height: 24),

            // Email login
            Center(child: GestureDetector(
              onTap: () => context.go(RouteNames.login),
              child: const Text('Email бо ворид шавед →',
                  style: TextStyle(color: AppColors.primary,
                      fontSize: 14, fontWeight: FontWeight.w600)))),

            const SizedBox(height: 12),
            Center(child: GestureDetector(
              onTap: () => context.go(RouteNames.register),
              child: Text('${l.dontHaveAccount} ${l.signUp}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)))),
          ]),
        ),
      ),
    );
  }
}

// ─── STEP 2: OTP рамз ────────────────────────────────────────────────────────
class PhoneOtpScreen extends ConsumerStatefulWidget {
  final String verificationId;
  final String phone;
  const PhoneOtpScreen({
    super.key,
    required this.verificationId,
    required this.phone,
  });
  @override
  ConsumerState<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends ConsumerState<PhoneOtpScreen> {
  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  String get _otp => _ctrls.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otp.length < 6) {
      setState(() => _error = '6 рақамро ворид кунед');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _otp,
      );
      final result = await FirebaseAuth.instance.signInWithCredential(cred);
      final idToken = await result.user?.getIdToken();
      if (idToken == null) throw Exception('Token нест');
      final ok = await ref.read(authProvider.notifier).loginWithPhone(idToken);
      if (ok && mounted) context.go(RouteNames.home);
      else setState(() { _loading = false; _error = 'Рамз нодуруст аст'; });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading = false;
        _error = e.code == 'invalid-verification-code'
            ? '❌ Рамз нодуруст аст'
            : e.message ?? 'Хато';
      });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  void _onDigit(int idx, String val) {
    if (val.isNotEmpty && idx < 5) {
      _nodes[idx + 1].requestFocus();
    }
    if (val.isEmpty && idx > 0) {
      _nodes[idx - 1].requestFocus();
    }
    if (_otp.length == 6) _verify();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            onPressed: () => context.pop())),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            const SizedBox(height: 20),
            const Text('🔐 SMS рамз',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Рамз ба ${widget.phone} фиристода шуд',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),

            const SizedBox(height: 40),

            // OTP boxes
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) => _OtpBox(
                controller: _ctrls[i],
                focusNode: _nodes[i],
                onChanged: (v) => _onDigit(i, v),
                autofocus: i == 0,
              ))),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.3))),
                child: Text(_error!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13))),
            ],

            const SizedBox(height: 32),
            AppButton(
              text: '✅ Тасдиқ кардан',
              isLoading: _loading,
              onTap: _verify,
            ),

            const SizedBox(height: 24),
            Center(child: TextButton(
              onPressed: () => context.pop(),
              child: const Text('Рақамро иваз кунед',
                  style: TextStyle(color: AppColors.primary, fontSize: 13)))),
          ]),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool autofocus;
  const _OtpBox({required this.controller, required this.focusNode,
      required this.onChanged, this.autofocus = false});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 46, height: 56,
    child: TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      maxLength: 1,
      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        counterText: '',
        filled: true,
        fillColor: AppColors.bgCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border)),
      ),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged));
}
