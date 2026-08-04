import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/api/api_client.dart';
import '../../core/app_l10n.dart';
import '../../core/l10n/admin_l10n.dart';
import '../../core/l10n/extra_l10n.dart';
import '../../providers/admin_provider.dart';
import '../../providers/cargo_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/return_provider.dart';
import '../../providers/search_provider.dart';
import '../../shared/widgets/error_screen.dart';
import '../../shared/widgets/safe_input.dart';

// ────────────────────────────────────────────────────────────────────────────
// Shared template building blocks
// ────────────────────────────────────────────────────────────────────────────
const _cardShadow = [BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 4))];

BoxDecoration _cardDeco(BuildContext context, {Color? highlight}) => BoxDecoration(
      color: context.pal.card,
      borderRadius: BorderRadius.circular(18),
      border: highlight != null ? Border.all(color: highlight, width: 1) : null,
      boxShadow: _cardShadow,
    );

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Gradient gradient;
  const _GradientButton({required this.label, required this.onPressed, this.gradient = AppColors.primaryGradient});
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Ink(
            height: 44,
            decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(14)),
            child: Center(
              child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      );
}

// ════════════════════════════════════════════════════════════════════════════
// КОРБАРОН
// ════════════════════════════════════════════════════════════════════════════
class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(adminUsersProvider);
    final l = AppL10n.of(context);
    return Scaffold(
      backgroundColor: context.pal.scaffold,
      appBar: AppBar(backgroundColor: context.pal.scaffold, elevation: 0,
        iconTheme: IconThemeData(color: context.pal.textPrimary),
        title: Text(l.usersLabel, style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: Icon(FeatherIcons.refreshCw, color: context.pal.textSecondary),
            onPressed: () => ref.invalidate(adminUsersProvider))]),
      body: users.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorScreen(message: e.toString(), onRetry: () => ref.invalidate(adminUsersProvider)),
        data: (list) => list.isEmpty
            ? Center(child: Text(l.noUsers, style: TextStyle(color: context.pal.textSecondary)))
            : ListView.builder(padding: const EdgeInsets.all(16), itemCount: list.length,
                itemBuilder: (_, i) => _UserCard(user: list[i],
                    onChanged: () => ref.invalidate(adminUsersProvider))),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onChanged;
  const _UserCard({required this.user, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final id = user['id']?.toString() ?? '';
    final name = user['name']?.toString() ?? user['full_name']?.toString() ?? l.userWord;
    final email = user['email']?.toString() ?? '';
    final role = user['role']?.toString() ?? 'buyer';
    final banned = user['is_banned'] == true;
    final verified = user['is_verified'] == true;
    final passport = user['passport_url']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14),
      decoration: _cardDeco(context),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.pal.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w700))),
            if (verified) const Padding(padding: EdgeInsets.only(left: 4),
                child: Icon(FeatherIcons.checkCircle, color: AppColors.info, size: 15)),
          ]),
          const SizedBox(height: 2),
          Text(email, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.pal.textMuted, fontSize: 12)),
          const SizedBox(height: 6),
          Row(children: [
            _chip(role, AppColors.primary),
            if (banned) ...[const SizedBox(width: 6), _chip(l.bannedLabel, AppColors.error)],
            if (passport.isNotEmpty) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _viewPassport(context, passport),
                child: _chip(l.passportChip, AppColors.info)),
            ],
          ]),
        ])),
        PopupMenuButton<String>(
          color: context.pal.elevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          icon: Icon(FeatherIcons.moreVertical, color: context.pal.textSecondary),
          onSelected: (v) async {
            final messenger = ScaffoldMessenger.of(context);
            try {
              if (v == 'ban') await AdminService.banUser(id);
              if (v == 'unban') await AdminService.unbanUser(id);
              if (v == 'verify') await AdminService.verifySeller(id);
              onChanged();
              messenger.showSnackBar(SnackBar(content: Text(l.executedDone),
                  backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
            } catch (_) {
              messenger.showSnackBar(SnackBar(content: Text(l.error),
                  backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
            }
          },
          itemBuilder: (_) => [
            if (!verified) PopupMenuItem(value: 'verify',
                child: Text(l.verifySellerAction, style: TextStyle(color: context.pal.textPrimary))),
            if (!banned) PopupMenuItem(value: 'ban',
                child: Text(l.banUserAction, style: const TextStyle(color: AppColors.error)))
            else PopupMenuItem(value: 'unban',
                child: Text(l.unbanAction, style: const TextStyle(color: AppColors.success))),
          ],
        ),
      ]),
    );
  }

  Widget _chip(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
    child: Text(t, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w700)));

  void _viewPassport(BuildContext context, String url) {
    final l = AppL10n.of(context);
    showDialog(context: context, builder: (_) => Dialog(
      backgroundColor: context.pal.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: const EdgeInsets.all(14),
          child: Text(l.userPassport, style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w700))),
        ClipRRect(borderRadius: BorderRadius.circular(12),
          child: InteractiveViewer(child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain,
            placeholder: (_, __) => const Padding(padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: AppColors.primary)),
            errorWidget: (_, __, ___) => Padding(padding: const EdgeInsets.all(40),
                child: Icon(FeatherIcons.image, color: context.pal.textMuted, size: 48))))),
        const SizedBox(height: 12),
      ]),
    ));
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ФАРМОИШҲО
// ════════════════════════════════════════════════════════════════════════════
const _orderStatuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];

