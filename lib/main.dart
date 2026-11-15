import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

const bg = Color(0xFF080D12);
const panel = Color(0xFF111B24);
const panel2 = Color(0xFF17232E);
const accent = Color(0xFF35D07F);
const blue = Color(0xFF39A9FF);
const muted = Color(0xFF91A0AD);
const api = 'https://matchora.to/api/v1';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: bg,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const FootballApp());
}

class FootballApp extends StatelessWidget {
  const FootballApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Football Live',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(primary: accent, secondary: blue, surface: panel),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(backgroundColor: bg, surfaceTintColor: Colors.transparent),
    ),
    home: const FootballHome(),
  );
}

class MatchoraApi {
  static Future<dynamic> get(String path) async {
    final response = await http.get(Uri.parse('$api$path'), headers: {
      'Accept': 'application/json',
      'User-Agent': 'FootballLive/1.0',
    }).timeout(const Duration(seconds: 18));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('API error: ${response.statusCode}');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  static List<Map<String, dynamic>> listFrom(dynamic json, [String key = 'events']) {
    dynamic value = json;
    if (json is Map) {
      value = json[key] ?? json['data'] ?? json['results'] ?? json['channels'] ?? [];
      if (value is Map) value = value[key] ?? value['items'] ?? [];
    }
    if (value is! List) return [];
    return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
}

String field(Map<String, dynamic> m, List<String> keys, [String fallback = '']) {
  for (final k in keys) {
    final v = m[k];
    if (v != null && v.toString().trim().isNotEmpty) return v.toString();
  }
  return fallback;
}

String eventTitle(Map<String, dynamic> e) =>
  '${field(e, ['home', 'home_team', 'homeTeam'], 'Home')}  vs  ${field(e, ['away', 'away_team', 'awayTeam'], 'Away')}';

String eventEmbed(Map<String, dynamic> e) {
  final direct = field(e, ['embed_url', 'embedUrl']);
  if (direct.isNotEmpty) return direct;
  final id = field(e, ['id', 'event_id']);
  return id.isEmpty ? '' : 'https://matchora.to/embed/match/$id';
}

class FootballHome extends StatefulWidget {
  const FootballHome({super.key});
  @override
  State<FootballHome> createState() => _FootballHomeState();
}

class _FootballHomeState extends State<FootballHome> {
  int tab = 0;
  final pages = const ['Live', 'Бозиҳо', 'Каналҳо'];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: tab, children: const [
        MatchListPage(liveOnly: true),
        MatchListPage(liveOnly: false),
        ChannelsPage(),
      ])),
      bottomNavigationBar: NavigationBar(
        backgroundColor: panel,
        indicatorColor: accent.withOpacity(.15),
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.sensors_outlined), selectedIcon: Icon(Icons.sensors), label: 'Live'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Бозиҳо'),
          NavigationDestination(icon: Icon(Icons.live_tv_outlined), selectedIcon: Icon(Icons.live_tv), label: 'Каналҳо'),
        ],
      ),
    );
  }
}

class MatchListPage extends StatefulWidget {
  const MatchListPage({super.key, required this.liveOnly});
  final bool liveOnly;
  @override
  State<MatchListPage> createState() => _MatchListPageState();
}

class _MatchListPageState extends State<MatchListPage> {
  late Future<List<Map<String, dynamic>>> future;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    future = load();
    if (widget.liveOnly) {
      timer = Timer.periodic(const Duration(seconds: 35), (_) {
        if (mounted) { setState(() => future = load()); }
      });
    }
  }
  @override
  void dispose() { timer?.cancel(); super.dispose(); }

  Future<List<Map<String, dynamic>>> load() async {
    final data = await MatchoraApi.get(widget.liveOnly ? '/live' : '/schedule?watchable=1');
    return MatchoraApi.listFrom(data);
  }

  Future<void> refresh() async { setState(() => future = load()); await future; }

  @override
  Widget build(BuildContext context) {
    final live = widget.liveOnly;
    return Column(children: [
      _TopHeader(title: live ? 'Бозиҳои зинда' : 'Бозиҳои дорои пахш',
        subtitle: live ? 'Ҳисобҳои зинда • навсозии автоматӣ' : 'Ҷадвали бозиҳои дастрас',
        icon: live ? Icons.sensors_outlined : Icons.calendar_month_outlined),
      Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: accent));
          }
          if (snap.hasError) return _ErrorView(message: 'Маълумот бор нашуд', onRetry: refresh);
          final events = snap.data ?? [];
          if (events.isEmpty) return _EmptyView(title: live ? 'Ҳоло бозии зинда нест' : 'Бозӣ ёфт нашуд',
            subtitle: 'Баъдтар дубора санҷед', onRefresh: refresh);
          return RefreshIndicator(
            color: accent, onRefresh: refresh,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              itemCount: events.length,
              itemBuilder: (_, i) => MatchCard(event: events[i]),
            ),
          );
        },
      )),
    ]);
  }
}

