import 'package:cached_network_image/cached_network_image.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/app_l10n.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/profile_l10n.dart';
import '../../core/l10n/stock_l10n.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/seller_provider.dart';
import '../../shared/widgets/fade_slide_in.dart';

/// Маҳсулоти тамомшуда — «боз ҳаст?»
///
/// Пештар маҳсулоти тамомшуда дар барнома ҳамчун «Тамом шуд» мемонд ва
/// касе онро нест намекард. Акнун ҳамин ки захира ба сифр мерасад,
/// фурӯшанда огоҳӣ мегирад ва ин ҷо ду ҷавоб дорад:
///
///   • «Ҳа, боз ҳаст» → шумораро мегӯяд, маҳсулот ба бозор бармегардад;
///   • «Не, нест кун» → маҳсулот аз барнома нест мешавад.
///
/// Бе ҷавоби фурӯшанда ҳеҷ чиз худ ба худ нест намешавад.
class SoldOutScreen extends ConsumerStatefulWidget {
  const SoldOutScreen({super.key});

  @override
  ConsumerState<SoldOutScreen> createState() => _SoldOutScreenState();
}

class _SoldOutScreenState extends ConsumerState<SoldOutScreen> {
  String? _busy;

  void _refresh() {
    ref.invalidate(soldOutProductsProvider);
    ref.invalidate(sellerStatsProvider);
  }

  Future<void> _restock(Map<String, dynamic> p) async {
    final l = AppL10n.of(context);
    final ctrl = TextEditingController(text: '10');
    final qty = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.pal.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l.soldOutHowMany,
            style: TextStyle(
                color: ctx.pal.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: TextStyle(color: ctx.pal.textPrimary, fontSize: 18),
          decoration: InputDecoration(
            hintText: '10',
            hintStyle: TextStyle(color: ctx.pal.textMuted),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  Text(l.cancel, style: TextStyle(color: ctx.pal.textMuted))),
          TextButton(
              onPressed: () =>
                  Navigator.pop(ctx, int.tryParse(ctrl.text.trim()) ?? 1),
              child: Text(l.soldOutYes,
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (qty == null || !mounted) return;

    final id = (p['id'] ?? '').toString();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = id);
    try {
      await ApiClient.instance.dio
          .post('/products/$id/restock', data: {'stock': qty});
      _refresh();
      messenger.showSnackBar(SnackBar(
          content: Text(l.soldOutBackOnSale),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating));
    } catch (_) {
      messenger.showSnackBar(SnackBar(
          content: Text(l.somethingWentWrong),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _delete(Map<String, dynamic> p) async {
    final l = AppL10n.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.pal.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text((p['title'] ?? '').toString(),
            style: TextStyle(
                color: ctx.pal.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        content: Text(l.soldOutDeleteConfirm,
            style: TextStyle(color: ctx.pal.textSecondary, fontSize: 13.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  Text(l.cancel, style: TextStyle(color: ctx.pal.textMuted))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.soldOutNo,
                  style: const TextStyle(
                      color: AppColors.error, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final id = (p['id'] ?? '').toString();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = id);
    try {
      await ApiClient.instance.dio.delete('/products/$id');
      _refresh();
      messenger.showSnackBar(SnackBar(
          content: Text(l.soldOutDeleted),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating));
    } catch (_) {
      messenger.showSnackBar(SnackBar(
          content: Text(l.somethingWentWrong),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final l = AppL10n.of(context);
    final async = ref.watch(soldOutProductsProvider);

    return Scaffold(
      backgroundColor: pal.scaffold,
      appBar: AppBar(
        backgroundColor: pal.scaffold,
        elevation: 0,
        iconTheme: IconThemeData(color: pal.textPrimary),
        title: Text(l.soldOutTitle,
            style: TextStyle(
                color: pal.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17)),
      ),
      body: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => Center(
            child: Text(l.soldOutEmpty,
                style: TextStyle(color: pal.textMuted, fontSize: 13))),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 84,
                  height: 84,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(FeatherIcons.checkCircle,
                      color: AppColors.success, size: 34),
                ),
                const SizedBox(height: 16),
                Text(l.soldOutEmpty,
                    style: TextStyle(
                        color: pal.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ]),
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => _refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.32)),
                  ),
                  child: Row(children: [
                    const Icon(FeatherIcons.alertCircle,
                        color: AppColors.warning, size: 19),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.soldOutCount(list.length),
                                style: TextStyle(
                                    color: pal.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 3),
                            Text(l.soldOutHint,
                                style: TextStyle(
                                    color: pal.textMuted,
                                    fontSize: 11.5,
                                    height: 1.3)),
                          ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 14),
                for (var i = 0; i < list.length; i++)
                  FadeSlideIn(
                    delay: Duration(milliseconds: 45 * i),
                    child: _card(pal, l, list[i]),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _card(AppPalette pal, AppL10n l, Map<String, dynamic> p) {
    final id = (p['id'] ?? '').toString();
    final title = (p['title'] ?? '').toString();
    final image = (p['image'] ?? '').toString();
    final price = (p['price'] as num?)?.toDouble() ?? 0;
    final busy = _busy == id;

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: pal.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: image.isEmpty
                ? Container(
                    width: 58,
                    height: 58,
                    color: pal.surface,
                    child: Icon(FeatherIcons.package,
                        color: pal.textMuted, size: 22))
                : CachedNetworkImage(
                    imageUrl: image,
                    width: 58,
                    height: 58,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(width: 58, height: 58, color: pal.surface),
                    errorWidget: (_, __, ___) => Container(
                        width: 58,
                        height: 58,
                        color: pal.surface,
                        child: Icon(FeatherIcons.package,
                            color: pal.textMuted, size: 22)),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.isEmpty ? '—' : title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: pal.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text('${price.toStringAsFixed(0)} сом.',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ]),
          ),
        ]),
        const SizedBox(height: 12),
        Text(l.soldOutQuestion,
            style: TextStyle(
                color: pal.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 9),
        Row(children: [
          Expanded(
            child: PressableScale(
              onTap: busy ? null : () => _delete(p),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.error.withValues(alpha: 0.32)),
                ),
                child: Center(
                  child: Text(l.soldOutNo,
                      style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: PressableScale(
              onTap: busy ? null : () => _restock(p),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.2))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(FeatherIcons.refreshCw,
                                color: Colors.white, size: 15),
                            const SizedBox(width: 7),
                            Text(l.soldOutYes,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700)),
                          ]),
                ),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}
