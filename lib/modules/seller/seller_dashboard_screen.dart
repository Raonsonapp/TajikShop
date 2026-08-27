import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/auth_provider.dart';
import '../../providers/seller_provider.dart';
import 'confirm_payment_screen.dart';
import '../../routes/route_names.dart';
import '../../core/app_l10n.dart';
import '../../core/l10n/seller_l10n.dart';

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  void _showStatsSheet(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: context.pal.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Consumer(builder: (ctx, ref, _) {
        final statsAsync = ref.watch(sellerStatsProvider);
        final stats = statsAsync.asData?.value;
        int si(String k) => (stats?[k] as num?)?.toInt() ?? 0;
        String rev = ((stats?['revenue'] as num?)?.toDouble() ?? 0).toStringAsFixed(0);
        final comm = ref.watch(platformCommissionProvider).maybeWhen(
          data: (v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1),
          orElse: () => '-');
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44, height: 4,
                    decoration: BoxDecoration(
                      color: context.pal.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(l.sellerSalesStats,
                    style: TextStyle(color: context.pal.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                // Revenue hero (green gradient)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Color(0x3300D084), blurRadius: 16, offset: Offset(0, 8)),
                    ],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(FeatherIcons.dollarSign, color: Colors.white70, size: 18),
                      const SizedBox(width: 6),
                      Text(l.sellerRevenue,
                          style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 10),
                    statsAsync.isLoading && stats == null
                        ? const SizedBox(
                            height: 30, width: 30,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                        : Text('$rev ${l.som}',
                            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
                  ]),
                ),
                const SizedBox(height: 18),
                _StatRow(icon: FeatherIcons.shoppingBag, label: l.orders, value: '${si('orders')}', color: AppColors.primary),
                _StatRow(icon: FeatherIcons.trendingUp, label: 'Фурӯхта', value: '${si('sold')}', color: AppColors.info),
                _StatRow(icon: FeatherIcons.package, label: 'Маҳсулоти фаъол', value: '${si('active_products')}', color: const Color(0xFF6C63FF)),
                _StatRow(icon: FeatherIcons.percent, label: 'Комиссия', value: '$comm%', color: AppColors.warning),
              ],
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final user = ref.watch(authProvider).user;
    final uid = user?.id ?? '';
    final pcount = ref.watch(sellerProductsProvider(uid))
        .maybeWhen(data: (l) => l.length, orElse: () => 0);
    final statsAsync = ref.watch(sellerStatsProvider);
    final stats = statsAsync.asData?.value;
    final loadingStats = statsAsync.isLoading && stats == null;

    int _statInt(String k) => (stats?[k] as num?)?.toInt() ?? 0;
    String _statNum(String k) => ((stats?[k] as num?)?.toDouble() ?? 0).toStringAsFixed(0);
    String _cell(String v) => loadingStats ? '-' : v;

    final products = stats != null ? _statInt('products') : pcount;

    return Scaffold(
      backgroundColor: context.pal.scaffold,
      appBar: AppBar(
        backgroundColor: context.pal.scaffold,
        elevation: 0,
        title: Text(l.sellerMyStore,
            style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w700)),
        iconTheme: IconThemeData(color: context.pal.textPrimary),
        actions: [
          IconButton(
            tooltip: l.sellerStats,
            onPressed: () {
              ref.invalidate(sellerStatsProvider);
              ref.invalidate(sellerProductsProvider(uid));
            },
            icon: const Icon(FeatherIcons.refreshCw, color: AppColors.primary, size: 20),
          ),
          TextButton.icon(
            onPressed: () => context.push(RouteNames.addProduct),
            icon: const Icon(FeatherIcons.plus, color: AppColors.primary, size: 18),
            label: Text(l.sellerAddShort, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(sellerStatsProvider);
          ref.invalidate(sellerProductsProvider(uid));
          await ref.read(sellerStatsProvider.future);
        },
        child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Seller header (green gradient, circle avatar) ────────────────
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x3300D084),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(FeatherIcons.shoppingBag, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(user?.fullName ?? l.seller,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                      const SizedBox(height: 4),
                      Text(l.sellerActiveSeller,
                          style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(l.sellerVerifiedBadge, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Stats ────────────────────────────────────────────────────────
            Text(l.sellerStats,
                style: TextStyle(color: context.pal.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
              childAspectRatio: 1.55,
              children: [
                _StatCard(value: _cell('$products'), label: l.productsWord, icon: FeatherIcons.package, color: const Color(0xFF6C63FF)),
                _StatCard(value: _cell('${_statInt('orders')}'), label: l.orders, icon: FeatherIcons.fileText, color: AppColors.primary),
                _StatCard(value: _cell('${_statInt('sold')}'), label: 'Фурӯхта', icon: FeatherIcons.trendingUp, color: AppColors.info),
                _StatCard(value: _cell('${_statNum('revenue')} ${l.som}'), label: l.sellerRevenue, icon: FeatherIcons.creditCard, color: AppColors.warning),
              ],
            ),
            const SizedBox(height: 26),

            // ── Графики фурӯши 7 рӯз ──────────────────────────────────────────
            const _SalesChartCard(),
            const SizedBox(height: 26),

            // ── Quick actions (grouped card, template ListTile style) ────────
            Text(l.sellerActions,
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
              child: Column(
                children: [
                  _ActionItem(
                    icon: FeatherIcons.plusSquare,
                    label: l.sellerAddProduct,
                    subtitle: l.sellerAddProductSub,
                    onTap: () => context.push(RouteNames.addProduct),
                  ),
                  _ActionDivider(),
                  _ActionItem(
                    icon: FeatherIcons.package,
                    label: l.myProducts,
                    subtitle: l.sellerManageProductsSub,
                    onTap: () => context.push(RouteNames.myProducts),
                  ),
                  _ActionDivider(),
                  _ActionItem(
                    icon: FeatherIcons.clock,
                    label: l.sellerNewOrders,
                    subtitle: l.sellerNewOrdersSub,
                    onTap: () => context.push('/seller/orders'),
                  ),
                  _ActionDivider(),
                  _ActionItem(
                    icon: FeatherIcons.checkCircle,
                    label: 'Тасдиқи пардохт',
                    subtitle: 'SMS-и бонкро гузоред — фармоиш худкор тасдиқ мешавад',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ConfirmPaymentScreen())),
                  ),
                  _ActionDivider(),
                  _ActionItem(
                    icon: FeatherIcons.barChart2,
                    label: l.sellerSalesStats,
                    subtitle: l.sellerSalesStatsSub,
                    onTap: () => _showStatsSheet(context, ref),
                  ),
                ],
              ),
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
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(color: context.pal.textPrimary, fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: context.pal.textMuted, fontSize: 11.5)),
        ]),
      );
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatRow({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: TextStyle(color: context.pal.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          Text(value,
              style: TextStyle(color: context.pal.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
        ]),
      );
}

class _ActionDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 68, right: 16),
        child: Divider(height: 1, thickness: 0.6, color: context.pal.divider),
      );
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final VoidCallback onTap;
  const _ActionItem({required this.icon, required this.label, required this.subtitle, required this.onTap});
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
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: AppColors.primary, size: 22)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: TextStyle(color: context.pal.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: context.pal.textMuted, fontSize: 11.5)),
              ])),
              const Icon(FeatherIcons.chevronRight, color: AppColors.primary),
            ]),
          ),
        ),
      );
}

