import 'dart:io';
import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../core/app_l10n.dart';
import '../../core/l10n/seller_l10n.dart';

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
          SnackBar(
            content: Text(AppL10n.of(context).sellerProductPublished),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    final l = AppL10n.of(context);
    return Scaffold(
      backgroundColor: context.pal.scaffold,
      appBar: AppBar(
        backgroundColor: context.pal.scaffold,
        elevation: 0,
        title: Text(l.sellerAddProduct,
            style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w700)),
        iconTheme: IconThemeData(color: context.pal.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Images Section
              _sectionHeader(l.sellerPhotosUpTo5),
              const SizedBox(height: 12),
              // Rounded dashed green image picker area
              GestureDetector(
                onTap: _pickImage,
                child: CustomPaint(
                  painter: _DashedBorderPainter(color: AppColors.primary, radius: 16),
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 54, height: 54,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 14, offset: const Offset(0, 6)),
                            ],
                          ),
                          child: const Icon(FeatherIcons.image, color: Colors.white, size: 26),
                        ),
                        const SizedBox(height: 10),
                        Text(l.addPhoto,
                            style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
              if (_images.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 82,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    itemBuilder: (_, i) => Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 78, height: 78,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8, offset: const Offset(0, 3)),
                            ],
                            image: DecorationImage(image: FileImage(_images[i]), fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          top: 0, right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() => _images.removeAt(i)),
                            child: Container(
                              width: 22, height: 22,
                              decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                              child: const Icon(FeatherIcons.x, size: 13, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Fields
              _sectionHeader(l.sellerProductInfo),
              const SizedBox(height: 14),
              AppTextField(
                hint: '${l.productName}*', controller: _titleCtrl,
                prefixIcon: FeatherIcons.package,
                validator: (v) => v!.trim().isEmpty ? l.sellerNameRequired : null,
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: AppTextField(
                    hint: '${l.price} (${l.som})*', controller: _priceCtrl,
                    prefixIcon: FeatherIcons.dollarSign,
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? l.sellerPriceRequired : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    hint: '${l.sellerStock}*', controller: _stockCtrl,
                    prefixIcon: FeatherIcons.package,
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? l.sellerStockRequired : null,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              AppTextField(
                hint: '${l.sellerProductDescField}*', controller: _descCtrl,
                prefixIcon: FeatherIcons.fileText,
                maxLines: 4,
                validator: (v) => v!.trim().isEmpty ? l.sellerDescRequired : null,
              ),
              const SizedBox(height: 24),

              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(FeatherIcons.alertCircle, color: AppColors.error, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                  ]),
                ),

              // Big rounded GREEN gradient submit button (AppButton uses primaryGradient)
              AppButton(text: l.publish, onTap: _submit, isLoading: _loading),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String t) => Row(children: [
        Container(
          width: 4, height: 18,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(t,
            style: TextStyle(
                color: context.pal.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
      ]);
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
