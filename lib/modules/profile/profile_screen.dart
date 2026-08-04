// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';

import '../../core/constants/app_colors.dart';
import '../../core/constants/business_types.dart';
import '../../core/theme/app_palette.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../providers/auth_provider.dart';
import '../../providers/seller_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/locale_provider.dart';
import '../../routes/route_names.dart';
import '../../core/app_l10n.dart';
import '../../core/l10n/seller_l10n.dart';
import 'package:latlong2/latlong.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/safe_input.dart';
import '../address/map_picker_screen.dart';
import '../seller/seller_verify_sheet.dart';

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
    final l = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final form = FormData.fromMap({'avatar': await MultipartFile.fromFile(xf.path)});
      // ✅ Endpoint-и дурусти аватар (POST /users/me/avatar)
      await ApiClient.instance.dio.post(ApiEndpoints.uploadAvatar, data: form);
      await ref.read(authProvider.notifier).checkAuth();
      messenger.showSnackBar(SnackBar(
        content: Text(l.profileImageUpdated),
        backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
    } catch (_) {
      messenger.showSnackBar(SnackBar(
        content: Text(l.profileImageFailed),
        backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    }
  }

  // ── Таҳрири профил (PUT /users/me) ─────────────────────────────────────────
  void _editProfile() {
    final l = AppL10n.of(context);
    final user = ref.read(authProvider).user;
    final nameCtrl = TextEditingController(text: user?.fullName ?? '');
    final bioCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: context.pal.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        bool loading = false;
        return StatefulBuilder(builder: (ctx, setSheet) {
          Widget field(String label, TextEditingController c, {int maxLines = 1}) =>
            Padding(padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(color: context.pal.surface, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.pal.border, width: 0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: SafeInput(controller: c, hint: label, maxLines: maxLines, fontSize: 14)));
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: context.pal.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(l.editProfile, style: TextStyle(color: context.pal.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              field(l.profileUserNameField, nameCtrl),
              field(l.profileBioField, bioCtrl, maxLines: 3),
              const SizedBox(height: 8),
              AppButton(text: l.save, isLoading: loading, onTap: () async {
                setSheet(() => loading = true);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await ApiClient.instance.dio.put(ApiEndpoints.updateProfile,
                      data: {'name': nameCtrl.text.trim(), 'bio': bioCtrl.text.trim()});
                  await ref.read(authProvider.notifier).checkAuth();
                  if (ctx.mounted) Navigator.pop(ctx);
                  messenger.showSnackBar(SnackBar(content: Text(l.profileUpdated),
                      backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
                } catch (_) {
                  setSheet(() => loading = false);
                  messenger.showSnackBar(SnackBar(content: Text(l.error),
                      backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
                }
              }),
            ]),
          );
        });
      });
  }

  // ── Бизнеси ман (store setup, PUT /users/me) ──────────────────────────────
  void _businessSetup() {
    final l = AppL10n.of(context);
    final user = ref.read(authProvider).user;
    final nameCtrl  = TextEditingController(text: user?.shopName ?? '');
    final descCtrl  = TextEditingController(text: user?.shopDesc ?? '');
    final phoneCtrl = TextEditingController(text: user?.shopPhone ?? '');
    final hoursCtrl = TextEditingController(text: user?.shopHours ?? '');
    String bizType = user?.businessType ?? 'shop';
    showModalBottomSheet(
      context: context,
      backgroundColor: context.pal.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        bool loading = false;
        return StatefulBuilder(builder: (ctx, setSheet) {
          Widget field(String label, TextEditingController c, {int maxLines = 1}) =>
            Padding(padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(color: context.pal.surface, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.pal.border, width: 0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: SafeInput(controller: c, hint: label, maxLines: maxLines, fontSize: 14)));
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: context.pal.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Row(children: [
                const Icon(FeatherIcons.shoppingBag, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text('Бизнеси ман', style: TextStyle(color: context.pal.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 16),
              field('Номи мағоза', nameCtrl),
              field('Тавсифи бизнес', descCtrl, maxLines: 3),
              field('Телефон', phoneCtrl),
              field('Соатҳои корӣ (9:00–20:00)', hoursCtrl),
              const SizedBox(height: 4),
              Text('Навъи бизнес', style: TextStyle(
                  color: context.pal.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final t in kBusinessTypes)
                  GestureDetector(
                    onTap: () => setSheet(() => bizType = t.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: bizType == t.key
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : context.pal.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: bizType == t.key ? AppColors.primary : context.pal.border,
                            width: bizType == t.key ? 1.3 : 0.5),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(t.icon,
                            size: 15,
                            color: bizType == t.key ? AppColors.primary : context.pal.textMuted),
                        const SizedBox(width: 6),
                        Text(t.label, style: TextStyle(
                            color: bizType == t.key ? AppColors.primary : context.pal.textSecondary,
                            fontSize: 13,
                            fontWeight: bizType == t.key ? FontWeight.w700 : FontWeight.w500)),
                      ]),
                    ),
                  ),
              ]),
              const SizedBox(height: 16),
              AppButton(text: l.save, isLoading: loading, onTap: () async {
                setSheet(() => loading = true);
                final messenger = ScaffoldMessenger.of(context);
                final currentName = ref.read(authProvider).user?.fullName ?? '';
                try {
                  await ApiClient.instance.dio.put(ApiEndpoints.updateProfile, data: {
                    'name': currentName,
                    'shop_name': nameCtrl.text.trim(),
                    'shop_desc': descCtrl.text.trim(),
                    'shop_phone': phoneCtrl.text.trim(),
                    'shop_hours': hoursCtrl.text.trim(),
                    'business_type': bizType,
                  });
                  await ref.read(authProvider.notifier).checkAuth();
                  if (ctx.mounted) Navigator.pop(ctx);
                  messenger.showSnackBar(SnackBar(content: Text(l.profileUpdated),
                      backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
                } catch (_) {
                  setSheet(() => loading = false);
                  messenger.showSnackBar(SnackBar(content: Text(l.error),
                      backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
                }
              }),
            ]),
          );
        });
      });
  }

  // ── Даъвати дӯстон / Referral ─────────────────────────────────────────────
  void _inviteFriends() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.pal.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 28),
        child: Consumer(builder: (ctx, ref2, _) {
          final async = ref2.watch(referralProvider);
          return async.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
            data: (d) {
              final code = (d['code'] ?? '').toString();
              final bonus = (d['bonus'] as num?)?.toString() ?? '10';
              final referrals = (d['referrals'] as num?)?.toInt() ?? 0;
              final earned = (d['earned'] as num?)?.toString() ?? '0';
              return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: context.pal.border, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 18),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(FeatherIcons.gift, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Flexible(child: Text('Даъват кунед — ҳарду $bonus сом мегиред',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.pal.textPrimary, fontSize: 17, fontWeight: FontWeight.w800))),
                ]),
                const SizedBox(height: 20),
                // ── Коди даъват (highlighted box) ─────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  decoration: BoxDecoration(
                    color: context.pal.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Center(
                    child: Text(code.isEmpty ? '—' : code,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          fontFamily: 'monospace',
                        )),
                  ),
                ),
                const SizedBox(height: 16),
                // ── Copy button ───────────────────────────────────────────
                AppButton(
                  text: 'Нусхабардорӣ',
                  onTap: () {
                    final messenger = ScaffoldMessenger.of(context);
                    Clipboard.setData(ClipboardData(
                        text: 'Коди даъвати ман дар TajikShop Pro: $code'));
                    Navigator.pop(ctx);
                    messenger.showSnackBar(const SnackBar(
                        content: Text('Нусхабардорӣ шуд ✅'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating));
                  },
                ),
                const SizedBox(height: 18),
                // ── Stats row ─────────────────────────────────────────────
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(FeatherIcons.users, color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text('$referrals дӯст',
                      style: TextStyle(color: context.pal.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 14),
                  Text('•', style: TextStyle(color: context.pal.textMuted)),
                  const SizedBox(width: 14),
                  const Icon(FeatherIcons.dollarSign, color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text('$earned сом кофтед',
                      style: TextStyle(color: context.pal.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ]);
            },
          );
        }),
      ),
    );
  }

  // ── Купонҳо ва промокодҳо ─────────────────────────────────────────────────
  void _showCoupons() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.pal.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 28),
        child: Consumer(builder: (ctx, ref2, _) {
          final async = ref2.watch(activeCouponsProvider);
          return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: context.pal.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(FeatherIcons.tag, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Купонҳои фаъол',
                  style: TextStyle(color: context.pal.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 8),
            Text('Кодро дар сабад ҳангоми пардохт ворид кунед',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.pal.textMuted, fontSize: 12.5)),
            const SizedBox(height: 18),
            async.when(
              loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
              error: (_, __) => _couponsEmpty(),
              data: (list) {
                if (list.isEmpty) return _couponsEmpty();
                return Column(children: [
                  for (final cpn in list) _couponRow(cpn),
                ]);
              },
            ),
          ]);
        }),
      ),
    );
  }

  Widget _couponsEmpty() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(children: [
          Icon(FeatherIcons.tag, size: 44, color: context.pal.textMuted),
          const SizedBox(height: 12),
          Text('Ҳоло купони фаъол нест',
              style: TextStyle(color: context.pal.textSecondary, fontSize: 14)),
        ]),
      );

  Widget _couponRow(Map<String, dynamic> cpn) {
    final code = (cpn['code'] ?? '').toString();
    final disc = (cpn['discount_percent'] as num?)?.toInt() ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.pal.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10)),
            child: Text('-$disc%',
                style: const TextStyle(
                    color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(code,
                style: TextStyle(
                    color: context.pal.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    fontFamily: 'monospace')),
          ),
          GestureDetector(
            onTap: () {
              final messenger = ScaffoldMessenger.of(context);
              Clipboard.setData(ClipboardData(text: code));
              messenger.showSnackBar(const SnackBar(
                  content: Text('Код нусхабардорӣ шуд ✅'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating));
            },
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(FeatherIcons.copy, color: Colors.white, size: 16),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Become Seller (бо тасдиқи паспорт) ────────────────────────────────────────
  Future<void> _becomeSeller() async {
    await showSellerVerify(context);
  }

  // ── Ҷойгиршавии мағоза (GPS, ихтиёрӣ) ─────────────────────────────────────────
  Future<void> _setStoreLocation() async {
    final picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => const MapPickerScreen(initial: LatLng(38.5598, 68.7870)),
      ),
    );
    if (picked == null) return;
    if (!mounted) return;
    final l = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ApiClient.instance.dio.put(
        '/users/me/location',
        data: {'lat': picked.latitude, 'lng': picked.longitude},
      );
      messenger.showSnackBar(SnackBar(
          content: Text(l.profileLocationSaved),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating));
    } catch (_) {
      messenger.showSnackBar(SnackBar(
          content: Text(l.profileLocationFailed),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating));
    }
  }

  // ── About ────────────────────────────────────────────────────────────────────
  void _showAbout(AppL10n l) {
    showAboutDialog(
      context: context,
      applicationName: 'TajikShop Pro',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12)),
        child: const Icon(FeatherIcons.shoppingBag, color: Colors.white, size: 28),
      ),
      children: [
        const SizedBox(height: 8),
        Text(l.profileAboutText),
      ],
    );
  }

  // ── Language picker ──────────────────────────────────────────────────────────
  void _showLanguagePicker() {
    final l = AppL10n.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: context.pal.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: context.pal.border,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text(l.language, style: TextStyle(color: context.pal.textPrimary,
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
                  style: TextStyle(color: isActive ? AppColors.primary : context.pal.textPrimary,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w400)),
              trailing: isActive
                  ? const Icon(FeatherIcons.checkCircle, color: AppColors.primary)
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
    final l      = AppL10n.of(context);
    final isSeller = user?.isSeller == true || user?.role == 'seller';
    final sellerRequested = user?.sellerRequested == true;

    final displayName = (user?.fullName != null && user!.fullName.isNotEmpty)
        ? user.fullName
        : (user?.email.split('@').first ?? l.userWord);

    return Scaffold(
      backgroundColor: context.pal.scaffold,
      body: SafeArea(
        top: true,
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [

            // ── App Bar ──────────────────────────────────────────────────
            SliverAppBar(
              backgroundColor: context.pal.scaffold,
              floating: true, elevation: 0,
              centerTitle: true,
              title: Text(l.profile, style: TextStyle(color: context.pal.textPrimary,
                  fontWeight: FontWeight.w700, fontSize: 20)),
            ),

            SliverToBoxAdapter(child: Column(children: [

              // ── Header: большой аватар + имя + email + роль ─────────────
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickAvatar,
                child: Stack(children: [
                  CircleAvatar(radius: 48,
                    backgroundColor: context.pal.surface,
                    backgroundImage: user?.avatar != null && user!.avatar!.isNotEmpty
                        ? CachedNetworkImageProvider(user.avatar!) : null,
                    child: user?.avatar == null || user!.avatar!.isEmpty
                        ? Icon(FeatherIcons.user, color: context.pal.textMuted, size: 48)
                        : null),
                  Positioned(bottom: 2, right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          gradient: _greenGradient,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.pal.scaffold, width: 2)),
                      child: const Icon(FeatherIcons.camera, color: Colors.white, size: 14))),
                ]),
              ),
              const SizedBox(height: 12),
              Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                Flexible(
                  child: Text(displayName,
                      style: TextStyle(color: context.pal.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis),
                ),
                if (user?.fullName == 'tajikshop' || user?.isVerified == true) ...[
                  const SizedBox(width: 6),
                  const Icon(FeatherIcons.checkCircle, color: Color(0xFF1DA1F2), size: 18),
                ],
              ]),
              const SizedBox(height: 4),
              Text(user?.email ?? '',
                  style: TextStyle(color: context.pal.textMuted, fontSize: 13)),
              const SizedBox(height: 10),
              _RoleBadge(role: user?.role ?? 'buyer', l: l),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _editProfile,
                icon: const Icon(FeatherIcons.edit2, size: 16),
                label: Text(l.editProfile),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                ),
              ),

              // ── Быстрые действия (карточка со «шэдоу», как в шаблоне) ────
              const SizedBox(height: 20),
              _QuickCard(children: [
                _QuickAction(icon: FeatherIcons.creditCard, color: const Color(0xFFFFB800),
                    label: l.myWallet, onTap: () => context.push(RouteNames.wallet)),
                _QuickAction(icon: FeatherIcons.truck, color: const Color(0xFF00A3FF),
                    label: l.orders, onTap: () => context.push(RouteNames.orders)),
                _QuickAction(icon: FeatherIcons.heart, color: const Color(0xFF00D084),
                    label: l.favorites, onTap: () => context.go(RouteNames.favorites)),
                _QuickAction(icon: FeatherIcons.mapPin, color: const Color(0xFFFF6B2C),
                    label: l.myAddresses, onTap: () => context.push(RouteNames.addresses)),
              ]),

              // ── Барномаи вафодорӣ (Bronze/Silver/Gold) ──────────────────
              const SizedBox(height: 16),
              const _LoyaltyCard(),

              // ── Seller / Become Seller ──────────────────────────────────
              if (isSeller) ...[
                _SectionLabel(l.sellerDashboard),
                _GroupCard(children: [
                  _Tile(icon: FeatherIcons.grid, iconColor: const Color(0xFF00D084),
                      label: l.sellerDashboard,
                      onTap: () => context.push(RouteNames.sellerDashboard)),
                  _Tile(icon: FeatherIcons.shoppingBag, iconColor: AppColors.primary,
                      label: 'Бизнеси ман',
                      onTap: _businessSetup),
                  _Tile(icon: FeatherIcons.mapPin, iconColor: const Color(0xFFFF6B2C),
                      label: l.storeLocation,
                      onTap: _setStoreLocation),
                ]),
              ] else if (sellerRequested)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40, alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12)),
                        child: const Icon(FeatherIcons.clock, color: AppColors.primary, size: 20)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(l.sellerRequestPending,
                          style: TextStyle(color: context.pal.textPrimary,
                              fontSize: 14, fontWeight: FontWeight.w600))),
                    ]),
                  ))
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: AppButton(
                    text: '🏪 ${l.becomeSeller}',
                    onTap: _becomeSeller,
                  )),

              // ── Даъвати дӯстон + Купонҳо (visible to everyone) ──────────
              _GroupCard(children: [
                _Tile(icon: FeatherIcons.gift, iconColor: AppColors.primary,
                    label: '🎁 Дӯстонро даъват кунед',
                    onTap: _inviteFriends),
                _Tile(icon: FeatherIcons.tag, iconColor: const Color(0xFFFF6B2C),
                    label: '🎟 Купонҳо ва промокодҳо',
                    onTap: _showCoupons),
              ]),

              // ── Настройки ───────────────────────────────────────────────
              _SectionLabel(l.settings),
              _GroupCard(children: [
                // Тема
                _SwitchTile(
                  icon: isDark ? FeatherIcons.moon : FeatherIcons.sun,
                  iconColor: const Color(0xFFFFB800),
                  label: isDark ? l.darkMode : l.lightMode,
                  value: isDark,
                  onChanged: (v) => ref.read(themeProvider.notifier).toggle()),
                // Забон
                _Tile(
                  icon: FeatherIcons.globe, iconColor: const Color(0xFF00A3FF),
                  label: '${l.language}: ${LocaleNotifier.langName(ref.watch(localeProvider).languageCode)}',
                  onTap: _showLanguagePicker),
                _Tile(icon: FeatherIcons.bell, iconColor: const Color(0xFFE040FB),
                    label: l.notifications, onTap: () => context.push(RouteNames.notifications)),
              ]),

              // ── О приложении ────────────────────────────────────────────
              _SectionLabel(l.about),
              _GroupCard(children: [
                _Tile(icon: FeatherIcons.info, iconColor: context.pal.textMuted,
                    label: l.about, onTap: () => _showAbout(l)),
              ]),

              // ── Выход ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Material(
                  color: const Color(0xFFFF3B5C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go(RouteNames.login);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(FeatherIcons.logOut, color: Color(0xFFFF3B5C), size: 20),
                        const SizedBox(width: 8),
                        Text(l.logout, style: const TextStyle(
                            color: Color(0xFFFF3B5C), fontWeight: FontWeight.w700, fontSize: 15)),
                      ]),
                    ),
                  ),
                )),
            ])),
          ]),
      ));
  }
}

