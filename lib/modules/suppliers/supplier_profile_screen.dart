import 'package:cached_network_image/cached_network_image.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/app_l10n.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/suppliers_l10n.dart';
import '../../core/theme/app_palette.dart';
import '../../shared/widgets/fade_slide_in.dart';

final supplierProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, id) async {
  final res = await ApiClient.instance.dio.get('/suppliers/$id');
  final raw = res.data;
  final data = raw is Map ? (raw['data'] is Map ? raw['data'] : raw) : null;
  return data is Map ? data.cast<String, dynamic>() : <String, dynamic>{};
});

/// Профили таъминкунанда.
///
/// Таҷрибаи муҳими UX ин ҷо: маълумоти ТАСДИҚШУДА ва ДАЪВОИ ФУРӮШАНДА
/// дар ДУ блоки ҷудо, бо сарлавҳаи равшан. Харидор бояд бидонад, кадом
/// рақамро платформа ҳисоб кардааст ва кадом сатрро худи фурӯшанда
/// навиштааст.
class SupplierProfileScreen extends ConsumerWidget {
  final String supplierId;
  const SupplierProfileScreen({super.key, required this.supplierId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pal = context.pal;
    final l = AppL10n.of(context);
    final async = ref.watch(supplierProvider(supplierId));

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
      body: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => Center(
            child: Text(l.supEmpty,
                style: TextStyle(color: pal.textMuted, fontSize: 13))),
        data: (s) => _body(context, pal, l, s),
      ),
    );
  }

  Widget _body(BuildContext context, AppPalette pal, AppL10n l,
      Map<String, dynamic> s) {
    final ver = (s['verified'] is Map)
        ? (s['verified'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final self = (s['self_reported'] is Map)
        ? (s['self_reported'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final wholesale = (s['wholesale'] is List)
        ? (s['wholesale'] as List)
            .whereType<Map>()
            .map((m) => m.cast<String, dynamic>())
            .toList()
        : const <Map<String, dynamic>>[];

    final name = (s['name'] ?? '—').toString();
    final avatar = (s['avatar_url'] ?? '').toString();
    final badge = ver['badge'] == true;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        // ── Сарлавҳа ──
        Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: avatar.isEmpty
                ? Container(
                    width: 68,
                    height: 68,
                    color: pal.surface,
                    alignment: Alignment.center,
                    child: Icon(FeatherIcons.briefcase,
                        color: pal.textMuted, size: 26))
                : CachedNetworkImage(
                    imageUrl: avatar,
                    width: 68,
                    height: 68,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                        width: 68,
                        height: 68,
                        color: pal.surface,
                        alignment: Alignment.center,
                        child: Icon(FeatherIcons.briefcase,
                            color: pal.textMuted, size: 26)),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: pal.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.25)),
              if (badge) ...[
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(FeatherIcons.checkCircle,
                        size: 12, color: AppColors.info),
                    const SizedBox(width: 5),
                    Text(l.supVerifiedBadge,
                        style: const TextStyle(
                            color: AppColors.info,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
              ],
            ]),
          ),
        ]),
        const SizedBox(height: 18),

        // ── Блоки 1: МАЪЛУМОТИ ТАСДИҚШУДА ──
        _block(
          pal,
          icon: FeatherIcons.shield,
          color: AppColors.success,
          title: l.supVerifiedData,
          children: [
            _line(pal, l.supProducts((s['products'] as num?)?.toInt() ?? 0)),
            _line(pal,
                l.supOrdersDone((ver['orders_completed'] as num?)?.toInt() ?? 0)),
            if (ver['completion_rate'] != null)
              _line(pal,
                  l.supCompletionRate((ver['completion_rate'] as num).toInt()),
                  bold: true)
            else
              // Чаро фоиз нест — инро гуфтан лозим аст, вагарна харидор
              // фикр мекунад, ки маълумот гум шуд.
              _line(pal, l.supNotEnoughOrders, muted: true),
            if (ver['rating'] != null)
              _line(
                  pal,
                  l.supRating(
                      (ver['rating'] as num).toStringAsFixed(1),
                      (ver['rating_count'] as num?)?.toInt() ?? 0)),
            if (ver['seller_since'] != null)
              _line(pal, l.supSince(ver['seller_since'].toString())),
          ],
        ),
        const SizedBox(height: 12),

        // ── Блоки 2: АЗ ГУФТАИ ФУРӮШАНДА ──
        //
        // Ҷудо ва бо ранги дигар. Ҳамин ҷойест, ки платформаҳо одатан
        // фиреб мекунанд: даъвои фурӯшанда ҳамчун маълумоти тасдиқшуда
        // нишон дода мешавад.
        if ((self['description'] ?? '').toString().isNotEmpty ||
            (self['region'] ?? '').toString().isNotEmpty)
          _block(
            pal,
            icon: FeatherIcons.messageCircle,
            color: pal.textMuted,
            title: l.supSelfReported,
            italic: true,
            children: [
              if ((self['region'] ?? '').toString().isNotEmpty)
                _line(pal, self['region'].toString(), muted: true),
              if ((self['description'] ?? '').toString().isNotEmpty)
                _line(pal, self['description'].toString(), muted: true),
            ],
          ),
        const SizedBox(height: 18),

        // ── Молҳои яклухт ──
        Row(children: [
          Icon(FeatherIcons.layers, size: 15, color: pal.textMuted),
          const SizedBox(width: 8),
          Text(l.supWholesaleItems,
              style: TextStyle(
                  color: pal.textMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 10),
        if (wholesale.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(l.supNoWholesale,
                style: TextStyle(color: pal.textMuted, fontSize: 13)),
          )
        else
          for (var i = 0; i < wholesale.length; i++)
            FadeSlideIn(
              delay: Duration(milliseconds: 30 * i),
              child: _item(context, pal, l, wholesale[i]),
            ),
      ],
    );
  }

  Widget _block(AppPalette pal,
          {required IconData icon,
          required Color color,
          required String title,
          required List<Widget> children,
          bool italic = false}) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: pal.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.28), width: 0.9),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(
                    color: color,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    fontStyle: italic ? FontStyle.italic : FontStyle.normal)),
          ]),
          const SizedBox(height: 9),
          ...children,
        ]),
      );

  Widget _line(AppPalette pal, String text,
          {bool bold = false, bool muted = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text,
            style: TextStyle(
                color: muted ? pal.textMuted : pal.textPrimary,
                fontSize: 13,
                height: 1.35,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
      );

  Widget _item(BuildContext context, AppPalette pal, AppL10n l,
      Map<String, dynamic> p) {
    final image = (p['image'] ?? '').toString();
    final price = (p['price'] as num?)?.toDouble() ?? 0;
    final from = (p['wholesale_from'] as num?)?.toDouble();
    final fromQty = (p['wholesale_min_qty'] as num?)?.toInt();

    return GestureDetector(
      onTap: () => context.push('/product/${p['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: pal.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: pal.border, width: 0.6),
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: image.isEmpty
                ? Container(
                    width: 48,
                    height: 48,
                    color: pal.surface,
                    alignment: Alignment.center,
                    child: Icon(FeatherIcons.package,
                        color: pal.textMuted, size: 18))
                : CachedNetworkImage(
                    imageUrl: image,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                        width: 48,
                        height: 48,
                        color: pal.surface,
                        alignment: Alignment.center,
                        child: Icon(FeatherIcons.package,
                            color: pal.textMuted, size: 18)),
                  ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((p['title'] ?? '—').toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: pal.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text('${price.toStringAsFixed(0)} сом.',
                  style: TextStyle(color: pal.textMuted, fontSize: 12)),
              if (from != null && fromQty != null)
                Text(l.supWholesaleFrom(from.toStringAsFixed(0), fromQty),
                    style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700)),
            ]),
          ),
          Icon(FeatherIcons.chevronRight, size: 15, color: pal.textMuted),
        ]),
      ),
    );
  }
}
