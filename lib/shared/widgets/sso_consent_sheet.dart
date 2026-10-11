import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/sso_authorize.dart';
import '../../core/theme/app_palette.dart';

/// Натиҷаи «Бо TajikShop ворид шавед».
enum SsoAuthorizeOutcome { opened, cancelled, unknownApp, needsLogin, failed }

/// Ҷараёни пурра: санҷиши барнома дар `/sso/apps` → розигии корбар →
/// `POST /sso/code` → кушодани барномаи шарик бо `&state=…`.
class SsoAuthorizeFlow {
  SsoAuthorizeFlow._();

  static Map _unwrap(Object? raw) => raw is Map
      ? (raw['data'] is Map ? raw['data'] as Map : raw)
      : const {};

  static Future<SsoAuthorizeOutcome> run(
    BuildContext context,
    SsoAuthorizeRequest req, {
    required String userName,
  }) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    void toast(String msg) => messenger?.showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating));

    // 1. Барнома бояд дар рӯйхати шарикон бошад.
    final SsoPartnerApp? app;
    try {
      final res = await ApiClient.instance.dio.get('/sso/apps');
      app = SsoPartnerApp.find(SsoPartnerApp.listFrom(res.data), req.app);
    } catch (_) {
      toast('Пайваст нашуд. Дубора кӯшиш кунед');
      return SsoAuthorizeOutcome.failed;
    }
    if (app == null) {
      toast('Барномаи номаълум');
      return SsoAuthorizeOutcome.unknownApp;
    }
    if (!context.mounted) return SsoAuthorizeOutcome.failed;

    // 2. Розигӣ.
    final result = await showModalBottomSheet<_ConsentResult>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SsoConsentSheet(app: app!, userName: userName),
    );
    if (result == null || result.outcome == SsoAuthorizeOutcome.cancelled) {
      return SsoAuthorizeOutcome.cancelled;
    }
    if (result.outcome != SsoAuthorizeOutcome.opened) {
      if (result.outcome == SsoAuthorizeOutcome.failed) {
        toast(result.message ?? 'Гузариш нашуд. Дубора кӯшиш кунед');
      }
      return result.outcome;
    }

    // 3. Бозгашт ба барномаи шарик бо ҳамон state.
    final link = SsoAuthorizeRequest.buildReturnLink(
        deepLink: result.deepLink!, expectedScheme: app.scheme, state: req.state);
    if (link == null) {
      toast('Ҷавоби нодурусти сервер');
      return SsoAuthorizeOutcome.failed;
    }
    var opened = false;
    try {
      opened = await launchUrl(link, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!opened && app.fallback.startsWith('https://')) {
      await launchUrl(Uri.parse(app.fallback),
          mode: LaunchMode.externalApplication);
    }
    return opened ? SsoAuthorizeOutcome.opened : SsoAuthorizeOutcome.failed;
  }

  /// `POST /sso/code` — дар sheet, пас аз «Идома».
  static Future<_ConsentResult> _issueCode(SsoPartnerApp app) async {
    try {
      final res = await ApiClient.instance.dio
          .post('/sso/code', data: {'target_app': app.id});
      final deepLink = (_unwrap(res.data)['deep_link'] ?? '').toString();
      if (deepLink.isEmpty) {
        return const _ConsentResult(SsoAuthorizeOutcome.failed);
      }
      return _ConsentResult(SsoAuthorizeOutcome.opened, deepLink: deepLink);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const _ConsentResult(SsoAuthorizeOutcome.needsLogin);
      }
      final d = e.response?.data;
      return _ConsentResult(SsoAuthorizeOutcome.failed,
          message: (d is Map ? d['error'] : null)?.toString());
    } catch (_) {
      return const _ConsentResult(SsoAuthorizeOutcome.failed);
    }
  }
}

class _ConsentResult {
  const _ConsentResult(this.outcome, {this.deepLink, this.message});
  final SsoAuthorizeOutcome outcome;
  final String? deepLink;
  final String? message;
}

class _SsoConsentSheet extends StatefulWidget {
  const _SsoConsentSheet({required this.app, required this.userName});
  final SsoPartnerApp app;
  final String userName;

  @override
  State<_SsoConsentSheet> createState() => _SsoConsentSheetState();
}

class _SsoConsentSheetState extends State<_SsoConsentSheet> {
  bool _busy = false;

  Future<void> _continue() async {
    if (_busy) return;
    setState(() => _busy = true);
    final r = await SsoAuthorizeFlow._issueCode(widget.app);
    if (mounted) Navigator.of(context).pop(r);
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final name = widget.userName.trim().isEmpty ? 'Корбар' : widget.userName.trim();
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        decoration: BoxDecoration(
          color: pal.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: pal.border),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient, shape: BoxShape.circle),
            child: const Icon(Icons.login_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 14),
          Text('Ба ${widget.app.name} ҳамчун $name идома медиҳед?',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: pal.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.3)),
          const SizedBox(height: 8),
          Text(
              '${widget.app.name} ном, почта ва акси профили шуморо мегирад. '
              'Парол дода намешавад.',
              textAlign: TextAlign.center,
              style: TextStyle(color: pal.textMuted, fontSize: 13, height: 1.35)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              key: const Key('sso_consent_continue'),
              onPressed: _busy ? null : _continue,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.2))
                  : const Text('Идома',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            key: const Key('sso_consent_cancel'),
            onPressed: _busy
                ? null
                : () => Navigator.of(context)
                    .pop(const _ConsentResult(SsoAuthorizeOutcome.cancelled)),
            child: Text('Бекор', style: TextStyle(color: pal.textSecondary)),
          ),
        ]),
      ),
    );
  }
}