// ── Green gradient (замена жёлтому/оранжевому шаблона) ───────────────────────
const LinearGradient _greenGradient = LinearGradient(
  colors: [Color(0xFF00D084), Color(0xFF00A3FF)],
  begin: Alignment.topLeft, end: Alignment.bottomRight,
);

List<BoxShadow> _softShadow(BuildContext context) => [
  BoxShadow(
    color: context.pal.textMuted.withValues(alpha: 0.12),
    blurRadius: 16,
    spreadRadius: 0,
    offset: const Offset(0, 6),
  ),
];

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
          color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withValues(alpha: 0.4))),
      child: Text(label, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700)));
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Text(label.toUpperCase(), style: TextStyle(
          color: context.pal.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
    ));
}

/// Карточка-контейнер с мягкой тенью (как «shadow» в шаблоне), разделители между строками.
class _GroupCard extends StatelessWidget {
  final List<Widget> children;
  const _GroupCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i != children.length - 1) {
        rows.add(Divider(height: 1, thickness: 0.6, indent: 60, endIndent: 16,
            color: context.pal.border));
      }
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: context.pal.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.pal.border),
        boxShadow: _softShadow(context),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(children: rows),
      ),
    );
  }
}

/// Строка списка в стиле шаблона: цветной значок в мягком квадрате, заголовок, шеврон.
class _Tile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  const _Tile({required this.icon, required this.iconColor,
      required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(width: 36, height: 36, alignment: Alignment.center,
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(color: context.pal.textPrimary,
              fontSize: 15, fontWeight: FontWeight.w500))),
          Icon(FeatherIcons.chevronRight, color: context.pal.textMuted, size: 22),
        ]),
      ),
    ));
}

