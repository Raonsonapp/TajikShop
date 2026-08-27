import 'package:dio/dio.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/seller_provider.dart';
import '../../shared/widgets/fade_slide_in.dart';

/// Тасдиқи пардохт аз SMS-и бонк.
///
/// Чаро матн ба ҷои хондани SMS-и телефон:
///   • Android иҷозати SMS-ро банк ба банк ҷудо карда наметавонад —
///     `READ_SMS` ҳамаи паёмҳоро мекушояд;
///   • Google Play онро танҳо ба барномаи SMS-и пешфарз медиҳад, пас
///     барномаи савдо бо он рад мешавад.
///
/// Роҳи кор: фурӯшанда SMS-и бонкро нусха мебардорад (ё Share мекунад),
/// ин ҷо мегузорад — сервер маблағро мехонад, фармоиши мувофиқро меёбад ва
/// худкор тасдиқ мекунад. Харидор фавран огоҳӣ мегирад.
class ConfirmPaymentScreen extends ConsumerStatefulWidget {
  const ConfirmPaymentScreen({super.key});

  @override
  ConsumerState<ConfirmPaymentScreen> createState() =>
      _ConfirmPaymentScreenState();
}

class _ConfirmPaymentScreenState extends ConsumerState<ConfirmPaymentScreen> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) return;
    setState(() {
      _ctrl.text = text;
      _error = null;
      _result = null;
    });
  }

  Future<void> _confirm() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Матни SMS-ро гузоред');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final res = await ApiClient.instance.dio
          .post('/seller/payments/confirm-sms', data: {'text': text});
      final raw = res.data;
      final data = raw is Map ? (raw['data'] is Map ? raw['data'] : raw) : {};
      if (!mounted) return;
      setState(() => _result = Map<String, dynamic>.from(data as Map));
      ref.invalidate(sellerOrdersProvider);
    } on DioException catch (e) {
      // Паёми сервер дақиқ мегӯяд чаро мувофиқ наомад — ҳамонро нишон медиҳем.
      final d = e.response?.data;
      final msg = (d is Map ? d['error'] : null)?.toString();
      if (mounted) {
        setState(() => _error = msg ?? 'Тасдиқ нашуд. Дубора кӯшиш кунед.');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Тасдиқ нашуд. Дубора кӯшиш кунед.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Scaffold(
      backgroundColor: pal.scaffold,
      appBar: AppBar(
        backgroundColor: pal.scaffold,
        elevation: 0,
        iconTheme: IconThemeData(color: pal.textPrimary),
        title: Text('Тасдиқи пардохт',
            style: TextStyle(
                color: pal.textPrimary, fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        FadeSlideIn(
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(FeatherIcons.zap,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text('Чӣ тавр кор мекунад',
                        style: TextStyle(
                            color: pal.textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: 10),
                  _step(pal, '1', 'SMS-и бонкро нусха бардоред'),
                  _step(pal, '2', 'Дар ин ҷо гузоред ва «Тасдиқ» кунед'),
                  _step(pal, '3',
                      'Барнома маблағро мехонад ва фармоишро худаш меёбад'),
                  const SizedBox(height: 6),
                  Text(
                      'Барнома SMS-ҳои шуморо намехонад — танҳо ҳамин матнеро, '
                      'ки худатон мегузоред.',
                      style: TextStyle(color: pal.textMuted, fontSize: 11.5)),
                ]),
          ),
        ),
        const SizedBox(height: 20),

        Text('Матни SMS-и бонк',
            style: TextStyle(
                color: pal.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: pal.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: pal.border, width: 0.8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: TextField(
            controller: _ctrl,
            maxLines: 5,
            style: TextStyle(color: pal.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Popolnenie 250.00 TJS. Karta *7344 ...',
              hintStyle: TextStyle(color: pal.textMuted, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: PressableScale(
              onTap: _pasteFromClipboard,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: pal.surface,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: pal.border, width: 0.8),
                ),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(FeatherIcons.clipboard, size: 16, color: pal.textSecondary),
                      const SizedBox(width: 8),
                      Text('Гузоштан',
                          style: TextStyle(
                              color: pal.textSecondary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600)),
                    ]),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: PressableScale(
              onTap: _loading ? null : _confirm,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Center(
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.2))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(FeatherIcons.checkCircle,
                                color: Colors.white, size: 16),
                            SizedBox(width: 8),
                            Text('Тасдиқи пардохт',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                          ]),
                ),
              ),
            ),
          ),
        ]),

        if (_error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
            ),
            child: Row(children: [
              const Icon(FeatherIcons.alertCircle,
                  color: AppColors.error, size: 17),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_error!,
                    style: TextStyle(color: pal.textSecondary, fontSize: 13)),
              ),
            ]),
          ),
        ],

        if (_result != null) ...[
          const SizedBox(height: 16),
          FadeSlideIn(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppColors.success.withValues(alpha: 0.4)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(FeatherIcons.checkCircle,
                          color: AppColors.success, size: 20),
                      const SizedBox(width: 9),
                      Text('Пардохт тасдиқ шуд',
                          style: TextStyle(
                              color: pal.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                        'Маблағ: ${(_result!['amount'] as num?)?.toStringAsFixed(2) ?? '-'} сом.',
                        style: TextStyle(color: pal.textSecondary, fontSize: 13)),
                    Text(
                        'Фармоиш: #${(_result!['order_id'] ?? '').toString().substring(0, 8).toUpperCase()}',
                        style: TextStyle(color: pal.textSecondary, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text('Харидор огоҳӣ гирифт: «Хариди шумо тайёр аст»',
                        style: TextStyle(color: pal.textMuted, fontSize: 12)),
                  ]),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _step(AppPalette pal, String n, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 19,
            height: 19,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Text(n,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(text,
                style: TextStyle(color: pal.textSecondary, fontSize: 12.5)),
          ),
        ]),
      );
}