String _statusLabel(AppL10n l, String s) {
  switch (s) {
    case 'pending':
      return l.statusPending;
    case 'processing':
      return l.statusProcessing;
    case 'shipped':
      return l.statusShipped;
    case 'delivered':
      return l.statusDelivered;
    case 'cancelled':
      return l.statusCancelled;
    case 'payment_uploaded':
      return l.paymentConfirmed;
    default:
      return s;
  }
}

class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(adminOrdersProvider);
    final l = AppL10n.of(context);
    return Scaffold(
      backgroundColor: context.pal.scaffold,
      appBar: AppBar(backgroundColor: context.pal.scaffold, elevation: 0,
        iconTheme: IconThemeData(color: context.pal.textPrimary),
        title: Text(l.allOrders, style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: Icon(FeatherIcons.refreshCw, color: context.pal.textSecondary),
            onPressed: () => ref.invalidate(adminOrdersProvider))]),
      body: orders.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorScreen(message: e.toString(), onRetry: () => ref.invalidate(adminOrdersProvider)),
        data: (list) => list.isEmpty
            ? Center(child: Text(l.noOrders, style: TextStyle(color: context.pal.textSecondary)))
            : ListView.builder(padding: const EdgeInsets.all(16), itemCount: list.length,
                itemBuilder: (_, i) => _OrderCard(order: list[i],
                    onChanged: () => ref.invalidate(adminOrdersProvider))),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onChanged;
  const _OrderCard({required this.order, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final id = order['id']?.toString() ?? '';
    final status = order['status']?.toString() ?? 'pending';
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    DateTime? created;
    if (order['created_at'] != null) created = DateTime.tryParse(order['created_at'].toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: _cardDeco(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('#${(id.length > 8 ? id.substring(0, 8) : id).toUpperCase()}',
              style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w800, fontSize: 14)),
          const Spacer(),
          Text('${total.toStringAsFixed(0)} ${l.som}',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 15)),
        ]),
        const SizedBox(height: 4),
        if (created != null)
          Text(DateFormat('dd.MM.yyyy • HH:mm').format(created),
              style: TextStyle(color: context.pal.textMuted, fontSize: 12)),
        const SizedBox(height: 12),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
            child: Text(_statusLabel(l, status),
                style: const TextStyle(color: AppColors.info, fontSize: 12, fontWeight: FontWeight.w700))),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _changeStatus(context),
            icon: const Icon(FeatherIcons.edit2, size: 16, color: AppColors.primary),
            label: Text(l.statusWord, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))),
        ]),
      ]),
    );
  }

  void _changeStatus(BuildContext context) {
    final l = AppL10n.of(context);
    final id = order['id']?.toString() ?? '';
    showModalBottomSheet(context: context, backgroundColor: context.pal.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: context.pal.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          Text(l.newStatus, style: TextStyle(color: context.pal.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ..._orderStatuses.map((s) => ListTile(
            leading: const Icon(FeatherIcons.circle, size: 10, color: AppColors.primary),
            title: Text(_statusLabel(l, s), style: TextStyle(color: context.pal.textPrimary)),
            onTap: () async {
              Navigator.pop(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await AdminService.updateOrderStatus(id, s);
                onChanged();
                messenger.showSnackBar(SnackBar(content: Text(l.statusUpdated),
                    backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
              } catch (_) {
                messenger.showSnackBar(SnackBar(content: Text(l.error),
                    backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
              }
            },
          )),
        ]),
      ));
  }
}

// ════════════════════════════════════════════════════════════════════════════
// КАТЕГОРИЯҲО
// ════════════════════════════════════════════════════════════════════════════
class AdminCategoriesScreen extends ConsumerWidget {
  const AdminCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider);
    final l = AppL10n.of(context);
    return Scaffold(
      backgroundColor: context.pal.scaffold,
      appBar: AppBar(backgroundColor: context.pal.scaffold, elevation: 0,
        iconTheme: IconThemeData(color: context.pal.textPrimary),
        title: Text(l.categories, style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w700))),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => _addCategory(context, ref),
        icon: const Icon(FeatherIcons.plus, color: Colors.white),
        label: Text(l.addWord, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
      body: cats.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorScreen(message: e.toString(), onRetry: () => ref.invalidate(categoriesProvider)),
        data: (list) => list.isEmpty
            ? Center(child: Text(l.noCategories, style: TextStyle(color: context.pal.textSecondary)))
            : ListView.builder(padding: const EdgeInsets.all(16), itemCount: list.length,
                itemBuilder: (_, i) => Container(
                  margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
                  decoration: _cardDeco(context),
                  child: Row(children: [
                    Container(width: 40, height: 40,
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(FeatherIcons.grid, color: AppColors.primary, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(list[i].name,
                        style: TextStyle(color: context.pal.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w600))),
                  ]))),
      ),
    );
  }

  void _addCategory(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: context.pal.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(l.newCategory, style: TextStyle(color: context.pal.textPrimary)),
      content: SafeInput(controller: ctrl, autofocus: true,
        hint: l.categoryNameHint,
        textColor: context.pal.textPrimary),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancelShort, style: TextStyle(color: context.pal.textMuted))),
        TextButton(
          onPressed: () async {
            final name = ctrl.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(ctx);
            final messenger = ScaffoldMessenger.of(context);
            final slug = name.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
            try {
              await AdminService.createCategory(name, slug);
              ref.invalidate(categoriesProvider);
              messenger.showSnackBar(SnackBar(content: Text(l.categoryAdded),
                  backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
            } catch (_) {
              messenger.showSnackBar(SnackBar(content: Text(l.error),
                  backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
            }
          },
          child: Text(l.addWord, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))),
      ],
    ));
  }
}

