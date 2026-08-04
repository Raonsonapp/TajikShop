import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/app_l10n.dart';
import '../../core/l10n/admin_l10n.dart';
import '../../providers/seller_provider.dart';
import '../../routes/route_names.dart';
import '../../shared/widgets/safe_input.dart';

final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ApiClient.instance.dio.get(ApiEndpoints.adminStats);
  final raw = res.data;
  final data = raw is Map
      ? (raw['data'] is Map ? raw['data'] as Map : raw)
      : <String, dynamic>{};
  return Map<String, dynamic>.from(data);
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  String _fmtPct(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  void _editCommission(BuildContext context, WidgetRef ref, double current) {
    final ctrl = TextEditingController(text: _fmtPct(current));
    showDialog(
      context: context,
      builder: (dctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (dctx, setLocal) => AlertDialog(
            backgroundColor: context.pal.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(children: [
              const Icon(FeatherIcons.percent, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text('Комиссияи платформа',
                  style: TextStyle(color: context.pal.textPrimary, fontSize: 16, fontWeight: FontWeight.w700))),
            ]),
            content: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: context.pal.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.pal.border),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SafeInput(
                  controller: ctrl,
                  hint: 'Фоиз (%)',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  textColor: context.pal.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dctx),
                child: Text('Бекор', style: TextStyle(color: context.pal.textMuted)),
              ),
              TextButton(
                onPressed: saving
                    ? null
                    : () async {
                        final pct = double.tryParse(ctrl.text.trim().replaceAll(',', '.'));
                        if (pct == null) return;
                        setLocal(() => saving = true);
                        try {
                          await ApiClient.instance.dio.post(
                            '/admin/settings/commission',
                            data: {'percent': pct},
                          );
                          ref.invalidate(adminStatsProvider);
                          ref.invalidate(platformCommissionProvider);
                          if (dctx.mounted) Navigator.pop(dctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Комиссия навсозӣ шуд: ${_fmtPct(pct)}%'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ));
                          }
                        } catch (_) {
                          setLocal(() => saving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Хатогӣ ҳангоми навсозӣ'),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ));
                          }
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                    : const Text('Нигоҳ доштан',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _editCashback(BuildContext context, WidgetRef ref, double current) {
    final ctrl = TextEditingController(text: _fmtPct(current));
    showDialog(
      context: context,
      builder: (dctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (dctx, setLocal) => AlertDialog(
            backgroundColor: context.pal.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(children: [
              const Icon(FeatherIcons.gift, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text('Cashback (%)',
                  style: TextStyle(color: context.pal.textPrimary, fontSize: 16, fontWeight: FontWeight.w700))),
            ]),
            content: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: context.pal.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.pal.border),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SafeInput(
                  controller: ctrl,
                  hint: 'Фоиз (%)',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  textColor: context.pal.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dctx),
                child: Text('Бекор', style: TextStyle(color: context.pal.textMuted)),
              ),
              TextButton(
                onPressed: saving
                    ? null
                    : () async {
                        final pct = double.tryParse(ctrl.text.trim().replaceAll(',', '.'));
                        if (pct == null) return;
                        setLocal(() => saving = true);
                        try {
                          await ApiClient.instance.dio.post(
                            '/admin/settings/cashback',
                            data: {'percent': pct},
                          );
                          ref.invalidate(adminStatsProvider);
                          ref.invalidate(cashbackProvider);
                          if (dctx.mounted) Navigator.pop(dctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Cashback навсозӣ шуд: ${_fmtPct(pct)}%'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ));
                          }
                        } catch (_) {
                          setLocal(() => saving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Хатогӣ ҳангоми навсозӣ'),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ));
                          }
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                    : const Text('Нигоҳ доштан',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminStatsProvider);
    final commAsync = ref.watch(platformCommissionProvider);
    final commLabel = commAsync.maybeWhen(
      data: (v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1),
      orElse: () => '—');
    final cashAsync = ref.watch(cashbackProvider);
    final cashLabel = cashAsync.maybeWhen(
      data: (v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1),
      orElse: () => '—');
    final l = AppL10n.of(context);
    return Scaffold(
      backgroundColor: context.pal.scaffold,
      appBar: AppBar(
        backgroundColor: context.pal.scaffold,
        elevation: 0,
        title: Text(l.adminPanel,
            style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w700)),
        iconTheme: IconThemeData(color: context.pal.textPrimary),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.refresh(adminStatsProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header banner (green gradient, template card) ─────────────
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(color: Color(0x3300D084), blurRadius: 18, offset: Offset(0, 8)),
                  ],
                ),
                child: Row(children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(FeatherIcons.shield, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l.adminPanelFull,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                      const SizedBox(height: 4),
                      Text(l.systemManagement,
                          style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 24),

              // ── Stats ──────────────────────────────────────────────────────
              Text(l.statistics,
                  style: TextStyle(color: context.pal.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              stats.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ),
                error: (e, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.pal.card,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: Text('${l.noData} (${e.toString().split(':').first})',
                      style: TextStyle(color: context.pal.textSecondary)),
                ),
                data: (data) => GridView.count(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
                  childAspectRatio: 1.55,
                  children: [
                    _StatCard(value: '${data['total_users'] ?? 0}', label: l.usersLabel, icon: FeatherIcons.users, color: AppColors.primary),
                    _StatCard(value: '${data['total_products'] ?? 0}', label: l.productsCountLabel, icon: FeatherIcons.package, color: const Color(0xFF6C63FF)),
                    _StatCard(value: '${data['total_orders'] ?? 0}', label: l.orders, icon: FeatherIcons.fileText, color: AppColors.warning),
                    _StatCard(value: '${data['total_sellers'] ?? 0}', label: l.sellersLabel, icon: FeatherIcons.shoppingBag, color: AppColors.info),
                    _StatCard(
                      value: '${((data['total_sales'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)} сом.',
                      label: 'Фурӯши умумӣ', icon: FeatherIcons.trendingUp, color: const Color(0xFF00A3FF)),
                    _StatCard(
                      value: '${((data['platform_commission'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)} сом.',
                      label: 'Даромади платформа (комиссия)', icon: FeatherIcons.percent, color: AppColors.success),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              // ── System management (grouped template card) ──────────────────
              Text(l.systemManagement,
                  style: TextStyle(color: context.pal.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: context.pal.card,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(children: [
                  _ManageItem(
                    icon: FeatherIcons.users, label: l.usersLabel, subtitle: l.manageUsersSub,
                    color: AppColors.primary, onTap: () => context.push(RouteNames.adminUsers),
                  ),
                  _ManageDivider(),
                  _ManageItem(
                    icon: FeatherIcons.shoppingBag, label: l.sellersLabel,
                    subtitle: l.manageSellersSub, color: const Color(0xFF6C63FF), onTap: () => context.push(RouteNames.adminUsers),
                  ),
                  _ManageDivider(),
                  _ManageItem(
                    icon: FeatherIcons.userCheck, label: 'Дархостҳои фурӯшанда',
                    subtitle: 'Тасдиқи фурӯшандагони нав', color: AppColors.primary,
                    onTap: () => context.push('/admin/seller-requests'),
                  ),
                  _ManageDivider(),
                  _ManageItem(
                    icon: FeatherIcons.fileText, label: l.allOrders,
                    subtitle: l.manageOrdersSub, color: AppColors.warning, onTap: () => context.push(RouteNames.adminOrders),
                  ),
                  _ManageDivider(),
                  _ManageItem(
                    icon: FeatherIcons.grid, label: l.categories,
                    subtitle: l.manageCategoriesSub, color: AppColors.success, onTap: () => context.push(RouteNames.adminCategories),
                  ),
                  _ManageDivider(),
                  _ManageItem(
                    icon: FeatherIcons.tag, label: l.couponsTitle,
                    subtitle: l.manageCouponsSub, color: const Color(0xFFE040FB), onTap: () => context.push(RouteNames.adminCoupons),
                  ),
                  _ManageDivider(),
                  _ManageItem(
                    icon: FeatherIcons.creditCard, label: l.walletApproval,
                    subtitle: l.walletRequestsSub, color: AppColors.warning, onTap: () => context.push(RouteNames.adminWallet),
                  ),
                  _ManageDivider(),
                  _ManageItem(
                    icon: FeatherIcons.flag, label: l.reportsTitle,
                    subtitle: l.reportsSub, color: AppColors.error, onTap: () => context.push(RouteNames.adminReports),
                  ),
                  _ManageDivider(),
                  _ManageItem(
                    icon: FeatherIcons.refreshCcw, label: l.returnsExchange,
                    subtitle: l.returnsSub, color: const Color(0xFF00A3FF), onTap: () => context.push(RouteNames.adminReturns),
                  ),
                  _ManageDivider(),
                  _ManageItem(
                    icon: FeatherIcons.package, label: 'Карго (доставка)',
                    subtitle: 'Дархостҳои доставка аз Хитой', color: const Color(0xFFFF6B2C),
                    onTap: () => context.push(RouteNames.adminCargo),
                  ),
                  _ManageDivider(),
                  _ManageItem(
                    icon: FeatherIcons.percent, label: 'Комиссия: $commLabel%',
                    subtitle: 'Фоизи комиссияи платформа', color: AppColors.success,
                    onTap: () => _editCommission(context, ref, commAsync.asData?.value ?? 10),
                  ),
                  _ManageDivider(),
                  _ManageItem(
                    icon: FeatherIcons.gift, label: 'Cashback: $cashLabel%',
                    subtitle: 'Фоизи бозгашти пул ба ҳамён', color: const Color(0xFF00A3FF),
                    onTap: () => _editCashback(context, ref, cashAsync.asData?.value ?? 2),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _StatCard({required this.value, required this.label, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.pal.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(color: context.pal.textPrimary, fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: context.pal.textMuted, fontSize: 11.5)),
        ]),
      );
}

class _ManageDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 68, right: 16),
        child: Divider(height: 1, thickness: 0.6, color: context.pal.divider),
      );
}

class _ManageItem extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ManageItem({required this.icon, required this.label, required this.subtitle, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(children: [
              Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: color, size: 22)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: TextStyle(color: context.pal.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: context.pal.textMuted, fontSize: 11.5)),
              ])),
              Icon(FeatherIcons.chevronRight, color: context.pal.textMuted),
            ]),
          ),
        ),
      );
}
