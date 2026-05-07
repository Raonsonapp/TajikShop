import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A0A0F), Color(0xFF141420)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: ClipOval(
                          child: user?.avatar != null && user!.avatar!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: user.avatar!,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => _avatarPlaceholder(user.fullName),
                                )
                              : _avatarPlaceholder(user?.fullName ?? 'U'),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.bgDark, width: 2),
                          ),
                          child: const Icon(Icons.edit, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.fullName ?? 'Меҳмон',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  // Badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (user?.isSeller == true)
                        _Badge(label: 'Фурӯшанда', color: AppColors.primary),
                      if (user?.isVerified == true) ...[
                        const SizedBox(width: 8),
                        _Badge(label: '✓ Тасдиқшуда', color: AppColors.info),
                      ],
                      if (user?.role == 'admin') ...[
                        const SizedBox(width: 8),
                        _Badge(label: 'Админ', color: AppColors.error),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Stats
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: const [
                        _StatItem(value: '24', label: 'Фармоишҳо'),
                        _Divider(),
                        _StatItem(value: '56', label: 'Дӯстдошта'),
                        _Divider(),
                        _StatItem(value: '18', label: 'Маҳсулот'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Menu
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _SectionTitle('Хариди ман'),
                  _MenuItem(icon: Icons.receipt_long_outlined, label: 'Фармоишҳои ман',
                      onTap: () => context.push(RouteNames.orders)),
                  _MenuItem(icon: Icons.favorite_outline_rounded, label: 'Дӯстдоштаҳо',
                      onTap: () => context.go(RouteNames.favorites)),
                  _MenuItem(icon: Icons.location_on_outlined, label: 'Суроғаҳо', onTap: () {}),
                  _MenuItem(icon: Icons.payment_outlined, label: 'Пардохтҳо', onTap: () {}),

                  const SizedBox(height: 8),
                  _SectionTitle('Фурӯш'),
                  if (user?.isSeller == true)
                    _MenuItem(icon: Icons.store_outlined, label: 'Дӯкони ман',
                        badge: 'Фурӯшанда',
                        onTap: () => context.push(RouteNames.seller))
                  else
                    _MenuItem(
                      icon: Icons.storefront_outlined,
                      label: 'Фурӯшанда шавед',
                      subtitle: 'Маҳсулотҳои худро бифурӯшед',
                      onTap: () {},
                    ),

                  if (user?.role == 'admin') ...[
                    const SizedBox(height: 8),
                    _SectionTitle('Идора'),
                    _MenuItem(icon: Icons.admin_panel_settings_outlined, label: 'Панели Админ',
                        onTap: () => context.push(RouteNames.admin)),
                  ],

                  const SizedBox(height: 8),
                  _SectionTitle('Тозакорӣ'),
                  _MenuItem(icon: Icons.notifications_outlined, label: 'Огоҳиномаҳо',
                      onTap: () => context.push(RouteNames.notifications)),
                  _MenuItem(icon: Icons.language_outlined, label: 'Забон: Тоҷикӣ', onTap: () {}),
                  _MenuItem(icon: Icons.dark_mode_outlined, label: 'Намоиш', onTap: () {}),
                  _MenuItem(icon: Icons.help_outline_rounded, label: 'Кӯмак', onTap: () {}),

                  const SizedBox(height: 8),
                  _MenuItem(
                    icon: Icons.logout_rounded,
                    label: 'Баромадан',
                    color: AppColors.error,
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: AppColors.bgCard,
                          title: const Text('Баромадан', style: TextStyle(color: AppColors.textPrimary)),
                          content: const Text('Шумо мутмаин ҳастед?',
                              style: TextStyle(color: AppColors.textSecondary)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false),
                                child: const Text('Не', style: TextStyle(color: AppColors.textSecondary))),
                            TextButton(onPressed: () => Navigator.pop(context, true),
                                child: const Text('Бале', style: TextStyle(color: AppColors.error))),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) context.go(RouteNames.login);
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                  const Center(
                    child: Text('TajikShop v1.0.0',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarPlaceholder(String name) {
    return Container(
      color: AppColors.bgSurface,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: const TextStyle(color: AppColors.primary, fontSize: 32, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

class _StatItem extends StatelessWidget {
  final String value, label;
  const _StatItem({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ]),
      );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: AppColors.border);
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 0, 8),
        child: Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
      );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final String? badge;
  final Color? color;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.label, required this.onTap,
      this.subtitle, this.badge, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: (color ?? AppColors.primary).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color ?? AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: TextStyle(color: c, fontSize: 14, fontWeight: FontWeight.w500)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ]),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(badge!, style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w600)),
              )
            else
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