// ════════════════════════════════════════════════════════════════════════════
// КУПОНҲО
// ════════════════════════════════════════════════════════════════════════════
class AdminCouponsScreen extends ConsumerWidget {
  const AdminCouponsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coupons = ref.watch(adminCouponsProvider);
    final l = AppL10n.of(context);
    return Scaffold(
      backgroundColor: context.pal.scaffold,
      appBar: AppBar(backgroundColor: context.pal.scaffold, elevation: 0,
        iconTheme: IconThemeData(color: context.pal.textPrimary),
        title: Text(l.couponsTitle, style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w700))),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => _create(context, ref),
        icon: const Icon(FeatherIcons.plus, color: Colors.white),
        label: Text(l.couponFab, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
      body: coupons.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorScreen(message: e.toString(), onRetry: () => ref.invalidate(adminCouponsProvider)),
        data: (list) => list.isEmpty
            ? Center(child: Text(l.noCoupons, style: TextStyle(color: context.pal.textSecondary)))
            : ListView.builder(padding: const EdgeInsets.all(16), itemCount: list.length,
                itemBuilder: (_, i) {
                  final c = list[i];
                  final used = (c['used_count'] as num?)?.toInt() ?? 0;
                  final max = (c['max_uses'] as num?)?.toInt() ?? 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
                    decoration: _cardDeco(context),
                    child: Row(children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(c['code']?.toString() ?? '',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 14))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('-${c['discount_percent'] ?? 0}% ${l.discountSuffix}',
                            style: TextStyle(color: context.pal.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('${l.usedLabel}: $used${max > 0 ? ' / $max' : ' ${l.unlimitedLabel}'}',
                            style: TextStyle(color: context.pal.textMuted, fontSize: 12)),
                      ])),
                    ]));
                }),
      ),
    );
  }

  void _create(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final code = TextEditingController();
    final disc = TextEditingController(text: '10');
    final maxU = TextEditingController(text: '0');
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: context.pal.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(l.newCoupon, style: TextStyle(color: context.pal.textPrimary)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _dlgField(code, l.codeExampleHint, cap: true),
        _dlgField(disc, l.discountPercentHint, number: true),
        _dlgField(maxU, l.usageLimitHint, number: true),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancelShort, style: TextStyle(color: context.pal.textMuted))),
        TextButton(
          onPressed: () async {
            final cd = code.text.trim();
            final pct = int.tryParse(disc.text.trim()) ?? 0;
            if (cd.isEmpty || pct <= 0) return;
            Navigator.pop(ctx);
            final messenger = ScaffoldMessenger.of(context);
            try {
              await AdminService.createCoupon(cd, pct, int.tryParse(maxU.text.trim()) ?? 0);
              ref.invalidate(adminCouponsProvider);
              messenger.showSnackBar(SnackBar(content: Text(l.couponCreated),
                  backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
            } catch (_) {
              messenger.showSnackBar(SnackBar(content: Text(l.couponDuplicateError),
                  backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
            }
          },
          child: Text(l.createWord, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))),
      ],
    ));
  }
}

