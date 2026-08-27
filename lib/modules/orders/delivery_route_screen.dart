import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/widgets/osm_tiles.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';

/// Харитаи роҳи расонидан: аз ҷои ҳозираи фурӯшанда то хонаи харидор.
///
/// Роҳ бо хати **сабз** кашида мешавад. Аввал роҳи воқеии кӯчагӣ аз OSRM
/// гирифта мешавад; агар шабака дастрас набошад, хати рост кашида мешавад
/// (то экран ҳеҷ гоҳ холӣ намонад) ва инро ба корбар рӯирост мегӯем.
class DeliveryRouteScreen extends StatefulWidget {
  final double destLat;
  final double destLng;
  final String destLabel; // масалан «Хонаи 42»
  final String? buyerName;

  const DeliveryRouteScreen({
    super.key,
    required this.destLat,
    required this.destLng,
    required this.destLabel,
    this.buyerName,
  });

  @override
  State<DeliveryRouteScreen> createState() => _DeliveryRouteScreenState();
}

class _DeliveryRouteScreenState extends State<DeliveryRouteScreen> {
  final _map = MapController();

  LatLng? _me;
  List<LatLng> _route = const [];
  bool _loading = true;
  bool _straightLine = false; // роҳи воқеӣ гирифта нашуд
  double _distanceKm = 0;
  int _minutes = 0;
  String? _error;

