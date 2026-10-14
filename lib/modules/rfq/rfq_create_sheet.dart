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

/// Сохтани дархости нарх.
Future<bool?> showRFQCreateSheet(BuildContext context) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _RFQCreateSheet(),
    );

/// Воҳидҳо — ҳамон рӯйхати сервер (`normalizeUnit` дар `catalog.go`).
///
/// Агар ин ҷо воҳиди дигар бошад, сервер онро ба «дона» иваз мекунад ва
/// корбар намефаҳмад, ки чаро «кг»-и ӯ гум шуд.
const _units = ['дона', 'кг', 'грамм', 'литр', 'мл', 'баста', 'қуттӣ', 'халта'];

class _RFQCreateSheet extends StatefulWidget {
  const _RFQCreateSheet();
  @override
  State<_RFQCreateSheet> createState() => _RFQCreateSheetState();
}

class _RFQCreateSheetState extends State<_RFQCreateSheet> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _qty = TextEditingController();
  final _target = TextEditingController();
  final _dest = TextEditingController();
  String _unit = 'дона';
  int _days = 7;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _qty.dispose();
    _target.dispose();
    _dest.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppL10n.of(context);
    final title = _title.text.trim();
    final qty = int.tryParse(_qty.text.trim()) ?? 0;

    // Санҷиши фаврӣ — ҳамон қоидаҳои сервер, вале корбар хаторо пеш аз
    // фиристодан мебинад.
    if (title.length < 3) {
      setState(() => _error = l.rfqWhatNeeded);
      return;
    }
    if (qty < 1) {
      setState(() => _error = l.rfqQuantity);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ApiClient.instance.dio.post('/rfqs', data: {
        'title': title,
        'description': _desc.text.trim(),
        'quantity': qty,
        'unit': _unit,
        'target_price':
            double.tryParse(_target.text.trim().replaceAll(',', '.')) ?? 0,
        'destination': _dest.text.trim(),
        'days': _days,
      });
      if (mounted) Navigator.of(context).pop(true);
    } on DioException catch (e) {
      final d = e.response?.data;
      setState(() {
        _saving = false;
        _error = (d is Map ? d['error']?.toString() : null) ?? l.rfqTitle;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = l.rfqTitle;
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
            const Icon(FeatherIcons.fileText,
                color: AppColors.primary, size: 19),
            const SizedBox(width: 10),
            Expanded(
              child: Text(l.rfqNew,
                  style: TextStyle(
                      color: pal.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(l.rfqExplain,
                style: TextStyle(color: pal.textMuted, fontSize: 12.5, height: 1.35)),
          ),
          const SizedBox(height: 16),

          _field(pal, _title, l.rfqWhatNeeded, maxLen: 200),
          const SizedBox(height: 10),
          _field(pal, _desc, l.rfqDetails, lines: 3, maxLen: 1000),
          const SizedBox(height: 10),

          Row(children: [
            Expanded(
              flex: 5,
              child: _field(pal, _qty, l.rfqQuantity,
                  digitsOnly: true, maxLen: 8),
            ),
            const SizedBox(width: 10),
            Expanded(flex: 4, child: _unitPicker(pal)),
          ]),
          const SizedBox(height: 10),

          _field(pal, _target, l.rfqTargetPrice, decimal: true, maxLen: 12),
          const SizedBox(height: 10),
          _field(pal, _dest, l.rfqDestination, maxLen: 200),
          const SizedBox(height: 16),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(l.rfqOpenFor,
                style: TextStyle(color: pal.textMuted, fontSize: 12.5)),
          ),
          const SizedBox(height: 8),
          Row(children: [
            for (final d in [3, 7, 14, 30]) ...[
              Expanded(child: _dayChip(pal, l, d)),
              if (d != 30) const SizedBox(width: 8),
            ],
          ]),

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
          // ⚠️ Калид барои тести эмулятор ҲАТМИСТ.
          //
          // Матни `l.rfqNew` дар СЕ ҷой истифода мешавад: тугмаи
          // шиновари рӯйхат, сарлавҳаи ҳамин варақа, ва ҳамин тугма.
          // `find.textContaining(...).first` тугмаи ПАСИ варақаро
          // мегирифт, ва Flutter огоҳӣ медод:
          //
          //   derived an Offset (300.3, 557.8) that would not hit test
          //   on the specified widget
          //
          // Зеркунӣ тасодуфан ба чизи дигари ҳамон нуқта мерасид — тест
          // аз рӯи БАХТ мегузашт. Калид ин тасодуфро мебандад.
          AppButton(
              key: const Key('rfq_submit'),
              text: l.rfqNew,
              onTap: _submit,
              isLoading: _saving),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _dayChip(AppPalette pal, AppL10n l, int d) {
    final active = _days == d;
    return GestureDetector(
      onTap: () => setState(() => _days = d),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.13)
              : pal.surface,
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

  Widget _unitPicker(AppPalette pal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: pal.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: pal.border, width: 0.6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _unit,
          isExpanded: true,
          dropdownColor: pal.card,
          icon: Icon(FeatherIcons.chevronDown, size: 16, color: pal.textMuted),
          style: TextStyle(color: pal.textPrimary, fontSize: 14),
          items: [
            for (final u in _units)
              DropdownMenuItem(value: u, child: Text(u)),
          ],
          onChanged: (v) => setState(() => _unit = v ?? 'дона'),
        ),
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
