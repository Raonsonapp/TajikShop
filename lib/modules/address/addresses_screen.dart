import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/address_provider.dart';
import '../../shared/widgets/error_screen.dart';
import 'add_address_sheet.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressesProvider);
    return Scaffold(
      backgroundColor: context.pal.scaffold,
      appBar: AppBar(
        backgroundColor: context.pal.scaffold,
        iconTheme: IconThemeData(color: context.pal.textPrimary),
        title: Text('Суроғаҳои ман',
            style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final ok = await showAddAddress(context);
          if (ok == true) ref.invalidate(addressesProvider);
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Суроға', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: addresses.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorScreen(message: e.toString(), onRetry: () => ref.invalidate(addressesProvider)),
        data: (list) => list.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.location_off_outlined, size: 80, color: context.pal.textMuted),
                const SizedBox(height: 16),
                Text('Суроға нест', style: TextStyle(color: context.pal.textSecondary, fontSize: 15)),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final a = list[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: context.pal.card, borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: a.isDefault ? AppColors.primary : context.pal.border,
                            width: a.isDefault ? 1.3 : 0.5)),
                    child: Row(children: [
                      Icon(a.hasLocation ? Icons.location_on : Icons.location_on_outlined,
                          color: AppColors.primary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(a.title, style: TextStyle(color: context.pal.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                          if (a.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Text('Пешфарз', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w600))),
                          ],
                        ]),
                        const SizedBox(height: 3),
                        Text(a.full, style: TextStyle(color: context.pal.textSecondary, fontSize: 12)),
                      ])),
                      PopupMenuButton<String>(
                        color: context.pal.elevated,
                        icon: Icon(Icons.more_vert, color: context.pal.textSecondary),
                        onSelected: (v) async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            if (v == 'default') await AddressService.setDefault(a.id);
                            if (v == 'delete') await AddressService.remove(a.id);
                            ref.invalidate(addressesProvider);
                          } catch (_) {
                            messenger.showSnackBar(const SnackBar(content: Text('Хато'),
                                backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
                          }
                        },
                        itemBuilder: (_) => [
                          if (!a.isDefault) PopupMenuItem(value: 'default',
                              child: Text('Пешфарз кардан', style: TextStyle(color: context.pal.textPrimary))),
                          const PopupMenuItem(value: 'delete',
                              child: Text('Нест кардан', style: TextStyle(color: AppColors.error))),
                        ],
                      ),
                    ]),
                  );
                }),
      ),
    );
  }
}
