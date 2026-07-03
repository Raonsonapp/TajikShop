import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/auth_provider.dart';
import '../../providers/seller_provider.dart';
import '../../routes/route_names.dart';

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  void _soon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Ин бахш ба зудӣ илова мешавад'),
      behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final uid = user?.id ?? '';
    final pcount = ref.watch(sellerProductsProvider(uid))
        .maybeWhen(data: (l) => l.length, orElse: () => 0);
    return Scaffold(
      backgroundColor: context.pal.scaffold,
      appBar: AppBar(
        backgroundColor: context.pal.scaffold,
        elevation: 0,
        title: Text('Дӯкони ман',
            style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w700)),
        iconTheme: IconThemeData(color: context.pal.textPrimary),
        actions: [
          TextButton.icon(
            onPressed: () => context.push(RouteNames.addProduct),
            icon: const Icon(Icons.add, color: AppColors.primary, size: 18),
            label: const Text('Илова', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                    child: const Icon(Icons.store_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(user?.fullName ?? 'Фурӯшанда',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                      const SizedBox(height: 4),
                      const Text('Фурӯшандаи фаъол',
                          style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('✓ Тасдиқ', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Stats ────────────────────────────────────────────────────────
            Text('Оморҳо',
                style: TextStyle(color: context.pal.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
              childAspectRatio: 1.55,
              children: [
                const _StatCard(value: '0', label: 'Фармоишҳо', icon: Icons.receipt_long_rounded, color: AppColors.primary),
                _StatCard(value: '$pcount', label: 'Маҳсулот', icon: Icons.inventory_2_rounded, color: const Color(0xFF6C63FF)),
                const _StatCard(value: '0 сом.', label: 'Даромад', icon: Icons.account_balance_wallet_rounded, color: AppColors.warning),
                const _StatCard(value: '0', label: 'Мизоҷон', icon: Icons.people_alt_rounded, color: AppColors.info),
              ],
            ),
            const SizedBox(height: 26),

            // ── Quick actions (grouped card, template ListTile style) ────────
            Text('Амалиётҳо',
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
                    icon: Icons.add_box_rounded,
                    label: 'Маҳсулот илова кунед',
                    subtitle: 'Маҳсулоти нав эълон кунед',
                    onTap: () => context.push(RouteNames.addProduct),
                  ),
                  _ActionDivider(),
                  _ActionItem(
                    icon: Icons.inventory_rounded,
                    label: 'Маҳсулотҳоям',
                    subtitle: 'Идораи маҳсулотҳо',
                    onTap: () => context.push(RouteNames.myProducts),
                  ),
                  _ActionDivider(),
                  _ActionItem(
                    icon: Icons.pending_actions_rounded,
                    label: 'Фармоишҳои нав',
                    subtitle: 'Фармоишҳои интизорро бубинед',
                    onTap: () => context.push(RouteNames.orders),
                  ),
                  _ActionDivider(),
                  _ActionItem(
                    icon: Icons.bar_chart_rounded,
                    label: 'Оморҳои фурӯш',
                    subtitle: 'Гузориши фурӯши ман',
                    onTap: () => _soon(context),
                  ),
                ],
              ),
            ),
          ],
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
              const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
            ]),
          ),
        ),
      );
}
