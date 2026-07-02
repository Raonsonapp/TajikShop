import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/seller_provider.dart';
import '../../routes/route_names.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/shimmer_card.dart';
import '../../shared/widgets/error_screen.dart';
import '../../shared/widgets/safe_input.dart';
import 'manage_variants_screen.dart';

class MyProductsScreen extends ConsumerWidget {
  const MyProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authProvider).user?.id ?? '';
    final products = ref.watch(sellerProductsProvider(uid));

    return Scaffold(
      backgroundColor: context.pal.scaffold,
      appBar: AppBar(
        backgroundColor: context.pal.scaffold,
        iconTheme: IconThemeData(color: context.pal.textPrimary),
        title: Text('Маҳсулотҳоям',
            style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () => context.push(RouteNames.addProduct)),
        ],
      ),
      body: products.when(
        loading: () => ListView.builder(padding: const EdgeInsets.all(16), itemCount: 5,
          itemBuilder: (_, __) => Padding(padding: const EdgeInsets.only(bottom: 12),
            child: ShimmerCard(height: 90, radius: 14))),
        error: (e, _) => ErrorScreen(message: e.toString(),
            onRetry: () => ref.invalidate(sellerProductsProvider(uid))),
        data: (list) => list.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.inventory_2_outlined, size: 80, color: context.pal.textMuted),
                const SizedBox(height: 16),
                Text('Шумо ҳоло маҳсулот надоред',
                    style: TextStyle(color: context.pal.textSecondary, fontSize: 15)),
                const SizedBox(height: 20),
                AppButton(text: 'Маҳсулот илова кунед', width: 220, height: 46,
                    onTap: () => context.push(RouteNames.addProduct)),
              ]))
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => ref.invalidate(sellerProductsProvider(uid)),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _ProductRow(
                    product: list[i],
                    onChanged: () => ref.invalidate(sellerProductsProvider(uid)),
                  ),
                ),
              ),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onChanged;
  const _ProductRow({required this.product, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = product;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: context.pal.card, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.pal.border, width: 0.5)),
      child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(10),
          child: p.mainImage.isNotEmpty
              ? CachedNetworkImage(imageUrl: p.mainImage, width: 64, height: 64, fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _ph())
              : _ph()),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.pal.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text('${p.price.toStringAsFixed(0)} сом. • Захира: ${p.stock}',
              style: TextStyle(color: context.pal.textMuted, fontSize: 12)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: (p.inStock ? AppColors.success : AppColors.error).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8)),
            child: Text(p.inStock ? 'Фаъол' : 'Ғайрифаъол',
                style: TextStyle(color: p.inStock ? AppColors.success : AppColors.error,
                    fontSize: 10, fontWeight: FontWeight.w600))),
        ])),
        IconButton(
          icon: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
          tooltip: 'Вариантҳо',
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ManageVariantsScreen(productId: p.id, title: p.title)))),
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: AppColors.info, size: 20),
          onPressed: () => _openEdit(context)),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
          onPressed: () => _confirmDelete(context)),
      ]),
    );
  }

  Widget _ph() => Container(width: 64, height: 64, color: AppColors.bgSurface,
      child: const Icon(Icons.image_outlined, color: AppColors.textMuted));

  void _openEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.pal.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _EditProductSheet(product: product, onDone: onChanged));
  }

  void _confirmDelete(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: context.pal.card,
      title: Text('Нест кардан?', style: TextStyle(color: context.pal.textPrimary)),
      content: Text('"${product.title}" нест карда шавад?',
          style: TextStyle(color: context.pal.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text('Не', style: TextStyle(color: context.pal.textMuted))),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            final messenger = ScaffoldMessenger.of(context);
            try {
              await SellerProductService.delete(product.id);
              onChanged();
              messenger.showSnackBar(const SnackBar(
                content: Text('Маҳсулот нест карда шуд'),
                backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
            } catch (_) {
              messenger.showSnackBar(const SnackBar(
                content: Text('Хато ҳангоми нест кардан'),
                backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
            }
          },
          child: const Text('Бале, нест кун', style: TextStyle(color: AppColors.error))),
      ],
    ));
  }
}

// ── Таҳрири маҳсулот ────────────────────────────────────────────────────────
class _EditProductSheet extends StatefulWidget {
  final ProductModel product;
  final VoidCallback onDone;
  const _EditProductSheet({required this.product, required this.onDone});
  @override
  State<_EditProductSheet> createState() => _EditProductSheetState();
}

class _EditProductSheetState extends State<_EditProductSheet> {
  late final TextEditingController _title;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _disc;
  late final TextEditingController _desc;
  final _sale = TextEditingController();
  late bool _active;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _title = TextEditingController(text: p.title);
    _price = TextEditingController(text: p.price.toStringAsFixed(0));
    _stock = TextEditingController(text: p.stock.toString());
    _disc = TextEditingController(text: p.discountPercent.toString());
    _desc = TextEditingController(text: p.description);
    _active = p.inStock;
  }

  @override
  void dispose() {
    _title.dispose(); _price.dispose(); _stock.dispose(); _disc.dispose(); _desc.dispose(); _sale.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await SellerProductService.update(widget.product.id,
        title: _title.text.trim(),
        description: _desc.text.trim(),
        price: double.tryParse(_price.text.replaceAll(',', '.')) ?? widget.product.price,
        discountPercent: int.tryParse(_disc.text.trim()) ?? 0,
        stock: int.tryParse(_stock.text.trim()) ?? 0,
        isActive: _active,
        saleHours: int.tryParse(_sale.text.trim()) ?? 0);
      widget.onDone();
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(
        content: Text('Маҳсулот навсозӣ шуд ✅'),
        backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      messenger.showSnackBar(const SnackBar(
        content: Text('Хато ҳангоми навсозӣ'),
        backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    }
  }

  Widget _f(String label, TextEditingController c, {TextInputType? type, int maxLines = 1}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: context.pal.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 5),
      Container(
        decoration: BoxDecoration(color: context.pal.surface, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.pal.border, width: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: SafeInput(controller: c, keyboardType: type, maxLines: maxLines,
          hint: '',
          textColor: context.pal.textPrimary, fontSize: 14),
      ),
      const SizedBox(height: 12),
    ]);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: context.pal.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Таҳрири маҳсулот', style: TextStyle(
              color: context.pal.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _f('Ном', _title),
          Row(children: [
            Expanded(child: _f('Нарх (сом.)', _price, type: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: _f('Тахфиф (%)', _disc, type: TextInputType.number)),
          ]),
          _f('Захира', _stock, type: TextInputType.number),
          _f('⚡ Flash sale (соат, холӣ=тағйир нест, -1=бекор)', _sale, type: TextInputType.number),
          _f('Тавсиф', _desc, maxLines: 3),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.primary,
            title: Text('Фаъол (намоиш дар бозор)',
                style: TextStyle(color: context.pal.textPrimary, fontSize: 14)),
            value: _active,
            onChanged: (v) => setState(() => _active = v)),
          const SizedBox(height: 12),
          AppButton(text: 'Захира кардан', onTap: _save, isLoading: _loading),
        ]),
      ),
    );
  }
}
