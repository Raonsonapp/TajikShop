import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/seller_provider.dart';
import '../../core/api/api_client.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../shared/widgets/fade_slide_in.dart';

/// «Фармоишҳои фурӯш» — фармоишҳое ки маҳсулоти фурӯшандаро доранд.
/// Барои иҷро: харидор, телефон, шумораи ашё ва маблағи фурӯшанда.
class SellerOrdersScreen extends ConsumerWidget {
  const SellerOrdersScreen({super.key});

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'delivered':
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  String _statusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'pending':
        return 'Дар интизор';
      case 'paid':
        return 'Пардохт шуд';
      case 'processing':
        return 'Омодасозӣ';
      case 'shipped':
        return 'Фиристода шуд';
      case 'delivered':
        return 'Расонида шуд';
      case 'completed':
        return 'Иҷро шуд';
      case 'cancelled':
        return 'Бекор шуд';
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pal = context.pal;
    final async = ref.watch(sellerOrdersProvider);

    return Scaffold(
      backgroundColor: pal.scaffold,
      appBar: AppBar(
        backgroundColor: pal.scaffold,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(FeatherIcons.chevronLeft, color: pal.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Фармоишҳои фурӯш',
            style: TextStyle(
                color: pal.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17)),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(sellerOrdersProvider),
        child: async.when(
          loading: () => const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2.6)),
          error: (_, __) => _empty(pal),
          data: (list) {
            if (list.isEmpty) return _empty(pal);
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: list.length,
              itemBuilder: (_, i) => _card(context, ref, pal, list[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _empty(AppPalette pal) => ListView(
        children: [
          const SizedBox(height: 120),
          Icon(FeatherIcons.inbox, size: 56, color: pal.textMuted),
          const SizedBox(height: 16),
          Center(
            child: Text('Ҳоло фармоиш нест',
                style: TextStyle(color: pal.textSecondary, fontSize: 15)),
          ),
        ],
      );

  Widget _card(BuildContext context, WidgetRef ref, AppPalette pal, Map<String, dynamic> o) {
    final id = o['id']?.toString() ?? '';
    final shortId =
        (id.length > 8 ? id.substring(0, 8) : id).toUpperCase();
    final status = o['status']?.toString() ?? 'pending';
    final buyer = o['buyer_name']?.toString() ?? 'Харидор';
    final phone = o['buyer_phone']?.toString() ?? '';
    final items = (o['items'] as num?)?.toInt() ?? 0;
    final subtotal = (o['subtotal'] as num?)?.toDouble() ?? 0;
    DateTime? date;
    if (o['created_at'] != null) {
      date = DateTime.tryParse(o['created_at'].toString())?.toLocal();
    }
    final c = _statusColor(status);

    return GestureDetector(
      onTap: () => context.push('/orders/$id'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: pal.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: pal.border, width: 0.6),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(FeatherIcons.shoppingBag,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('#$shortId',
                        style: TextStyle(
                            color: pal.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    const SizedBox(height: 3),
                    Text(
                        date != null
                            ? DateFormat('dd.MM.yyyy • HH:mm').format(date)
                            : '',
                        style: TextStyle(color: pal.textMuted, fontSize: 12)),
                  ]),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(_statusLabel(status),
                  style: TextStyle(
                      color: c, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 12),
          Divider(color: pal.divider, height: 1),
          const SizedBox(height: 10),
          Row(children: [
            Icon(FeatherIcons.user, size: 14, color: pal.textMuted),
            const SizedBox(width: 6),
            Text(buyer,
                style: TextStyle(color: pal.textSecondary, fontSize: 13)),
            if (phone.isNotEmpty) ...[
              const SizedBox(width: 10),
              Icon(FeatherIcons.phone, size: 13, color: pal.textMuted),
              const SizedBox(width: 5),
              Text(phone,
                  style: TextStyle(color: pal.textSecondary, fontSize: 13)),
            ],
          ]),
          // ── Суроғаи расонидан — то фурӯшанда гум нашавад ──────────
          ..._addressBlock(context, pal, o),

          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('$items ашё',
                style: TextStyle(color: pal.textSecondary, fontSize: 13)),
            Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('${subtotal.toStringAsFixed(0)} ',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                  const Text('сом',
                      style: TextStyle(
                          color: AppColors.primary, fontSize: 12)),
                ]),
          ]),

          // ── Қадами навбатӣ (фурӯшанда ҳолатро худаш нав мекунад) ──
          ..._nextStepButtons(context, ref, pal, id, status),
        ]),
      ),
    );
  }

