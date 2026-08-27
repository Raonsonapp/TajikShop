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
import '../../providers/auth_provider.dart';
import '../../providers/search_provider.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../core/app_l10n.dart';
import '../../core/l10n/seller_l10n.dart';
import '../product/barcode_scanner_screen.dart';
import 'seller_verify_sheet.dart';

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
  final _barcodeCtrl = TextEditingController();
  final _deliveryDaysCtrl = TextEditingController();
  final _deliveryPriceCtrl = TextEditingController();
  String? _catId;          // категорияи интихобшуда
  bool _hasDelivery = true; // оё расонидан ҳаст
  final ImagePicker _picker = ImagePicker();
  List<File> _images = [];
  bool _loading = false;
  String? _error;

  Future<void> _scanForBarcode() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (code != null && code.isNotEmpty && mounted) {
      setState(() => _barcodeCtrl.text = code);
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickMultiImage(limit: 5);
    if (picked.isNotEmpty) {
      setState(() => _images = picked.map((e) => File(e.path)).toList());
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    // Категория ҳатмист — вагарна маҳсулот дар ҷустуҷӯ ва каталог гум мешавад.
    if (_catId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Категорияи маҳсулотро интихоб кунед'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final formData = FormData.fromMap({
        'title': _titleCtrl.text.trim(),
        'price': double.tryParse(_priceCtrl.text.trim()) ?? 0,
        'description': _descCtrl.text.trim(),
        'stock': int.tryParse(_stockCtrl.text.trim()) ?? 1,
        'barcode': _barcodeCtrl.text.trim(),
        if (_catId != null) 'category_id': _catId,
        'has_delivery': _hasDelivery,
        // Ҳангоми «расонидан нест» рӯз ва нархро намефиристем.
        'delivery_days': _hasDelivery
            ? (int.tryParse(_deliveryDaysCtrl.text.trim()) ?? 0)
            : 0,
        'delivery_price': _hasDelivery
            ? (double.tryParse(_deliveryPriceCtrl.text.trim().replaceAll(',', '.')) ?? 0)
            : 0,
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
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg = e.message ?? AppL10n.of(context).sellerVerifyError;
      if (data is Map) {
        msg = (data['error'] ?? data['message'] ?? data['detail'] ?? msg).toString();
      }
      setState(() => _error = msg);
      // Сервер бо 403 нашрро манъ мекунад (то тасдиқи админ) — паёми серверро нишон медиҳем.
      if (e.response?.statusCode == 403 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating));
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
    _barcodeCtrl.dispose();
    _deliveryDaysCtrl.dispose();
    _deliveryPriceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final user = ref.watch(authProvider).user;
    final isSeller = user?.isSeller == true || user?.role == 'seller' || user?.role == 'admin';
    if (!isSeller) return _sellerGate(l, user?.sellerRequested == true);
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
              const SizedBox(height: 12),
              // Штрих-код (ихтиёрӣ) — харидорон онро сканкарда маҳсулотро меёбанд.
              AppTextField(
                hint: 'Штрих-код (ихтиёрӣ)', controller: _barcodeCtrl,
                prefixIcon: FeatherIcons.hash,
                keyboardType: TextInputType.number,
                suffixIcon: FeatherIcons.maximize,
                onSuffixTap: _scanForBarcode,
              ),
              const SizedBox(height: 20),

              // ── Категория (ҳатмӣ) ────────────────────────────────────────
              _sectionHeader('Категория'),
              const SizedBox(height: 12),
              _categoryPicker(),
              const SizedBox(height: 20),

              // ── Расонидан ────────────────────────────────────────────────
              _sectionHeader('Расонидан'),
              const SizedBox(height: 12),
              _deliveryBlock(),
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

  // Экрани дарвоза — агар корбар фурӯшандаи тасдиқшуда набошад.
  Widget _sellerGate(AppL10n l, bool requested) => Scaffold(
    backgroundColor: context.pal.scaffold,
    appBar: AppBar(
      backgroundColor: context.pal.scaffold,
      elevation: 0,
      title: Text(l.sellerAddProduct,
          style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w700)),
      iconTheme: IconThemeData(color: context.pal.textPrimary),
    ),
    body: Center(child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 88, height: 88, alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle),
          child: Icon(requested ? FeatherIcons.clock : FeatherIcons.shoppingBag,
              color: AppColors.primary, size: 42)),
        const SizedBox(height: 20),
        Text(
          requested ? l.sellerRequestPendingUpload : l.sellerBecomeToPost,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.pal.textSecondary, fontSize: 15, height: 1.45,
              fontWeight: FontWeight.w500)),
        if (!requested) ...[
          const SizedBox(height: 24),
          SizedBox(width: 240,
            child: AppButton(
              text: '🏪 ${l.becomeSeller}',
              onTap: () => showSellerVerify(context))),
        ],
      ]),
    )),
  );

  /// Интихоби категория — ҳатмист, вагарна маҳсулот дар каталог пайдо намешавад.
  Widget _categoryPicker() {
    final pal = context.pal;
    final cats = ref.watch(categoriesProvider);
    return cats.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(
            color: AppColors.primary, backgroundColor: pal.surface),
      ),
      error: (_, __) => Text('Категорияҳо бор нашуданд',
          style: TextStyle(color: AppColors.error, fontSize: 12.5)),
      data: (list) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: pal.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: _catId == null
                  ? pal.border
                  : AppColors.primary.withValues(alpha: 0.5),
              width: _catId == null ? 0.8 : 1.3),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _catId,
            isExpanded: true,
            dropdownColor: pal.card,
            hint: Row(children: [
              Icon(FeatherIcons.grid, size: 18, color: pal.textMuted),
              const SizedBox(width: 10),
              Text('Категорияро интихоб кунед *',
                  style: TextStyle(color: pal.textMuted, fontSize: 14)),
            ]),
            icon: Icon(FeatherIcons.chevronDown, color: pal.textMuted),
            style: TextStyle(color: pal.textPrimary, fontSize: 14),
            items: [
              for (final c in list)
                DropdownMenuItem<String>(
                  value: c.id as String,
                  child: Text(c.name as String, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() => _catId = v),
          ),
        ),
      ),
    );
  }

  /// Оё расонидан ҳаст ва нархаш чанд — харидор инро дар саҳифаи маҳсулот мебинад.
  Widget _deliveryBlock() {
    final pal = context.pal;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: pal.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: pal.border, width: 0.8),
        ),
        child: Row(children: [
          Icon(_hasDelivery ? FeatherIcons.truck : FeatherIcons.home,
              size: 19,
              color: _hasDelivery ? AppColors.primary : pal.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
                _hasDelivery
                    ? 'Ман расонида метавонам'
                    : 'Расонидан нест — харидор худаш мегирад',
                style: TextStyle(color: pal.textPrimary, fontSize: 14)),
          ),
          Switch(
            value: _hasDelivery,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _hasDelivery = v),
          ),
        ]),
      ),
      // Нарх ва мӯҳлат танҳо вақте маъно доранд, ки расонидан бошад.
      AnimatedSize(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: _hasDelivery
            ? Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(children: [
                  Expanded(
                    child: AppTextField(
                      hint: 'Нархи расонидан (сом)',
                      controller: _deliveryPriceCtrl,
                      prefixIcon: FeatherIcons.dollarSign,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      hint: 'Дар чанд рӯз',
                      controller: _deliveryDaysCtrl,
                      prefixIcon: FeatherIcons.clock,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ]),
              )
            : const SizedBox(width: double.infinity),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 8, left: 4),
        child: Text(
            _hasDelivery
                ? 'Нархро холӣ монед — расонидан ройгон ҳисоб мешавад'
                : 'Харидор инро дар саҳифаи маҳсулот мебинад',
            style: TextStyle(color: pal.textMuted, fontSize: 11.5)),
      ),
    ]);
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
