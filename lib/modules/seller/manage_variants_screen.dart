import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/seller_provider.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/error_screen.dart';
import '../../shared/widgets/safe_input.dart';
import '../../core/app_l10n.dart';
import '../../core/l10n/seller_l10n.dart';

/// Градиенти сабз (ecommerce_int2 look, ранги бренди TajikShop).
const LinearGradient _greenGradient = LinearGradient(
  colors: [Color(0xFF00D084), Color(0xFF00A3FF)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class ManageVariantsScreen extends ConsumerWidget {
  final String productId;
  final String title;
  const ManageVariantsScreen({super.key, required this.productId, this.title = ''});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final variants = ref.watch(productVariantsProvider(productId));
    return Scaffold(
      backgroundColor: context.pal.scaffold,
      appBar: AppBar(
        backgroundColor: context.pal.scaffold,
        elevation: 0,
        iconTheme: IconThemeData(color: context.pal.textPrimary),
        title: Text(l.sellerVariantsTitle,
            style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      floatingActionButton: GestureDetector(
        onTap: () => _add(context, ref),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: _greenGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Color(0x4D00D084), offset: Offset(0, 6), blurRadius: 16),
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(l.sellerVariant, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
          ]),
        ),
      ),
      body: variants.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorScreen(message: e.toString(), onRetry: () => ref.invalidate(productVariantsProvider(productId))),
        data: (list) => list.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.tune_rounded, size: 44, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text(l.sellerNoVariants,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.pal.textSecondary, fontSize: 14)),
              ]))
            : ListView.builder(padding: const EdgeInsets.fromLTRB(20, 12, 20, 100), itemCount: list.length,
                itemBuilder: (_, i) {
                  final v = list[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.pal.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: context.pal.border, width: 0.6),
                      boxShadow: const [
                        BoxShadow(color: Color(0x1400D084), offset: Offset(0, 4), blurRadius: 14),
                      ],
                    ),
                    child: Row(children: [
                      // Green gradient leading badge
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          gradient: _greenGradient,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(v.label, style: TextStyle(color: context.pal.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('${v.price > 0 ? '${v.price.toStringAsFixed(0)} ${l.som} • ' : ''}${l.sellerStock}: ${v.stock}'
                            '${v.sku.isNotEmpty ? ' • SKU: ${v.sku}' : ''}',
                            style: TextStyle(color: context.pal.textMuted, fontSize: 12)),
                      ])),
                      GestureDetector(
                        onTap: () async {
                          try {
                            await VariantService.remove(v.id);
                            ref.invalidate(productVariantsProvider(productId));
                          } catch (_) {}
                        },
                        child: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                        ),
                      ),
                    ]),
                  );
                }),
      ),
    );
  }

  void _add(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final size = TextEditingController();
    final color = TextEditingController();
    final sku = TextEditingController();
    final price = TextEditingController();
    final stock = TextEditingController(text: '1');
    showModalBottomSheet(context: context, backgroundColor: context.pal.card, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        Widget f(String h, TextEditingController c, {bool num = false}) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 52,
            decoration: BoxDecoration(color: context.pal.surface, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.pal.border, width: 0.6)),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SafeInput(controller: c, keyboardType: num ? TextInputType.number : null,
              hint: h,
              textColor: context.pal.textPrimary, fontSize: 14),
          ));
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: context.pal.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 18),
            Text(l.sellerNewVariant, style: TextStyle(color: context.pal.textPrimary, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 18),
            Row(children: [Expanded(child: f(l.sellerSizeHint, size)), const SizedBox(width: 12), Expanded(child: f(l.sellerColor, color))]),
            Row(children: [Expanded(child: f(l.sellerPriceOptional, price, num: true)), const SizedBox(width: 12), Expanded(child: f(l.sellerStock, stock, num: true))]),
            f(l.sellerSkuOptional, sku),
            const SizedBox(height: 8),
            AppButton(text: l.sellerAddAction, icon: Icons.add_rounded, onTap: () async {
              if (size.text.trim().isEmpty && color.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text(l.sellerEnterSizeOrColor),
                  backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
                return;
              }
              Navigator.pop(ctx);
              try {
                await VariantService.add(productId,
                  size: size.text.trim(), color: color.text.trim(), sku: sku.text.trim(),
                  price: double.tryParse(price.text.replaceAll(',', '.')) ?? 0,
                  stock: int.tryParse(stock.text.trim()) ?? 0);
                ref.invalidate(productVariantsProvider(productId));
              } catch (_) {}
            }),
          ]),
        );
      });
  }
}
