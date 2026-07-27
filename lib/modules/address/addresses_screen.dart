import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_l10n.dart';
import '../../core/l10n/orders_l10n.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/address_model.dart';
import '../../providers/address_provider.dart';
import '../../shared/widgets/error_screen.dart';
import 'add_address_sheet.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  IconData _iconFor(AddressModel a) {
    final t = a.title.toLowerCase();
    if (t.contains('кор') || t.contains('work') || t.contains('офис')) {
      return Icons.work_rounded;
    }
    if (t.contains('хона') || t.contains('home')) return Icons.home_rounded;
    return a.hasLocation ? Icons.location_on_rounded : Icons.location_on_outlined;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressesProvider);
    return Scaffold(
      backgroundColor: context.pal.scaffold,
      appBar: AppBar(
        backgroundColor: context.pal.scaffold,
        elevation: 0,
        iconTheme: IconThemeData(color: context.pal.textPrimary),
        title: Text(AppL10n.of(context).myAddresses,
            style: TextStyle(
                color: context.pal.textPrimary, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Expanded(
            child: addresses.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => ErrorScreen(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(addressesProvider)),
              data: (list) => list.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.10),
                            ),
                            child: const Icon(Icons.location_off_outlined,
                                size: 44, color: AppColors.primary),
                          ),
                          const SizedBox(height: 18),
                          Text(AppL10n.of(context).noAddresses,
                              style: TextStyle(
                                  color: context.pal.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(AppL10n.of(context).addNewAddressHint,
                              style: TextStyle(
                                  color: context.pal.textSecondary,
                                  fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: list.length,
                      itemBuilder: (_, i) =>
                          _AddressCard(a: list[i], icon: _iconFor(list[i]), ref: ref),
                    ),
            ),
          ),
          // ── Тугмаи иловаи суроға (градиенти сабз) ──────────────────────
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: GestureDetector(
                onTap: () async {
                  final ok = await showAddAddress(context);
                  if (ok == true) ref.invalidate(addressesProvider);
                },
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        offset: const Offset(0, 6),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_location_alt_rounded,
                            color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Text(AppL10n.of(context).addAddress,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final AddressModel a;
  final IconData icon;
  final WidgetRef ref;
  const _AddressCard({required this.a, required this.icon, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.pal.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: a.isDefault ? AppColors.primary : context.pal.border,
          width: a.isDefault ? 1.4 : 0.6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Иконаи навъи суроға дар доираи градиентӣ
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(a.title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: context.pal.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                    ),
                    if (a.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(AppL10n.of(context).defaultBadge,
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Text(a.full,
                    style: TextStyle(
                        color: context.pal.textSecondary,
                        fontSize: 13,
                        height: 1.35)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: context.pal.elevated,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            icon: Icon(Icons.more_vert, color: context.pal.textSecondary),
            onSelected: (v) async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                if (v == 'default') await AddressService.setDefault(a.id);
                if (v == 'delete') await AddressService.remove(a.id);
                ref.invalidate(addressesProvider);
              } catch (_) {
                messenger.showSnackBar(SnackBar(
                    content: Text(AppL10n.of(context).error),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating));
              }
            },
            itemBuilder: (_) => [
              if (!a.isDefault)
                PopupMenuItem(
                  value: 'default',
                  child: Row(children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Text(AppL10n.of(context).setDefaultAction,
                        style: TextStyle(color: context.pal.textPrimary)),
                  ]),
                ),
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error, size: 18),
                  const SizedBox(width: 10),
                  Text(AppL10n.of(context).deleteAction,
                      style: const TextStyle(color: AppColors.error)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
