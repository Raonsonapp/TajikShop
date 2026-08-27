// ignore_for_file: depend_on_referenced_packages
import 'package:cached_network_image/cached_network_image.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/osm_tiles.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/business_types.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/shops_provider.dart';
import '../../core/constants/tj_regions.dart';
import '../../shared/widgets/fade_slide_in.dart';

const String _kMediaHost = 'https://mahmadmurodov-tajikshop.hf.space';
const LatLng _kDushanbe = LatLng(38.5598, 68.7870);

String _mediaUrl(String path) =>
    path.startsWith('http') ? path : '$_kMediaHost$path';

double _asDouble(dynamic v) =>
    v is num ? v.toDouble() : (double.tryParse('$v') ?? 0);

/// Харитаи «Дӯконҳои наздик» — харидор бизнесҳои маҳаллиро дар харитаи
/// OpenStreetMap меёбад. Ҳар дӯкони дорои координата маркери сабз мегирад;
/// зеркунӣ корти поёнӣ бо маълумоти дӯкон ва тугмаи «Ба мағоза»-ро мекушояд.
class NearbyShopsScreen extends ConsumerStatefulWidget {
  const NearbyShopsScreen({super.key});

  @override
  ConsumerState<NearbyShopsScreen> createState() => _NearbyShopsScreenState();
}

class _NearbyShopsScreenState extends ConsumerState<NearbyShopsScreen> {
  final _controller = MapController();
  Map<String, dynamic>? _selected;
  bool _locating = false;
  String? _filterType; // null = ҳама навъҳо