// ── Графики фурӯши 7 рӯз ──────────────────────────────────────────────────────
class _SalesChartCard extends ConsumerWidget {
  const _SalesChartCard();

  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static const _wd = {1: 'Дш', 2: 'Сш', 3: 'Чш', 4: 'Пш', 5: 'Ҷм', 6: 'Шн', 7: 'Яш'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pal = context.pal;
    final async = ref.watch(sellerSalesChartProvider);

    final byDate = <String, double>{};
    async.whenData((list) {
      for (final e in list) {
        final d = e['date']?.toString() ?? '';
        final t = (e['total'] as num?)?.toDouble() ?? 0;
        if (d.isNotEmpty) byDate[d] = t;
      }
    });

    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final d = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - i));
      return (d, byDate[_key(d)] ?? 0.0);
    });
    final maxVal = days.fold<double>(0, (m, e) => e.$2 > m ? e.$2 : m);
    final total = days.fold<double>(0, (s, e) => s + e.$2);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: pal.border, width: 0.6),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(FeatherIcons.barChart2, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Text('Фурӯши 7 рӯз',
              style: TextStyle(
                  color: pal.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('${total.toStringAsFixed(0)} сом',
              style: const TextStyle(
                  color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final e in days)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        e.$2 > 0 ? e.$2.toStringAsFixed(0) : '',
                        style: TextStyle(color: pal.textMuted, fontSize: 9),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        height: maxVal <= 0 ? 3 : (6 + 70 * (e.$2 / maxVal)),
                        decoration: BoxDecoration(
                          gradient: e.$2 > 0 ? AppColors.primaryGradient : null,
                          color: e.$2 > 0 ? null : pal.surface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(_wd[e.$1.weekday] ?? '',
                          style: TextStyle(color: pal.textSecondary, fontSize: 10)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}
