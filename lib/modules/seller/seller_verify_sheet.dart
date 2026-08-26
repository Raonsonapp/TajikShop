import 'dart:io';
import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/app_button.dart';
import '../../core/app_l10n.dart';
import '../../core/l10n/seller_l10n.dart';

/// Градиенти сабз (ecommerce_int2 look, ранги бренди TajikShop).
const LinearGradient _greenGradient = LinearGradient(
  colors: [Color(0xFF00D084), Color(0xFF00A86B)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Равзанаи KYC — корбар барои фурӯшанда шудан акси паспортро бор мекунад.
/// Натиҷа: true агар муваффақ.
Future<bool?> showSellerVerify(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: context.pal.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => const SellerVerifySheet(),
  );
}

class SellerVerifySheet extends ConsumerStatefulWidget {
  const SellerVerifySheet({super.key});
  @override
  ConsumerState<SellerVerifySheet> createState() => _SellerVerifySheetState();
}

class _SellerVerifySheetState extends ConsumerState<SellerVerifySheet> {
  File? _passport;
  bool _loading = false;

  Future<void> _pick() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1600);
    if (x != null) setState(() => _passport = File(x.path));
  }

  Future<void> _submit() async {
    if (_passport == null) return;
    setState(() => _loading = true);
    final l = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref.read(authProvider.notifier).submitSellerVerification(_passport!.path);
    if (ok) {
      // Дархост фиристода шуд — вазъияти корбарро нав мекунем (seller_requested).
      await ref.read(authProvider.notifier).checkAuth();
    }
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
      messenger.showSnackBar(SnackBar(
        content: Text(l.sellerVerifyRequestSent),
        backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
    } else {
      setState(() => _loading = false);
      messenger.showSnackBar(SnackBar(
        content: Text(l.sellerVerifyError),
        backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: context.pal.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        // Header with green gradient badge
        Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: _greenGradient,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(color: Color(0x4D00D084), offset: Offset(0, 4), blurRadius: 12),
              ],
            ),
            child: const Icon(FeatherIcons.shield, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(l.sellerVerifyTitle,
              style: TextStyle(color: context.pal.textPrimary, fontSize: 20, fontWeight: FontWeight.w900))),
        ]),
        const SizedBox(height: 14),
        Text(l.sellerVerifyDesc,
            style: TextStyle(color: context.pal.textSecondary, fontSize: 13, height: 1.45)),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: _pick,
          child: Container(
            width: double.infinity, height: _passport != null ? 200 : 130,
            decoration: BoxDecoration(
              color: context.pal.surface, borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _passport != null ? AppColors.success : context.pal.border, width: 1.5),
              image: _passport != null ? DecorationImage(image: FileImage(_passport!), fit: BoxFit.cover) : null),
            child: _passport == null ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(FeatherIcons.creditCard, color: AppColors.primary, size: 30),
              ),
              const SizedBox(height: 10),
              Text(l.sellerUploadPassport, style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700)),
            ])) : Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                  child: const Icon(FeatherIcons.check, color: Colors.white, size: 16),
                ),
              ),
            )),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Icon(FeatherIcons.lock, color: context.pal.textMuted, size: 14),
          const SizedBox(width: 6),
          Expanded(child: Text(l.sellerDataPrivate,
              style: TextStyle(color: context.pal.textMuted, fontSize: 11))),
        ]),
        const SizedBox(height: 18),
        AppButton(
          text: _passport == null ? l.sellerUploadPhotoFirst : l.sellerSubmitBecomeSeller,
          icon: _passport == null ? null : FeatherIcons.checkCircle,
          isLoading: _loading,
          onTap: _passport != null ? _submit : null),
      ]),
    );
  }
}
