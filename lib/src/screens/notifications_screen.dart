part of '../../main.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonDecode(prefs.getString('almaz_orders') ?? '[]');
    if (!mounted) return;
    setState(() {
      _orders = raw is List ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: bg,
    appBar: AppBar(
      backgroundColor: bg,
      title: const Text('Огоҳиномаҳо', style: TextStyle(fontWeight: FontWeight.w900)),
      leading: IconButton(icon: const Icon(HeroiconsOutline.chevronLeft), onPressed: () => Navigator.pop(context)),
      actions: [IconButton(icon: const Icon(HeroiconsOutline.arrowPath, color: green), onPressed: () { setState(() => _loading = true); _load(); })],
    ),
    body: _loading
      ? const Center(child: CircularProgressIndicator(color: green))
      : _orders.isEmpty
        ? const EmptyState(icon: HeroiconsOutline.bell, title: 'Огоҳинома нест', sub: 'Вақте фармоиш сабт шавад, маълумоти он дар ин ҷо пайдо мешавад.')
        : ListView(padding: const EdgeInsets.all(16), children: [
            const Text('ФАЪОЛИЯТИ ОХИР', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .8)),
            const SizedBox(height: 12),
            ..._orders.map((order) {
              final game = (order['game'] ?? order['game_name'] ?? 'Фармоиш').toString();
              final pack = (order['pack'] ?? order['product_name'] ?? '').toString();
              final status = (order['status'] ?? 'Дар интизорӣ').toString();
              final date = (order['date'] ?? order['created_at'] ?? '').toString();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(18), border: Border.all(color: green.withOpacity(.18))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 42, height: 42, decoration: BoxDecoration(color: green.withOpacity(.13), borderRadius: BorderRadius.circular(13)), child: const Icon(HeroiconsOutline.bell, color: green, size: 21)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Фармоиши $game', style: const TextStyle(fontWeight: FontWeight.w900)),
                    if (pack.isNotEmpty) Text(pack, style: const TextStyle(color: muted, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(status, style: const TextStyle(color: green, fontSize: 11, fontWeight: FontWeight.w800)),
                    if (date.isNotEmpty) Text(date, style: const TextStyle(color: muted, fontSize: 10)),
                  ])),
                ]),
              );
            }),
          ]),
  );
}
