import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_l10n.dart';
import '../../core/l10n/misc_l10n.dart';
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
  final _refCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      setState(() => _error = AppL10n.of(context).fillAllFields);
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = AppL10n.of(context).passwordMin6Error);
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final refCode = _refCtrl.text.trim();
      final ok = await ref.read(authProvider.notifier).register(
            email,
            pass,
            name,
            referralCode: refCode.isNotEmpty ? refCode : null,
          );
      if (!mounted) return;
      if (ok) {
        context.go(RouteNames.home);
      } else {
        setState(() { _loading = false; _error = ref.read(authProvider).error ?? AppL10n.of(context).error; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Scaffold(
      backgroundColor: context.pal.scaffold,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // Branded curved green header (intro_page vibe)
          _AuthHeader(
            title: l.registerWelcomeTitle,
            subtitle: l.registerWelcomeSubtitle,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 28, 26, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.register,
                      style: TextStyle(
                          color: context.pal.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(l.registerPrompt,
                      style: TextStyle(color: context.pal.textSecondary, fontSize: 14)),
                  const SizedBox(height: 22),

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
                        const Icon(FeatherIcons.alertCircle, color: AppColors.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                      ]),
                    ),

                  DarkTextField(controller: _nameCtrl, hint: l.usernameHint, icon: FeatherIcons.user,
                      formatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_.]')),
                        LengthLimitingTextInputFormatter(30),
                      ]),
                  Padding(
                    padding: const EdgeInsets.only(left: 6, top: 6, bottom: 12),
                    child: Text(l.usernameRule,
                        style: TextStyle(color: context.pal.textMuted, fontSize: 11)),
                  ),
                  DarkTextField(controller: _emailCtrl, hint: 'Email', icon: FeatherIcons.mail,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 14),
                  DarkTextField(controller: _passCtrl, hint: l.passwordMin6Hint, icon: FeatherIcons.lock,
                      obscure: _obscure,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _loading ? null : _register(),
                      suffix: GestureDetector(
                        onTap: () => setState(() => _obscure = !_obscure),
                        child: Icon(_obscure ? FeatherIcons.eyeOff : FeatherIcons.eye,
                            color: context.pal.textMuted, size: 20))),
                  const SizedBox(height: 14),
                  DarkTextField(controller: _refCtrl, hint: 'Коди даъват (ихтиёрӣ)',
                      icon: FeatherIcons.gift,
                      textInputAction: TextInputAction.done,
                      formatters: [
                        LengthLimitingTextInputFormatter(20),
                      ]),
                  const SizedBox(height: 26),

                  _GradientButton(
                    label: l.register,
                    loading: _loading,
                    onTap: _loading ? null : _register,
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go(RouteNames.login),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(color: context.pal.textSecondary, fontSize: 14),
                          children: [
                            TextSpan(text: l.haveAccountPrefix),
                            TextSpan(
                                text: l.signIn,
                                style: const TextStyle(
                                    color: AppColors.primary, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Branded green gradient curved header (template intro/auth vibe).
class _AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _AuthHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 30, left: 28, right: 28, bottom: 30),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(38),
          bottomRight: Radius.circular(38),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x3300D084),
            offset: Offset(0, 10),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(19),
            ),
            child: const Icon(FeatherIcons.shoppingBag, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 18),
          const Text('TajikShop',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.9), fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }
}

/// Big rounded GREEN gradient primary button (template `mainButton` → green).
class _GradientButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;
  const _GradientButton({required this.label, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4D00D084),
              offset: Offset(0, 8),
              blurRadius: 18,
            ),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
