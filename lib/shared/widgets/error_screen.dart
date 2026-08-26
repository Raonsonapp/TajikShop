import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/app_l10n.dart';
import '../../core/l10n/admin_l10n.dart';
import '../../core/l10n/profile_l10n.dart';
import 'fade_slide_in.dart';

/// Навъи хатогӣ — то ба корбар сабаби воқеиро гӯем.
enum _Kind { offline, auth, notFound, server }

/// Экрани хатогӣ.
///
/// ⚠️ Пештар ин экран сарфи назар аз хатои воқеӣ ҳамеша «Пайвастшавӣ мавҷуд
/// нест» менавишт — яъне хатои сервер (404/500) низ ҳамчун «интернет нест»
/// нишон дода мешуд ва корбар сабабро намедонист. Ҳоло `message` таҳлил шуда,
/// иконка/матни мувофиқ нишон дода мешавад.
class ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorScreen({super.key, required this.message, this.onRetry});

  _Kind get _kind {
    final m = message.toLowerCase();
    if (m.contains('socketexception') ||
        m.contains('failed host lookup') ||
        m.contains('network is unreachable') ||
        m.contains('connection refused') ||
        m.contains('connection error') ||
        m.contains('connectiontimeout') ||
        m.contains('connection timeout') ||
        m.contains('no address associated')) {
      return _Kind.offline;
    }
    if (m.contains('401') || m.contains('unauthor') || m.contains('token')) {
      return _Kind.auth;
    }
    if (m.contains('404') || m.contains('not found')) return _Kind.notFound;
    return _Kind.server;
  }

  /// Матни хом (Exception/stack) барои корбар фоида надорад — тоза мекунем.
  String get _detail => message
      .replaceAll('Exception:', '')
      .replaceAll('DioException', '')
      .trim();

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final kind = _kind;

    final (IconData icon, String title, String hint) = switch (kind) {
      _Kind.offline => (FeatherIcons.wifiOff, l.noConnection, l.checkInternet),
      _Kind.auth => (FeatherIcons.lock, l.sessionExpired, ''),
      _Kind.notFound => (FeatherIcons.search, l.notFoundHint, l.serverErrorHint),
      _Kind.server => (
          FeatherIcons.alertTriangle,
          l.somethingWentWrong,
          l.serverErrorHint
        ),
    };

    return Scaffold(
      backgroundColor: context.pal.scaffold,
      appBar: AppBar(
          backgroundColor: context.pal.scaffold,
          elevation: 0,
          iconTheme: IconThemeData(color: context.pal.textPrimary)),
      body: Center(
        child: FadeSlideIn(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 108,
                height: 108,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 22),
              Text(title,
                  style: TextStyle(
                      color: context.pal.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center),
              if (hint.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(hint,
                    style: TextStyle(color: context.pal.textSecondary, fontSize: 14),
                    textAlign: TextAlign.center),
              ],

              // Тафсилоти техникӣ — танҳо барои хатоҳои сервер, паси expander.
              if (kind != _Kind.offline && _detail.isNotEmpty) ...[
                const SizedBox(height: 14),
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    title: Text(l.details,
                        style: TextStyle(
                            color: context.pal.textMuted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600)),
                    iconColor: context.pal.textMuted,
                    collapsedIconColor: context.pal.textMuted,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: context.pal.surface,
                            borderRadius: BorderRadius.circular(12)),
                        child: Text(_detail,
                            style: TextStyle(
                                color: context.pal.textMuted, fontSize: 11.5)),
                      ),
                    ],
                  ),
                ),
              ],

              if (onRetry != null) ...[
                const SizedBox(height: 24),
                PressableScale(
                  onTap: onRetry,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.32),
                            blurRadius: 14,
                            offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(FeatherIcons.refreshCw, color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      Text(l.tryAgain,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                    ]),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