  /// Суроғаи харидор бо рақами хона + тугмаи «Роҳ».
  ///
  /// Ҳангоми «аз мағоза гирифтан» сервер суроға намефиристад — он ҷо
  /// расонидан лозим нест, пас блок нишон дода намешавад.
  List<Widget> _addressBlock(
      BuildContext context, AppPalette pal, Map<String, dynamic> o) {
    if ((o['fulfilment']?.toString() ?? 'delivery') != 'delivery') {
      return [
        const SizedBox(height: 10),
        Row(children: [
          Icon(FeatherIcons.home, size: 14, color: pal.textMuted),
          const SizedBox(width: 6),
          Text('Аз мағоза мегиранд',
              style: TextStyle(color: pal.textSecondary, fontSize: 12.5)),
        ]),
      ];
    }

    final street = o['street']?.toString() ?? '';
    final house = o['house']?.toString() ?? '';
    final city = o['city']?.toString() ?? '';
    final entrance = o['entrance']?.toString() ?? '';
    final floor = o['floor']?.toString() ?? '';
    final apartment = o['apartment']?.toString() ?? '';
    final landmark = o['landmark']?.toString() ?? '';
    final lat = (o['lat'] as num?)?.toDouble() ?? 0;
    final lng = (o['lng'] as num?)?.toDouble() ?? 0;
    if (street.isEmpty && house.isEmpty && lat == 0) return const [];

    final extras = <String>[
      if (apartment.isNotEmpty) 'ҳуҷра $apartment',
      if (entrance.isNotEmpty) 'вуруд $entrance',
      if (floor.isNotEmpty) 'ошёна $floor',
    ];

    return [
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(FeatherIcons.mapPin, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Рақами хона калон ва равшан — маҳз ҳамонро меҷӯянд.
                    if (house.isNotEmpty)
                      Text('Хонаи $house',
                          style: TextStyle(
                              color: pal.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                    if (street.isNotEmpty || city.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                            [street, city].where((e) => e.isNotEmpty).join(', '),
                            style: TextStyle(
                                color: pal.textSecondary, fontSize: 12.5)),
                      ),
                    if (extras.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(extras.join(' • '),
                            style:
                                TextStyle(color: pal.textMuted, fontSize: 12)),
                      ),
                    if (landmark.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(children: [
                          Icon(FeatherIcons.flag, size: 12, color: pal.textMuted),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(landmark,
                                style: TextStyle(
                                    color: pal.textMuted, fontSize: 12)),
                          ),
                        ]),
                      ),
                  ]),
            ),
          ]),
          if (lat != 0 || lng != 0) ...[
            const SizedBox(height: 10),
            PressableScale(
              onTap: () => _openRoute(context, lat, lng),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(FeatherIcons.navigation,
                          color: Colors.white, size: 15),
                      SizedBox(width: 8),
                      Text('Роҳ ба ин хона',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ]),
              ),
            ),
          ],
        ]),
      ),
    ];
  }

  /// Роҳро дар барномаи харитаи дастгоҳ мекушояд (Google Maps / Yandex / ғ.).
  Future<void> _openRoute(BuildContext context, double lat, double lng) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {/* поён fallback */}
    // Агар барномаи харита набошад — дар браузер мекушоем.
    final web = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    try {
      await launchUrl(web, mode: LaunchMode.externalApplication);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Барномаи харита ёфт нашуд'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  /// Қадамҳое, ки фурӯшанда аз ҳолати ҳозира гузошта метавонад.
  /// Мисли Alibaba: харидор ҳар қадамро push мегирад ва дар timeline мебинад.
  static const _flow = <String, List<String>>{
    'pending': ['processing'],
    'paid': ['processing'],
    'processing': ['shipped'],
    'shipped': ['delivered'],
  };

  List<Widget> _nextStepButtons(BuildContext context, WidgetRef ref,
      AppPalette pal, String id, String status) {
    final next = _flow[status.toLowerCase()];
    if (next == null || next.isEmpty || id.isEmpty) return const [];
    return [
      const SizedBox(height: 12),
      Divider(color: pal.divider, height: 1),
      const SizedBox(height: 12),
      Row(
        children: [
          for (final s in next)
            Expanded(
              child: PressableScale(
                onTap: () => _setStatus(context, ref, id, s),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_stepIcon(s), color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(_stepLabel(s),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ]),
                ),
              ),
            ),
        ],
      ),
    ];
  }

  IconData _stepIcon(String s) => switch (s) {
        'processing' => FeatherIcons.package,
        'shipped' => FeatherIcons.truck,
        'delivered' => FeatherIcons.checkCircle,
        _ => FeatherIcons.chevronRight,
      };

  String _stepLabel(String s) => switch (s) {
        'processing' => 'Қабул кардам',
        'shipped' => 'Фиристодам',
        'delivered' => 'Супоридам',
        _ => s,
      };

  Future<void> _setStatus(
      BuildContext context, WidgetRef ref, String id, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    String? tracking;

    // Ҳангоми фиристодан коди пайгирӣ пурсида мешавад (ихтиёрӣ).
    if (status == 'shipped') {
      final ctrl = TextEditingController();
      tracking = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: ctx.pal.card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('Коди пайгирӣ (ихтиёрӣ)',
              style: TextStyle(
                  color: ctx.pal.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            style: TextStyle(color: ctx.pal.textPrimary),
            decoration: InputDecoration(
              hintText: 'Масалан: TJ123456789',
              hintStyle: TextStyle(color: ctx.pal.textMuted),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: ctx.pal.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(''),
              child: Text('Бе код',
                  style: TextStyle(color: ctx.pal.textMuted)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
              child: const Text('Тайёр',
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      if (tracking == null) return; // корбар бекор кард
    }

    try {
      await ApiClient.instance.dio.post('/seller/orders/$id/status', data: {
        'status': status,
        if (tracking != null && tracking.isNotEmpty) 'tracking_code': tracking,
      });
      ref.invalidate(sellerOrdersProvider);
      messenger.showSnackBar(SnackBar(
        content: Text('Ҳолат нав шуд: ${_statusLabel(status)}'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Иваз кардани ҳолат нашуд. Дубора кӯшиш кунед.'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}
