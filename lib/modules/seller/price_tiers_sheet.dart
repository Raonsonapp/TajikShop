import 'package:dio/dio.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api/api_client.dart';
import '../../core/app_l10n.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/checkout_l10n.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/price_tier.dart';
import '../../shared/widgets/app_button.dart';

/// Муҳаррири зинаҳои нархи яклухт.
///
/// Бе ин экран тамоми хусусияти зинаҳо бефоида буд: фурӯшанда роҳе
/// надошт онҳоро гузорад.
///
/// Сервер қоидаҳоро месанҷад (`price_tiers.go`), вале онҳо ҳамин ҷо низ
/// санҷида мешаванд — то фурӯшанда хаторо ФАВРАН бинад, на баъди
/// фиристодан.
Future<bool?> showPriceTiersSheet(BuildContext context,
    {required String productId, required double retailPrice}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PriceTiersSheet(
      productId: productId,
      retailPrice: retailPrice,
    ),
  );
}

class _TierDraft {
  final TextEditingController qty;
  final TextEditingController price;
  _TierDraft({String q = '', String p = ''})
      : qty = TextEditingController(text: q),
        price = TextEditingController(text: p);
  void dispose() {
    qty.dispose();
    price.dispose();
  }
}

class _PriceTiersSheet extends StatefulWidget {
  final String productId;
  final double retailPrice;
  const _PriceTiersSheet({required this.productId, required this.retailPrice});

  @override
  State<_PriceTiersSheet> createState() => _PriceTiersSheetState();
}

class _PriceTiersSheetState extends State<_PriceTiersSheet> {
  final List<_TierDraft> _drafts = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final d in _drafts) {
      d.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient.instance.dio
          .get('/products/${widget.productId}/tiers');
      final raw = res.data;
      final data = raw is Map ? raw['data'] : raw;
      if (data is List) {
        for (final e in data) {
          if (e is! Map) continue;
          final t = PriceTier.fromJson(e.cast<String, dynamic>());
          _drafts.add(_TierDraft(
              q: '${t.minQty}', p: t.price.toStringAsFixed(0)));
        }
      }
    } catch (_) {
      // Зина набудан хато нест — холӣ сар мекунем.
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Ҳамон қоидаҳои сервер, вале ин ҷо фавран.
  ///
  /// Қоидаи «зинаи калонтар бояд арзонтар бошад» аз мантиқи савдо меояд:
  /// харидори ЯКЛУХТ набояд БЕШТАР пардозад. Ин қариб ҳамеша хатои
  /// хаттӣ аст.
  String? _validate(List<PriceTier> tiers) {
    final l = AppL10n.of(context);
    final seen = <int>{};
    for (final t in tiers) {
      if (t.minQty < 2) return l.tierErrMinQty;
      if (t.price <= 0) return l.tierErrPrice;
      if (t.price >= widget.retailPrice) return l.tierErrAboveRetail;
      if (!seen.add(t.minQty)) return l.tierErrDuplicate;
    }
    final sorted = [...tiers]..sort((a, b) => a.minQty.compareTo(b.minQty));
    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i].price > sorted[i - 1].price) return l.tierErrIncreasing;
    }
    return null;
  }

  List<PriceTier>? _collect() {
    final out = <PriceTier>[];
    for (final d in _drafts) {
      final q = int.tryParse(d.qty.text.trim());
      final p = double.tryParse(d.price.text.trim().replaceAll(',', '.'));
      // Сатри тамоман холӣ — нодида (фурӯшанда зина илова карда, баъд
      // фикрашро иваз кард).
      if (d.qty.text.trim().isEmpty && d.price.text.trim().isEmpty) continue;
      if (q == null || p == null) return null;
      out.add(PriceTier(minQty: q, price: p));
    }
    return out;
  }

  Future<void> _save() async {
    final l = AppL10n.of(context);
    final tiers = _collect();
    if (tiers == null) {
      setState(() => _error = l.tierErrPrice);
      return;
    }
    final msg = _validate(tiers);
    if (msg != null) {
      setState(() => _error = msg);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ApiClient.instance.dio.put(
        '/products/${widget.productId}/tiers',
        data: {
          'tiers': [
            for (final t in tiers) {'min_qty': t.minQty, 'price': t.price},
          ],
        },
      );
      if (mounted) Navigator.of(context).pop(true);
    } on DioException catch (e) {
      final d = e.response?.data;
      setState(() {
        _saving = false;
        _error = (d is Map ? d['error']?.toString() : null) ?? l.tierSaveError;
      });
    } catch (_) {
      if (mounted) setState(() {
        _saving = false;
        _error = l.tierSaveError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final l = AppL10n.of(context);

    return Container(
      padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: pal.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 18),
          Row(children: [
            const Icon(FeatherIcons.layers, color: AppColors.primary, size: 19),
            const SizedBox(width: 10),
            Expanded(
              child: Text(l.tiersTitle,
                  style: TextStyle(
                      color: pal.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(l.tiersHint(widget.retailPrice),
                style: TextStyle(color: pal.textMuted, fontSize: 12.5, height: 1.35)),
          ),
          const SizedBox(height: 16),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          else ...[
            for (var i = 0; i < _drafts.length; i++) _row(pal, l, i),
            const SizedBox(height: 4),
            // Зиёда аз 10 зина сервер рад мекунад — тугмаро пинҳон мекунем,
            // то фурӯшанда ба деворе нарасад.
            if (_drafts.length < 10)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _drafts.add(_TierDraft())),
                  icon: const Icon(FeatherIcons.plus,
                      size: 16, color: AppColors.primary),
                  label: Text(l.tierAdd,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5)),
                ),
              ),
          ],

          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 2),
              child: Row(children: [
                const Icon(FeatherIcons.alertCircle,
                    color: AppColors.error, size: 15),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(_error!,
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 12.5)),
                ),
              ]),
            ),

          const SizedBox(height: 14),
          AppButton(text: l.save, onTap: _save, isLoading: _saving),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _row(AppPalette pal, AppL10n l, int i) {
    final d = _drafts[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Expanded(
          flex: 4,
          child: _numField(pal, d.qty, l.tierQtyField, decimal: false),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 5,
          child: _numField(pal, d.price, '${l.price} (${l.som})', decimal: true),
        ),
        IconButton(
          onPressed: () => setState(() {
            _drafts.removeAt(i).dispose();
            _error = null;
          }),
          icon: const Icon(FeatherIcons.x, color: AppColors.error, size: 18),
          tooltip: l.tierRemove,
        ),
      ]),
    );
  }

  Widget _numField(AppPalette pal, TextEditingController c, String hint,
      {required bool decimal}) {
    return TextField(
      controller: c,
      keyboardType: decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      inputFormatters: [
        // Танҳо рақам (ва нуқта барои нарх) — то «10 дона» ё «abc»
        // ба сервер нарасад.
        FilteringTextInputFormatter.allow(
            decimal ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]')),
        LengthLimitingTextInputFormatter(decimal ? 12 : 6),
      ],
      style: TextStyle(color: pal.textPrimary, fontSize: 14),
      onChanged: (_) {
        if (_error != null) setState(() => _error = null);
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: pal.textMuted, fontSize: 13),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
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
            borderSide: const BorderSide(color: AppColors.primary, width: 1.3)),
      ),
    );
  }
}