Widget _dlgField(TextEditingController c, String hint, {bool number = false, bool cap = false}) =>
    Padding(padding: const EdgeInsets.only(bottom: 10),
      child: SafeInput(controller: c,
        keyboardType: number ? TextInputType.number : null,
        textCapitalization: cap ? TextCapitalization.characters : TextCapitalization.none,
        hint: hint,
        textColor: AppColors.textPrimary));

// ════════════════════════════════════════════════════════════════════════════
// ТАСДИҚИ ҲАМЁН (пополнения)
// ════════════════════════════════════════════════════════════════════════════
class AdminWalletScreen extends ConsumerWidget {
  const AdminWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(adminWalletPendingProvider);
    final l = AppL10n.of(context);
    return Scaffold(
      backgroundColor: context.pal.scaffold,
      appBar: AppBar(backgroundColor: context.pal.scaffold, elevation: 0,
        iconTheme: IconThemeData(color: context.pal.textPrimary),
        title: Text(l.topUpApproval, style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: Icon(FeatherIcons.refreshCw, color: context.pal.textSecondary),
            onPressed: () => ref.invalidate(adminWalletPendingProvider))]),
      body: pending.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorScreen(message: e.toString(), onRetry: () => ref.invalidate(adminWalletPendingProvider)),
        data: (list) => list.isEmpty
            ? Center(child: Text(l.noPendingRequests, style: TextStyle(color: context.pal.textSecondary)))
            : ListView.builder(padding: const EdgeInsets.all(16), itemCount: list.length,
                itemBuilder: (_, i) {
                  final t = list[i];
                  final id = t['id']?.toString() ?? '';
                  final amount = (t['amount'] as num?)?.toDouble() ?? 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
                    decoration: _cardDeco(context),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(t['name']?.toString() ?? t['email']?.toString() ?? l.userWord,
                            style: TextStyle(color: context.pal.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w700))),
                        Text('+${amount.toStringAsFixed(0)} ${l.som}',
                            style: const TextStyle(color: AppColors.success, fontSize: 16, fontWeight: FontWeight.w800)),
                      ]),
                      const SizedBox(height: 4),
                      Text(t['email']?.toString() ?? '', style: TextStyle(color: context.pal.textMuted, fontSize: 12)),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(child: OutlinedButton(
                          onPressed: () => _act(context, ref, id, false),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            minimumSize: const Size.fromHeight(44)),
                          child: Text(l.rejectShort, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)))),
                        const SizedBox(width: 10),
                        Expanded(child: _GradientButton(
                          label: l.confirmShort,
                          onPressed: () => _act(context, ref, id, true))),
                      ]),
                    ]));
                }),
      ),
    );
  }

  void _act(BuildContext context, WidgetRef ref, String id, bool approve) async {
    final l = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (approve) {
        await AdminService.approveWalletTx(id);
      } else {
        await AdminService.rejectWalletTx(id);
      }
      ref.invalidate(adminWalletPendingProvider);
      messenger.showSnackBar(SnackBar(content: Text(approve ? l.confirmedDone : l.rejectedDone),
          backgroundColor: approve ? AppColors.success : AppColors.error, behavior: SnackBarBehavior.floating));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.error),
          backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ГУЗОРИШҲО (Reports)