class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.event});
  final Map<String, dynamic> event;
  @override
  Widget build(BuildContext context) {
    final isLive = event['live'] == true || field(event, ['status']).toUpperCase().contains('H');
    final score = field(event, ['score'], '—');
    final minute = field(event, ['minute']);
    final league = field(event, ['league', 'competition'], 'Футбол');
    final channels = field(event, ['channel_count'], '0');
    final embed = eventEmbed(event);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(.055))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(league, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w600))),
          if (isLive) Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(color: const Color(0xFFED4545).withOpacity(.15), borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFFF5555), shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(minute.isEmpty ? 'LIVE' : '$minute′', style: const TextStyle(color: Color(0xFFFF7777), fontSize: 11, fontWeight: FontWeight.bold)),
            ]),
          ) else Text(field(event, ['status'], 'Дар пеш'), style: const TextStyle(color: muted, fontSize: 11)),
        ]),
        const SizedBox(height: 15),
        Row(children: [
          Expanded(child: Text(field(event, ['home', 'home_team', 'homeTeam'], 'Home'),
            maxLines: 2, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(color: panel2, borderRadius: BorderRadius.circular(10)),
            child: Text(score, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()])),
          ),
          Expanded(child: Text(field(event, ['away', 'away_team', 'awayTeam'], 'Away'),
            textAlign: TextAlign.end, maxLines: 2, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Icon(Icons.tv_outlined, size: 16, color: accent.withOpacity(.9)),
          const SizedBox(width: 6),
          Text('$channels канал', style: const TextStyle(color: muted, fontSize: 12)),
          const Spacer(),
          if (embed.isNotEmpty) FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: bg,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => MatchPlayerPage(title: eventTitle(event), url: embed))),
            icon: const Icon(Icons.play_arrow_rounded, size: 19),
            label: const Text('Тамошо', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ]),
      ]),
    );
  }
}

class ChannelsPage extends StatefulWidget {
  const ChannelsPage({super.key});
  @override
  State<ChannelsPage> createState() => _ChannelsPageState();
}
class _ChannelsPageState extends State<ChannelsPage> {
  late Future<List<Map<String, dynamic>>> future;
  @override
  void initState() { super.initState(); future = load(); }
  Future<List<Map<String, dynamic>>> load() async =>
    MatchoraApi.listFrom(await MatchoraApi.get('/channels'), 'channels');
  Future<void> refresh() async { setState(() => future = load()); await future; }
  @override
  Widget build(BuildContext context) => Column(children: [
    const _TopHeader(title: 'Каналҳо', subtitle: 'Рӯйхати каналҳои API', icon: Icons.live_tv_outlined),
    Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: accent));
        if (snap.hasError) return _ErrorView(message: 'Каналҳо бор нашуданд', onRetry: refresh);
        final items = snap.data ?? [];
        if (items.isEmpty) return _EmptyView(title: 'Канал дастрас нест', subtitle: 'Баъдтар санҷед', onRefresh: refresh);
        return RefreshIndicator(color: accent, onRefresh: refresh, child: ListView.builder(
          padding: const EdgeInsets.all(16), itemCount: items.length,
          itemBuilder: (_, i) {
            final c = items[i];
            final name = field(c, ['name', 'title', 'channel', 'label'], 'Канали ${i + 1}');
            final id = field(c, ['id', 'channel_id']);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: Container(width: 42, height: 42,
                  decoration: BoxDecoration(color: blue.withOpacity(.12), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.live_tv_outlined, color: blue)),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(field(c, ['country', 'language', 'category'], 'Пахши варзишӣ'),
                  style: const TextStyle(color: muted, fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded, color: muted),
                onTap: id.isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => MatchPlayerPage(title: name, url: 'https://matchora.to/embed/channel/$id'))),
              ),
            );
          },
        ));
      },
    )),
  ]);
}

class MatchPlayerPage extends StatefulWidget {
  const MatchPlayerPage({super.key, required this.title, required this.url});
  final String title;
  final String url;
  @override
  State<MatchPlayerPage> createState() => _MatchPlayerPageState();
}
class _MatchPlayerPageState extends State<MatchPlayerPage> {
  late final WebViewController controller;
  bool loading = true;
  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) { if (mounted) setState(() => loading = true); },
        onPageFinished: (_) { if (mounted) setState(() => loading = false); },
        onWebResourceError: (_) { if (mounted) setState(() => loading = false); },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => Navigator.pop(context))),
    body: Column(children: [
      Expanded(child: Stack(children: [
        WebViewWidget(controller: controller),
        if (loading) const Align(alignment: Alignment.topCenter,
          child: LinearProgressIndicator(color: accent, backgroundColor: panel, minHeight: 2)),
      ])),
      Container(width: double.infinity, padding: const EdgeInsets.all(10), color: panel,
        child: const Text('Пахш дар плеери Matchora • рекламаи дохилии плеер нигоҳ дошта мешавад',
          textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 11))),
    ]),
  );
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.title, required this.subtitle, required this.icon});
  final String title, subtitle;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
    child: Row(children: [
      Container(width: 46, height: 46, decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [accent, blue], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(15)),
        child: Icon(icon, color: bg, size: 25)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -.4)),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(color: muted, fontSize: 11)),
      ])),
      IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded, color: muted)),
    ]),
  );
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.title, required this.subtitle, required this.onRefresh});
  final String title, subtitle;
  final Future<void> Function() onRefresh;
  @override
  Widget build(BuildContext context) => RefreshIndicator(color: accent, onRefresh: onRefresh,
    child: ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
      const SizedBox(height: 130), const Icon(Icons.sports_soccer_outlined, size: 54, color: muted),
      const SizedBox(height: 16), Center(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17))),
      const SizedBox(height: 6), Center(child: Text(subtitle, style: const TextStyle(color: muted, fontSize: 12))),
    ]));
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.cloud_off_outlined, size: 46, color: muted),
      const SizedBox(height: 12), Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 6), const Text('Пайвасти интернет ё API-ро санҷед', style: TextStyle(color: muted, fontSize: 12)),
      const SizedBox(height: 14), OutlinedButton.icon(onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded), label: const Text('Аз нав кӯшиш кун')),
    ]),
  ));
}
