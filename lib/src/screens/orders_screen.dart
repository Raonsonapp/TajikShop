part of '../../main.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});
  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late Future<dynamic> _ordersFuture;
  List<Map<String, dynamic>> _localOrders = [];
  @override
  void initState() { super.initState(); _ordersFuture = _load(); }
  Future<dynamic> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final decoded = jsonDecode(prefs.getString('almaz_orders') ?? '[]');
    _localOrders = decoded is List ? decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
    if (!await AlmazApi.instance.hasAccessToken()) return null;
    return AlmazApi.instance.getMyOrders();
  }
  void _refresh() => setState(() => _ordersFuture = _load());
  List<Map<String, dynamic>> _rows(dynamic value) {
    dynamic raw = value;
    if (raw is Map) {
      raw = raw['items'] ?? raw['orders'] ?? raw['data'] ?? raw['results'] ?? [];
      if (raw is Map) raw = raw['items'] ?? raw['orders'] ?? raw['results'] ?? [];
    }
    if (raw is! List) return [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
  String _value(Map<String, dynamic> item, List<String> keys, [String fallback = '—']) {
    for (final key in keys) {
      final v = item[key];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return fallback;
  }
  Widget _orderCard(Map<String, dynamic> order, {bool local = false}) {
    final title = _value(order, ['game', 'game_name', 'product_name', 'title'], 'Фармоиш');
    final pack = _value(order, ['pack', 'package', 'product', 'variant_name']);
    final status = _value(order, ['status', 'payment_status', 'order_status'], 'Дар коркард');
    final player = _value(order, ['player', 'player_id', 'game_id', 'user_game_id']);
    final id = _value(order, ['id', 'order_id', 'order_number']);
    final date = _value(order, ['date', 'created_at', 'createdAt']);
    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: green.withOpacity(.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900))),
          Text(status, style: const TextStyle(color: gold, fontSize: 10, fontWeight: FontWeight.bold))]),
        const SizedBox(height: 7),
        Text(pack, style: const TextStyle(color: muted, fontSize: 12)),
        Text('ID: $player', style: const TextStyle(color: muted, fontSize: 11)),
        Text('#$id • $date', style: const TextStyle(color: green, fontSize: 10)),
        if (local) const Padding(padding: EdgeInsets.only(top: 7),
          child: Text('Танҳо дар ин дастгоҳ сабт шудааст • аз сервер тасдиқ нашудааст', style: TextStyle(color: gold, fontSize: 9))),
      ]),
    );
  }
  @override
  Widget build(BuildContext context) => Column(children: [
    const BrandHeader(),
    Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 12), child: Row(children: [
      const Expanded(child: Text('Фармоишҳои ман', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
      IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh, color: green)),
    ])),
    Expanded(child: FutureBuilder<dynamic>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _localOrders.isEmpty) return const Center(child: CircularProgressIndicator(color: green));
        final serverOrders = snapshot.hasData ? _rows(snapshot.data) : <Map<String, dynamic>>[];
        final hasToken = snapshot.hasData;
        if (!snapshot.hasData && snapshot.hasError && _localOrders.isEmpty) return const EmptyState(icon: Icons.cloud_off_outlined, title: 'Сервер дастрас нест', sub: 'Пайвастшавиро санҷ ва тугмаи навсозиро пахш кун.');
        if (serverOrders.isEmpty && _localOrders.isEmpty) return EmptyState(icon: Icons.receipt_long, title: 'Ҳоло фармоиш нест',
          sub: hasToken ? 'Фармоишҳои сервер дар ин ҷо пайдо мешаванд.' : 'Барои дидани фармоишҳои сервер аввал ба ҳисоб ворид шудан лозим аст.');
        return ListView(padding: const EdgeInsets.all(15), children: [
          if (serverOrders.isNotEmpty) ...[const SectionTitle('ФАРМОИШҲОИ СЕРВЕР', 'LIVE'), const SizedBox(height: 9), ...serverOrders.map((o) => _orderCard(o))],
          if (_localOrders.isNotEmpty) ...[const SizedBox(height: 8), const SectionTitle('САБТҲОИ МАҲАЛЛӢ', ''), const SizedBox(height: 9), ..._localOrders.map((o) => _orderCard(o, local: true))],
          if (!hasToken) const Padding(padding: EdgeInsets.only(top: 10), child: Text('Барои ҳамоҳангсозии фармоишҳо воридшавии ҳисоби корбар лозим аст.', style: TextStyle(color: muted, fontSize: 11))),
          if (snapshot.hasError) const Padding(padding: EdgeInsets.only(top: 10), child: Text('Фармоишҳои сервер нав нашуданд. Маълумоти маҳаллӣ ҷудо нигоҳ дошта шуд.', style: TextStyle(color: gold, fontSize: 10))),
        ]);
      },
    )),
  ]);
}
