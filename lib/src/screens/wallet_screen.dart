part of '../../main.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});
  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late Future<dynamic> _walletFuture;
  @override
  void initState() { super.initState(); _walletFuture = _loadWallet(); }
  Future<dynamic> _loadWallet() async {
    if (!await AlmazApi.instance.hasAccessToken()) return null;
    return AlmazApi.instance.getWallet();
  }
  void _refresh() => setState(() => _walletFuture = _loadWallet());
  Map<String, dynamic> _walletMap(dynamic value) {
    if (value is! Map) return {};
    var map = Map<String, dynamic>.from(value);
    for (final key in ['wallet', 'data', 'account', 'result']) {
      if (map[key] is Map) { map = Map<String, dynamic>.from(map[key] as Map); break; }
    }
    return map;
  }
  String _first(Map<String, dynamic> map, List<String> keys, [String fallback = '—']) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) return value.toString();
    }
    return fallback;
  }
  List<Map<String, dynamic>> _transactions(Map<String, dynamic> map) {
    dynamic rows = map['transactions'] ?? map['history'] ?? map['operations'] ?? map['items'];
    if (rows is Map) rows = rows['items'] ?? rows['data'] ?? [];
    if (rows is! List) return [];
    return rows.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
  @override
  Widget build(BuildContext context) => Column(children: [
    const BrandHeader(),
    Expanded(child: FutureBuilder<dynamic>(
      future: _walletFuture,
      builder: (context, snapshot) {
        final data = snapshot.hasData ? _walletMap(snapshot.data) : <String, dynamic>{};
        final balance = _first(data, ['balance', 'available_balance', 'amount', 'current_balance']);
        final currency = _first(data, ['currency', 'currency_code'], 'с');
        final transactions = _transactions(data);
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final noToken = snapshot.hasData && snapshot.data == null;
        return ListView(padding: const EdgeInsets.all(17), children: [
          Row(children: [const Expanded(child: Text('Баланс', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900))),
            IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh, color: green))]),
          const SizedBox(height: 15),
          Container(height: 160, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(22),
              gradient: almazLightMode.value ? const LinearGradient(colors: [Color(0xFFE9F1EC), Color(0xFFDCE7E0)]) : const LinearGradient(colors: [Color(0xFF1B1E21), Color(0xFF252A2E)]),
              border: Border.all(color: green.withOpacity(.24))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('БАЛАНСИ ШУМО', style: TextStyle(color: almazLightMode.value ? const Color(0xFF315B40) : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(loading ? '…' : '$balance $currency', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: almazLightMode.value ? const Color(0xFF102017) : Colors.white)),
              const Spacer(),
              Text('TAJ DONATE • WALLET', style: const TextStyle(color: Color(0xFF00A94F), fontWeight: FontWeight.w900, fontSize: 10)),
            ])),
          const SizedBox(height: 12),
          if (noToken) const Text('Барои дидани баланси воқеӣ ба ҳисоби худ ворид шав.', style: TextStyle(color: gold, fontSize: 11))
          else if (snapshot.hasError) Text('Баланс аз сервер гирифта нашуд: ' + snapshot.error.toString(), style: const TextStyle(color: gold, fontSize: 11))
          else if (!loading && balance == '—') const Text('Сервер ҷавоб дод, аммо майдони баланс дар ҷавоб муайян нашуд.', style: TextStyle(color: muted, fontSize: 10)),
          const SizedBox(height: 17),
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Пур кардани баланс', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Пардохти онлайн то фаъол шудани провайдери пардохт дар сервер дастрас нест.', style: TextStyle(color: muted, fontSize: 11, height: 1.5)),
              const SizedBox(height: 9),
              ...[
                {'name':'Алиф','domain':'alif.tj'},
                {'name':'Душанбе Сити','domain':'dc.tj'},
                {'name':'Эсхата','domain':'eskhata.com'},
                {'name':'Ориёнбонк','domain':'orienbank.tj'},
              ].map((bank) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(width:42,height:42,padding:const EdgeInsets.all(7),decoration:BoxDecoration(color:almazLightMode.value ? const Color(0xFFEAF3ED) : Colors.white,borderRadius:BorderRadius.circular(11)),child:_AlmazBankImage(domain:bank['domain']!,size:28)),
                title: Text(bank['name']!), trailing: const Icon(Icons.lock_outline, color: muted),
                onTap: () => showDialog<void>(context: context, builder: (ctx) => AlertDialog(
                  title: Text(bank['name']!), content: const Text('Ин усули пардохт ҳоло аз ҷониби сервер фаъол карда нашудааст. Ҳоло маблағ нагузаронед.'),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Фаҳмо'))],
                )),
              )),
            ])),
          const SizedBox(height: 17),
          const SectionTitle('ТАЪРИХИ АМАЛИЁТ', ''),
          const SizedBox(height: 9),
          if (loading) const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: green, strokeWidth: 2)))
          else if (noToken) const EmptyState(icon: Icons.lock_outline, title: 'Воридшавӣ лозим аст', sub: 'Пас аз ворид шудан таърихи амалиёт нишон дода мешавад.')
          else if (transactions.isEmpty) const EmptyState(icon: Icons.history, title: 'Амалиёт нест', sub: 'Таърихи пуркунӣ ва хароҷот дар ин ҷо намоиш дода мешавад.')
          else ...transactions.map((tx) {
            final title = _first(tx, ['title', 'description', 'type', 'method'], 'Амалиёт');
            final amount = _first(tx, ['amount', 'value', 'total']);
            final status = _first(tx, ['status', 'state'], '');
            final date = _first(tx, ['created_at', 'date', 'createdAt'], '');
            return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(13)),
              child: Row(children: [const Icon(Icons.swap_horiz_rounded, color: green), const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  Text('$status $date', style: const TextStyle(color: muted, fontSize: 9)),
                ])),
                Text('$amount $currency', style: const TextStyle(color: green, fontWeight: FontWeight.w900, fontSize: 11)),
              ]));
          }),
        ]);
      },
    )),
  ]);
}