  /// Реҷаи харита: тамоми кишвар → шаҳру ноҳия → кӯчаву хонаҳо.
  _MapMode _mode = _MapMode.city;
  TjPlace? _place; // ноҳияи интихобшуда (дар реҷаи district)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _goToMyLocation(initial: true));
  }

  Future<void> _goToMyLocation({bool initial = false}) async {
    if (mounted) setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'GPS хомӯш аст';
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw 'Иҷозати ҷойгиршавӣ дода нашуд';
      }
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      _controller.move(LatLng(pos.latitude, pos.longitude), 14);
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

  /// Гузариш байни се реҷаи харита.
  Widget _modeSwitcher(AppPalette pal) {
    Widget seg(_MapMode m, IconData icon, String label) {
      final sel = _mode == m;
      return Expanded(
        child: GestureDetector(
          onTap: () => _setMode(m),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
            decoration: BoxDecoration(
              gradient: sel ? AppColors.primaryGradient : null,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon,
                  size: 14, color: sel ? Colors.white : pal.textSecondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: sel ? Colors.white : pal.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: pal.border, width: 0.8),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(children: [
        seg(_MapMode.country, FeatherIcons.globe, 'Тоҷикистон'),
        // Агар ноҳия интихоб шуда бошад, номи ҳамонро нишон медиҳем.
        seg(_MapMode.city, FeatherIcons.mapPin, _place?.name ?? 'Шаҳру ноҳия'),
        seg(_MapMode.street, FeatherIcons.home, 'Кӯчаҳо'),
      ]),
    );
  }

  void _setMode(_MapMode m) {
    setState(() {
      _mode = m;
      _selected = null;
    });
    switch (m) {
      case _MapMode.country:
        // Тамоми Тоҷикистон — ҳамаи дӯконҳо якҷоя дида мешаванд.
        _controller.move(kTjCenter, kTjZoom);
      case _MapMode.city:
        _pickPlace();
      case _MapMode.street:
        // Ба зуми кӯча меравем — дар ин зум OSM рақами хонаҳоро нишон медиҳад.
        _controller.move(_controller.camera.center, 17.5);
    }
  }

  /// Рӯйхати шаҳру ноҳияҳо бо ҷустуҷӯ — гурӯҳбандӣ аз рӯи вилоят.
  Future<void> _pickPlace() async {
    final picked = await showModalBottomSheet<TjPlace>(
      context: context,
      backgroundColor: context.pal.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => const _PlacePickerSheet(),
    );
    if (picked == null || !mounted) return;
    setState(() => _place = picked);
    _controller.move(picked.center, picked.zoom);
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> shops) {
    if (_filterType == null) return shops;
    return shops
        .where((s) => (s['business_type']?.toString() ?? 'shop') == _filterType)
        .toList();
  }

  List<Marker> _markers(List<Map<String, dynamic>> shops) {
    final out = <Marker>[];
    for (final s in shops) {
      final lat = _asDouble(s['store_lat']);
      final lng = _asDouble(s['store_lng']);
      if (lat == 0 && lng == 0) continue;
      out.add(Marker(
        point: LatLng(lat, lng),
        width: 46,
        height: 46,
        child: GestureDetector(
          onTap: () => setState(() => _selected = s),
          child: _PinMarker(selected: identical(_selected, s)),
        ),
      ));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final shopsAsync = ref.watch(shopsProvider);

    return Scaffold(
      backgroundColor: pal.scaffold,
      appBar: AppBar(
        backgroundColor: pal.scaffold,
        elevation: 0,
        leading: IconButton(
          icon: Icon(FeatherIcons.chevronLeft, color: pal.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Дӯконҳои наздик',
            style: TextStyle(
                color: pal.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17)),
      ),
      body: shopsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2.6),
        ),
        error: (_, __) => _mapWith(pal, const []),
        data: (shops) => _mapWith(pal, shops),
      ),
    );
  }

  Widget _mapWith(AppPalette pal, List<Map<String, dynamic>> allShops) {
    final shops = _filtered(allShops);
    final markers = _markers(shops);
    return Stack(children: [
      FlutterMap(
        mapController: _controller,
        options: MapOptions(
          initialCenter: _kDushanbe,
          initialZoom: 12,
          // Тамоми Тоҷикистон дар доираи ҳаракат — то корбар аз кишвар набарояд.
          minZoom: 5,
          maxZoom: 19,
          backgroundColor: mapBackground(context),
          onTap: (_, __) => setState(() => _selected = null),
        ),
        children: [
          const OsmTiles(),
          MarkerLayer(markers: markers),
        ],
      ),

      // ── Реҷаи харита: Тоҷикистон / Шаҳру ноҳия / Кӯчаву хонаҳо ──
      Positioned(
        top: 12,
        left: 16,
        right: 16,
        child: FadeSlideIn(child: _modeSwitcher(pal)),
      ),

      // Филтри навъи бизнес (чипҳои уфуқӣ)
      Positioned(
        top: 62,
        left: 0,
        right: 0,
        child: SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _TypeChip(
                label: 'Ҳама',
                icon: FeatherIcons.grid,
                selected: _filterType == null,
                onTap: () => setState(() {
                  _filterType = null;
                  _selected = null;
                }),
              ),
              for (final t in kBusinessTypes)
                _TypeChip(
                  label: t.label,
                  icon: t.icon,
                  selected: _filterType == t.key,
                  onTap: () => setState(() {
                    _filterType = _filterType == t.key ? null : t.key;
                    _selected = null;
                  }),
                ),
            ],
          ),
        ),
      ),

      // Ёддошт: ягон дӯкон координата надорад
      if (markers.isEmpty)
        Positioned(
          top: 112,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: pal.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: pal.border, width: 0.8),
            ),
            child: Row(children: [
              const Icon(FeatherIcons.mapPin,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _filterType == null
                      ? 'Ҳанӯз ягон дӯкон ҷойгиршавиро нишон надодааст'
                      : 'Дар ин навъ ягон дӯкон ёфт нашуд',
                  style: TextStyle(color: pal.textSecondary, fontSize: 12.5),
                ),
              ),
            ]),
          ),
        ),

      // Тугмаи «ҷойгиршавии ман»
      Positioned(
        right: 16,
        bottom: _selected != null ? 188 : 24,
        child: FloatingActionButton(
          heroTag: 'shops_myloc',
          backgroundColor: pal.card,
          onPressed: _locating ? null : () => _goToMyLocation(),
          child: _locating
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: AppColors.primary))
              : const Icon(FeatherIcons.navigation, color: AppColors.primary),
        ),
      ),

      // Корти поёнии дӯкони интихобшуда
      if (_selected != null)
        Positioned(
          left: 16,
          right: 16,
          bottom: 20,
          child: _ShopCard(
            shop: _selected!,
            onClose: () => setState(() => _selected = null),
          ),
        ),
    ]);
  }
}

// ── Чипи филтри навъи бизнес ──
class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : pal.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? AppColors.primary : pal.border, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon,
                size: 14,
                color: selected ? Colors.white : pal.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : pal.textSecondary,
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
          ]),
        ),
      ),
    );
  }
}

