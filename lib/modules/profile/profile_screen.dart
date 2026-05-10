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
import '../../routes/route_names.dart';
import '../../shared/widgets/app_button.dart';

final _profileStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  try {
    final orders = await ApiClient.instance.dio.get(ApiEndpoints.orders);
    final favs = await ApiClient.instance.dio.get(ApiEndpoints.favorites);
    final ordList = orders.data is List ? orders.data as List : (orders.data['orders'] ?? []);
    final favList = favs.data is List ? favs.data as List : (favs.data['favorites'] ?? favs.data['items'] ?? []);
    return {'orders': ordList.length, 'favorites': favList.length};
  } catch (_) {
    return {'orders': 0, 'favorites': 0};
  }
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final stats = ref.watch(_profileStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
              child: Column(children: [
                // Avatar with edit
                Stack(children: [
                  Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                        border: Border.all(color: AppColors.primary, width: 2)),
                    child: ClipOval(child: user?.avatar != null && user!.avatar!.isNotEmpty
                        ? CachedNetworkImage(imageUrl: user.avatar!, fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => _initials(user.fullName))
                        : _initials(user?.fullName ?? 'U')),
                  ),
                  Positioned(bottom: 0, right: 0,
                    child: GestureDetector(
                      onTap: () => _uploadAvatar(context, ref),
                      child: Container(width: 26, height: 26,
                        decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle,
                            border: Border.all(color: AppColors.bgDark, width: 2)),
                        child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white)),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                // Username lowercase
                Text('@${(user?.fullName ?? 'меҳмон').toLowerCase().replaceAll(' ', '_')}',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(user?.email ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                // Badges
                Wrap(spacing: 8, children: [
                  if (user?.isSeller == true) _badge('🏪 Фурӯшанда', AppColors.primary),
                  if (user?.isVerified == true) _badge('✓ Тасдиқ', AppColors.info),
                  if (user?.role == 'admin') _badge('👑 Админ', AppColors.error),
                ]),
                const SizedBox(height: 20),
                // Real stats from API
                Container(
                  decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16)),
                  child: stats.when(
                    loading: () => const Padding(padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
                    error: (_, __) => _statsRow(0, 0),
                    data: (s) => _statsRow(s['orders'] ?? 0, s['favorites'] ?? 0),
                  ),
                ),
                const SizedBox(height: 16),
                // Edit profile button
                OutlinedButton.icon(
                  onPressed: () => _showEditDialog(context, ref, user),
                  icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                  label: const Text('Таҳрир кардан', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  ),
                ),
              ]),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _section('Харид'),
                _tile(context, Icons.receipt_long_outlined, 'Фармоишҳоям', AppColors.primary,
                    subtitle: 'Таърихи харид', onTap: () => context.push(RouteNames.orders)),
                _tile(context, Icons.favorite_outline_rounded, 'Дӯстдоштаҳо', AppColors.error,
                    subtitle: 'Маҳсулотҳои маъруб', onTap: () => context.go(RouteNames.favorites)),
                _tile(context, Icons.location_on_outlined, 'Суроғаҳо', AppColors.warning,
                    subtitle: 'Идораи суроғаҳо', onTap: () => _showAddressDialog(context, ref)),
                _tile(context, Icons.payment_outlined, 'Пардохтҳо', AppColors.info,
                    subtitle: 'DC / Корт', onTap: () => _showPaymentInfo(context)),

                _section('Нашр'),
                _tile(context, Icons.add_box_outlined, 'Маҳсулот нашр кунед', AppColors.primary,
                    onTap: () => context.go(RouteNames.upload)),
                if (user?.isSeller == true)
                  _tile(context, Icons.store_outlined, 'Дӯкони ман', const Color(0xFF6C63FF),
                      onTap: () => context.push(RouteNames.seller))
                else
                  _tile(context, Icons.storefront_outlined, 'Фурӯшанда шавед', AppColors.success,
                      subtitle: 'Маҳсулотҳои худро бифурӯшед', onTap: () => _becomeSeller(context, ref)),

                if (user?.role == 'admin') ...[
                  _section('Идора'),
                  _tile(context, Icons.admin_panel_settings_outlined, 'Панели Админ', AppColors.error,
                      onTap: () => context.push(RouteNames.admin)),
                ],

                _section('Танзимот'),
                _tile(context, Icons.notifications_outlined, 'Огоҳиномаҳо', AppColors.primary,
                    onTap: () => context.push(RouteNames.notifications)),
                _tile(context, Icons.language_outlined, 'Забон', AppColors.info,
                    subtitle: 'Тоҷикӣ', onTap: () => _showLanguageDialog(context)),
                _tile(context, Icons.dark_mode_outlined, 'Намоиш', AppColors.textMuted,
                    subtitle: 'Торик', onTap: () {}),
                _tile(context, Icons.help_outline_rounded, 'Кӯмак', AppColors.textMuted,
                    onTap: () => _showHelp(context)),
                const SizedBox(height: 8),
                _tile(context, Icons.logout_rounded, 'Баромадан', AppColors.error,
                    onTap: () => _logout(context, ref)),
                const SizedBox(height: 16),
                const Center(child: Text('TajikShop v1.0 • Бозори Тоҷикистон',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11))),
                const SizedBox(height: 90),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow(int orders, int favs) => Row(children: [
    _stat('$orders', 'Фармоишҳо', Icons.receipt_long_outlined),
    Container(width: 1, height: 40, color: AppColors.border),
    _stat('$favs', 'Дӯстдошта', Icons.favorite_outline),
    Container(width: 1, height: 40, color: AppColors.border),
    _stat('0', 'Маҳсулот', Icons.inventory_2_outlined),
  ]);

  Widget _stat(String val, String label, IconData icon) => Expanded(
    child: Padding(padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
      ])),
  );

  Widget _initials(String name) => Container(color: AppColors.bgSurface,
    child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: const TextStyle(color: AppColors.primary, fontSize: 32, fontWeight: FontWeight.w700))));

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)));

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 16, 0, 8),
    child: Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)));

  Widget _tile(BuildContext context, IconData icon, String label, Color color,
      {String? subtitle, VoidCallback? onTap}) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5)),
      child: Row(children: [
        Container(width: 38, height: 38,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(
              color: color == AppColors.error && label.contains('Барор') ? color : AppColors.textPrimary,
              fontSize: 14, fontWeight: FontWeight.w500)),
          if (subtitle != null) Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ])),
        Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
      ]),
    ));

  Future<void> _uploadAvatar(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 500);
    if (img == null) return;
    try {
      final formData = FormData.fromMap({'avatar': await MultipartFile.fromFile(img.path)});
      await ApiClient.instance.dio.post(ApiEndpoints.uploadAvatar, data: formData);
      await ref.read(authProvider.notifier).checkAuth();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('✅ Расм нав шуд'), backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Хато: $e'), backgroundColor: AppColors.error));
    }
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, dynamic user) {
    final nameCtrl = TextEditingController(text: user?.fullName ?? '');
    showModalBottomSheet(context: context, backgroundColor: AppColors.bgCard, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Таҳрири профил', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          TextField(controller: nameCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(hintText: 'Номи пурра', hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true, fillColor: AppColors.bgSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 16),
          AppButton(text: 'Сабт кардан', onTap: () async {
            try {
              await ApiClient.instance.dio.put(ApiEndpoints.updateProfile, data: {'name': nameCtrl.text.trim()});
              await ref.read(authProvider.notifier).checkAuth();
              if (context.mounted) Navigator.pop(context);
            } catch (_) {}
          }),
        ]),
      ));
  }

  void _showAddressDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(context: context, backgroundColor: AppColors.bgCard, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        final ctrl = TextEditingController();
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Суроғаи нав', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            TextField(controller: ctrl, style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(hintText: 'Суроға, Шаҳр, Кӯча...', hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true, fillColor: AppColors.bgSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            const SizedBox(height: 16),
            AppButton(text: 'Илова кардан', onTap: () async {
              try {
                await ApiClient.instance.dio.post('/addresses', data: {'address': ctrl.text.trim()});
                if (context.mounted) { Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('✅ Суроға илова шуд'), backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating)); }
              } catch (_) {}
            }),
          ]));
      });
  }

  void _showPaymentInfo(BuildContext context) {
    showModalBottomSheet(context: context, backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        const Icon(Icons.payment_outlined, color: AppColors.primary, size: 48),
        const SizedBox(height: 12),
        const Text('Пардохти DC', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        const Text('Вақте харид мекунед, рақами DC-и фурӯшандаро мебинед. Пул мефиристед ва чекро ба барнома бор мекунед.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14), textAlign: TextAlign.center),
        const SizedBox(height: 20),
      ])));
  }

  void _showLanguageDialog(BuildContext context) {
    showModalBottomSheet(context: context, backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Забон', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        for (final lang in [('🇹🇯 Тоҷикӣ', true), ('🇷🇺 Русӣ', false), ('🇬🇧 English', false)])
          ListTile(title: Text(lang.$1, style: const TextStyle(color: AppColors.textPrimary)),
            trailing: lang.$2 ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
            onTap: () => Navigator.pop(context)),
      ])));
  }

  void _showHelp(BuildContext context) {
    showModalBottomSheet(context: context, backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const Padding(padding: EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 48),
        SizedBox(height: 12),
        Text('Кӯмак', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        SizedBox(height: 12),
        Text('Агар мушкил дошта бошед, ба @TajikShop_support нависед.',
            style: TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
      ])));
  }

  Future<void> _becomeSeller(BuildContext context, WidgetRef ref) async {
    try {
      // becomeSeller() дар authProvider токени нав захира мекунад
      final ok = await ref.read(authProvider.notifier).becomeSeller();
      if (!context.mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('🎉 Шумо фурӯшанда шудед!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Фурӯшанда шудан мумкин набуд'),
          backgroundColor: AppColors.error));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Хато: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppColors.bgCard,
      title: const Text('Баромадан', style: TextStyle(color: AppColors.textPrimary)),
      content: const Text('Шумо мутмаин ҳастед?', style: TextStyle(color: AppColors.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Не', style: TextStyle(color: AppColors.textSecondary))),
        TextButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('Бале', style: TextStyle(color: AppColors.error))),
      ]));
    if (ok == true) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) context.go(RouteNames.login);
    }
  }
}
