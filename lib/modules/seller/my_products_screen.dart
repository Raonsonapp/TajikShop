import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
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
import '../../core/app_l10n.dart';
import '../../core/l10n/seller_l10n.dart';
import 'manage_variants_screen.dart';

class MyProductsScreen extends ConsumerWidget {
  const MyProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final uid = ref.watch(authProvider).user?.id ?? '';
    final products = ref.watch(sellerProductsProvider(uid));

    return Scaffold(
      backgroundColor: context.pal.scaffold,
      appBar: AppBar(
        backgroundColor: context.pal.scaffold,
        elevation: 0,
        iconTheme: IconThemeData(color: context.pal.textPrimary),
        title: Text(l.myProducts,
            style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(FeatherIcons.plus, color: AppColors.primary),
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
                Icon(FeatherIcons.package, size: 80, color: context.pal.textMuted),
                const SizedBox(height: 16),
                Text(l.sellerNoProductsYet,
                    style: TextStyle(color: context.pal.textSecondary, fontSize: 15)),
                const SizedBox(height: 20),
                AppButton(text: l.sellerAddProduct, width: 220, height: 46,
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
    final l = AppL10n.of(context);
    final p = product;
    final active = p.inStock;
    final statusColor = active ? AppColors.success : AppColors.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.pal.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(16),
              child: p.mainImage.isNotEmpty
                  ? CachedNetworkImage(imageUrl: p.mainImage, width: 68, height: 68, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _ph())
                  : _ph()),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.pal.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              Row(children: [
                Text('${p.price.toStringAsFixed(0)} ${l.som}',
                    style: const TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(width: 10),
                Icon(FeatherIcons.package, size: 13, color: context.pal.textMuted),
                const SizedBox(width: 3),
                Text('${p.stock}',
                    style: TextStyle(color: context.pal.textMuted, fontSize: 12.5)),
              ]),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(active ? l.sellerActive : l.sellerInactive,
                    style: TextStyle(color: statusColor,
                        fontSize: 10.5, fontWeight: FontWeight.w700))),
            ])),
          ]),
          const SizedBox(height: 10),
          Divider(height: 1, thickness: 0.6, color: context.pal.divider),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _RowAction(
                icon: FeatherIcons.sliders,
                label: l.variants,
                color: AppColors.primary,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ManageVariantsScreen(productId: p.id, title: p.title))),
              ),
              _RowAction(
                icon: FeatherIcons.edit2,
                label: l.sellerEditAction,
                color: AppColors.info,
                onTap: () => _openEdit(context),
              ),
              _RowAction(
                icon: FeatherIcons.trash2,
                label: l.sellerDeleteAction,
                color: AppColors.error,
                onTap: () => _confirmDelete(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ph() => Container(width: 68, height: 68, color: AppColors.bgSurface,
      child: const Icon(FeatherIcons.image, color: AppColors.textMuted));

  void _openEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.pal.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _EditProductSheet(product: product, onDone: onChanged));
  }

  void _confirmDelete(BuildContext context) {
    final l = AppL10n.of(context);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: context.pal.card,
      title: Text(l.sellerDeleteTitle, style: TextStyle(color: context.pal.textPrimary)),
      content: Text('"${product.title}" ${l.sellerDeleteQuestion}',
          style: TextStyle(color: context.pal.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text(l.sellerNo, style: TextStyle(color: context.pal.textMuted))),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            final messenger = ScaffoldMessenger.of(context);
            try {
              await SellerProductService.delete(product.id);
              onChanged();
              messenger.showSnackBar(SnackBar(
                content: Text(l.sellerProductDeleted),
                backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
            } catch (_) {
              messenger.showSnackBar(SnackBar(
                content: Text(l.sellerDeleteError),
                backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
            }
          },
          child: Text(l.sellerYesDelete, style: const TextStyle(color: AppColors.error))),
      ],
    ));
  }
}

class _RowAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _RowAction({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 6),
                  Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      );
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
    final l = AppL10n.of(context);
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
      messenger.showSnackBar(SnackBar(
        content: Text(l.sellerProductUpdated),
        backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      messenger.showSnackBar(SnackBar(
        content: Text(l.sellerUpdateError),
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
    final l = AppL10n.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: context.pal.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(l.sellerEditProductTitle, style: TextStyle(
              color: context.pal.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _f(l.sellerFieldName, _title),
          Row(children: [
            Expanded(child: _f('${l.price} (${l.som})', _price, type: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: _f(l.sellerDiscountPercent, _disc, type: TextInputType.number)),
          ]),
          _f(l.sellerStock, _stock, type: TextInputType.number),
          _f(l.sellerFlashSaleField, _sale, type: TextInputType.number),
          _f(l.description, _desc, maxLines: 3),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.primary,
            title: Text(l.sellerActiveInMarket,
                style: TextStyle(color: context.pal.textPrimary, fontSize: 14)),
            value: _active,
            onChanged: (v) => setState(() => _active = v)),
          const SizedBox(height: 12),
          AppButton(text: l.save, onTap: _save, isLoading: _loading),
        ]),
      ),
    );
  }
}
