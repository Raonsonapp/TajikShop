// ignore_for_file: curly_braces_in_flow_control_structures, camel_case_types
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../core/app_l10n.dart';
import '../../core/l10n/profile_l10n.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/address_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/seller_provider.dart';
import '../../data/models/cart_model.dart';
import '../../routes/route_names.dart';
import '../address/add_address_sheet.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/shimmer_card.dart';
import '../../shared/widgets/safe_input.dart';

/// Ҳаққи расонидан (сом.) — дар як ҷо, то дар экранҳо фарқ накунад.
const double kDeliveryFee = 20;

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
    final cashbackPct = ref.watch(cashbackProvider).maybeWhen(data: (v) => v, orElse: () => 2.0);

    if (!isAuth) return Scaffold(backgroundColor: context.pal.scaffold, appBar: _bar(),
      body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(FeatherIcons.shoppingBag, size: 80, color: context.pal.textMuted),
        const SizedBox(height: 16),
        Text(AppL10n.of(context).loginToViewCart, style: TextStyle(color: context.pal.textSecondary, fontSize: 15)),
        const SizedBox(height: 20),
        AppButton(text: AppL10n.of(context).signIn, width: 200, height: 46, onTap: () => context.go(RouteNames.login)),
      ])));

    return Scaffold(
      backgroundColor: context.pal.scaffold,
      appBar: _bar(action: cart.items.isNotEmpty ? TextButton(
        onPressed: () async { for (final i in [...cart.items]) await ref.read(cartProvider.notifier).removeItem(i.id); },
        child: Text(AppL10n.of(context).clearShort, style: const TextStyle(color: AppColors.error))) : null),
      body: cart.isLoading
          ? ListView.builder(padding: const EdgeInsets.all(16), itemCount: 4,
              itemBuilder: (_, __) => Padding(padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [ShimmerCard(width: 80, height: 80, radius: 12),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [ShimmerCard(height: 14, radius: 4), const SizedBox(height: 8), ShimmerCard(height: 14, width: 100, radius: 4)]))])))
          : cart.items.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(FeatherIcons.shoppingCart, size: 80, color: context.pal.textMuted),
                  const SizedBox(height: 16),
                  Text(AppL10n.of(context).emptyCart, style: TextStyle(color: context.pal.textSecondary, fontSize: 16)),
                  const SizedBox(height: 24),
                  AppButton(text: AppL10n.of(context).shopNow, width: 200, height: 46, onTap: () => context.go(RouteNames.home))]))
              : Column(children: [
                  // Subtotal header bar (template style, green)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 208, 132, 0.28), offset: Offset(0, 4), blurRadius: 10)]),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('${AppL10n.of(context).productsWord} (${cart.itemCount})',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('${cart.total.toStringAsFixed(0)} сом.',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ]),
                  ),
                  Expanded(child: ListView.builder(padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: cart.items.length,
                    itemBuilder: (_, i) => _Item(item: cart.items[i],
                      onRemove: () => ref.read(cartProvider.notifier).removeItem(cart.items[i].id),
                      onQuantity: (q) => ref.read(cartProvider.notifier).updateQuantity(cart.items[i].id, q)))),
                  // Summary + DC Checkout
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    decoration: BoxDecoration(color: context.pal.card,
                        border: Border(top: BorderSide(color: context.pal.border, width: 0.5)),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(0, -3), blurRadius: 10)]),
                    child: Column(children: [
                      _row('${AppL10n.of(context).productsWord} (${cart.itemCount})', '${cart.total.toStringAsFixed(0)} сом.'),
                      const SizedBox(height: 6),
                      _row(AppL10n.of(context).delivery, '${kDeliveryFee.toStringAsFixed(0)} сом.'),
                      const SizedBox(height: 10),
                      Divider(color: context.pal.divider),
                      const SizedBox(height: 10),
                      _row(AppL10n.of(context).total, '${(cart.total + kDeliveryFee).toStringAsFixed(0)} сом.', bold: true),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(FeatherIcons.gift, color: AppColors.primary, size: 14),
                        const SizedBox(width: 6),
                        Expanded(child: Text(
                          '💸 Cashback: ${cashbackPct == cashbackPct.roundToDouble() ? cashbackPct.toStringAsFixed(0) : cashbackPct.toStringAsFixed(1)}% (${(cart.total * cashbackPct / 100).toStringAsFixed(0)} сом ба ҳамён)',
                          style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600))),
                      ]),
                      const SizedBox(height: 20),
                      // Big rounded gradient checkout button (template style)
                      Center(child: GestureDetector(
                        onTap: () => _dcCheckout(context),
                        child: Container(
                          height: 62,
                          width: MediaQuery.of(context).size.width / 1.5,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 208, 132, 0.35), offset: Offset(0, 6), blurRadius: 14)]),
                          child: Center(child: Text(AppL10n.of(context).payNow,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18))),
                        ),
                      )),
                    ]),
                  ),
                ]),
    );
  }

  void _dcCheckout(BuildContext context) {
    // Show seller DC number and receipt upload
    showModalBottomSheet(context: context, backgroundColor: context.pal.card, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _DcCheckoutSheet());
  }

  PreferredSizeWidget _bar({Widget? action}) => AppBar(
    backgroundColor: context.pal.scaffold,
    title: Text(AppL10n.of(context).cart, style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w700)),
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
  String _fulfilment = 'delivery'; // delivery | pickup
  bool _asap = true;               // Ҳарчи зудтар / Вақти муайян
  TimeOfDay? _slot;                // вақти интихобшуда (агар !_asap)
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
        _couponMsg = '✅ $pct% ${AppL10n.of(context).discountApplied}';
      } else {
        _discountPct = 0;
        _couponMsg = AppL10n.of(context).couponInvalid;
      }
    });
  }

  Future<void> _submit() async {
    if (_method == 'dc' && _receipt == null) {
      setState(() => _error = AppL10n.of(context).uploadReceiptFirst);
      return;
    }
    // Барои расонидан суроға ҳатмист (ҳангоми аз мағоза гирифтан не).
    if (_fulfilment == 'delivery' && _addressId == null) {
      setState(() => _error = AppL10n.of(context).addAddress);
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      // 1) Фармоиш месозем
      final res = await ApiClient.instance.dio.post(ApiEndpoints.checkout, data: {
        if (_fulfilment == 'delivery' && _addressId != null) 'address_id': _addressId,
        'payment_method': _method,
        'fulfilment': _fulfilment,
        'delivery_fee': _deliveryFee,
        'delivery_asap': _asap,
        if (!_asap && _slot != null)
          'delivery_slot':
              '${_slot!.hour.toString().padLeft(2, '0')}:${_slot!.minute.toString().padLeft(2, '0')}',
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
      if (mounted) setState(() { _loading = false; _error = msg ?? AppL10n.of(context).errorDuringPayment; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = AppL10n.of(context).errorDuringPayment; });
    }
  }

  double get _cartTotal => ref.read(cartProvider).total;

  /// Ҳаққи расонидан: ҳангоми «аз мағоза гирифтан» ройгон аст.
  double get _deliveryFee => _fulfilment == 'pickup' ? 0 : kDeliveryFee;
  double get _finalTotal =>
      (_cartTotal + _deliveryFee) * (1 - _discountPct / 100);

  Future<void> _addAddress() async {
    final added = await showAddAddress(context);
    if (added == true) ref.invalidate(addressesProvider);
  }

  Widget _addressSelector() {
    final addresses = ref.watch(addressesProvider);
    return addresses.when(
      loading: () => Padding(padding: const EdgeInsets.symmetric(vertical: 8),
          child: LinearProgressIndicator(color: AppColors.primary, backgroundColor: context.pal.surface)),
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
                color: context.pal.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _addressId == a.id ? AppColors.primary : context.pal.border,
                    width: _addressId == a.id ? 1.4 : 0.5)),
              child: Row(children: [
                Icon(_addressId == a.id ? FeatherIcons.checkCircle : FeatherIcons.circle,
                    color: _addressId == a.id ? AppColors.primary : context.pal.textMuted, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.title, style: TextStyle(color: context.pal.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(a.full, style: TextStyle(color: context.pal.textSecondary, fontSize: 12)),
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
    icon: const Icon(FeatherIcons.mapPin, color: AppColors.primary, size: 18),
    label: Text(AppL10n.of(context).addAddress,
        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)));

  @override
  Widget build(BuildContext context) {
    if (_sent) return Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(FeatherIcons.checkCircle, color: AppColors.success, size: 72),
      const SizedBox(height: 16),
      Text(AppL10n.of(context).orderAccepted, style: TextStyle(color: context.pal.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text(AppL10n.of(context).orderReceiptSent,
          style: TextStyle(color: context.pal.textSecondary), textAlign: TextAlign.center),
      const SizedBox(height: 20),
      AppButton(text: AppL10n.of(context).myOrders, onTap: () { Navigator.pop(context); context.push(RouteNames.orders); }),
    ]));

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: context.pal.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Align(alignment: Alignment.centerLeft,
          child: Text(AppL10n.of(context).confirmOrder, style: TextStyle(color: context.pal.textPrimary, fontSize: 18, fontWeight: FontWeight.w700))),
        const SizedBox(height: 16),

        // Тарзи расонидан (расонидан / аз мағоза гирифтан)
        Align(alignment: Alignment.centerLeft,
          child: Text(AppL10n.of(context).deliveryMethod, style: TextStyle(color: context.pal.textSecondary, fontSize: 13, fontWeight: FontWeight.w600))),
        const SizedBox(height: 8),
        _fulfilmentToggle(),
        const SizedBox(height: 16),

        // Суроғаи расонидан — танҳо барои расонидан лозим аст
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _fulfilment == 'pickup'
              ? Container(
                  key: const ValueKey('pickup-note'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(FeatherIcons.home, color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(AppL10n.of(context).pickupNoAddress,
                        style: TextStyle(color: context.pal.textSecondary, fontSize: 12.5))),
                  ]),
                )
              : Column(
                  key: const ValueKey('address-block'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppL10n.of(context).deliveryAddress,
                        style: TextStyle(color: context.pal.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _addressSelector(),
                  ],
                ),
        ),
        const SizedBox(height: 16),

        // Вақти расонидан
        Align(alignment: Alignment.centerLeft,
          child: Text(AppL10n.of(context).deliveryTime, style: TextStyle(color: context.pal.textSecondary, fontSize: 13, fontWeight: FontWeight.w600))),
        const SizedBox(height: 8),
        _timeChoice(),
        const SizedBox(height: 16),

        // Купон
        Align(alignment: Alignment.centerLeft,
          child: Text(AppL10n.of(context).couponPromo, style: TextStyle(color: context.pal.textSecondary, fontSize: 13, fontWeight: FontWeight.w600))),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Container(
            decoration: BoxDecoration(color: context.pal.surface, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.pal.border, width: 0.5)),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SafeInput(controller: _couponCtrl,
              hint: AppL10n.of(context).enterCode,
              textCapitalization: TextCapitalization.characters,
              textColor: context.pal.textPrimary, fontSize: 14))),
          const SizedBox(width: 8),
          SizedBox(height: 46, child: ElevatedButton(
            onPressed: _checkingCoupon ? null : _applyCoupon,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _checkingCoupon
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(AppL10n.of(context).apply, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))),
        ]),
        if (_couponMsg != null) Padding(padding: const EdgeInsets.only(top: 6),
          child: Align(alignment: Alignment.centerLeft,
            child: Text(_couponMsg!, style: TextStyle(
                color: _discountPct > 0 ? AppColors.success : AppColors.error, fontSize: 12)))),
        const SizedBox(height: 16),

        // Усули пардохт
        Align(alignment: Alignment.centerLeft,
          child: Text(AppL10n.of(context).paymentMethod, style: TextStyle(color: context.pal.textSecondary, fontSize: 13, fontWeight: FontWeight.w600))),
        const SizedBox(height: 8),
        _payOption('dc', FeatherIcons.creditCard, AppL10n.of(context).dcCard, AppL10n.of(context).dcCardDesc),
        _payOption('cod', FeatherIcons.truck, AppL10n.of(context).codTitle, AppL10n.of(context).codDesc),
        _walletOption(),
        const SizedBox(height: 16),

        // Қисми вобаста ба усул
        if (_method == 'dc') ...[
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: context.pal.surface, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [const Icon(FeatherIcons.creditCard, color: AppColors.primary, size: 20),
                const SizedBox(width: 8), Text(AppL10n.of(context).sellerDcNumber, style: TextStyle(color: context.pal.textMuted, fontSize: 12))]),
              const SizedBox(height: 8),
              Text('+992 XX XXX XXXX', style: TextStyle(color: context.pal.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(AppL10n.of(context).dcInstructions, style: TextStyle(color: context.pal.textSecondary, fontSize: 12)),
            ])),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickReceipt,
            child: Container(width: double.infinity, height: _receipt != null ? 160 : 90,
              decoration: BoxDecoration(color: context.pal.surface, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _receipt != null ? AppColors.success : context.pal.border, width: 1.5),
                  image: _receipt != null ? DecorationImage(image: FileImage(_receipt!), fit: BoxFit.cover) : null),
              child: _receipt == null ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(FeatherIcons.upload, color: AppColors.primary, size: 32),
                const SizedBox(height: 6),
                Text(AppL10n.of(context).uploadReceipt, style: const TextStyle(color: AppColors.primary, fontSize: 13)),
              ])) : null)),
          const SizedBox(height: 16),
        ],

        // Ҷамъбаст
        Container(padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: context.pal.surface, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            _row(AppL10n.of(context).productsWord, '${_cartTotal.toStringAsFixed(0)} сом.'),
            const SizedBox(height: 6),
            _row(
              AppL10n.of(context).delivery,
              _fulfilment == 'pickup'
                  ? AppL10n.of(context).pickupFree
                  : '${_deliveryFee.toStringAsFixed(0)} сом.',
            ),
            if (_discountPct > 0) ...[
              const SizedBox(height: 6),
              _row('${AppL10n.of(context).discountWord} ($_discountPct%)', '-${((_cartTotal + _deliveryFee) * _discountPct / 100).toStringAsFixed(0)} сом.'),
            ],
            const SizedBox(height: 8),
            Divider(color: context.pal.divider, height: 1),
            const SizedBox(height: 8),
            _row(AppL10n.of(context).totalPayment, '${_finalTotal.toStringAsFixed(0)} сом.', bold: true),
          ])),

        if (_error != null) Padding(padding: const EdgeInsets.only(top: 12),
          child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),

        const SizedBox(height: 16),
        AppButton(
          text: _method == 'wallet' ? AppL10n.of(context).payFromWallet : (_method == 'cod' ? AppL10n.of(context).confirmOrder : '${AppL10n.of(context).send} ✓'),
          isLoading: _loading,
          onTap: _submit,
        ),
        const SizedBox(height: 8),
      ])),
    );
  }

  /// Тугмаи дугона: Расонидан ↔ Аз мағоза гирифтан (бо аниматсияи ҳамворшуда).
  Widget _fulfilmentToggle() {
    final l = AppL10n.of(context);
    Widget half(String value, IconData icon, String label) {
      final sel = _fulfilment == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() {
            _fulfilment = value;
            _error = null;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
            decoration: BoxDecoration(
              gradient: sel ? AppColors.primaryGradient : null,
              color: sel ? null : context.pal.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: sel ? Colors.transparent : context.pal.border, width: 0.8),
              boxShadow: sel
                  ? [BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.32),
                      blurRadius: 12, offset: const Offset(0, 4))]
                  : null,
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(sel ? FeatherIcons.check : icon,
                  size: 17, color: sel ? Colors.white : context.pal.textSecondary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(label,
                    maxLines: 2,
                    style: TextStyle(
                        color: sel ? Colors.white : context.pal.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ),
      );
    }

    return Row(children: [
      half('delivery', FeatherIcons.truck, l.deliveryOption),
      const SizedBox(width: 10),
      half('pickup', FeatherIcons.home, l.pickupOption),
    ]);
  }

  /// Интихоби вақт: Ҳарчи зудтар ↔ Вақти муайян (бо интихобгари соат).
  Widget _timeChoice() {
    final l = AppL10n.of(context);
    Widget option(bool asapValue, String label) {
      final sel = _asap == asapValue;
      return GestureDetector(
        onTap: () async {
          if (!asapValue) {
            final picked = await showTimePicker(
              context: context,
              initialTime: _slot ?? const TimeOfDay(hour: 12, minute: 0),
            );
            if (picked == null) return;
            if (!mounted) return;
            setState(() { _asap = false; _slot = picked; });
          } else {
            setState(() { _asap = true; _slot = null; });
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 21, height: 21,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: sel ? AppColors.primary : context.pal.textMuted, width: 2),
              ),
              child: Center(
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutBack,
                  scale: sel ? 1 : 0,
                  child: Container(
                    width: 11, height: 11,
                    decoration: const BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    color: context.pal.textPrimary,
                    fontSize: 14,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
            if (!asapValue && _slot != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(_slot!.format(context),
                    style: const TextStyle(
                        color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ]),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      option(true, l.asSoonAsPossible),
      option(false, l.specificTime),
    ]);
  }

  Widget _payOption(String value, IconData icon, String title, String subtitle) {
    final sel = _method == value;
    return GestureDetector(
      onTap: () => setState(() { _method = value; _error = null; }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: context.pal.surface, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? AppColors.primary : context.pal.border, width: sel ? 1.4 : 0.5)),
        child: Row(children: [
          Icon(sel ? FeatherIcons.checkCircle : FeatherIcons.circle,
              color: sel ? AppColors.primary : context.pal.textMuted, size: 20),
          const SizedBox(width: 10),
          Icon(icon, color: context.pal.textSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: context.pal.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            Text(subtitle, style: TextStyle(color: context.pal.textMuted, fontSize: 11)),
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
        decoration: BoxDecoration(color: context.pal.surface, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? AppColors.primary : context.pal.border, width: sel ? 1.4 : 0.5)),
        child: Row(children: [
          Icon(sel ? FeatherIcons.checkCircle : FeatherIcons.circle,
              color: sel ? AppColors.primary : context.pal.textMuted, size: 20),
          const SizedBox(width: 10),
          Icon(FeatherIcons.dollarSign, color: context.pal.textSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppL10n.of(context).wallet, style: TextStyle(color: context.pal.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            Text('${AppL10n.of(context).balance}: ${balance.toStringAsFixed(0)} сом.${enough ? '' : ' (${AppL10n.of(context).insufficient})'}',
                style: TextStyle(color: enough ? context.pal.textMuted : AppColors.error, fontSize: 11)),
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
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Container(
      margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: pal.card, borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(0, 3), blurRadius: 8)]),
      child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(12),
          child: item.image != null ? CachedNetworkImage(imageUrl: item.image!, width: 84, height: 84, fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _ph(pal)) : _ph(pal)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: pal.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w700))),
            GestureDetector(onTap: onRemove,
              child: Padding(padding: const EdgeInsets.only(left: 6),
                child: Icon(FeatherIcons.x, color: pal.textMuted, size: 20))),
          ]),
          const SizedBox(height: 6),
          Text('${item.total.toStringAsFixed(0)} сом.',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 10),
          // Stepper-и миқдор (template style, green)
          Row(children: [
            _qtyBtn(FeatherIcons.minus, () => onQuantity(item.quantity - 1)),
            Container(
              constraints: const BoxConstraints(minWidth: 38),
              alignment: Alignment.center,
              child: Text('${item.quantity}',
                  style: TextStyle(color: pal.textPrimary, fontSize: 15, fontWeight: FontWeight.w700))),
            _qtyBtn(FeatherIcons.plus, () => onQuantity(item.quantity + 1)),
          ]),
        ])),
      ]),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
      child: Icon(icon, color: AppColors.primary, size: 18)),
  );

  Widget _ph(AppPalette pal) => Container(width: 84, height: 84, color: pal.surface,
      child: Icon(FeatherIcons.image, color: pal.textMuted));
}

class _row extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _row(this.label, this.value, {this.bold = false});
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(label, style: TextStyle(color: bold ? context.pal.textPrimary : context.pal.textSecondary,
        fontSize: bold ? 15 : 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
    Text(value, style: TextStyle(color: bold ? AppColors.primary : context.pal.textSecondary,
        fontSize: bold ? 17 : 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w400)),
  ]);
}

