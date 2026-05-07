import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
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
      if (ref.read(authProvider).isAuthenticated) {
        ref.read(cartProvider.notifier).loadCart();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final isAuth = ref.watch(authProvider).isAuthenticated;

    if (!isAuth) {
      return Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: _appBar(),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.shopping_bag_outlined, size: 80, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text('Барои дидани сабад ворид шавед',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
            const SizedBox(height: 20),
            AppButton(text: 'Ворид шавед', width: 200, height: 46,
                onTap: () => context.go(RouteNames.login)),
          ]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: _appBar(
        action: cart.items.isNotEmpty
            ? TextButton(
                onPressed: () async {
                  for (final item in [...cart.items]) {
                    await ref.read(cartProvider.notifier).removeItem(item.id);
                  }
                },
                child: const Text('Тоза кардан', style: TextStyle(color: AppColors.error, fontSize: 13)),
              )
            : null,
      ),
      body: cart.isLoading
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [
                  ShimmerCard(width: 80, height: 80, radius: 12),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ShimmerCard(height: 14, radius: 4),
                    const SizedBox(height: 8),
                    ShimmerCard(height: 14, width: 100, radius: 4),
                  ])),
                ]),
              ),
            )
          : cart.items.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.shopping_cart_outlined, size: 80, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    const Text('Сабад холи аст', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text('Маҳсулотҳои дилхоҳро ба сабад илова кунед',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13), textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    AppButton(text: 'Харид кунед', width: 200, height: 46,
                        onTap: () => context.go(RouteNames.home)),
                  ]),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: cart.items.length,
                        itemBuilder: (_, i) => _CartItem(
                          item: cart.items[i],
                          onRemove: () => ref.read(cartProvider.notifier).removeItem(cart.items[i].id),
                          onIncrease: () => ref.read(cartProvider.notifier).addToCart(cart.items[i].productId),
                          onDecrease: () {
                            if (cart.items[i].quantity > 1) {
                              // local qty -- could call API for decrement
                            } else {
                              ref.read(cartProvider.notifier).removeItem(cart.items[i].id);
                            }
                          },
                        ),
                      ),
                    ),
                    // Summary
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      decoration: const BoxDecoration(
                        color: AppColors.bgCard,
                        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Column(
                        children: [
                          _SummaryRow('Маҳсулот (${cart.itemCount})',
                              '${cart.total.toStringAsFixed(0)} сом.'),
                          const SizedBox(height: 8),
                          const _SummaryRow('Доставка', '20 сом.'),
                          const SizedBox(height: 12),
                          const Divider(color: AppColors.divider, height: 1),
                          const SizedBox(height: 12),
                          _SummaryRow(
                            'Ҷамъ',
                            '${(cart.total + 20).toStringAsFixed(0)} сом.',
                            bold: true,
                          ),
                          const SizedBox(height: 16),
                          AppButton(
                            text: 'Пардохт — ${(cart.total + 20).toStringAsFixed(0)} сом.',
                            onTap: () => _checkout(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  void _checkout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Icon(Icons.payment_outlined, color: AppColors.primary, size: 48),
          const SizedBox(height: 12),
          const Text('Пардохт', style: TextStyle(
              color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Тарзи пардохтро интихоб кунед',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          _PayOption(icon: Icons.account_balance_outlined, label: 'Корти бонкӣ'),
          const SizedBox(height: 8),
          _PayOption(icon: Icons.money_outlined, label: 'Пардохти нақд'),
          const SizedBox(height: 8),
          _PayOption(icon: Icons.phone_android_outlined, label: 'EasyPay / Alif'),
          const SizedBox(height: 20),
          AppButton(
            text: 'Тасдиқ кардан',
            onTap: () async {
              Navigator.pop(context);
              await ref.read(cartProvider.notifier).checkout('');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('Фармоиш қабул шуд ✅'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                context.push(RouteNames.orders);
              }
            },
          ),
        ]),
      ),
    );
  }

  PreferredSizeWidget _appBar({Widget? action}) => AppBar(
    backgroundColor: AppColors.bgDark,
    title: const Text('Сабад',
        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
    actions: [if (action != null) action],
  );
}

class _CartItem extends StatelessWidget {
  final CartItemModel item;
  final VoidCallback onRemove, onIncrease, onDecrease;
  const _CartItem({required this.item, required this.onRemove,
      required this.onIncrease, required this.onDecrease});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(children: [
        // Image
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: item.image != null && item.image!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: item.image!,
                  width: 80, height: 80, fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _placeholder())
              : _placeholder(),
        ),
        const SizedBox(width: 12),
        // Info
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text('${item.price.toStringAsFixed(0)} сом.',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            // Qty controls
            Row(children: [
              _QtyBtn(icon: Icons.remove, onTap: onDecrease),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('${item.quantity}',
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              _QtyBtn(icon: Icons.add, onTap: onIncrease),
              const Spacer(),
              Text('${item.total.toStringAsFixed(0)} сом.',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ]),
          ]),
        ),
        const SizedBox(width: 8),
        // Delete
        IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
          padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
      ]),
    );
  }

  Widget _placeholder() => Container(
      width: 80, height: 80,
      decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(12)),
      child: const Icon(Icons.image_outlined, color: AppColors.textMuted, size: 32));
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
          color: AppColors.bgSurface, borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 0.5)),
      child: Icon(icon, size: 16, color: AppColors.textSecondary),
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _SummaryRow(this.label, this.value, {this.bold = false});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(
          color: bold ? AppColors.textPrimary : AppColors.textSecondary,
          fontSize: bold ? 16 : 13,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
      Text(value, style: TextStyle(
          color: bold ? AppColors.primary : AppColors.textSecondary,
          fontSize: bold ? 18 : 13,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w400)),
    ],
  );
}

class _PayOption extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PayOption({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
        color: AppColors.bgSurface, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5)),
    child: Row(children: [
      Icon(icon, color: AppColors.primary, size: 22),
      const SizedBox(width: 12),
      Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
      const Spacer(),
      const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
    ]),
  );
}