// ════════════════════════════════════════════════════════════════════════════
class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(adminReportsProvider);
    final l = AppL10n.of(context);
    return Scaffold(
      backgroundColor: context.pal.scaffold,
      appBar: AppBar(backgroundColor: context.pal.scaffold, elevation: 0,
        iconTheme: IconThemeData(color: context.pal.textPrimary),
        title: Text(l.reportsTitle, style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: Icon(FeatherIcons.refreshCw, color: context.pal.textSecondary),
            onPressed: () => ref.invalidate(adminReportsProvider))]),
      body: reports.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorScreen(message: e.toString(), onRetry: () => ref.invalidate(adminReportsProvider)),
        data: (list) => list.isEmpty
            ? Center(child: Text(l.noReports, style: TextStyle(color: context.pal.textSecondary)))
            : ListView.builder(padding: const EdgeInsets.all(16), itemCount: list.length,
                itemBuilder: (_, i) {
                  final r = list[i];
                  final resolved = r['resolved'] == true;
                  final type = r['target_type']?.toString() ?? '';
                  DateTime? date;
                  if (r['created_at'] != null) date = DateTime.tryParse(r['created_at'].toString());
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
                    decoration: _cardDeco(context, highlight: resolved ? null : AppColors.error.withValues(alpha: 0.4)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                          child: Text(type == 'product' ? l.productsCountLabel : l.userWord,
                              style: const TextStyle(color: AppColors.info, fontSize: 10, fontWeight: FontWeight.w700))),
                        const Spacer(),
                        if (resolved)
                          Text(l.resolvedLabel, style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w700))
                        else
                          TextButton(onPressed: () async {
                            try {
                              await ApiClient.instance.dio.post('/admin/reports/${r['id']}/resolve');
                              ref.invalidate(adminReportsProvider);
                            } catch (_) {}
                          }, child: Text(l.resolveAction, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))),
                      ]),
                      const SizedBox(height: 8),
                      Text(r['reason']?.toString() ?? '',
                          style: TextStyle(color: context.pal.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('ID: ${r['target_id']?.toString() ?? ''}',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: context.pal.textMuted, fontSize: 11)),
                      if (date != null)
                        Text(DateFormat('dd.MM.yyyy • HH:mm').format(date),
                            style: TextStyle(color: context.pal.textMuted, fontSize: 11)),
                    ]));
                }),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// БОЗГАШТ / ИВАЗ (Returns)
// ════════════════════════════════════════════════════════════════════════════
class AdminReturnsScreen extends ConsumerWidget {
  const AdminReturnsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final returns = ref.watch(adminReturnsProvider);
    final l = AppL10n.of(context);
    return Scaffold(
      backgroundColor: context.pal.scaffold,
      appBar: AppBar(backgroundColor: context.pal.scaffold, elevation: 0,
        iconTheme: IconThemeData(color: context.pal.textPrimary),
        title: Text(l.returnsAndExchange, style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: Icon(FeatherIcons.refreshCw, color: context.pal.textSecondary),
            onPressed: () => ref.invalidate(adminReturnsProvider))]),
      body: returns.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorScreen(message: e.toString(), onRetry: () => ref.invalidate(adminReturnsProvider)),
        data: (list) => list.isEmpty
            ? Center(child: Text(l.noRequests, style: TextStyle(color: context.pal.textSecondary)))
            : ListView.builder(padding: const EdgeInsets.all(16), itemCount: list.length,
                itemBuilder: (_, i) {
                  final r = list[i];
                  final status = r['status']?.toString() ?? 'pending';
                  final type = r['type']?.toString() == 'exchange' ? l.exchangeWord : l.refundWord;
                  final id = r['id']?.toString() ?? '';
                  DateTime? date;
                  if (r['created_at'] != null) date = DateTime.tryParse(r['created_at'].toString());
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
                    decoration: _cardDeco(context, highlight: status == 'pending' ? AppColors.warning.withValues(alpha: 0.4) : null),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                          child: Text(type, style: const TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.w700))),
                        const SizedBox(width: 8),
                        Text(r['user_name']?.toString() ?? '', style: TextStyle(color: context.pal.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text(status, style: TextStyle(
                            color: status == 'rejected' ? AppColors.error : (status == 'completed' || status == 'approved' ? AppColors.success : AppColors.warning),
                            fontSize: 11, fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 8),
                      Text(r['reason']?.toString() ?? '', style: TextStyle(color: context.pal.textSecondary, fontSize: 13)),
                      Text('${l.orderPrefix}: #${(r['order_id']?.toString() ?? '').padRight(8).substring(0, 8).toUpperCase()}'
                          '${date != null ? ' • ${DateFormat('dd.MM.yyyy').format(date)}' : ''}',
                          style: TextStyle(color: context.pal.textMuted, fontSize: 11)),
                      if (status == 'pending' || status == 'approved') ...[
                        const SizedBox(height: 14),
                        Row(children: [
                          if (status == 'pending')
                            Expanded(child: OutlinedButton(
                              onPressed: () => _update(context, ref, id, 'rejected'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.error),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                minimumSize: const Size.fromHeight(44)),
                              child: Text(l.rejectShort, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)))),
                          if (status == 'pending') const SizedBox(width: 8),
                          if (status == 'pending')
                            Expanded(child: _GradientButton(
                              label: l.acceptShort,
                              gradient: const LinearGradient(colors: [AppColors.info, Color(0xFF00A3FF)]),
                              onPressed: () => _update(context, ref, id, 'approved'))),
                          if (status == 'approved')
                            Expanded(child: _GradientButton(
                              label: l.completeRefundAction,
                              onPressed: () => _update(context, ref, id, 'completed'))),
                        ]),
                      ],
                    ]));
                }),
      ),
    );
  }

  void _update(BuildContext context, WidgetRef ref, String id, String status) async {
    final l = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ReturnService.adminUpdate(id, status);
      ref.invalidate(adminReturnsProvider);
      messenger.showSnackBar(SnackBar(content: Text(l.updatedDone),
          backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.error),
          backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ДАРХОСТҲОИ ФУРӮШАНДА (Seller requests / pending approvals)
// ════════════════════════════════════════════════════════════════════════════
class AdminSellerRequestsScreen extends ConsumerWidget {
  const AdminSellerRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(adminSellerRequestsProvider);
    return Scaffold(
      backgroundColor: context.pal.scaffold,
      appBar: AppBar(
        backgroundColor: context.pal.scaffold,
        elevation: 0,
        iconTheme: IconThemeData(color: context.pal.textPrimary),
        title: Text(AppL10n.of(context).sellerRequestsTitle,
            style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
              icon: Icon(FeatherIcons.refreshCw, color: context.pal.textSecondary),
              onPressed: () => ref.invalidate(adminSellerRequestsProvider)),
        ],
      ),
      body: requests.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorScreen(
            message: e.toString(), onRetry: () => ref.invalidate(adminSellerRequestsProvider)),
        data: (list) => list.isEmpty
            ? _empty(context)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) => _SellerRequestCard(
                      request: list[i],
                      onChanged: () => ref.invalidate(adminSellerRequestsProvider),
                    )),
      ),
    );
  }

  Widget _empty(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 96, height: 96,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(FeatherIcons.clock, color: AppColors.primary, size: 42),
          ),
          const SizedBox(height: 18),
          Text(AppL10n.of(context).noNewRequests,
              style: TextStyle(color: context.pal.textSecondary, fontSize: 15, fontWeight: FontWeight.w600)),
        ]),
      );
}

