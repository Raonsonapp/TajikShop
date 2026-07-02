import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/app_button.dart';

/// Равзанаи KYC — корбар барои фурӯшанда шудан акси паспортро бор мекунад.
/// Натиҷа: true агар муваффақ.
Future<bool?> showSellerVerify(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: context.pal.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref.read(authProvider.notifier).submitSellerVerification(_passport!.path);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
      messenger.showSnackBar(const SnackBar(
        content: Text('Дархост фиристода шуд! Акнун шумо фурӯшандаед ✅'),
        backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
    } else {
      setState(() => _loading = false);
      messenger.showSnackBar(const SnackBar(
        content: Text('Хато. Дубора кӯшиш кунед'),
        backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: context.pal.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Text('Фурӯшанда шудан 🏪',
            style: TextStyle(color: context.pal.textPrimary, fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Барои бехатарии харидорон, акси паспорт (ё шиноснома)-ро бор кунед. '
            'Админ онро месанҷад ва нишони «тасдиқшуда» медиҳад.',
            style: TextStyle(color: context.pal.textSecondary, fontSize: 13, height: 1.4)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _pick,
          child: Container(
            width: double.infinity, height: _passport != null ? 200 : 120,
            decoration: BoxDecoration(
              color: context.pal.surface, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _passport != null ? AppColors.success : context.pal.border, width: 1.5),
              image: _passport != null ? DecorationImage(image: FileImage(_passport!), fit: BoxFit.cover) : null),
            child: _passport == null ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.badge_outlined, color: AppColors.primary, size: 36),
              SizedBox(height: 8),
              Text('Акси паспортро бор кунед', style: TextStyle(color: AppColors.primary, fontSize: 13)),
            ])) : null),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Icon(Icons.lock_outline_rounded, color: context.pal.textMuted, size: 14),
          const SizedBox(width: 6),
          Expanded(child: Text('Маълумоти шумо махфӣ нигоҳ дошта мешавад.',
              style: TextStyle(color: context.pal.textMuted, fontSize: 11))),
        ]),
        const SizedBox(height: 16),
        AppButton(
          text: _passport == null ? 'Аввал акс бор кунед' : 'Фиристодан ва фурӯшанда шудан',
          isLoading: _loading,
          onTap: _passport != null ? _submit : null),
      ]),
    );
  }
}
