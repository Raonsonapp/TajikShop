part of '../../main.dart';

class ApiStatusCard extends StatefulWidget {
  const ApiStatusCard({super.key});
  @override
  State<ApiStatusCard> createState() => _ApiStatusCardState();
}

class _ApiStatusCardState extends State<ApiStatusCard> {
  late Future<Map<String, dynamic>> _health;
  @override
  void initState() {
    super.initState();
    _health = AlmazApi.instance.health();
  }

  void _retry() => setState(() => _health = AlmazApi.instance.health());

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: _health,
    builder: (context, snapshot) {
      final online = snapshot.hasData && snapshot.data?['status'] == 'ok';
      final waiting = snapshot.connectionState == ConnectionState.waiting;
      final color = online ? green : (waiting ? gold : Colors.redAccent);
      final label = online ? 'Сервер фаъол аст' : (waiting ? 'Пайвастшавӣ...' : 'Сервер дастнорас');
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(.35)),
        ),
        child: Row(children: [
          Icon(Icons.cloud_done_outlined, color: color, size: 23),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 12)),
            const Text('TAJ DONATE • API', style: TextStyle(color: muted, fontSize: 10)),
          ])),
          IconButton(
            tooltip: 'Аз нав санҷидан',
            onPressed: waiting ? null : _retry,
            icon: const Icon(Icons.refresh_rounded, color: muted),
          ),
        ]),
      );
    },
  );
}