class _SellerRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onChanged;
  const _SellerRequestCard({required this.request, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final id = request['id']?.toString() ?? '';
    final name = request['name']?.toString() ?? l.userWord;
    final email = request['email']?.toString() ?? '';
    final passport = request['passport_url']?.toString() ?? '';
    DateTime? created;
    if (request['created_at'] != null) created = DateTime.tryParse(request['created_at'].toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 48, height: 48,
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
            child: Center(
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 19)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.pal.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Row(children: [
              Icon(FeatherIcons.mail, color: context.pal.textMuted, size: 13),
              const SizedBox(width: 5),
              Expanded(child: Text(email, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.pal.textMuted, fontSize: 12))),
            ]),
          ])),
        ]),
        if (created != null) ...[
          const SizedBox(height: 10),
          Row(children: [
            Icon(FeatherIcons.clock, color: context.pal.textMuted, size: 13),
            const SizedBox(width: 5),
            Text(DateFormat('dd.MM.yyyy • HH:mm').format(created),
                style: TextStyle(color: context.pal.textMuted, fontSize: 11.5)),
          ]),
        ],
        const SizedBox(height: 12),
        if (passport.isNotEmpty)
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _viewPassport(context, passport),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(FeatherIcons.image, color: AppColors.info, size: 16),
                  const SizedBox(width: 8),
                  Text(l.viewPassport,
                      style: const TextStyle(color: AppColors.info, fontSize: 13, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: () => _act(context, id, approve: false),
            icon: const Icon(FeatherIcons.userX, size: 16, color: AppColors.error),
            label: Text(l.rejectAction,
                style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              minimumSize: const Size.fromHeight(44),
            ),
          )),
          const SizedBox(width: 10),
          Expanded(child: _GradientButton(
            label: l.approveAction,
            onPressed: () => _act(context, id, approve: true),
          )),
        ]),
      ]),
    );
  }

  void _act(BuildContext context, String id, {required bool approve}) async {
    final l = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ApiClient.instance.dio.post(
          approve ? '/admin/users/$id/verify-seller' : '/admin/users/$id/reject-seller');
      onChanged();
      messenger.showSnackBar(SnackBar(
          content: Text(approve ? l.sellerApproved : l.requestRejected),
          backgroundColor: approve ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.error),
          backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    }
  }

  void _viewPassport(BuildContext context, String url) {
    showDialog(context: context, builder: (_) => Dialog(
      backgroundColor: context.pal.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: const EdgeInsets.all(14),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(FeatherIcons.image, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(AppL10n.of(context).passportTitle,
                style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w700)),
          ])),
        ClipRRect(borderRadius: BorderRadius.circular(12),
          child: InteractiveViewer(child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain,
            placeholder: (_, __) => const Padding(padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: AppColors.primary)),
            errorWidget: (_, __, ___) => Padding(padding: const EdgeInsets.all(40),
                child: Icon(FeatherIcons.image, color: context.pal.textMuted, size: 48))))),
        const SizedBox(height: 12),
      ]),
    ));
  }
}

