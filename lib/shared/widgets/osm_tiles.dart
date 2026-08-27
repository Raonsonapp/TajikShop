import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';

/// Қабати плиткаҳои OpenStreetMap бо як танзими муштарак барои ҳамаи харитаҳо.
///
/// Чаро: то плиткаҳо бор шаванд (дар интернети суст ин чанд сония аст),
/// `flutter_map` заминаро бо ранги пешфарзи худ — `0xFFE0E0E0` — пур мекунад.
/// Маҳз ҳамон «майдони хокистарранг»-е, ки дар харита дида мешуд. Акнун
/// замина ранги бренд аст ва сервери дуюм ҳамчун захира гузошта шудааст.
class OsmTiles extends StatelessWidget {
  const OsmTiles({super.key});

  @override
  Widget build(BuildContext context) => TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        // Агар сервери асосӣ ҷавоб надиҳад, аз оинаи дуюм мегирем.
        fallbackUrl: 'https://tile-a.openstreetmap.fr/hot/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.tajikshop.app',
        // OSM то зуми 19 плитка дорад — дар зумҳои калон рақами хонаҳо
        // намоён мешаванд.
        maxNativeZoom: 19,
        // Каме бештар плитка дар захира — ҳангоми ҳаракат камтар «холигӣ».
        keepBuffer: 3,
      );
}

/// Ранги заминаи харита — ба ҷои хокистарранги пешфарзи `flutter_map`.
Color mapBackground(BuildContext context) => context.pal.surface;

/// Ранги маркер/акценти харита — дар ҳамаи харитаҳо якхела.
const Color kMapAccent = AppColors.primary;
