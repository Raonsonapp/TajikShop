import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/app_l10n.dart';
import '../../core/l10n/orders_l10n.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/address_provider.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/safe_input.dart';
import 'map_picker_screen.dart';

/// Равзанаи иловаи суроға (бо интихоб дар харита). Натиҷа: true агар захира шуд.
Future<bool?> showAddAddress(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: context.pal.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => const AddAddressSheet(),
  );
}

class AddAddressSheet extends ConsumerStatefulWidget {
  const AddAddressSheet({super.key});
  @override
  ConsumerState<AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends ConsumerState<AddAddressSheet> {
  final _title = TextEditingController(text: 'Хона');
  final _city = TextEditingController(text: 'Душанбе');
  final _street = TextEditingController();
  final _zip = TextEditingController();
  bool _loading = false;
  double _lat = 0, _lng = 0;

  @override
  void dispose() {
    _title.dispose();
    _city.dispose();
    _street.dispose();
    _zip.dispose();
    super.dispose();
  }

  Future<void> _pickOnMap() async {
    final result = await Navigator.of(context).push<LatLng>(MaterialPageRoute(
      builder: (_) => MapPickerScreen(
          initial:
              LatLng(_lat != 0 ? _lat : 38.5598, _lng != 0 ? _lng : 68.7870)),
    ));
    if (result != null) {
      setState(() {
        _lat = result.latitude;
        _lng = result.longitude;
      });
    }
  }

  Future<void> _save() async {
    if (_street.text.trim().isEmpty || _city.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppL10n.of(context).fillCityStreet),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _loading = true);
    try {
      await AddressService.add(
          title: _title.text.trim().isEmpty ? 'Суроға' : _title.text.trim(),
          city: _city.text.trim(),
          street: _street.text.trim(),
          zip: _zip.text.trim(),
          lat: _lat,
          lng: _lng);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppL10n.of(context).addressSaveFailed),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating));
      }
    }
  }

  // Нишонаи болои гурӯҳи майдонҳо
  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6, top: 4),
        child: Text(text,
            style: TextStyle(
                color: context.pal.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2)),
      );

  // Майдони мудаввар (SafeInput дар дохил)
  Widget _f(String hint, TextEditingController c,
          {TextInputType? keyboardType}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: context.pal.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.pal.border, width: 0.6)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: SafeInput(
          controller: c,
          hint: hint,
          keyboardType: keyboardType,
          textColor: context.pal.textPrimary,
          fontSize: 15,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final picked = _lat != 0;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                      color: context.pal.border,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.add_location_alt_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Text(l.newAddress,
                    style: TextStyle(
                        color: context.pal.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 22),
            _label(l.addressNameLabel),
            _f(l.addressNameHint, _title),
            _label(l.city),
            _f(l.cityHint, _city),
            _label(l.fullAddressLabel),
            _f(l.streetHint, _street),
            _label(l.indexLabel),
            _f(l.indexHint, _zip,
                keyboardType: TextInputType.number),
            const SizedBox(height: 4),
            _label(l.locationOnMap),
            // ── Тугмаи интихоб дар харита (сабз) ────────────────────────
            GestureDetector(
              onTap: _pickOnMap,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: (picked ? AppColors.success : AppColors.primary)
                      .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: (picked ? AppColors.success : AppColors.primary)
                          .withValues(alpha: 0.45),
                      width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                        picked
                            ? Icons.check_circle_rounded
                            : Icons.map_outlined,
                        color: picked ? AppColors.success : AppColors.primary,
                        size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                          picked
                              ? '${l.locationPicked} (${_lat.toStringAsFixed(4)}, ${_lng.toStringAsFixed(4)})'
                              : l.pickLocationOnMap,
                          style: TextStyle(
                              color: picked
                                  ? AppColors.success
                                  : AppColors.primary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700)),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: context.pal.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            // ── Тугмаи захира (градиенти калони сабз) ───────────────────
            AppButton(
              text: l.save,
              onTap: _save,
              isLoading: _loading,
              height: 58,
            ),
          ],
        ),
      ),
    );
  }
}
