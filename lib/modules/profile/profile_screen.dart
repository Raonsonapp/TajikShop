// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';

import '../../core/constants/app_colors.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/locale_provider.dart';
import '../../routes/route_names.dart';
import '../../main.dart' show _AppL10n;
import '../../shared/widgets/app_button.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {

  // ── Avatar upload ────────────────────────────────────────────────────────────
  Future<void> _pickAvatar() async {
    final xf = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xf == null) return;
    final file = File(xf.path);
    try {
      final form = FormData.fromMap({'avatar': await MultipartFile.fromFile(file.path)});
      final res = await ApiClient.instance.dio.put(ApiEndpoints.me, data: form);
      final body = res.data is Map ? res.data as Map<String, dynamic> : <String, dynamic>{};
      final data = body['data'] as Map<String, dynamic>? ?? body;
      final url  = data['avatar_url']?.toString();
      if (url != null && url.isNotEmpty) {
        await ref.read(authProvider.notifier).checkAuth();
      }
    } catch (_) {}
  }

  // ── Become Seller ────────────────────────────────────────────────────────────
  Future<void> _becomeSeller() async {
    final l = _AppL10n.of(context);
    final ok = await ref.read(authProvider.notifier).becomeSeller();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? l.becomeSellerSuccess : l.error),
      backgroundColor: ok ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating));
  }

  // ── Language picker ──────────────────────────────────────────────────────────
  void _showLanguagePicker() {
    final l = _AppL10n.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text(l.language, style: const TextStyle(color: Colors.white,
              fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          ...LocaleNotifier.supported.map((locale) {
            final current = ref.read(localeProvider);
            final isActive = current.languageCode == locale.languageCode;
            return ListTile(
              leading: Text(locale.languageCode == 'tg' ? '🇹🇯' :
                  locale.languageCode == 'ru' ? '🇷🇺' : '🇬🇧',
                  style: const TextStyle(fontSize: 24)),
              title: Text(LocaleNotifier.langName(locale.languageCode),
                  style: TextStyle(color: isActive ? AppColors.primary : Colors.white,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w400)),
              trailing: isActive
                  ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                  : null,
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(locale);
                Navigator.pop(context);
              });
          }),
        ])));
  }

  @override
  Widget build(BuildContext context) {
    final auth   = ref.watch(authProvider);
    final user   = auth.user;
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final l      = _AppL10n.of(context);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [

          // ── App Bar ────────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppColors.bgDark,
            floating: true, elevation: 0,
            title: Text(l.profile, style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.w700, fontSize: 20)),
          ),

          SliverToBoxAdapter(child: Column(children: [

            // ── Avatar & Name ──────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [AppColors.primary.withOpacity(0.15), AppColors.bgCard],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border)),
              child: Row(children: [
                // Avatar
                GestureDetector(
                  onTap: _pickAvatar,
                  child: Stack(children: [
                    CircleAvatar(radius: 36,
                      backgroundColor: AppColors.bgSurface,
                      backgroundImage: user?.avatar != null && user!.avatar!.isNotEmpty
                          ? CachedNetworkImageProvider(user.avatar!) : null,
                      child: user?.avatar == null || user!.avatar!.isEmpty
                          ? const Icon(Icons.person_rounded, color: AppColors.textMuted, size: 36)
                          : null),
                    Positioned(bottom: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [Color(0xFF00D084), Color(0xFF00A3FF)]),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 12))),
                  ])),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user?.fullName ?? 'Корбар',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(user?.email ?? '',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(height: 8),
                  _RoleBadge(role: user?.role ?? 'buyer', l: l),
                ])),
              ])),

            // ── Seller / Become Seller ─────────────────────────────────────
            if (user?.isSeller == true || user?.role == 'seller')
              _MenuItem(icon: Icons.store_rounded, iconColor: const Color(0xFF00D084),
                  label: l.sellerDashboard,
                  onTap: () => context.push(RouteNames.sellerDashboard))
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: AppButton(
                  text: '🏪 ${l.becomeSeller}', // ← ИСЛОҲ: label → text
                  onTap: _becomeSeller,           // ← ИСЛОҲ: onPressed → onTap
                )),

            const SizedBox(height: 8),
            _SectionLabel(l.orders),
            _MenuItem(icon: Icons.receipt_long_rounded, iconColor: const Color(0xFF00A3FF),
                label: l.orders, onTap: () => context.push(RouteNames.orders)),
            _MenuItem(icon: Icons.favorite_rounded, iconColor: const Color(0xFF00D084),
                label: l.favorites, onTap: () => context.push(RouteNames.favorites)),

            const SizedBox(height: 8),
            _SectionLabel(l.settings),
            // ── Тема ─────────────────────────────────────────────────────
            _SwitchTile(
              icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              iconColor: const Color(0xFFFFB800),
              label: isDark ? l.darkMode : l.lightMode,
              value: isDark,
              onChanged: (v) => ref.read(themeProvider.notifier).toggle()),

            // ── Забон ────────────────────────────────────────────────────
            _MenuItem(
              icon: Icons.language_rounded, iconColor: const Color(0xFF00A3FF),
              label: '${l.language}: ${LocaleNotifier.langName(ref.watch(localeProvider).languageCode)}',
              onTap: _showLanguagePicker),

            _MenuItem(icon: Icons.notifications_outlined, iconColor: const Color(0xFFE040FB),
                label: l.notifications, onTap: () => context.push(RouteNames.notifications)),

            const SizedBox(height: 8),
            _SectionLabel(l.about),
            _MenuItem(icon: Icons.info_outline_rounded, iconColor: AppColors.textMuted,
                label: l.about, onTap: () {}),

            // ── Logout ─────────────────────────────────────────────────
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: const Color(0xFFFF3B5C).withOpacity(0.1),
                leading: const Icon(Icons.logout_rounded, color: Color(0xFFFF3B5C)),
                title: Text(l.logout, style: const TextStyle(
                    color: Color(0xFFFF3B5C), fontWeight: FontWeight.w600)),
                onTap: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go(RouteNames.login);
                })),
          ])),
        ]));
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _RoleBadge extends StatelessWidget {
  final String role;
  final dynamic l;
  const _RoleBadge({required this.role, required this.l});

  @override
  Widget build(BuildContext context) {
    Color c;
    String label;
    switch (role) {
      case 'seller': c = const Color(0xFF00D084); label = '🏪 ${l.seller}'; break;
      case 'admin':  c = const Color(0xFFE040FB); label = '👑 ${l.admin}'; break;
      default:       c = const Color(0xFF00A3FF); label = '🛍️ ${l.buyer}';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withOpacity(0.4))),
      child: Text(label, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700)));
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
    child: Text(label.toUpperCase(), style: const TextStyle(
        color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)));
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.iconColor,
      required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
    child: ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: AppColors.bgCard,
      leading: Container(padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 18)),
      title: Text(label, style: const TextStyle(color: Colors.white,
          fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.textMuted, size: 20),
      onTap: onTap));
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({required this.icon, required this.iconColor,
      required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
    child: ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: AppColors.bgCard,
      leading: Container(padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 18)),
      title: Text(label, style: const TextStyle(color: Colors.white,
          fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: Switch.adaptive(value: value, onChanged: onChanged,
          activeColor: AppColors.primary)));
}