// ════════════════════════════════════════════════════════════════════════════
// КАРГО (доставка аз Хитой) — идораи шарик/админ
// ════════════════════════════════════════════════════════════════════════════
const _cargoStatuses = ['new', 'received', 'shipped', 'arrived', 'delivered'];
const _cargoStatusLabels = {
  'new': 'Қабул шуд',
  'received': 'Ба анбори Хитой расид',
  'shipped': 'Фиристода шуд',
  'arrived': 'Ба кишвар расид',
  'delivered': 'Супорида шуд',
};

class AdminCargoScreen extends ConsumerWidget {
  const AdminCargoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cargo = ref.watch(adminCargoProvider);
    return Scaffold(
      backgroundColor: context.pal.scaffold,
      appBar: AppBar(
        backgroundColor: context.pal.scaffold,
        elevation: 0,
        iconTheme: IconThemeData(color: context.pal.textPrimary),
        title: Text('Карго — дархостҳо',
            style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
              tooltip: 'Танзимот (суроға, тарифҳо)',
              icon: const Icon(FeatherIcons.settings, color: AppColors.primary),
              onPressed: () => _cargoSettings(context, ref)),
          IconButton(
              icon: Icon(FeatherIcons.refreshCw, color: context.pal.textSecondary),
              onPressed: () => ref.invalidate(adminCargoProvider))
        ],
      ),
      body: cargo.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorScreen(message: e.toString(), onRetry: () => ref.invalidate(adminCargoProvider)),
        data: (list) => list.isEmpty
            ? Center(child: Text('Ҳоло дархост нест', style: TextStyle(color: context.pal.textSecondary)))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) => _CargoAdminCard(
                    order: list[i], onChanged: () => ref.invalidate(adminCargoProvider))),
      ),
    );
  }
}

