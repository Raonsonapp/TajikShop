import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/address_provider.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/safe_input.dart';
import 'map_picker_screen.dart';

/// Равзанаи иловаи суроға (бо интихоб дар харита). Натиҷа: true агар захира шуд.
Future<bool?> showAddAddress(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.bgCard,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
    _title.dispose(); _city.dispose(); _street.dispose(); _zip.dispose();
    super.dispose();
  }

  Future<void> _pickOnMap() async {
    final result = await Navigator.of(context).push<LatLng>(MaterialPageRoute(
      builder: (_) => MapPickerScreen(
        initial: LatLng(_lat != 0 ? _lat : 38.5598, _lng != 0 ? _lng : 68.7870)),
    ));
    if (result != null) {
      setState(() { _lat = result.latitude; _lng = result.longitude; });
    }
  }

  Future<void> _save() async {
    if (_street.text.trim().isEmpty || _city.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Шаҳр ва кӯчаро пур кунед'),
        backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _loading = true);
    try {
      await AddressService.add(
        title: _title.text.trim().isEmpty ? 'Суроға' : _title.text.trim(),
        city: _city.text.trim(),
        street: _street.text.trim(),
        zip: _zip.text.trim(),
        lat: _lat, lng: _lng);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Суроға захира нашуд'),
          backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
      }
    }
  }

  Widget _f(String hint, TextEditingController c) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5)),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: SafeInput(
      controller: c,
      hint: hint,
      textColor: AppColors.textPrimary,
      fontSize: 14,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        const Text('Суроғаи нав', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        _f('Номи суроға (Хона, Кор...)', _title),
        _f('Шаҳр *', _city),
        _f('Кӯча, хона, манзил *', _street),
        _f('Индекс (ихтиёрӣ)', _zip),
        GestureDetector(
          onTap: _pickOnMap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: (_lat != 0 ? AppColors.success : AppColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: (_lat != 0 ? AppColors.success : AppColors.primary).withValues(alpha: 0.4))),
            child: Row(children: [
              Icon(_lat != 0 ? Icons.check_circle_rounded : Icons.map_outlined,
                  color: _lat != 0 ? AppColors.success : AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(
                  _lat != 0
                      ? 'Ҷой дар харита интихоб шуд (${_lat.toStringAsFixed(4)}, ${_lng.toStringAsFixed(4)})'
                      : 'Ҷойро дар харита интихоб кунед',
                  style: TextStyle(
                      color: _lat != 0 ? AppColors.success : AppColors.primary,
                      fontSize: 13, fontWeight: FontWeight.w600))),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        AppButton(text: 'Захира кардан', onTap: _save, isLoading: _loading),
      ]),
    );
  }
}