  LatLng get _dest => LatLng(widget.destLat, widget.destLng);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final me = await _currentPosition();
      if (!mounted) return;
      setState(() => _me = me);
      await _buildRoute(me, _dest);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
      _fitBounds();
    }
  }

  Future<LatLng> _currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw 'GPS хомӯш аст — онро фаъол кунед';
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      throw 'Иҷозати ҷойгиршавӣ дода нашуд';
    }
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return LatLng(p.latitude, p.longitude);
  }

  /// Роҳи кӯчагӣ аз OSRM; агар нашавад — хати рост.
  Future<void> _buildRoute(LatLng from, LatLng to) async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ));
      final url = 'https://router.project-osrm.org/route/v1/driving/'
          '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
          '?overview=full&geometries=geojson';
      final res = await dio.get(url);
      final data = res.data is String ? jsonDecode(res.data) : res.data;
      final routes = (data is Map) ? data['routes'] : null;
      if (routes is List && routes.isNotEmpty) {
        final r = routes.first as Map;
        final coords = (r['geometry']?['coordinates'] as List?) ?? const [];
        final pts = <LatLng>[
          for (final c in coords)
            if (c is List && c.length >= 2)
              LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
        ];
        if (pts.length >= 2 && mounted) {
          setState(() {
            _route = pts;
            _straightLine = false;
            _distanceKm = ((r['distance'] as num?)?.toDouble() ?? 0) / 1000;
            _minutes = (((r['duration'] as num?)?.toDouble() ?? 0) / 60).round();
          });
          return;
        }
      }
    } catch (_) {
      // поён — хати рост
    }
    if (!mounted) return;
    setState(() {
      _route = [from, to];
      _straightLine = true;
      _distanceKm = _haversineKm(from, to);
      // Тахмини дағал: ~25 км/соат дар шаҳр.
      _minutes = (_distanceKm / 25 * 60).round();
    });
  }

  static double _haversineKm(LatLng a, LatLng b) {
    const r = 6371.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLon = _rad(b.longitude - a.longitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(a.latitude)) *
            math.cos(_rad(b.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  static double _rad(double d) => d * math.pi / 180;

  /// Ҳарду нуқтаро дар экран ҷой медиҳад.
  void _fitBounds() {
    if (_route.length < 2) return;
    try {
      _map.fitCamera(CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(_route),
        padding: const EdgeInsets.fromLTRB(50, 130, 50, 220),
      ));
    } catch (_) {/* харита ҳанӯз омода нест */}
  }

  /// Кунҷи самти ҳаракат — то иконаи самолёт ба сӯи харидор нигарад.
  double get _bearing {
    if (_me == null) return 0;
    final from = _me!;
    final to = _dest;
    final dLon = _rad(to.longitude - from.longitude);
    final y = math.sin(dLon) * math.cos(_rad(to.latitude));
    final x = math.cos(_rad(from.latitude)) * math.sin(_rad(to.latitude)) -
        math.sin(_rad(from.latitude)) *
            math.cos(_rad(to.latitude)) *
            math.cos(dLon);
    return math.atan2(y, x); // радиан
  }

  Future<void> _openInMaps() async {
    final messenger = ScaffoldMessenger.of(context);
    final geo = Uri.parse(
        'geo:${widget.destLat},${widget.destLng}?q=${widget.destLat},${widget.destLng}');
    try {
      if (await canLaunchUrl(geo)) {
        await launchUrl(geo, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {/* поён */}
    try {
      await launchUrl(
        Uri.parse('https://www.google.com/maps/dir/?api=1'
            '&destination=${widget.destLat},${widget.destLng}'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Барномаи харита ёфт нашуд'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Scaffold(
      backgroundColor: pal.scaffold,
      appBar: AppBar(
        backgroundColor: pal.scaffold,
        elevation: 0,
        iconTheme: IconThemeData(color: pal.textPrimary),
        title: Text('Роҳ то харидор',
            style: TextStyle(
                color: pal.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        actions: [
          IconButton(
            tooltip: 'Нав кардан',
            icon: Icon(FeatherIcons.refreshCw, size: 19, color: pal.textSecondary),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: Stack(children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: _dest,
            initialZoom: 13,
            minZoom: 5,
            maxZoom: 19,
            backgroundColor: mapBackground(context),
          ),
          children: [
            const OsmTiles(),

            // ── Хати САБЗИ роҳ ──
            if (_route.length >= 2)
              PolylineLayer(polylines: [
                // Сояи васеътар — то хат дар харитаи равшан ҳам намоён бошад.
                Polyline(
                  points: _route,
                  strokeWidth: 9,
                  color: Colors.black.withValues(alpha: 0.18),
                ),
                Polyline(
                  points: _route,
                  // Роҳи тахминӣ (хати рост) борик ва шаффофтар кашида
                  // мешавад, то аз роҳи воқеии кӯчагӣ фарқ кунад; дар
                  // панели поён низ дар ин бора навишта мешавад.
                  strokeWidth: _straightLine ? 4 : 5.5,
                  color: _straightLine
                      ? AppColors.primary.withValues(alpha: 0.65)
                      : AppColors.primary,
                ),
              ]),

            MarkerLayer(markers: [
              // Харидор
              Marker(
                point: _dest,
                width: 132,
                height: 74,
                alignment: Alignment.topCenter,
                child: _destMarker(pal),
              ),
              // Фурӯшанда (ман) — иконаи самолёт ба сӯи харидор нигаронида
              if (_me != null)
                Marker(
                  point: _me!,
                  width: 54,
                  height: 54,
                  child: Transform.rotate(
                    angle: _bearing,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.45),
                              blurRadius: 14),
                        ],
                      ),
                      child: const Icon(FeatherIcons.navigation,
                          color: Colors.white, size: 24),
                    ),
                  ),
                ),
            ]),
          ],
        ),

        if (_loading)
          const Positioned(
            top: 14,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2.6),
              ),
            ),
          ),

        if (_error != null)
          Positioned(
            top: 14,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: pal.card,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
              ),
              child: Row(children: [
                const Icon(FeatherIcons.alertCircle,
                    color: AppColors.error, size: 17),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(_error!,
                      style: TextStyle(color: pal.textSecondary, fontSize: 12.5)),
                ),
              ]),
            ),
          ),

        // ── Панели поёнӣ: масофа, вақт ва тугмаи навигатсия ──
        Positioned(
          left: 12,
          right: 12,
          bottom: 16,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: pal.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: pal.border, width: 0.7),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 20,
                    offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(FeatherIcons.user,
                          color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Харидор дар ин ҷост',
                                style: TextStyle(
                                    color: pal.textPrimary,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(
                                [
                                  widget.destLabel,
                                  if (widget.buyerName != null &&
                                      widget.buyerName!.isNotEmpty)
                                    widget.buyerName!,
                                ].join(' • '),
                                style: TextStyle(
                                    color: pal.textSecondary, fontSize: 12.5)),
                          ]),
                    ),
                  ]),
                  if (_route.length >= 2) ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      _stat(pal, FeatherIcons.map,
                          '${_distanceKm.toStringAsFixed(_distanceKm < 10 ? 1 : 0)} км'),
                      const SizedBox(width: 10),
                      _stat(pal, FeatherIcons.clock, '≈ $_minutes дақ'),
                    ]),
                    if (_straightLine)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(children: [
                          Icon(FeatherIcons.info, size: 12, color: pal.textMuted),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                                'Роҳи кӯчагӣ гирифта нашуд — хати мустақим нишон дода шуд',
                                style: TextStyle(
                                    color: pal.textMuted, fontSize: 11)),
                          ),
                        ]),
                      ),
                  ],
                  const SizedBox(height: 13),
                  GestureDetector(
                    onTap: _openInMaps,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(FeatherIcons.navigation2,
                                color: Colors.white, size: 17),
                            SizedBox(width: 9),
                            Text('Навигатсияро оғоз кунед',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700)),
                          ]),
                    ),
                  ),
                ]),
          ),
        ),
      ]),
    );
  }

  Widget _stat(AppPalette pal, IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
            color: pal.surface, borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  color: pal.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _destMarker(AppPalette pal) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: pal.card,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.primary, width: 1.2),
            ),
            child: Text(widget.destLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: pal.textPrimary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800)),
          ),
          const Icon(FeatherIcons.mapPin,
              color: AppColors.primary,
              size: 32,
              shadows: [Shadow(color: Colors.black45, blurRadius: 6)]),
        ],
      );
}
