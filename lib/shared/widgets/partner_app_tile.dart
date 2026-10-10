import 'package:dio/dio.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import 'fade_slide_in.dart';

/// Гузариш ба барномаи шарик (Raonson) бе парол.
///
/// Сервер коди якдафъаина медиҳад, мо барномаи дигарро бо он мекушоем, ва
/// он корбарро бе бақайдгирии нав мегирад — мисли Instagram → Facebook.
///
/// Агар барнома насб набошад, корбар ба Google Play меравад, на ба девор.
class PartnerAppTile extends StatefulWidget {
  const PartnerAppTile({super.key, this.appId = 'raonson'});

  final String appId;

  @override
  State<PartnerAppTile> createState() => _PartnerAppTileState();
}

class _PartnerAppTileState extends State<PartnerAppTile> {
  bool _busy = false;

  Future<void> _open() async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final res = await ApiClient.instance.dio
          .post('/sso/code', data: {'target_app': widget.appId});
      final raw = res.data;
      final data = raw is Map
          ? (raw['data'] is Map ? raw['data'] as Map : raw)
          : const {};
      final deepLink = (data['deep_link'] ?? '').toString();
      final fallback = (data['fallback'] ?? '').toString();

      var opened = false;
      if (deepLink.isNotEmpty) {
        final uri = Uri.parse(deepLink);
        try {
          opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {
          opened = false; // барнома насб нашудааст
        }
      }
      // Барнома насб набошад — ба мағозаи барномаҳо мебарем.
      if (!opened && fallback.isNotEmpty) {
        await launchUrl(Uri.parse(fallback),
            mode: LaunchMode.externalApplication);
      }
    } on DioException catch (e) {
      final d = e.response?.data;
      final msg = (d is Map ? d['error'] : null)?.toString();
      messenger.showSnackBar(SnackBar(
          content: Text(msg ?? 'Гузариш нашуд. Дубора кӯшиш кунед'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Гузариш нашуд. Дубора кӯшиш кунед'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return FadeSlideIn(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.14),
              AppColors.primary.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: PressableScale(
          onTap: _busy ? null : _open,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle),
                child: const Icon(FeatherIcons.grid,
                    color: Colors.white, size: 21),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ба Raonson гузаред',
                          style: TextStyle(
                              color: pal.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text('Ҳамон ҳисоб — парол лозим нест',
                          style: TextStyle(
                              color: pal.textMuted, fontSize: 12, height: 1.3)),
                    ]),
              ),
              if (_busy)
                const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2.2))
              else
                const Icon(FeatherIcons.externalLink,
                    color: AppColors.primary, size: 19),
            ]),
          ),
        ),
      ),
    );
  }
}
