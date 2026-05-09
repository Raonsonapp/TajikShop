import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../routes/route_names.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});
  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '1');
  final _picker = ImagePicker();
  List<File> _images = [];
  bool _loading = false;
  String? _error;
  double _progress = 0;

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(
      imageQuality: 72,
      maxWidth: 1080,
      maxHeight: 1080,
      limit: 5,
    );
    if (picked.isNotEmpty) {
      setState(() => _images = picked.map((e) => File(e.path)).toList());
    }
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) { setState(() => _error = 'Номи маҳсулотро ворид кунед'); return; }
    if (_priceCtrl.text.trim().isEmpty) { setState(() => _error = 'Нархро ворид кунед'); return; }
    if (_images.isEmpty) { setState(() => _error = 'Ҳадди ақал 1 расм илова кунед'); return; }
    setState(() { _loading = true; _error = null; _progress = 0.1; });
    try {
      final res = await ApiClient.instance.dio.post(ApiEndpoints.products, data: {
        'title': _titleCtrl.text.trim(),
        'price': double.tryParse(_priceCtrl.text.trim()) ?? 0,
        'description': _descCtrl.text.trim().isEmpty ? _titleCtrl.text.trim() : _descCtrl.text.trim(),
        'stock': int.tryParse(_stockCtrl.text.trim()) ?? 1,
      });
      final productId = res.data['id']?.toString() ?? res.data['product']?['id']?.toString() ?? '';
      if (productId.isNotEmpty) {
        setState(() => _progress = 0.4);
        final formData = FormData();
        for (final img in _images) {
          formData.files.add(MapEntry('images',
              await MultipartFile.fromFile(img.path, filename: img.path.split('/').last)));
        }
        await ApiClient.instance.dio.post(ApiEndpoints.productImages(productId), data: formData,
            onSendProgress: (s, t) => setState(() => _progress = 0.4 + 0.6 * s / t));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('✅ Маҳсулот нашр шуд!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
        _titleCtrl.clear(); _priceCtrl.clear(); _descCtrl.clear(); _stockCtrl.text = '1';
        setState(() { _images = []; _progress = 0; });
        context.go(RouteNames.profile);
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() { _titleCtrl.dispose(); _priceCtrl.dispose(); _descCtrl.dispose(); _stockCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isAuth = ref.watch(authProvider).isAuthenticated;
    if (!isAuth) {
      return Scaffold(backgroundColor: AppColors.bgDark,
        appBar: AppBar(backgroundColor: AppColors.bgDark,
            title: const Text('Нашр кардан', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700))),
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock_outline_rounded, size: 80, color: AppColors.textMuted),
          const SizedBox(height: 16),
          const Text('Барои нашр кардан ворид шавед', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          const SizedBox(height: 20),
          AppButton(text: 'Ворид шавед', width: 200, height: 46, onTap: () => context.go(RouteNames.login)),
        ])));
    }
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(backgroundColor: AppColors.bgDark,
          title: const Text('Маҳсулот нашр кунед',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            onTap: _pickImages,
            child: _images.isEmpty
                ? Container(height: 180,
                    decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4))),
                    child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 48),
                      SizedBox(height: 10),
                      Text('Расм илова кунед (то 5)', style: TextStyle(color: AppColors.primary, fontSize: 14)),
                      SizedBox(height: 4),
                      Text('Автоматӣ хурд мешавад • 1080px • 72%', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ])))
                : SizedBox(height: 120,
                    child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _images.length + 1,
                      itemBuilder: (_, i) {
                        if (i == _images.length) return GestureDetector(onTap: _pickImages,
                          child: Container(width: 110, height: 110, margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4))),
                            child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 32)));
                        return Stack(children: [
                          Container(width: 110, height: 110, margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(image: FileImage(_images[i]), fit: BoxFit.cover))),
                          Positioned(top: 4, right: 12, child: GestureDetector(onTap: () => setState(() => _images.removeAt(i)),
                            child: Container(width: 22, height: 22,
                              decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 14, color: Colors.white)))),
                        ]);
                      })),
          ),
          const SizedBox(height: 20),
          AppTextField(hint: 'Номи маҳсулот*', controller: _titleCtrl, prefixIcon: Icons.inventory_2_outlined),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: AppTextField(hint: 'Нарх (сом.)*', controller: _priceCtrl,
                prefixIcon: Icons.monetization_on_outlined, keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: AppTextField(hint: 'Захира', controller: _stockCtrl,
                prefixIcon: Icons.warehouse_outlined, keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 12),
          AppTextField(hint: 'Тавсиф (ихтиёрӣ)', controller: _descCtrl,
              prefixIcon: Icons.description_outlined, maxLines: 3),
          const SizedBox(height: 20),
          if (_error != null) Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3))),
            child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
          if (_loading && _progress > 0) Column(children: [
            ClipRRect(borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: _progress, backgroundColor: AppColors.bgCard,
                  color: AppColors.primary, minHeight: 6)),
            const SizedBox(height: 6),
            Text('Бор шудан ${(_progress * 100).round()}%', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 12),
          ]),
          AppButton(text: 'Нашр кардан 🚀', onTap: _submit, isLoading: _loading),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}
