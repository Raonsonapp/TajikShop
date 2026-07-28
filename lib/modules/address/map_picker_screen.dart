import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/app_l10n.dart';
import '../../core/l10n/orders_l10n.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';

/// Интихоби нуқта дар харитаи OpenStreetMap (ройгон, бе калид).
/// Ҳангоми кушода шудан ба ҷойгиршавии ҳозираи дастгоҳ (GPS) меравад,
/// то фурӯшанда мағозаашро осон ёбад. Натиҷа: LatLng ҳангоми тасдиқ.
class MapPickerScreen extends StatefulWidget {
  final LatLng initial;
  const MapPickerScreen({super.key, required this.initial});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final _controller = MapController();
  late LatLng _center = widget.initial;
  bool _locating = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _goToMyLocation(initial: true));
  }

  Future<void> _goToMyLocation({bool initial = false}) async {
    if (mounted) setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw mounted ? AppL10n.of(context).gpsOff : 'GPS';
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw mounted ? AppL10n.of(context).locationPermissionDenied : 'Permission denied';
      }
      final pos = await Geolocator.getCurrentPosition();
      final here = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() => _center = here);
      _controller.move(here, 16);
    } catch (e) {
      if (!initial && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pal.scaffold,
      appBar: AppBar(
        backgroundColor: context.pal.scaffold,
        iconTheme: IconThemeData(color: context.pal.textPrimary),
        title: Text(AppL10n.of(context).pickStoreLocationTitle,
            style: TextStyle(color: context.pal.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      body: Stack(children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: widget.initial,
            initialZoom: 13,
            onPositionChanged: (camera, _) => _center = camera.center,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.tajikshop',
            ),
          ],
        ),

        // Маркери собит дар марказ
        IgnorePointer(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 36),
              child: Icon(FeatherIcons.mapPin, size: 46, color: AppColors.primary,
                  shadows: const [Shadow(color: Colors.black54, blurRadius: 8)]),
            ),
          ),
        ),

        // Дастур
        Positioned(top: 12, left: 16, right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12)),
            child: Text(
                _locating
                    ? AppL10n.of(context).findingYourLocation
                    : AppL10n.of(context).moveMapHint,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 12)))),

        // Тугмаи «ҷойгиршавии ман»
        Positioned(right: 16, bottom: 96,
          child: FloatingActionButton(
            heroTag: 'myloc',
            backgroundColor: context.pal.card,
            onPressed: _locating ? null : () => _goToMyLocation(),
            child: _locating
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.primary))
                : const Icon(FeatherIcons.navigation, color: AppColors.primary))),

        // Тугмаи тасдиқ
        Positioned(left: 16, right: 16, bottom: 24,
          child: SizedBox(height: 52, child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, _center),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            icon: const Icon(FeatherIcons.check, color: Colors.white),
            label: Text(AppL10n.of(context).pickThisLocation,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))))),
      ]),
    );
  }
}
