// ignore_for_file: curly_braces_in_flow_control_structures
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_colors.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../providers/auth_provider.dart';
import '../../providers/search_provider.dart';
import '../../routes/route_names.dart';
import '../../shared/widgets/app_button.dart';

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
  bool       _becomingS = false;
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

  // Become seller first, then reload user
  Future<bool> _ensureSeller() async {
    final user = ref.read(authProvider).user;
    if (user == null) return false;
    if (user.isSeller || user.role == 'seller' || user.role == 'admin') return true;

    setState(() { _becomingS = true; _error = null; });
    try {
      await ApiClient.instance.dio.post(ApiEndpoints.becomeSeller);
      await ref.read(authProvider.notifier).checkAuth();
      return true;
    } catch (e) {
      setState(() => _error = 'Фурӯшанда шудан мумкин набуд: ${e.toString().replaceAll("Exception: ", "")}');
      return false;
    } finally {
      setState(() => _becomingS = false);
    }
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

      final pid = (res.data['id'] ?? res.data['product']?['id'])?.toString() ?? '';

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
        content: const Row(children: [
          Icon(Icons.check_circle_rounded, color: Colors.white),
          SizedBox(width: 10),
          Text('Эълон нашр шуд! 🎉', style: TextStyle(fontWeight: FontWeight.w600)),
        ]),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      _reset();
      context.go(RouteNames.profile);
    } on DioException catch (e) {
      setState(() => _error = e.message ?? 'Хатои номаълум');
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
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.canPop(context) ? Navigator.pop(context) : context.go(RouteNames.home)),
        title: const Text('Эълон додан',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [TextButton(onPressed: _reset,
            child: const Text('Тоза кардан',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)))],
      ),
      body: Column(children: [
        Container(color: AppColors.bgDark, padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(children: [
            Text('$_step / 2', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(width: 12),
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: _step == 1 ? 0.5 : 1.0,
                  backgroundColor: AppColors.bgSurface, color: AppColors.primary, minHeight: 5))),
          ])),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: _step == 1 ? _step1(cats) : _step2())),
        _bottomBar(),
      ]),
    );
  }

  Widget _step1(AsyncValue cats) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _sec('1. Расмҳо', 'Беҳтар бо 3–5 расм эълон диққатҷалб мешавад'),
    GestureDetector(onTap: _pick, child: Container(
      width: double.infinity, height: 130,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary, width: 1.5)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 48, height: 48,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 26)),
        const SizedBox(height: 8),
        const Text('Расм илова кунед', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 3),
        const Text('То 5 расм • хаҷм автоматӣ кам мешавад', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ]))),
    const SizedBox(height: 10),
    if (_images.isNotEmpty) SizedBox(height: 86, child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _images.length < 5 ? _images.length + 1 : _images.length,
      itemBuilder: (_, i) {
        if (i == _images.length) return GestureDetector(onTap: _pick,
          child: Container(width: 78, height: 78, margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(border: Border.all(color: AppColors.primary, width: 1.5),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 30)));
        return Stack(children: [
          Container(width: 78, height: 78, margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
              image: DecorationImage(image: FileImage(_images[i]), fit: BoxFit.cover))),
          Positioned(bottom: 2, left: 2,
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
              child: Text(_fsize(_images[i]), style: const TextStyle(color: Colors.white, fontSize: 9)))),
          Positioned(top: -2, right: 4, child: GestureDetector(
            onTap: () => setState(() => _images.removeAt(i)),
            child: Container(width: 20, height: 20,
              decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 13, color: Colors.white)))),
        ]);
      })),
    const SizedBox(height: 20),
    _sec('2. Маълумоти асосӣ', null),
    _field('Номи маҳсулот *', _titleCtrl, hint: 'Номи маҳсулотро ворид кунед'),
    const SizedBox(height: 12),
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: _field('Нарх (сомонӣ) *', _priceCtrl, hint: '0', type: TextInputType.number)),
      const SizedBox(width: 10),
      Expanded(child: _drop<String>(label: 'Категория', value: _catId, hint: 'Интихоб кунед',
        items: cats.when(
          data: (l) => l.map<DropdownMenuItem<String>>((c) =>
            DropdownMenuItem(value: c.id as String, child: Text(c.name as String, overflow: TextOverflow.ellipsis))).toList(),
          loading: () => [], error: (_, __) => []),
        onChanged: (v) => setState(() => _catId = v))),
    ]),
    const SizedBox(height: 20),
    _sec('3. Тавсиф', null),
    Container(decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5)),
      child: TextField(controller: _descCtrl, maxLines: 4, maxLength: 500,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: const InputDecoration(hintText: 'Тавсифи кӯтоҳ...',
          hintStyle: TextStyle(color: AppColors.textMuted), border: InputBorder.none,
          contentPadding: EdgeInsets.all(12),
          counterStyle: TextStyle(color: AppColors.textMuted, fontSize: 11)))),
  ]);

  Widget _step2() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _sec('4. Тафсилот', null),
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: _drop<String>(label: 'Ҳолати маҳсулот', value: _condition, hint: '',
        items: _conditions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: (v) => setState(() => _condition = v ?? _condition))),
      const SizedBox(width: 10),
      Expanded(child: _drop<String>(label: 'Шаҳр', value: _city, hint: '',
        items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: (v) => setState(() => _city = v ?? _city))),
    ]),
    const SizedBox(height: 12),
    _field('Миқдор', _stockCtrl, hint: '1', type: TextInputType.number),
    const SizedBox(height: 20),

    // Seller info notice
    Container(padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
      child: Row(children: [
        const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Барои нашр фурӯшанда шудан лозим',
              style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text('Агар шумо ҳанӯз фурӯшанда набошед, '
              '"Нашр кардан" автоматӣ шуморо фурӯшанда мекунад.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ])),
      ])),
    const SizedBox(height: 20),

    if (_becomingS) Container(padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12)),
      child: const Row(children: [
        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
        SizedBox(width: 12),
        Text('Фурӯшанда шудан...', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ])),

    if (_error != null) Container(padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3))),
      child: Row(children: [
        const Icon(Icons.error_outline, color: AppColors.error, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
      ])),

    if (_loading && _progress > 0) Column(children: [
      const SizedBox(height: 12),
      ClipRRect(borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(value: _progress,
            backgroundColor: AppColors.bgSurface, color: AppColors.primary, minHeight: 8)),
      const SizedBox(height: 6),
      Text('${(_progress * 100).round()}% бор шуд', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
    ]),
  ]);

  Widget _bottomBar() => Container(
    padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
    decoration: const BoxDecoration(color: AppColors.bgCard,
        border: Border(top: BorderSide(color: AppColors.border))),
    child: Row(children: [
      Expanded(child: OutlinedButton.icon(
        onPressed: _loading ? null : (_step == 2 ? () => setState(() { _step = 1; _error = null; }) : () {}),
        icon: Icon(_step == 2 ? Icons.arrow_back_rounded : Icons.visibility_outlined, size: 18, color: AppColors.primary),
        label: Text(_step == 2 ? 'Қафо' : 'Пешнамоиш',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
      const SizedBox(width: 12),
      Expanded(child: ElevatedButton.icon(
        onPressed: (_loading || _becomingS) ? null : () {
          if (_step == 1) {
            if (_images.isEmpty) { setState(() => _error = 'Расм илова кунед'); return; }
            if (_titleCtrl.text.trim().isEmpty) { setState(() => _error = 'Номро ворид кунед'); return; }
            final p = double.tryParse(_priceCtrl.text.replaceAll(',', '.'));
            if (p == null || p <= 0) { setState(() => _error = 'Нархро ворид кунед'); return; }
            setState(() { _step = 2; _error = null; });
          } else { _submit(); }
        },
        icon: (_loading || _becomingS)
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(_step == 1 ? Icons.arrow_forward_rounded : Icons.send_rounded, size: 18),
        label: Text((_loading || _becomingS) ? 'Кор карда истода...' : _step == 1 ? 'Давом додан' : 'Нашр кардан',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
    ]),
  );

  Widget _sec(String t, String? s) => Padding(padding: const EdgeInsets.only(bottom: 10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(t, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
      if (s != null) ...[const SizedBox(height: 2),
        Text(s, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))],
    ]));

  Widget _field(String label, TextEditingController c,
      {String? hint, TextInputType? type, List<TextInputFormatter>? formatters}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 5),
      TextField(controller: c, keyboardType: type, inputFormatters: formatters,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: AppColors.textMuted),
          filled: true, fillColor: AppColors.bgCard,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)))),
    ]);

  Widget _drop<T>({required String label, required T? value, required String hint,
      required List<DropdownMenuItem<T>> items, required void Function(T?) onChanged}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 5),
      Container(padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.5)),
        child: DropdownButtonHideUnderline(child: DropdownButton<T>(
          value: value, isExpanded: true, dropdownColor: AppColors.bgCard,
          hint: Text(hint, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
          items: items, onChanged: onChanged,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)))),
    ]);

  Widget _notAuth() => Scaffold(backgroundColor: AppColors.bgDark,
    appBar: AppBar(backgroundColor: AppColors.bgDark, elevation: 0,
        title: const Text('Эълон додан', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700))),
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.lock_outline_rounded, size: 80, color: AppColors.textMuted),
      const SizedBox(height: 16),
      const Text('Барои эълон додан ворид шавед', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
      const SizedBox(height: 20),
      AppButton(text: 'Ворид шавед', width: 200, height: 46, onTap: () => context.go(RouteNames.login)),
    ])));
}
