import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_colors.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});
  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '1');
  final ImagePicker _picker = ImagePicker();
  List<File> _images = [];
  bool _loading = false;
  String? _error;

  Future<void> _pickImage() async {
    final picked = await _picker.pickMultiImage(limit: 5);
    if (picked.isNotEmpty) {
      setState(() => _images = picked.map((e) => File(e.path)).toList());
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final formData = FormData.fromMap({
        'title': _titleCtrl.text.trim(),
        'price': double.tryParse(_priceCtrl.text.trim()) ?? 0,
        'description': _descCtrl.text.trim(),
        'stock': int.tryParse(_stockCtrl.text.trim()) ?? 1,
        for (int i = 0; i < _images.length; i++)
          'images': await MultipartFile.fromFile(_images[i].path),
      });
      await ApiClient.instance.dio.post(ApiEndpoints.products, data: formData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Маҳсулот нашр шуд!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _priceCtrl.dispose();
    _descCtrl.dispose(); _stockCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        title: const Text('Маҳсулот илова кунед',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Images Section
              const Text('Расмҳо (то 5)',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withOpacity(0.5), style: BorderStyle.solid),
                  ),
                  child: const Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 32),
                      SizedBox(height: 8),
                      Text('Расм илова кунед', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                    ]),
                  ),
                ),
              ),
              if (_images.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    itemBuilder: (_, i) => Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 75, height: 75,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(image: FileImage(_images[i]), fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          top: 0, right: 0,
                          child: GestureDetector(
                            onTap: () => setState(() => _images.removeAt(i)),
                            child: Container(
                              width: 20, height: 20,
                              decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Fields
              const Text('Маълумоти маҳсулот',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              AppTextField(
                hint: 'Номи маҳсулот*', controller: _titleCtrl,
                prefixIcon: Icons.inventory_2_outlined,
                validator: (v) => v!.trim().isEmpty ? 'Ном лозим аст' : null,
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: AppTextField(
                    hint: 'Нарх (сом.)*', controller: _priceCtrl,
                    prefixIcon: Icons.monetization_on_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Нарх лозим' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    hint: 'Захира*', controller: _stockCtrl,
                    prefixIcon: Icons.warehouse_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Захира лозим' : null,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              AppTextField(
                hint: 'Тавсифи маҳсулот*', controller: _descCtrl,
                prefixIcon: Icons.description_outlined,
                maxLines: 4,
                validator: (v) => v!.trim().isEmpty ? 'Тавсиф лозим аст' : null,
              ),
              const SizedBox(height: 20),

              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ),

              AppButton(text: 'Нашр кардан', onTap: _submit, isLoading: _loading),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
