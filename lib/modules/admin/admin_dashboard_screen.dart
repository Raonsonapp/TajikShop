import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/app_l10n.dart';
import '../../core/l10n/admin_l10n.dart';
import '../../routes/route_names.dart';

final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ApiClient.instance.dio.get(ApiEndpoints.adminStats);
  return res.data as Map<String, dynamic>;
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminStatsProvider);
    final l = AppL10n.of(context);
    return Scaffold(
      backgroundColor: context.pal.scaffold,
      appBar: AppBar(
        backgroundColor: context.pal.scaffold,
        title: Text(l.adminPanel,
            style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w700)),
        iconTheme: IconThemeData(color: context.pal.textPrimary),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.refresh(adminStatsProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Alert banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  const Icon(Icons.admin_panel_settings, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text(l.adminPanelFull, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ]),
              ),
              const SizedBox(height: 20),

              Text(l.statistics,
                  style: TextStyle(color: context.pal.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              stats.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: context.pal.card, borderRadius: BorderRadius.circular(14)),
                  child: Text('${l.noData} (${e.toString().split(':').first})',
                      style: TextStyle(color: context.pal.textSecondary)),
                ),
                data: (data) => GridView.count(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _StatCard(value: '${data['total_users'] ?? 0}', label: l.usersLabel, icon: Icons.people_outline, color: AppColors.primary),
                    _StatCard(value: '${data['total_products'] ?? 0}', label: l.productsCountLabel, icon: Icons.inventory_2_outlined, color: const Color(0xFF6C63FF)),
                    _StatCard(value: '${data['total_orders'] ?? 0}', label: l.orders, icon: Icons.receipt_long_outlined, color: AppColors.warning),
                    _StatCard(value: '${data['total_sellers'] ?? 0}', label: l.sellersLabel, icon: Icons.store_outlined, color: AppColors.info),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text(l.systemManagement,
                  style: TextStyle(color: context.pal.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              _ManageCard(
                icon: Icons.people_alt_outlined, label: l.usersLabel, subtitle: l.manageUsersSub,
                color: AppColors.primary, onTap: () => context.push(RouteNames.adminUsers),
              ),
              _ManageCard(
                icon: Icons.store_mall_directory_outlined, label: l.sellersLabel,
                subtitle: l.manageSellersSub, color: const Color(0xFF6C63FF), onTap: () => context.push(RouteNames.adminUsers),
              ),
              _ManageCard(
                icon: Icons.receipt_outlined, label: l.allOrders,
                subtitle: l.manageOrdersSub, color: AppColors.warning, onTap: () => context.push(RouteNames.adminOrders),
              ),
              _ManageCard(
                icon: Icons.category_outlined, label: l.categories,
                subtitle: l.manageCategoriesSub, color: AppColors.success, onTap: () => context.push(RouteNames.adminCategories),
              ),
              _ManageCard(
                icon: Icons.confirmation_number_outlined, label: l.couponsTitle,
                subtitle: l.manageCouponsSub, color: const Color(0xFFE040FB), onTap: () => context.push(RouteNames.adminCoupons),
              ),
              _ManageCard(
                icon: Icons.account_balance_wallet_outlined, label: l.walletApproval,
                subtitle: l.walletRequestsSub, color: AppColors.warning, onTap: () => context.push(RouteNames.adminWallet),
              ),
              _ManageCard(
                icon: Icons.flag_outlined, label: l.reportsTitle,
                subtitle: l.reportsSub, color: AppColors.error, onTap: () => context.push(RouteNames.adminReports),
              ),
              _ManageCard(
                icon: Icons.assignment_return_outlined, label: l.returnsExchange,
                subtitle: l.returnsSub, color: const Color(0xFF00A3FF), onTap: () => context.push(RouteNames.adminReturns),
              ),
              const SizedBox(height: 40),
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: context.pal.card, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.pal.border, width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: context.pal.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
          Text(label, style: TextStyle(color: context.pal.textMuted, fontSize: 11)),
        ]),
      );
}

class _ManageCard extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ManageCard({required this.icon, required this.label, required this.subtitle, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: context.pal.card, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.pal.border, width: 0.5)),
          child: Row(children: [
            Container(width: 44, height: 44,
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(color: context.pal.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              Text(subtitle, style: TextStyle(color: context.pal.textMuted, fontSize: 11)),
            ])),
            Icon(Icons.chevron_right_rounded, color: context.pal.textMuted),
          ]),
        ),
      );
}
