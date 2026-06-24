import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';

/// Интихоби нуқта дар харитаи OpenStreetMap (ройгон, бе калид).
/// Натиҷа: LatLng-и маркази харита ҳангоми тасдиқ.
class MapPickerScreen extends StatefulWidget {
  final LatLng initial;
  const MapPickerScreen({super.key, required this.initial});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final _controller = MapController();
  LatLng _center = const LatLng(38.5598, 68.7870); // Душанбе

  @override
  void initState() {
    super.initState();
    _center = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text('Ҷойро дар харита интихоб кунед',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      body: Stack(children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: widget.initial,
            initialZoom: 14,
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
              child: Icon(Icons.location_on, size: 46, color: AppColors.primary,
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
            child: const Text('Харитаро ҳаракат диҳед, то маркер ба ҷои дилхоҳ ишора кунад',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 12)))),

        // Тугмаи тасдиқ
        Positioned(left: 16, right: 16, bottom: 24,
          child: SizedBox(height: 52, child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, _center),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            icon: const Icon(Icons.check_rounded, color: Colors.white),
            label: const Text('Ин ҷойро интихоб мекунам',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))))),
      ]),
    );
  }
}