// ── Маркери сабзи дӯкон ──
class _PinMarker extends StatelessWidget {
  final bool selected;
  const _PinMarker({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(
            color: Colors.white, width: selected ? 3 : 2),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: const Icon(FeatherIcons.mapPin, color: Colors.white, size: 22),
    );
  }
}

// ── Корти маълумоти дӯкон ──
class _ShopCard extends StatelessWidget {
  final Map<String, dynamic> shop;
  final VoidCallback onClose;
  const _ShopCard({required this.shop, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final avatar = '${shop['avatar_url'] ?? ''}';
    final name = '${shop['name'] ?? 'Дӯкон'}';
    final verified = shop['is_verified'] == true;
    final bizType = businessTypeFor(shop['business_type']?.toString());
    final products = shop['products'] is num
        ? (shop['products'] as num).toInt()
        : int.tryParse('${shop['products']}') ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: pal.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Аватар
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: pal.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: pal.border, width: 0.8),
                ),
                clipBehavior: Clip.antiAlias,
                child: avatar.isEmpty
                    ? const Icon(FeatherIcons.shoppingBag,
                        color: AppColors.primary, size: 24)
                    : CachedNetworkImage(
                        imageUrl: _mediaUrl(avatar),
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const SizedBox.shrink(),
                        errorWidget: (_, __, ___) => const Icon(
                            FeatherIcons.shoppingBag,
                            color: AppColors.primary,
                            size: 24),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: pal.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        if (verified) ...[
                          const SizedBox(width: 6),
                          const Icon(FeatherIcons.checkCircle,
                              color: AppColors.primary, size: 16),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(bizType.icon, size: 13, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Text(bizType.label,
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Text('•', style: TextStyle(color: pal.textMuted)),
                      const SizedBox(width: 8),
                      Text(
                        '$products маҳсулот',
                        style: TextStyle(
                            color: pal.textMuted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500),
                      ),
                    ]),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: Icon(FeatherIcons.x, color: pal.textMuted, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/seller/${shop['id']}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(FeatherIcons.shoppingBag,
                  color: Colors.white, size: 18),
              label: const Text('Ба мағоза',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}


/// Се реҷаи харита.
enum _MapMode { country, city, street }

/// Варақаи интихоби шаҳр/ноҳия бо ҷустуҷӯ.
class _PlacePickerSheet extends StatefulWidget {
  const _PlacePickerSheet();

  @override
  State<_PlacePickerSheet> createState() => _PlacePickerSheetState();
}

class _PlacePickerSheetState extends State<_PlacePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final q = _query.trim().toLowerCase();
    final places = q.isEmpty
        ? kTjPlaces
        : kTjPlaces
            .where((p) =>
                p.name.toLowerCase().contains(q) ||
                p.region.toLowerCase().contains(q))
            .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(children: [
          const SizedBox(height: 10),
          Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                  color: pal.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 14),
          Text('Шаҳр ё ноҳияро интихоб кунед',
              style: TextStyle(
                  color: pal.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              autofocus: false,
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(color: pal.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ҷустуҷӯ: Хуҷанд, Кӯлоб, Бохтар...',
                hintStyle: TextStyle(color: pal.textMuted, fontSize: 13.5),
                prefixIcon:
                    Icon(FeatherIcons.search, size: 18, color: pal.textMuted),
                filled: true,
                fillColor: pal.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide(color: pal.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: places.isEmpty
                ? Center(
                    child: Text('Ёфт нашуд',
                        style: TextStyle(color: pal.textMuted, fontSize: 14)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: places.length,
                    itemBuilder: (_, i) {
                      final p = places[i];
                      // Сарлавҳаи вилоят — вақте вилоят иваз мешавад.
                      final showHeader =
                          i == 0 || places[i - 1].region != p.region;
                      return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showHeader)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(8, 14, 8, 6),
                                child: Text(p.region.toUpperCase(),
                                    style: TextStyle(
                                        color: pal.textMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.4)),
                              ),
                            ListTile(
                              dense: true,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              leading: Container(
                                width: 34,
                                height: 34,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(FeatherIcons.mapPin,
                                    size: 16, color: AppColors.primary),
                              ),
                              title: Text(p.name,
                                  style: TextStyle(
                                      color: pal.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              trailing: Icon(FeatherIcons.chevronRight,
                                  size: 16, color: pal.textMuted),
                              onTap: () => Navigator.of(context).pop(p),
                            ),
                          ]);
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}
