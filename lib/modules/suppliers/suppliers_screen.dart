import 'package:cached_network_image/cached_network_image.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/app_l10n.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/suppliers_l10n.dart';
import '../../core/theme/app_palette.dart';
import '../../shared/widgets/fade_slide_in.dart';
import 'supplier_profile_screen.dart';

/// Таъминкунандагон бо филтр.
///
/// `(verified, region, query)` ҳамчун калид: ҳар тағйири филтр дархости
/// нав месозад ва Riverpod кӯҳнаро худаш мепартояд.
final suppliersProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, key) async {
  final parts = key.split('|');
  final res = await ApiClient.instance.dio.get('/suppliers', queryParameters: {
    if (parts[0] == '1') 'verified': '1',
    if (parts.length > 1 && parts[1].isNotEmpty) 'region': parts[1],
    if (parts.length > 2 && parts[2].isNotEmpty) 'q': parts[2],
    'limit': 60,
  });
  final raw = res.data;
  final data = raw is Map ? raw['data'] : raw;
  if (data is! List) return const [];
  return data
      .whereType<Map>()
      .map((m) => m.cast<String, dynamic>())
      .toList();
});

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});
  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  bool _onlyVerified = false;
  String _region = '';
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _key => '${_onlyVerified ? 1 : 0}|$_region|$_query';

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final l = AppL10n.of(context);
    final async = ref.watch(suppliersProvider(_key));

    return Scaffold(
      backgroundColor: pal.scaffold,
      appBar: AppBar(
        backgroundColor: pal.scaffold,
        elevation: 0,
        iconTheme: IconThemeData(color: pal.textPrimary),
        title: Text(l.supTitle,
            style: TextStyle(
                color: pal.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17)),
      ),
      body: Column(children: [
        _filters(pal, l),
        Expanded(
          child: async.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
            error: (_, __) => _empty(pal, l),
            data: (list) {
              if (list.isEmpty) return _empty(pal, l);
              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async =>
                    ref.invalidate(suppliersProvider(_key)),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Text(l.supExplain,
                          style: TextStyle(
                              color: pal.textMuted,
                              fontSize: 12.5,
                              height: 1.35)),
                    ),
                    for (var i = 0; i < list.length; i++)
                      FadeSlideIn(
                        delay: Duration(milliseconds: 35 * i),
                        child: _card(pal, l, list[i]),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _filters(AppPalette pal, AppL10n l) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        child: Column(children: [
          TextField(
            controller: _search,
            style: TextStyle(color: pal.textPrimary, fontSize: 14),
            onSubmitted: (v) => setState(() => _query = v.trim()),
            decoration: InputDecoration(
              hintText: l.supSearchHint,
              hintStyle: TextStyle(color: pal.textMuted, fontSize: 13),
              prefixIcon:
                  Icon(FeatherIcons.search, size: 17, color: pal.textMuted),
              isDense: true,
              filled: true,
              fillColor: pal.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: pal.border, width: 0.6)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: pal.border, width: 0.6)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.3)),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            GestureDetector(
              onTap: () => setState(() => _onlyVerified = !_onlyVerified),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: _onlyVerified
                      ? AppColors.info.withValues(alpha: 0.13)
                      : pal.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _onlyVerified ? AppColors.info : pal.border,
                      width: _onlyVerified ? 1.3 : 0.6),
                ),
                child: Row(children: [
                  Icon(
                      _onlyVerified
                          ? FeatherIcons.checkCircle
                          : FeatherIcons.circle,
                      size: 14,
                      color: _onlyVerified ? AppColors.info : pal.textMuted),
                  const SizedBox(width: 7),
                  Text(l.supOnlyVerified,
                      style: TextStyle(
                          color: _onlyVerified ? AppColors.info : pal.textMuted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
        ]),
      );

  Widget _empty(AppPalette pal, AppL10n l) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(FeatherIcons.briefcase,
                  color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 16),
            Text(l.supEmpty,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: pal.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
      );

  Widget _card(AppPalette pal, AppL10n l, Map<String, dynamic> s) {
    final ver = (s['verified'] is Map)
        ? (s['verified'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final self = (s['self_reported'] is Map)
        ? (s['self_reported'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};

    final name = (s['name'] ?? '—').toString();
    final avatar = (s['avatar_url'] ?? '').toString();
    final badge = ver['badge'] == true;
    final products = (s['products'] as num?)?.toInt() ?? 0;
    final done = (ver['orders_completed'] as num?)?.toInt() ?? 0;
    final rate = (ver['completion_rate'] as num?)?.toInt();
    final rating = (ver['rating'] as num?)?.toDouble();
    final ratingCount = (ver['rating_count'] as num?)?.toInt() ?? 0;
    final region = (self['region'] ?? '').toString();

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              SupplierProfileScreen(supplierId: (s['id'] ?? '').toString()))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: pal.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: pal.border, width: 0.6),
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: avatar.isEmpty
                ? Container(
                    width: 52,
                    height: 52,
                    color: pal.surface,
                    alignment: Alignment.center,
                    child: Icon(FeatherIcons.briefcase,
                        color: pal.textMuted, size: 20))
                : CachedNetworkImage(
                    imageUrl: avatar,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                        width: 52,
                        height: 52,
                        color: pal.surface,
                        alignment: Alignment.center,
                        child: Icon(FeatherIcons.briefcase,
                            color: pal.textMuted, size: 20)),
                  ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: pal.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700)),
                ),
                if (badge) ...[
                  const SizedBox(width: 6),
                  const Icon(FeatherIcons.checkCircle,
                      size: 14, color: AppColors.info),
                ],
              ]),
              const SizedBox(height: 5),
              // Рақамҳои тасдиқшуда.
              Wrap(spacing: 10, runSpacing: 3, children: [
                _stat(pal, FeatherIcons.package, l.supProducts(products)),
                if (done > 0)
                  _stat(pal, FeatherIcons.checkSquare, l.supOrdersDone(done)),
                if (rate != null)
                  _stat(pal, FeatherIcons.trendingUp,
                      l.supCompletionRate(rate), AppColors.success),
                if (rating != null)
                  _stat(pal, FeatherIcons.star,
                      l.supRating(rating.toStringAsFixed(1), ratingCount),
                      AppColors.warning),
              ]),
              // Минтақа — аз ГУФТАИ фурӯшанда, бо нишонаи дигар.
              if (region.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(children: [
                  Icon(FeatherIcons.mapPin, size: 11, color: pal.textMuted),
                  const SizedBox(width: 5),
                  Text('$region · ${l.supSelfReported}',
                      style: TextStyle(
                          color: pal.textMuted,
                          fontSize: 11,
                          fontStyle: FontStyle.italic)),
                ]),
              ],
            ]),
          ),
          Icon(FeatherIcons.chevronRight, size: 16, color: pal.textMuted),
        ]),
      ),
    );
  }

  Widget _stat(AppPalette pal, IconData icon, String text, [Color? color]) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11.5, color: color ?? pal.textMuted),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
                color: color ?? pal.textMuted,
                fontSize: 11.5,
                fontWeight: color != null ? FontWeight.w700 : FontWeight.w500)),
      ]);
}
