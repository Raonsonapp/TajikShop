import 'package:dio/dio.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api/api_client.dart';
import '../../core/app_l10n.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/rfq_l10n.dart';
import '../../core/theme/app_palette.dart';
import '../../shared/widgets/app_button.dart';

/// Пешниҳоди нарх аз ҷониби фурӯшанда.
Future<bool?> showRFQQuoteSheet(BuildContext context,
        {required String rfqId, required int quantity, required String unit}) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _RFQQuoteSheet(rfqId: rfqId, quantity: quantity, unit: unit),
    );

class _RFQQuoteSheet extends StatefulWidget {
  final String rfqId;
  final int quantity;
  final String unit;
  const _RFQQuoteSheet(
      {required this.rfqId, required this.quantity, required this.unit});

  @override
  State<_RFQQuoteSheet> createState() => _RFQQuoteSheetState();
}

class _RFQQuoteSheetState extends State<_RFQQuoteSheet> {
  final _price = TextEditingController();
  final _shipping = TextEditingController();
  final _minQty = TextEditingController();
  final _leadDays = TextEditingController();
  final _terms = TextEditingController();
  final _note = TextEditingController();
  int _validDays = 7;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _price.dispose();
    _shipping.dispose();
    _minQty.dispose();
    _leadDays.dispose();
    _terms.dispose();
    _note.dispose();
    super.dispose();
  }

  double get _unitPrice =>
      double.tryParse(_price.text.trim().replaceAll(',', '.')) ?? 0;
  double get _shipCost =>
      double.tryParse(_shipping.text.trim().replaceAll(',', '.')) ?? 0;

  /// Ҷамъ — ҳамон тавре, ки сервер ҳисоб мекунад
  /// (`quoteTotal` дар `rfq_logic.go`).
  ///
  /// Фурӯшанда бояд ҶАМЪро фавран бинад: харидор маҳз аз рӯи он муқоиса
  /// мекунад, на аз рӯи нархи як дона.
  double get _total => _unitPrice * widget.quantity + _shipCost;

  Future<void> _submit() async {
    final l = AppL10n.of(context);
    if (_unitPrice <= 0) {
      setState(() => _error = l.rfqUnitPrice);
      return;
    }
    final minQty = int.tryParse(_minQty.text.trim()) ?? 1;
    if (minQty > widget.quantity) {
      setState(() => _error = l.rfqMinQty);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ApiClient.instance.dio.post('/rfqs/${widget.rfqId}/quotes', data: {
        'unit_price': _unitPrice,
        'shipping_cost': _shipCost,
        'min_qty': minQty,
        'lead_days': int.tryParse(_leadDays.text.trim()) ?? 0,
        'payment_terms': _terms.text.trim(),
        'note': _note.text.trim(),
        'valid_days': _validDays,
      });
      if (mounted) Navigator.of(context).pop(true);
    } on DioException catch (e) {
      final d = e.response?.data;
      setState(() {
        _saving = false;
        // Паёми сервер — он мегӯяд КАДОМ қоида халал расонд.
        _error = (d is Map ? d['error']?.toString() : null) ?? l.rfqSendQuote;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = l.rfqSendQuote;
        });
      }
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
            const Icon(FeatherIcons.tag, color: AppColors.primary, size: 19),
            const SizedBox(width: 10),
            Expanded(
              child: Text(l.rfqSendQuote,
                  style: TextStyle(
                      color: pal.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('${widget.quantity} ${widget.unit}',
                style: TextStyle(color: pal.textMuted, fontSize: 12.5)),
          ),
          const SizedBox(height: 16),

          _field(pal, _price, l.rfqUnitPrice, decimal: true, maxLen: 12),
          const SizedBox(height: 10),
          _field(pal, _shipping, l.rfqShipping, decimal: true, maxLen: 12),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: _field(pal, _minQty, l.rfqMinQty,
                    digitsOnly: true, maxLen: 8)),
            const SizedBox(width: 10),
            Expanded(
                child: _field(pal, _leadDays, l.rfqLeadDays,
                    digitsOnly: true, maxLen: 3)),
          ]),
          const SizedBox(height: 10),
          _field(pal, _terms, l.rfqPaymentTerms, maxLen: 200),
          const SizedBox(height: 10),
          _field(pal, _note, l.rfqNote, lines: 2, maxLen: 500),
          const SizedBox(height: 16),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(l.rfqValidDays,
                style: TextStyle(color: pal.textMuted, fontSize: 12.5)),
          ),
          const SizedBox(height: 8),
          Row(children: [
            for (final d in [3, 7, 14, 30]) ...[
              Expanded(child: _dayChip(pal, l, d)),
              if (d != 30) const SizedBox(width: 8),
            ],
          ]),

          // Ҷамъ — фурӯшанда бояд онро фавран бинад, чунки харидор маҳз
          // аз рӯи он муқоиса мекунад.
          if (_unitPrice > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.24)),
              ),
              child: Row(children: [
                const Icon(FeatherIcons.dollarSign,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(l.rfqTotal,
                      style: TextStyle(color: pal.textPrimary, fontSize: 13)),
                ),
                Text('${_total.toStringAsFixed(0)} сом.',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
              ]),
            ),
          ],

          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
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

          const SizedBox(height: 18),
          AppButton(text: l.rfqSendQuote, onTap: _submit, isLoading: _saving),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _dayChip(AppPalette pal, AppL10n l, int d) {
    final active = _validDays == d;
    return GestureDetector(
      onTap: () => setState(() => _validDays = d),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color:
              active ? AppColors.primary.withValues(alpha: 0.13) : pal.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: active ? AppColors.primary : pal.border,
              width: active ? 1.3 : 0.6),
        ),
        child: Text(l.rfqDays(d),
            style: TextStyle(
                color: active ? AppColors.primary : pal.textMuted,
                fontSize: 12.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
      ),
    );
  }

  Widget _field(AppPalette pal, TextEditingController c, String hint,
      {int lines = 1,
      bool digitsOnly = false,
      bool decimal = false,
      required int maxLen}) {
    return TextField(
      controller: c,
      maxLines: lines,
      keyboardType: digitsOnly
          ? TextInputType.number
          : (decimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text),
      inputFormatters: [
        if (digitsOnly) FilteringTextInputFormatter.digitsOnly,
        if (decimal) FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        LengthLimitingTextInputFormatter(maxLen),
      ],
      style: TextStyle(color: pal.textPrimary, fontSize: 14),
      onChanged: (_) => setState(() => _error = null),
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
