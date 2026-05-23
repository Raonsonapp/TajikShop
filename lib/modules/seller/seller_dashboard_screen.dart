import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        title: const Text('Дӯкони ман',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          TextButton.icon(
            onPressed: () => context.push(RouteNames.addProduct),
            icon: const Icon(Icons.add, color: AppColors.primary, size: 18),
            label: const Text('Илова', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seller Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.store_rounded, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(user?.fullName ?? 'Фурӯшанда',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 4),
                      const Text('Фурӯшандаи фаъол',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('✓ Тасдиқ', style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stats
            const Text('Оморҳо',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: const [
                _StatCard(value: '0', label: 'Фармоишҳо', icon: Icons.receipt_long_outlined, color: AppColors.primary),
                _StatCard(value: '0', label: 'Маҳсулот', icon: Icons.inventory_2_outlined, color: Color(0xFF6C63FF)),
                _StatCard(value: '0 сом.', label: 'Даромад', icon: Icons.account_balance_wallet_outlined, color: AppColors.warning),
                _StatCard(value: '0', label: 'Мизоҷон', icon: Icons.people_outline, color: AppColors.info),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Actions
            const Text('Амалиётҳо',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _ActionItem(
              icon: Icons.add_box_outlined,
              label: 'Маҳсулот илова кунед',
              subtitle: 'Маҳсулоти нав эълон кунед',
              onTap: () => context.push(RouteNames.addProduct),
            ),
            _ActionItem(
              icon: Icons.inventory_outlined,
              label: 'Маҳсулотҳоям',
              subtitle: 'Идораи маҳсулотҳо',
              onTap: () {},
            ),
            _ActionItem(
              icon: Icons.pending_actions_outlined,
              label: 'Фармоишҳои нав',
              subtitle: 'Фармоишҳои интизорро бубинед',
              onTap: () {},
            ),
            _ActionItem(
              icon: Icons.bar_chart_outlined,
              label: 'Оморҳои фурӯш',
              subtitle: 'Гузориши фурӯши ман',
              onTap: () {},
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ]),
      );
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final VoidCallback onTap;
  const _ActionItem({required this.icon, required this.label, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.5)),
          child: Row(children: [
            Container(width: 42, height: 42,
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppColors.primary, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ])),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ]),
        ),
      );
}