/// Как _Tile, но с переключателем (тема) — остаётся полностью функциональной.
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
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: Row(children: [
      Container(width: 36, height: 36, alignment: Alignment.center,
          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 20)),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: TextStyle(color: context.pal.textPrimary,
          fontSize: 15, fontWeight: FontWeight.w500))),
      Switch.adaptive(value: value, onChanged: onChanged,
          activeColor: AppColors.primary),
    ]));
}

/// Полоса быстрых действий (карточка с тенью, ряд иконок — как в шаблоне).
class _QuickCard extends StatelessWidget {
  final List<Widget> children;
  const _QuickCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
    decoration: BoxDecoration(
      color: context.pal.card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: context.pal.border),
      boxShadow: _softShadow(context),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: children,
    ),
  );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.color,
      required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 46, height: 46, alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 22)),
        const SizedBox(height: 6),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.pal.textSecondary,
                fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    ));
}

// ── Корти вафодорӣ (Bronze / Silver / Gold) ───────────────────────────────────
class _LoyaltyCard extends ConsumerWidget {
  const _LoyaltyCard();

  ({String label, Color color, IconData icon}) _tierInfo(String tier) {
    switch (tier) {
      case 'gold':
        return (label: 'Gold', color: const Color(0xFFFFB800), icon: FeatherIcons.award);
      case 'silver':
        return (label: 'Silver', color: const Color(0xFF9AA5B1), icon: FeatherIcons.award);
      default:
        return (label: 'Bronze', color: const Color(0xFFCD7F32), icon: FeatherIcons.award);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pal = context.pal;
    final async = ref.watch(loyaltyProvider);
    final d = async.asData?.value ?? const {};
    final tier = (d['tier'] ?? 'bronze').toString();
    final spent = (d['total_spent'] as num?)?.toDouble() ?? 0;
    final cashback = (d['cashback_percent'] as num?)?.toDouble() ?? 2;
    final nextAt = (d['next_tier_at'] as num?)?.toDouble() ?? 0;
    final info = _tierInfo(tier);
    final progress = nextAt > 0 ? (spent / nextAt).clamp(0.0, 1.0) : 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: pal.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: info.color.withValues(alpha: 0.4), width: 1),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: info.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(info.icon, color: info.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('Сатҳи ${info.label}',
                      style: TextStyle(
                          color: pal.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 2),
                Text('Cashback: ${cashback.toStringAsFixed(cashback == cashback.roundToDouble() ? 0 : 1)}% аз ҳар харид',
                    style: TextStyle(color: pal.textMuted, fontSize: 12)),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          if (nextAt > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: pal.surface,
                valueColor: AlwaysStoppedAnimation(info.color),
              ),
            ),
            const SizedBox(height: 7),
            Text(
                'То сатҳи баъдӣ: ${(nextAt - spent).clamp(0, nextAt).toStringAsFixed(0)} сом харид кунед',
                style: TextStyle(color: pal.textSecondary, fontSize: 12)),
          ] else
            Row(children: [
              const Icon(FeatherIcons.checkCircle, color: AppColors.success, size: 15),
              const SizedBox(width: 6),
              Text('Сатҳи болоӣ — cashback-и максималӣ!',
                  style: TextStyle(
                      color: pal.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ]),
        ]),
      ),
    );
  }
}
