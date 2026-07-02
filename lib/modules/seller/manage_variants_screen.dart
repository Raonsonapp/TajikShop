import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/seller_provider.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/error_screen.dart';
import '../../shared/widgets/safe_input.dart';

class ManageVariantsScreen extends ConsumerWidget {
  final String productId;
  final String title;
  const ManageVariantsScreen({super.key, required this.productId, this.title = ''});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variants = ref.watch(productVariantsProvider(productId));
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text('Вариантҳо (андоза/ранг)',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Вариант', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: variants.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorScreen(message: e.toString(), onRetry: () => ref.invalidate(productVariantsProvider(productId))),
        data: (list) => list.isEmpty
            ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.tune_rounded, size: 72, color: AppColors.textMuted),
                SizedBox(height: 12),
                Text('Вариант нест.\nАндоза/рангро илова кунед.',
                    textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
              ]))
            : ListView.builder(padding: const EdgeInsets.all(16), itemCount: list.length,
                itemBuilder: (_, i) {
                  final v = list[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 0.5)),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(v.label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Text('${v.price > 0 ? '${v.price.toStringAsFixed(0)} сом. • ' : ''}Захира: ${v.stock}'
                            '${v.sku.isNotEmpty ? ' • SKU: ${v.sku}' : ''}',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ])),
                      IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                        onPressed: () async {
                          try {
                            await VariantService.remove(v.id);
                            ref.invalidate(productVariantsProvider(productId));
                          } catch (_) {}
                        }),
                    ]),
                  );
                }),
      ),
    );
  }

  void _add(BuildContext context, WidgetRef ref) {
    final size = TextEditingController();
    final color = TextEditingController();
    final sku = TextEditingController();
    final price = TextEditingController();
    final stock = TextEditingController(text: '1');
    showModalBottomSheet(context: context, backgroundColor: AppColors.bgCard, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        Widget f(String h, TextEditingController c, {bool num = false}) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.5)),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SafeInput(controller: c, keyboardType: num ? TextInputType.number : null,
              hint: h,
              textColor: AppColors.textPrimary, fontSize: 14),
          ));
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Варианти нав', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(children: [Expanded(child: f('Андоза (S, M, 42...)', size)), const SizedBox(width: 10), Expanded(child: f('Ранг', color))]),
            Row(children: [Expanded(child: f('Нарх (ихтиёрӣ)', price, num: true)), const SizedBox(width: 10), Expanded(child: f('Захира', stock, num: true))]),
            f('SKU (ихтиёрӣ)', sku),
            const SizedBox(height: 6),
            AppButton(text: 'Илова кардан', onTap: () async {
              if (size.text.trim().isEmpty && color.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                  content: Text('Андоза ё рангро ворид кунед'),
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
