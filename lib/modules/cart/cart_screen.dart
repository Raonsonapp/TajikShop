// ignore_for_file: curly_braces_in_flow_control_structures, camel_case_types
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_colors.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/cart_model.dart';
import '../../routes/route_names.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/shimmer_card.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});
  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(authProvider).isAuthenticated) ref.read(cartProvider.notifier).loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final isAuth = ref.watch(authProvider).isAuthenticated;

    if (!isAuth) return Scaffold(backgroundColor: AppColors.bgDark, appBar: _bar(),
      body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.shopping_bag_outlined, size: 80, color: AppColors.textMuted),
        const SizedBox(height: 16),
        const Text('Барои дидани сабад ворид шавед', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
        const SizedBox(height: 20),
        AppButton(text: 'Ворид шавед', width: 200, height: 46, onTap: () => context.go(RouteNames.login)),
      ])));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: _bar(action: cart.items.isNotEmpty ? TextButton(
        onPressed: () async { for (final i in [...cart.items]) await ref.read(cartProvider.notifier).removeItem(i.id); },
        child: const Text('Тоза', style: TextStyle(color: AppColors.error))) : null),
      body: cart.isLoading
          ? ListView.builder(padding: const EdgeInsets.all(16), itemCount: 4,
              itemBuilder: (_, __) => Padding(padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [ShimmerCard(width: 80, height: 80, radius: 12),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [ShimmerCard(height: 14, radius: 4), const SizedBox(height: 8), ShimmerCard(height: 14, width: 100, radius: 4)]))])))
          : cart.items.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.shopping_cart_outlined, size: 80, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  const Text('Сабад холи аст', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                  const SizedBox(height: 24),
                  AppButton(text: 'Харид кунед', width: 200, height: 46, onTap: () => context.go(RouteNames.home))]))
              : Column(children: [
                  Expanded(child: ListView.builder(padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    itemBuilder: (_, i) => _Item(item: cart.items[i],
                      onRemove: () => ref.read(cartProvider.notifier).removeItem(cart.items[i].id)))),
                  // Summary + DC Checkout
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    decoration: const BoxDecoration(color: AppColors.bgCard,
                        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                    child: Column(children: [
                      _row('Маҳсулот (${cart.itemCount})', '${cart.total.toStringAsFixed(0)} сом.'),
                      const SizedBox(height: 6),
                      const _row('Доставка', '20 сом.'),
                      const SizedBox(height: 10),
                      const Divider(color: AppColors.divider),
                      const SizedBox(height: 10),
                      _row('Ҷамъ', '${(cart.total + 20).toStringAsFixed(0)} сом.', bold: true),
                      const SizedBox(height: 16),
                      AppButton(text: 'Пардохт тавасути DC', onTap: () => _dcCheckout(context)),
                    ]),
                  ),
                ]),
    );
  }

  void _dcCheckout(BuildContext context) {
    // Show seller DC number and receipt upload
    showModalBottomSheet(context: context, backgroundColor: AppColors.bgCard, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _DcCheckoutSheet());
  }

  PreferredSizeWidget _bar({Widget? action}) => AppBar(
    backgroundColor: AppColors.bgDark,
    title: const Text('Сабад', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
    actions: [if (action != null) action]);
}

class _DcCheckoutSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_DcCheckoutSheet> createState() => _DcCheckoutSheetState();
}

class _DcCheckoutSheetState extends ConsumerState<_DcCheckoutSheet> {
  File? _receipt;
  bool _loading = false;
  bool _sent = false;
  final _picker = ImagePicker();

  Future<void> _pickReceipt() async {
    final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) setState(() => _receipt = File(img.path));
  }

  Future<void> _submit() async {
    if (_receipt == null) return;
    setState(() => _loading = true);
    try {
      // Create order first
      final cart = ref.read(cartProvider);
      await ApiClient.instance.dio.post(ApiEndpoints.checkout, data: {});
      // Get latest order to upload proof
      final orders = await ApiClient.instance.dio.get(ApiEndpoints.orders);
      final list = orders.data is List ? orders.data as List : (orders.data['orders'] ?? []);
      if (list.isNotEmpty) {
        final orderId = list.first['id']?.toString() ?? '';
        if (orderId.isNotEmpty) {
          final formData = FormData.fromMap({
            'proof': await MultipartFile.fromFile(_receipt!.path)
          });
          await ApiClient.instance.dio.post(
            '${ApiEndpoints.orders}/$orderId/payment-proof', data: formData);
        }
      }
      await ref.read(cartProvider.notifier).loadCart();
      setState(() { _loading = false; _sent = true; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) return Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 72),
      const SizedBox(height: 16),
      const Text('Фармоиш қабул шуд!', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      const Text('Чек ба фурӯшанда фиристода шуд. Тасдиқ баъд аз санҷиш.',
          style: TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
      const SizedBox(height: 20),
      AppButton(text: 'Фармоишҳоям', onTap: () { Navigator.pop(context); context.push(RouteNames.orders); }),
    ]));

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        const Text('Пардохти DC', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        // Seller DC info
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: 8), Text('Рақами DC-и фурӯшанда', style: TextStyle(color: AppColors.textMuted, fontSize: 12))]),
            const SizedBox(height: 8),
            const Text('+992 XX XXX XXXX', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Пулро ба ин рақам интиқол диҳед', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ])),
        const SizedBox(height: 16),
        // Receipt upload
        GestureDetector(
          onTap: _pickReceipt,
          child: Container(width: double.infinity, height: _receipt != null ? 160 : 90,
            decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _receipt != null ? AppColors.success : AppColors.border, width: 1.5),
                image: _receipt != null ? DecorationImage(image: FileImage(_receipt!), fit: BoxFit.cover) : null),
            child: _receipt == null ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.upload_file_rounded, color: AppColors.primary, size: 32),
              SizedBox(height: 6),
              Text('Чеки пардохтро бор кунед', style: TextStyle(color: AppColors.primary, fontSize: 13)),
            ])) : null),
        ),
        const SizedBox(height: 16),
        AppButton(
          text: _receipt == null ? 'Аввал чек бор кунед' : 'Фиристодан ✓',
          isLoading: _loading,
          onTap: _receipt != null ? _submit : null,
        ),
      ]),
    );
  }
}

class _Item extends StatelessWidget {
  final CartItemModel item;
  final VoidCallback onRemove;
  const _Item({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5)),
    child: Row(children: [
      ClipRRect(borderRadius: BorderRadius.circular(10),
        child: item.image != null ? CachedNetworkImage(imageUrl: item.image!, width: 72, height: 72, fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _ph()) : _ph()),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('${item.price.toStringAsFixed(0)} сом. × ${item.quantity}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        Text('${item.total.toStringAsFixed(0)} сом.',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
      ])),
      IconButton(onPressed: onRemove, icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20)),
    ]));

  Widget _ph() => Container(width: 72, height: 72, color: AppColors.bgSurface,
      child: const Icon(Icons.image_outlined, color: AppColors.textMuted));
}

class _row extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _row(this.label, this.value, {this.bold = false});
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(label, style: TextStyle(color: bold ? AppColors.textPrimary : AppColors.textSecondary,
        fontSize: bold ? 15 : 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
    Text(value, style: TextStyle(color: bold ? AppColors.primary : AppColors.textSecondary,
        fontSize: bold ? 17 : 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w400)),
  ]);
}
