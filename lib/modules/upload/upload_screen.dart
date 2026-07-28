// ignore_for_file: curly_braces_in_flow_control_structures
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../core/app_l10n.dart';
import '../../core/l10n/misc_l10n.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../providers/auth_provider.dart';
import '../../providers/search_provider.dart';
import '../../routes/route_names.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/safe_input.dart';
import '../seller/seller_verify_sheet.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});
  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController(text: '0');
  final _descCtrl  = TextEditingController();
  final _stockCtrl = TextEditingController(text: '1');
  final _picker    = ImagePicker();

  List<File> _images    = [];
  String?    _catId;
  String     _condition = 'Нав';
  String     _city      = 'Душанбе';
  bool       _loading   = false;
  final bool _becomingS = false;
  double     _progress  = 0;
  String?    _error;
  int        _step      = 1;

  static const _conditions = ['Нав','Хуб','Қабулшуда','Кӯҳна'];
  static const _cities = ['Душанбе','Хуҷанд','Бохтар','Кӯлоб','Истаравшан','Ӯротеппа','Норак','Вахдат','Турсунзода','Исфара'];

  @override
  void dispose() {
    _titleCtrl.dispose(); _priceCtrl.dispose();
    _descCtrl.dispose(); _stockCtrl.dispose();
    super.dispose();
  }

  // Localized label for a stored condition value (value itself stays in TG).
  String _condLabel(String c) {
    final l = AppL10n.of(context);
    switch (c) {
      case 'Нав':       return l.conditionNew;
      case 'Хуб':       return l.conditionGood;
      case 'Қабулшуда': return l.conditionAcceptable;
      case 'Кӯҳна':     return l.conditionOld;
      default:          return c;
    }
  }

  String _fsize(File f) {
    final b = f.lengthSync();
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)}KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  Future<void> _pick() async {
    final picked = await _picker.pickMultiImage(
        imageQuality: 72, maxWidth: 1080, maxHeight: 1080, limit: 5);
    if (picked.isEmpty) return;
    setState(() => _images =
        [..._images, ...picked.map((x) => File(x.path))].take(5).toList());
  }

  // Become seller first — токени нав гирифта захира мешавад
  Future<bool> _ensureSeller() async {
    final user = ref.read(authProvider).user;
    if (user == null) return false;
    if (user.isSeller || user.role == 'seller' || user.role == 'admin') return true;

    // Бо тасдиқи паспорт (KYC) фурӯшанда мешавад
    final ok = await showSellerVerify(context);
    final nowSeller = ok == true && (ref.read(authProvider).user?.isSeller ?? false);
    if (!nowSeller) {
      setState(() => _error = AppL10n.of(context).becomeSellerFirst);
    }
    return nowSeller;
  }

  Future<void> _submit() async {
    setState(() { _error = null; _loading = true; _progress = 0.05; });
    try {
      // Step 1: ensure seller role
      final ok = await _ensureSeller();
      if (!ok) { setState(() => _loading = false); return; }

      setState(() => _progress = 0.15);

      // Step 2: create product
      final res = await ApiClient.instance.dio.post(
        ApiEndpoints.products,
        data: {
          'title':       _titleCtrl.text.trim(),
          'price':       double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0,
          'description': _descCtrl.text.trim().isEmpty ? _titleCtrl.text.trim() : _descCtrl.text.trim(),
          'stock':       int.tryParse(_stockCtrl.text.trim()) ?? 1,
          if (_catId != null) 'category_id': _catId,
        },
      );
      setState(() => _progress = 0.4);

      final body = res.data is Map<String, dynamic> ? res.data as Map<String, dynamic> : <String, dynamic>{};
      final productData = body['data'] as Map<String, dynamic>? ?? body;
      final pid = (productData['id'] ?? productData['product']?['id'])?.toString() ?? '';

      // Step 3: upload images one by one
      if (pid.isNotEmpty && _images.isNotEmpty) {
        for (int i = 0; i < _images.length; i++) {
          final form = FormData.fromMap({
            'images': await MultipartFile.fromFile(
                _images[i].path, filename: 'img_$i.jpg'),
          });
          await ApiClient.instance.dio.post(
            ApiEndpoints.productImages(pid),
            data: form,
            onSendProgress: (s, t) => setState(() =>
              _progress = (0.4 + 0.6 * ((i + (t > 0 ? s / t : 1)) / _images.length)).clamp(0.0, 1.0)),
          );
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(FeatherIcons.checkCircle, color: Colors.white),
          const SizedBox(width: 10),
          Text(AppL10n.of(context).productPublished, style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      _reset();
      context.go(RouteNames.profile);
    } on DioException catch (e) {
      setState(() => _error = e.message ?? AppL10n.of(context).unknownError);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _reset() {
    _titleCtrl.clear(); _priceCtrl.text = '0';
    _descCtrl.clear(); _stockCtrl.text = '1';
    setState(() { _images = []; _progress = 0; _catId = null; _step = 1; _error = null; });
  }

  @override
  Widget build(BuildContext context) {
    final isAuth = ref.watch(authProvider).isAuthenticated;
    if (!isAuth) return _notAuth();
    final cats = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: context.pal.scaffold,
      appBar: AppBar(
        backgroundColor: context.pal.scaffold, elevation: 0,
        leading: IconButton(
          icon: Icon(FeatherIcons.chevronLeft, size: 20, color: context.pal.textPrimary),
          onPressed: () => Navigator.canPop(context) ? Navigator.pop(context) : context.go(RouteNames.home)),
        title: Text(AppL10n.of(context).postListing,
            style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [TextButton(onPressed: _reset,
            child: Text(AppL10n.of(context).clearAll,
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)))],
      ),
      body: Column(children: [
        // Step indicator with green gradient progress bar
        Container(color: context.pal.scaffold, padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20)),
              child: Text('$_step / 2', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
            const SizedBox(width: 12),
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(6),
              child: Stack(children: [
                Container(height: 6, color: context.pal.surface),
                FractionallySizedBox(
                  widthFactor: _step == 1 ? 0.5 : 1.0,
                  child: Container(height: 6,
                    decoration: const BoxDecoration(gradient: AppColors.primaryGradient))),
              ]))),
          ])),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: _step == 1 ? _step1(cats) : _step2())),
        _bottomBar(),
      ]),
    );
  }

  Widget _step1(AsyncValue cats) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _sec('1. ${AppL10n.of(context).photos}', AppL10n.of(context).photosHint),
    // Rounded dashed green image picker area
    GestureDetector(onTap: _pick, child: CustomPaint(
      painter: _DashedBorderPainter(color: AppColors.primary, radius: 16),
      child: Container(
        width: double.infinity, height: 140,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 54, height: 54,
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6))]),
            child: const Icon(FeatherIcons.camera, color: Colors.white, size: 26)),
          const SizedBox(height: 10),
          Text(AppL10n.of(context).addPhoto, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 3),
          Text(AppL10n.of(context).photosSubHint, style: TextStyle(color: context.pal.textMuted, fontSize: 11)),
        ])))),
    const SizedBox(height: 12),
    if (_images.isNotEmpty) SizedBox(height: 88, child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _images.length < 5 ? _images.length + 1 : _images.length,
      itemBuilder: (_, i) {
        if (i == _images.length) return GestureDetector(onTap: _pick,
          child: CustomPaint(
            painter: _DashedBorderPainter(color: AppColors.primary, radius: 14),
            child: Container(width: 80, height: 80, margin: const EdgeInsets.only(right: 8),
              alignment: Alignment.center,
              child: const Icon(FeatherIcons.plus, color: AppColors.primary, size: 30))));
        return Stack(children: [
          Container(width: 80, height: 80, margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 3))],
              image: DecorationImage(image: FileImage(_images[i]), fit: BoxFit.cover))),
          Positioned(bottom: 2, left: 2,
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
              child: Text(_fsize(_images[i]), style: const TextStyle(color: Colors.white, fontSize: 9)))),
          Positioned(top: -2, right: 4, child: GestureDetector(
            onTap: () => setState(() => _images.removeAt(i)),
            child: Container(width: 22, height: 22,
              decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
              child: const Icon(FeatherIcons.x, size: 13, color: Colors.white)))),
        ]);
      })),
    const SizedBox(height: 22),
    _sec('2. ${AppL10n.of(context).basicInfo}', null),
    _field('${AppL10n.of(context).productName} *', _titleCtrl, hint: AppL10n.of(context).productNameHint),
    const SizedBox(height: 14),
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: _field('${AppL10n.of(context).price} (${AppL10n.of(context).currencySomoni}) *', _priceCtrl, hint: '0', type: TextInputType.number)),
      const SizedBox(width: 12),
      Expanded(child: _drop<String>(label: AppL10n.of(context).category, value: _catId, hint: AppL10n.of(context).selectHint,
        items: cats.when(
          data: (l) => l.map<DropdownMenuItem<String>>((c) =>
            DropdownMenuItem(value: c.id as String, child: Text(c.name as String, overflow: TextOverflow.ellipsis))).toList(),
          loading: () => [], error: (_, __) => []),
        onChanged: (v) => setState(() => _catId = v))),
    ]),
    const SizedBox(height: 22),
    _sec('3. ${AppL10n.of(context).description}', null),
    _card(
      height: 128,
      padding: const EdgeInsets.all(14),
      child: SafeInput(
        controller: _descCtrl,
        maxLines: 5,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        hint: AppL10n.of(context).descriptionHint,
        textColor: context.pal.textPrimary,
        fontSize: 14,
      ),
    ),
  ]);

  Widget _step2() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _sec('4. ${AppL10n.of(context).details}', null),
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: _drop<String>(label: AppL10n.of(context).conditionLabel, value: _condition, hint: '',
        items: _conditions.map((c) => DropdownMenuItem(value: c, child: Text(_condLabel(c)))).toList(),
        onChanged: (v) => setState(() => _condition = v ?? _condition))),
      const SizedBox(width: 12),
      Expanded(child: _drop<String>(label: AppL10n.of(context).city, value: _city, hint: '',
        items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: (v) => setState(() => _city = v ?? _city))),
    ]),
    const SizedBox(height: 14),
    _field(AppL10n.of(context).quantity, _stockCtrl, hint: '1', type: TextInputType.number),
    const SizedBox(height: 22),

    // Seller info notice
    Container(padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
      child: Row(children: [
        const Icon(FeatherIcons.info, color: AppColors.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(AppL10n.of(context).mustBeSeller,
              style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(AppL10n.of(context).mustBeSellerDesc,
              style: TextStyle(color: context.pal.textSecondary, fontSize: 12)),
        ])),
      ])),
    const SizedBox(height: 20),

    if (_becomingS) Container(padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: context.pal.card, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
        const SizedBox(width: 12),
        Text(AppL10n.of(context).becomingSeller, style: TextStyle(color: context.pal.textSecondary, fontSize: 13)),
      ])),

    if (_error != null) Container(padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3))),
      child: Row(children: [
        const Icon(FeatherIcons.alertCircle, color: AppColors.error, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
      ])),

    if (_loading && _progress > 0) Column(children: [
      const SizedBox(height: 14),
      ClipRRect(borderRadius: BorderRadius.circular(8),
        child: Stack(children: [
          Container(height: 8, color: context.pal.surface),
          FractionallySizedBox(
            widthFactor: _progress.clamp(0.0, 1.0),
            child: Container(height: 8,
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient))),
        ])),
      const SizedBox(height: 6),
      Text('${(_progress * 100).round()}% ${AppL10n.of(context).uploaded}', style: TextStyle(color: context.pal.textMuted, fontSize: 12)),
    ]),
  ]);

  Widget _bottomBar() {
    final busy = _loading || _becomingS;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(color: context.pal.card,
          border: Border(top: BorderSide(color: context.pal.border))),
      child: Row(children: [
        Expanded(child: OutlinedButton.icon(
          onPressed: _loading ? null : (_step == 2 ? () => setState(() { _step = 1; _error = null; }) : () {}),
          icon: Icon(_step == 2 ? FeatherIcons.arrowLeft : FeatherIcons.eye, size: 18, color: AppColors.primary),
          label: Text(_step == 2 ? AppL10n.of(context).back : AppL10n.of(context).preview,
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
        const SizedBox(width: 12),
        // Big rounded GREEN gradient primary button
        Expanded(flex: 2, child: _gradientButton(
          enabled: true,
          onTap: busy ? null : () {
            if (_step == 1) {
              if (_images.isEmpty) { setState(() => _error = AppL10n.of(context).addPhoto); return; }
              if (_titleCtrl.text.trim().isEmpty) { setState(() => _error = AppL10n.of(context).enterName); return; }
              final p = double.tryParse(_priceCtrl.text.replaceAll(',', '.'));
              if (p == null || p <= 0) { setState(() => _error = AppL10n.of(context).enterPrice); return; }
              setState(() { _step = 2; _error = null; });
            } else { _submit(); }
          },
          child: busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(_step == 1 ? FeatherIcons.arrowRight : FeatherIcons.send, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(_step == 1 ? AppL10n.of(context).continueWord : AppL10n.of(context).publish,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
                ]),
        )),
      ]),
    );
  }

  // Big rounded green gradient button
  Widget _gradientButton({required bool enabled, required VoidCallback? onTap, required Widget child}) =>
    DecoratedBox(
      decoration: BoxDecoration(
        gradient: enabled ? AppColors.primaryGradient : null,
        color: enabled ? null : context.pal.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: enabled
            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))]
            : null,
      ),
      child: Material(color: Colors.transparent,
        child: InkWell(borderRadius: BorderRadius.circular(16), onTap: onTap,
          child: Container(height: 52, alignment: Alignment.center, child: child))),
    );

  Widget _sec(String t, String? s) => Padding(padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 4, height: 18,
          decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(t, style: TextStyle(color: context.pal.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
      ]),
      if (s != null) ...[const SizedBox(height: 4),
        Padding(padding: const EdgeInsets.only(left: 14),
          child: Text(s, style: TextStyle(color: context.pal.textSecondary, fontSize: 12)))],
    ]));

  // Soft rounded card container (radius 16 + soft shadow)
  Widget _card({required Widget child, double? height, EdgeInsets? padding}) => Container(
    height: height,
    padding: padding,
    decoration: BoxDecoration(
      color: context.pal.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: context.pal.border, width: 0.5),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: child,
  );

  Widget _field(String label, TextEditingController c,
      {String? hint, TextInputType? type, List<TextInputFormatter>? formatters}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: context.pal.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      _card(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Align(alignment: Alignment.centerLeft, child: SafeInput(
          controller: c,
          keyboardType: type,
          formatters: formatters,
          hint: hint ?? '',
          textColor: context.pal.textPrimary,
          fontSize: 14,
        )),
      ),
    ]);

  Widget _drop<T>({required String label, required T? value, required String hint,
      required List<DropdownMenuItem<T>> items, required void Function(T?) onChanged}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: context.pal.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      _card(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(child: DropdownButton<T>(
          value: value, isExpanded: true, dropdownColor: context.pal.card,
          hint: Text(hint, style: TextStyle(color: context.pal.textMuted, fontSize: 12)),
          icon: Icon(FeatherIcons.chevronDown, color: context.pal.textMuted),
          items: items, onChanged: onChanged,
          style: TextStyle(color: context.pal.textPrimary, fontSize: 13))),
      ),
    ]);

  Widget _notAuth() => Scaffold(backgroundColor: context.pal.scaffold,
    appBar: AppBar(backgroundColor: context.pal.scaffold, elevation: 0,
        title: Text(AppL10n.of(context).postListing, style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w700))),
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(FeatherIcons.lock, size: 80, color: context.pal.textMuted),
      const SizedBox(height: 16),
      Text(AppL10n.of(context).loginToPost, style: TextStyle(color: context.pal.textSecondary, fontSize: 15)),
      const SizedBox(height: 20),
      AppButton(text: AppL10n.of(context).signIn, width: 200, height: 46, onTap: () => context.go(RouteNames.login)),
    ])));
}

/// Ҳошияи чиндор (dashed) барои майдони интихоби расм — услуби template.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dash;
  final double gap;
  final double strokeWidth;
  _DashedBorderPainter({
    required this.color,
    this.radius = 16,
    this.dash = 6,
    this.gap = 4,
    this.strokeWidth = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
        Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