class _CargoAdminCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onChanged;
  const _CargoAdminCard({required this.order, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final id = order['id']?.toString() ?? '';
    final desc = order['description']?.toString() ?? '';
    final link = order['product_link']?.toString() ?? '';
    final track = order['track_code']?.toString() ?? '';
    final dest = order['destination']?.toString() ?? 'tj';
    final status = order['status']?.toString() ?? 'new';
    final weight = (order['weight'] as num?)?.toDouble() ?? 0;
    final cost = (order['cost'] as num?)?.toDouble() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8)),
            child: Text(dest == 'ru' ? '🇷🇺 РУ' : '🇹🇯 ТҶ',
                style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
        if (link.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(link, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.info, fontSize: 12)),
        ],
        if (track.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('Track: $track', style: TextStyle(color: context.pal.textSecondary, fontSize: 12)),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
            child: Text(_cargoStatusLabels[status] ?? status,
                style: const TextStyle(color: AppColors.info, fontSize: 12, fontWeight: FontWeight.w700))),
          const Spacer(),
          if (weight > 0)
            Text('${weight.toStringAsFixed(1)} кг · ${cost.toStringAsFixed(0)} сом',
                style: TextStyle(color: context.pal.textSecondary, fontSize: 12)),
        ]),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _edit(context),
            icon: const Icon(FeatherIcons.edit2, size: 16, color: AppColors.primary),
            label: const Text('Идора', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  void _edit(BuildContext context) {
    final id = order['id']?.toString() ?? '';
    final trackCtrl = TextEditingController(text: order['track_code']?.toString() ?? '');
    final weightCtrl = TextEditingController(
        text: ((order['weight'] as num?)?.toDouble() ?? 0) > 0
            ? ((order['weight'] as num).toDouble()).toString()
            : '');
    String status = order['status']?.toString() ?? 'new';
    showModalBottomSheet(
      context: context,
      backgroundColor: context.pal.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        Widget field(String label, TextEditingController c, {TextInputType? type}) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                    color: context.pal.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.pal.border, width: 0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: SafeInput(controller: c, hint: label, keyboardType: type, fontSize: 14),
              ),
            );
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: context.pal.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Идораи карго', style: TextStyle(color: context.pal.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            field('Track-код', trackCtrl),
            field('Вазн (кг) — арзиш худкор ҳисоб мешавад', weightCtrl, type: TextInputType.number),
            Text('Ҳолат', style: TextStyle(color: context.pal.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in _cargoStatuses)
                GestureDetector(
                  onTap: () => setSheet(() => status = s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: status == s ? AppColors.primary.withValues(alpha: 0.14) : context.pal.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: status == s ? AppColors.primary : context.pal.border, width: status == s ? 1.3 : 0.5),
                    ),
                    child: Text(_cargoStatusLabels[s] ?? s,
                        style: TextStyle(
                            color: status == s ? AppColors.primary : context.pal.textSecondary,
                            fontSize: 12.5,
                            fontWeight: status == s ? FontWeight.w700 : FontWeight.w500)),
                  ),
                ),
            ]),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await AdminService.updateCargo(id,
                        trackCode: trackCtrl.text.trim(),
                        weight: double.tryParse(weightCtrl.text.trim().replaceAll(',', '.')) ?? 0,
                        status: status);
                    onChanged();
                    messenger.showSnackBar(const SnackBar(
                        content: Text('Нав шуд ✅'),
                        backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
                  } catch (_) {
                    messenger.showSnackBar(const SnackBar(
                        content: Text('Хатогӣ'),
                        backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
                  }
                },
                child: const Text('Захира', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ]),
        );
      }),
    );
  }
}

// Танзими карго — суроғаи анбор ва тарифҳо (шарик/админ)
void _cargoSettings(BuildContext context, WidgetRef ref) {
  final info = ref.read(cargoInfoProvider).asData?.value ?? const {};
  final whCtrl = TextEditingController(text: (info['warehouse'] ?? '').toString());
  final tjCtrl = TextEditingController(
      text: ((info['rate_tj'] as num?)?.toDouble() ?? 0) > 0
          ? ((info['rate_tj'] as num).toDouble()).toStringAsFixed(0)
          : '');
  final ruCtrl = TextEditingController(
      text: ((info['rate_ru'] as num?)?.toDouble() ?? 0) > 0
          ? ((info['rate_ru'] as num).toDouble()).toStringAsFixed(0)
          : '');
  final phoneCtrl = TextEditingController(text: (info['phone'] ?? '').toString());

  showModalBottomSheet(
    context: context,
    backgroundColor: context.pal.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) {
      Widget field(String label, TextEditingController c, {int maxLines = 1, TextInputType? type}) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              decoration: BoxDecoration(
                  color: context.pal.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.pal.border, width: 0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: SafeInput(controller: c, hint: label, maxLines: maxLines, keyboardType: type, fontSize: 14),
            ),
          );
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: context.pal.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Танзими карго', style: TextStyle(color: context.pal.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          field('Суроғаи анбор (Хитой)', whCtrl, maxLines: 3),
          Row(children: [
            Expanded(child: field('Тариф ТҶ (сом/кг)', tjCtrl, type: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: field('Тариф РУ (сом/кг)', ruCtrl, type: TextInputType.number)),
          ]),
          field('Телефони шарик', phoneCtrl, type: TextInputType.phone),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: () async {
                Navigator.pop(ctx);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await AdminService.updateCargoSettings(
                    warehouse: whCtrl.text.trim(),
                    rateTj: double.tryParse(tjCtrl.text.trim().replaceAll(',', '.')) ?? 0,
                    rateRu: double.tryParse(ruCtrl.text.trim().replaceAll(',', '.')) ?? 0,
                    phone: phoneCtrl.text.trim(),
                  );
                  ref.invalidate(cargoInfoProvider);
                  messenger.showSnackBar(const SnackBar(
                      content: Text('Захира шуд ✅'),
                      backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
                } catch (_) {
                  messenger.showSnackBar(const SnackBar(
                      content: Text('Хатогӣ'),
                      backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
                }
              },
              child: const Text('Захира', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ]),
      );
    },
  );
}
