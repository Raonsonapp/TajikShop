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
import '../../providers/address_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../data/models/cart_model.dart';
import '../../routes/route_names.dart';
import '../address/add_address_sheet.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/shimmer_card.dart';
import '../../shared/widgets/safe_input.dart';

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
                      onRemove: () => ref.read(cartProvider.notifier).removeItem(cart.items[i].id),
                      onQuantity: (q) => ref.read(cartProvider.notifier).updateQuantity(cart.items[i].id, q)))),
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
                      AppButton(text: 'Пардохт кардан', onTap: () => _dcCheckout(context)),
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
  String? _addressId;
  String _method = 'dc'; // dc | cod | wallet
  final _couponCtrl = TextEditingController();
  int _discountPct = 0;
  String? _couponMsg;
  bool _checkingCoupon = false;
  String? _error;
  final _picker = ImagePicker();

  @override
  void dispose() { _couponCtrl.dispose(); super.dispose(); }

  Future<void> _pickReceipt() async {
    final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) setState(() => _receipt = File(img.path));
  }

  Future<void> _applyCoupon() async {
    final code = _couponCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() { _checkingCoupon = true; _couponMsg = null; });
    final pct = await WalletService.validateCoupon(code);
    setState(() {
      _checkingCoupon = false;
      if (pct != null && pct > 0) {
        _discountPct = pct;
        _couponMsg = '✅ Тахфифи $pct% татбиқ шуд';
      } else {
        _discountPct = 0;
        _couponMsg = '❌ Купон нодуруст ё гузаштааст';
      }
    });
  }

  Future<void> _submit() async {
    if (_method == 'dc' && _receipt == null) {
      setState(() => _error = 'Аввал чеки пардохтро бор кунед');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      // 1) Фармоиш месозем
      final res = await ApiClient.instance.dio.post(ApiEndpoints.checkout, data: {
        if (_addressId != null) 'address_id': _addressId,
        'payment_method': _method,
        if (_discountPct > 0) 'coupon_code': _couponCtrl.text.trim(),
      });
      final body = res.data is Map ? res.data as Map : const {};
      final data = body['data'] is Map ? body['data'] as Map : body;
      final orderId = (data['order_id'] ?? data['id'] ?? '').toString();

      // 2) Барои DC чеки пардохтро бор мекунем
      if (_method == 'dc' && _receipt != null && orderId.isNotEmpty) {
        final formData = FormData.fromMap({
          'proof': await MultipartFile.fromFile(_receipt!.path)
        });
        await ApiClient.instance.dio.post(
          '${ApiEndpoints.orders}/$orderId/payment-proof', data: formData);
      }
      await ref.read(cartProvider.notifier).loadCart();
      if (_method == 'wallet') ref.invalidate(walletProvider);
      if (!mounted) return;
      setState(() { _loading = false; _sent = true; });
    } on DioException catch (e) {
      final msg = (e.response?.data is Map ? e.response?.data['error'] : null)?.toString();
      if (mounted) setState(() { _loading = false; _error = msg ?? 'Хато ҳангоми пардохт'; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'Хато ҳангоми пардохт'; });
    }
  }

  double get _cartTotal => ref.read(cartProvider).total;
  double get _finalTotal => (_cartTotal + 20) * (1 - _discountPct / 100);

  Future<void> _addAddress() async {
    final added = await showAddAddress(context);
    if (added == true) ref.invalidate(addressesProvider);
  }

  Widget _addressSelector() {
    final addresses = ref.watch(addressesProvider);
    return addresses.when(
      loading: () => const Padding(padding: EdgeInsets.symmetric(vertical: 8),
          child: LinearProgressIndicator(color: AppColors.primary, backgroundColor: AppColors.bgSurface)),
      error: (_, __) => _addAddressBtn(),
      data: (list) {
        if (list.isEmpty) return _addAddressBtn();
        _addressId ??= list.firstWhere((a) => a.isDefault, orElse: () => list.first).id;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ...list.map((a) => GestureDetector(
            onTap: () => setState(() => _addressId = a.id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _addressId == a.id ? AppColors.primary : AppColors.border,
                    width: _addressId == a.id ? 1.4 : 0.5)),
              child: Row(children: [
                Icon(_addressId == a.id ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: _addressId == a.id ? AppColors.primary : AppColors.textMuted, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(a.full, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ])),
              ]),
            ))),
          _addAddressBtn(),
        ]);
      },
    );
  }

  Widget _addAddressBtn() => TextButton.icon(
    onPressed: _addAddress,
    icon: const Icon(Icons.add_location_alt_outlined, color: AppColors.primary, size: 18),
    label: const Text('Суроға илова кунед',
        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)));

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
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        const Align(alignment: Alignment.centerLeft,
          child: Text('Тасдиқи фармоиш', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700))),
        const SizedBox(height: 16),

        // Суроғаи расонидан
        const Align(alignment: Alignment.centerLeft,
          child: Text('Суроғаи расонидан', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600))),
        const SizedBox(height: 8),
        _addressSelector(),
        const SizedBox(height: 16),

        // Купон
        const Align(alignment: Alignment.centerLeft,
          child: Text('Купон / Промокод', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600))),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Container(
            decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.5)),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SafeInput(controller: _couponCtrl,
              hint: 'Кодро ворид кунед',
              textCapitalization: TextCapitalization.characters,
              textColor: AppColors.textPrimary, fontSize: 14))),
          const SizedBox(width: 8),
          SizedBox(height: 46, child: ElevatedButton(
            onPressed: _checkingCoupon ? null : _applyCoupon,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _checkingCoupon
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Татбиқ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))),
        ]),
        if (_couponMsg != null) Padding(padding: const EdgeInsets.only(top: 6),
          child: Align(alignment: Alignment.centerLeft,
            child: Text(_couponMsg!, style: TextStyle(
                color: _discountPct > 0 ? AppColors.success : AppColors.error, fontSize: 12)))),
        const SizedBox(height: 16),

        // Усули пардохт
        const Align(alignment: Alignment.centerLeft,
          child: Text('Усули пардохт', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600))),
        const SizedBox(height: 8),
        _payOption('dc', Icons.account_balance_wallet_outlined, 'Корти DC', 'Интиқол + чеки пардохт'),
        _payOption('cod', Icons.local_shipping_outlined, 'Пардохт ҳангоми расонидан', 'Накд ба курьер'),
        _walletOption(),
        const SizedBox(height: 16),

        // Қисми вобаста ба усул
        if (_method == 'dc') ...[
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary, size: 20),
                SizedBox(width: 8), Text('Рақами DC-и фурӯшанда', style: TextStyle(color: AppColors.textMuted, fontSize: 12))]),
              SizedBox(height: 8),
              Text('+992 XX XXX XXXX', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
              SizedBox(height: 4),
              Text('Пулро ба ин рақам интиқол диҳед, баъд чекро бор кунед', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ])),
          const SizedBox(height: 12),
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
              ])) : null)),
          const SizedBox(height: 16),
        ],

        // Ҷамъбаст
        Container(padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            _row('Маҳсулот + доставка', '${(_cartTotal + 20).toStringAsFixed(0)} сом.'),
            if (_discountPct > 0) ...[
              const SizedBox(height: 6),
              _row('Тахфиф ($_discountPct%)', '-${((_cartTotal + 20) * _discountPct / 100).toStringAsFixed(0)} сом.'),
            ],
            const SizedBox(height: 8),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 8),
            _row('Ҷамъи пардохт', '${_finalTotal.toStringAsFixed(0)} сом.', bold: true),
          ])),

        if (_error != null) Padding(padding: const EdgeInsets.only(top: 12),
          child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),

        const SizedBox(height: 16),
        AppButton(
          text: _method == 'wallet' ? 'Пардохт аз ҳамён' : (_method == 'cod' ? 'Тасдиқи фармоиш' : 'Фиристодан ✓'),
          isLoading: _loading,
          onTap: _submit,
        ),
        const SizedBox(height: 8),
      ])),
    );
  }

  Widget _payOption(String value, IconData icon, String title, String subtitle) {
    final sel = _method == value;
    return GestureDetector(
      onTap: () => setState(() { _method = value; _error = null; }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? AppColors.primary : AppColors.border, width: sel ? 1.4 : 0.5)),
        child: Row(children: [
          Icon(sel ? Icons.radio_button_checked : Icons.radio_button_off,
              color: sel ? AppColors.primary : AppColors.textMuted, size: 20),
          const SizedBox(width: 10),
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ])),
        ]),
      ),
    );
  }

  Widget _walletOption() {
    final wallet = ref.watch(walletProvider);
    final balance = wallet.maybeWhen(data: (d) => (d['balance'] as num?)?.toDouble() ?? 0, orElse: () => 0.0);
    final enough = balance >= _finalTotal;
    final sel = _method == 'wallet';
    return GestureDetector(
      onTap: () => setState(() { _method = 'wallet'; _error = null; }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? AppColors.primary : AppColors.border, width: sel ? 1.4 : 0.5)),
        child: Row(children: [
          Icon(sel ? Icons.radio_button_checked : Icons.radio_button_off,
              color: sel ? AppColors.primary : AppColors.textMuted, size: 20),
          const SizedBox(width: 10),
          const Icon(Icons.savings_outlined, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Ҳамён', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            Text('Тавозун: ${balance.toStringAsFixed(0)} сом.${enough ? '' : ' (нокифоя)'}',
                style: TextStyle(color: enough ? AppColors.textMuted : AppColors.error, fontSize: 11)),
          ])),
        ]),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final CartItemModel item;
  final VoidCallback onRemove;
  final void Function(int) onQuantity;
  const _Item({required this.item, required this.onRemove, required this.onQuantity});

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
        Row(children: [
          Expanded(child: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
          GestureDetector(onTap: onRemove,
            child: const Padding(padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20))),
        ]),
        const SizedBox(height: 4),
        Text('${item.total.toStringAsFixed(0)} сом.',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 8),
        // Stepper-и миқдор
        Row(children: [
          _qtyBtn(Icons.remove_rounded, () => onQuantity(item.quantity - 1)),
          Container(
            constraints: const BoxConstraints(minWidth: 34),
            alignment: Alignment.center,
            child: Text('${item.quantity}',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700))),
          _qtyBtn(Icons.add_rounded, () => onQuantity(item.quantity + 1)),
        ]),
      ])),
    ]));

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 30, height: 30,
      decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 0.5)),
      child: Icon(icon, color: AppColors.textPrimary, size: 18)),
  );

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

