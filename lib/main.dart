import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/almaz_api.dart';

const bg=Color(0xFF050907), surface=Color(0xFF0C1710), card=Color(0xFF101F16), green=Color(0xFF39FF72), lime=Color(0xFFB6FF38), muted=Color(0xFF91A69A), gold=Color(0xFFFFD65A);
void main(){WidgetsFlutterBinding.ensureInitialized();SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor:bg,statusBarIconBrightness:Brightness.light,systemNavigationBarColor:bg,systemNavigationBarIconBrightness:Brightness.light));runApp(const AlmazApp());}
final ValueNotifier<bool> almazLightMode = ValueNotifier<bool>(false);
class AlmazApp extends StatelessWidget {
  const AlmazApp({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: almazLightMode,
    builder: (context, light, _) => MaterialApp(
      title: 'Almaz TJ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: light ? Brightness.light : Brightness.dark,
        scaffoldBackgroundColor: light ? const Color(0xFFF3F7F4) : bg,
        colorScheme: light
          ? ColorScheme.fromSeed(seedColor: const Color(0xFF087A3B), brightness: Brightness.light)
          : const ColorScheme.dark(primary: green, surface: surface),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const AlmazSplash(),
    ),
  );
}
class AlmazSplash extends StatefulWidget {
  const AlmazSplash({super.key});
  @override
  State<AlmazSplash> createState() => _AlmazSplashState();
}

class _AlmazSplashState extends State<AlmazSplash> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1700), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AlmazHome(),
          transitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            Positioned(
              top: -110,
              left: -100,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: green.withOpacity(.12), blurRadius: 90, spreadRadius: 25)],
                ),
              ),
            ),
            Positioned(
              bottom: -130,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: green.withOpacity(.10), blurRadius: 100, spreadRadius: 25)],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AlmazMark(size: 174),
                  const SizedBox(height: 27),
                  const Text(
                    'Almaz TJ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 38),
                  SizedBox(
                    width: 25,
                    height: 25,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(green.withOpacity(.9)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class AlmazHome extends StatefulWidget{const AlmazHome({super.key});@override State<AlmazHome> createState()=>_AlmazHomeState();}
class _AlmazHomeState extends State<AlmazHome>{int tab=0;final pages=const[HomePage(),GamesPage(),CartPage(),OrdersPage(),WalletPage(),ProfilePage()];@override Widget build(BuildContext c)=>Scaffold(body:SafeArea(child:IndexedStack(index:tab,children:pages)),bottomNavigationBar:GlassBottomNavigation(index:tab,onChanged:(v)=>setState(()=>tab=v)));}
class GlassBottomNavigation extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const GlassBottomNavigation({
    super.key,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const labels = ['Дӯкон', 'Бозиҳо', 'Сабад', 'Фармоиш', 'Ҳамён', 'Профил'];
    const icons = [
      Icons.home_outlined,
      Icons.sports_esports_outlined,
      Icons.shopping_bag_outlined,
      Icons.receipt_long_outlined,
      Icons.account_balance_wallet_outlined,
      Icons.person_outline_rounded,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 5, 12, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            height: 75,
            decoration: BoxDecoration(
              color: const Color(0xFFB8C4BC).withOpacity(.13),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(.34),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(.09),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(.28),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: List.generate(
                labels.length,
                (i) => Expanded(
                  child: InkWell(
                    onTap: () => onChanged(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: index == i
                            ? green.withOpacity(.17)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                        border: index == i
                            ? Border.all(color: green.withOpacity(.3))
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (i == 2)
                            ValueListenableBuilder<int>(
                              valueListenable: AlmazCartStore.count,
                              builder: (context, total, _) => Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(icons[i], size: 23, color: index == i ? green : Colors.white),
                                  if (total > 0)
                                    Positioned(
                                      right: -9, top: -7,
                                      child: Container(
                                        constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        decoration: const BoxDecoration(color: green, shape: BoxShape.circle),
                                        child: Text(total > 99 ? '99+' : '$total',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(color: bg, fontSize: 8, fontWeight: FontWeight.w900)),
                                      ),
                                    ),
                                ],
                              ),
                            )
                          else
                            Icon(icons[i], size: 23, color: index == i ? green : Colors.white),
                          const SizedBox(height: 3),
                          Text(
                            labels[i],
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: index == i ? green : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BrandHeader extends StatelessWidget{final bool showActions;const BrandHeader({super.key,this.showActions=true});@override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.fromLTRB(17,13,17,12),child:Row(children:[const AlmazMark(size:48),const SizedBox(width:11),const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Almaz TJ',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900,letterSpacing:.4)),Text('МАРКАЗИ ДОНОТИ БОЗИҲО',style:TextStyle(fontSize:9,color:muted,letterSpacing:1.3,fontWeight:FontWeight.bold))])),if(showActions)IconButton(onPressed:()=>{},icon:const Icon(Icons.notifications_none,color:green))]));}
class AlmazMark extends StatelessWidget{final double size;const AlmazMark({super.key,this.size=54});@override Widget build(BuildContext c)=>Container(width:size,height:size,decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF1DFF65),Color(0xFF006B35)],begin:Alignment.topLeft,end:Alignment.bottomRight),borderRadius:BorderRadius.circular(size*.25),border:Border.all(color:green.withOpacity(.7)),boxShadow:[BoxShadow(color:green.withOpacity(.22),blurRadius:15)]),child:Stack(alignment:Alignment.center,children:[Icon(Icons.gamepad_rounded,color:Colors.white,size:size*.58),Positioned(top:size*.03,child:Icon(Icons.workspace_premium,color:gold,size:size*.27))]));}
class PageShell extends StatelessWidget{final String title,subtitle;final Widget child;const PageShell({super.key,required this.title,required this.subtitle,required this.child});@override Widget build(BuildContext c)=>Column(children:[BrandHeader(),Padding(padding:const EdgeInsets.fromLTRB(18,4,18,12),child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900)),Text(subtitle,style:const TextStyle(color:muted,fontSize:11))]))])),Expanded(child:child)]);}
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const BrandHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 3, 16, 20),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(23),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF063A1D), Color(0xFF0C1B11), Color(0xFF102919)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: green.withOpacity(.55)),
                  boxShadow: [BoxShadow(color: green.withOpacity(.10), blurRadius: 24)],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -5,
                      top: 2,
                      child: Icon(Icons.diamond, color: green.withOpacity(.16), size: 130),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: green.withOpacity(.14),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            'ALMAZ TJ • OFFICIAL',
                            style: TextStyle(color: green, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'Бозии дӯстдоштаатро\\nпурқувват кун!',
                          style: TextStyle(fontSize: 25, height: 1.15, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Донат ва ваучерҳои бозӣ — зуд, осон ва боэътимод',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        const SizedBox(height: 17),
                        FilledButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const GamesPage()),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: green,
                            foregroundColor: bg,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                          child: const Text('Интихоби бозӣ', style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const ApiStatusCard(),
              const SizedBox(height: 14),
              const LiveProductsSection(),
              const SizedBox(height: 22),
              const SectionTitle('Бозиҳои маъмул', 'Ҳама'),
              const SizedBox(height: 12),
              const GameGrid(),
              const SizedBox(height: 22),
              const SectionTitle('Чаро Almaz TJ?', ''),
              const SizedBox(height: 10),
              const Row(
                children: [
                  Benefit(icon: Icons.bolt, title: 'Зуд', sub: 'Коркарди фармоиш'),
                  SizedBox(width: 8),
                  Benefit(icon: Icons.verified_user_outlined, title: 'Эътимод', sub: 'Дастгирии муштарӣ'),
                  SizedBox(width: 8),
                  Benefit(icon: Icons.support_agent, title: 'Кӯмак', sub: 'Дастгирии онлайн'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
class SectionTitle extends StatelessWidget{final String title,action;const SectionTitle(this.title,this.action,{super.key});@override Widget build(BuildContext c)=>Row(children:[Expanded(child:Text(title,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w900))),if(action.isNotEmpty)Text(action,style:const TextStyle(color:green,fontSize:11,fontWeight:FontWeight.bold))]);}

class Game {
  final String name, sub, logoText;
  final Color color;
  final List<String> packs;
  const Game(this.name, this.sub, this.logoText, this.color, this.packs);
}

const games = [
  Game('Free Fire', 'Алмос • Ваучер • Membership', 'FREE\\nFIRE', Color(0xFFFFA52B), ['100 алмос','210 алмос','520 алмос','Ваучери ҳафтаина']),
  Game('PUBG Mobile', 'UC • Royale Pass', 'PUBG', Color(0xFFFFD15C), ['60 UC','325 UC','660 UC','Royale Pass']),
  Game('Mobile Legends', 'Diamonds • Pass', 'MLBB', Color(0xFF5B9BFF), ['86 Diamonds','172 Diamonds','Weekly Pass']),
  Game('Standoff 2', 'Gold • Бастаҳо', 'S2', Color(0xFFE34B55), ['100 Gold','500 Gold','1000 Gold']),
  Game('Telegram', 'Premium • Stars', 'TG', Color(0xFF36AEEA), ['Telegram Premium','Stars']),
  Game('IMO', 'Coins • хизматрасонӣ', 'imo', Color(0xFF2D9BEA), ['Coins','Бастаи махсус']),
];

class GameLogo extends StatelessWidget {
  final Game game;
  final double size;
  const GameLogo({super.key, required this.game, this.size = 76});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: const Color(0xFF080D0A),
      borderRadius: BorderRadius.circular(size * .25),
      border: Border.all(color: game.color.withOpacity(.7), width: 1.3),
      boxShadow: [BoxShadow(color: game.color.withOpacity(.18), blurRadius: 16)],
    ),
    child: Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          game.logoText,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: game.color,
            fontSize: game.logoText.length > 5 ? 19 : 25,
            height: .92,
            fontWeight: FontWeight.w900,
            letterSpacing: game.logoText == 'PUBG' ? -1.8 : .3,
            shadows: [Shadow(color: game.color.withOpacity(.55), blurRadius: 12)],
          ),
        ),
      ),
    ),
  );
}

class GameGrid extends StatelessWidget {
  const GameGrid({super.key});
  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: games.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisSpacing: 11,
      crossAxisSpacing: 11,
      childAspectRatio: 1.08,
    ),
    itemBuilder: (context, index) {
      final game = games[index];
      return InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GameDetail(game: game))),
        borderRadius: BorderRadius.circular(21),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B211E), Color(0xFF0D1410)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: Colors.white.withOpacity(.12)),
            boxShadow: [BoxShadow(color: game.color.withOpacity(.07), blurRadius: 17, offset: const Offset(0, 5))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                GameLogo(game: game, size: 66),
                const Spacer(),
                Icon(Icons.arrow_outward_rounded, size: 17, color: game.color.withOpacity(.8)),
              ]),
              const Spacer(),
              Text(game.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              const SizedBox(height: 3),
              Text(game.sub, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: muted, fontSize: 9)),
              const SizedBox(height: 9),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(color: game.color.withOpacity(.13), borderRadius: BorderRadius.circular(20)),
                child: Text('Бастаҳо  ›', style: TextStyle(color: game.color, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      );
    },
  );
}
class Benefit extends StatelessWidget{final IconData icon;final String title,sub;const Benefit({super.key,required this.icon,required this.title,required this.sub});@override Widget build(BuildContext c)=>Expanded(child:Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:card,borderRadius:BorderRadius.circular(14),border:Border.all(color:Colors.white10)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:green,size:20),const SizedBox(height:7),Text(title,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:12)),Text(sub,style:const TextStyle(color:muted,fontSize:9))])));}
class GamesPage extends StatelessWidget{const GamesPage({super.key});@override Widget build(BuildContext c)=>PageShell(title:'Бозиҳо',subtitle:'Бозиро интихоб намо ва бастаҳои дастрасро бин',child:ListView(padding:const EdgeInsets.all(16),children:[const GameGrid(),const SizedBox(height:18),Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:card,borderRadius:BorderRadius.circular(14)),child:const Text('Барои фармоиш ID-и бозингарро дуруст ворид намо. Пеш аз пардохт маълумоти фармоишро санҷ.',style:TextStyle(color:muted,fontSize:11,height:1.5)))]));}
class GameDetail extends StatefulWidget{final Game game;const GameDetail({super.key,required this.game});@override State<GameDetail> createState()=>_GameDetailState();}
class _GameDetailState extends State<GameDetail> {
  int selected = -1;
  final player = TextEditingController();
  @override
  void dispose() { player.dispose(); super.dispose(); }

  Future<void> submit() async {
    if (selected < 0 || player.text.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final decoded = jsonDecode(prefs.getString('almaz_orders') ?? '[]') as List;
    final orders = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    final game = widget.game;
    orders.insert(0, {
      'id': 'A\${DateTime.now().millisecondsSinceEpoch}',
      'game': game.name,
      'pack': game.packs[selected],
      'player': player.text.trim(),
      'status': 'Дар интизорӣ',
      'date': DateTime.now().toString().substring(0, 16),
    });
    await prefs.setString('almaz_orders', jsonEncode(orders));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Фармоиш сабт шуд. Пардохт ҳанӯз тасдиқ нашудааст.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return Scaffold(
      appBar: AppBar(title: Text(game.name)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            height: 145,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(colors: [game.color.withOpacity(.3), card]),
              border: Border.all(color: game.color.withOpacity(.5)),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GameLogo(game: game, size: 104),
                  Text(game.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text('Баста интихоб кун', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 10),
          ...List.generate(game.packs.length, (index) {
            final isSelected = selected == index;
            return InkWell(
              onTap: () => setState(() => selected = index),
              borderRadius: BorderRadius.circular(15),
              child: Container(
                margin: const EdgeInsets.only(bottom: 9),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: isSelected ? game.color.withOpacity(.14) : card,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: isSelected ? game.color : Colors.white12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.diamond, color: game.color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(game.packs[index], style: const TextStyle(fontWeight: FontWeight.w900)),
                          const Text('Нарх баъд аз пайвасти нархнома', style: TextStyle(color: muted, fontSize: 10)),
                        ],
                      ),
                    ),
                    Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: game.color),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          const Text('ID-и бозингар', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          TextField(
            controller: player,
            decoration: InputDecoration(
              hintText: 'ID-ро ворид кун',
              filled: true,
              fillColor: card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: selected < 0 || player.text.trim().isEmpty ? null : submit,
            style: FilledButton.styleFrom(
              backgroundColor: green,
              foregroundColor: bg,
              padding: const EdgeInsets.all(15),
            ),
            child: const Text('Сабти фармоиш', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 10),
          const Text(
            'Дархост дар дастгоҳ сабт мешавад. Пардохти воқеӣ ва пуркунии автоматӣ то пайвасти API фаъол нест.',
            style: TextStyle(color: muted, fontSize: 10, height: 1.5),
          ),
        ],
      ),
    );
  }
}

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
              gradient: const LinearGradient(colors: [Color(0xFF063F23), Color(0xFF122C1B), Color(0xFF25452B)]),
              border: Border.all(color: green.withOpacity(.6))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('БАЛАНСИ ШУМО', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(loading ? '…' : '$balance $currency', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
              const Spacer(),
              const Text('ALMAZ TJ • WALLET', style: TextStyle(color: green, fontWeight: FontWeight.w900, fontSize: 10)),
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
              ...['Алиф', 'Душанбе Сити', 'Эсхата', 'Ориёнбонк'].map((method) => ListTile(
                contentPadding: EdgeInsets.zero, leading: const Icon(Icons.account_balance_outlined, color: green),
                title: Text(method), trailing: const Icon(Icons.lock_outline, color: muted),
                onTap: () => showDialog<void>(context: context, builder: (ctx) => AlertDialog(
                  title: Text(method), content: const Text('Ин усули пардохт ҳоло аз ҷониби сервер фаъол карда нашудааст. Ҳоло маблағ нагузаронед.'),
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
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}
class _ProfilePageState extends State<ProfilePage> {
  String displayName = 'Меҳмон';
  bool notifications = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      displayName = p.getString('almaz_display_name') ?? 'Меҳмон';
      notifications = p.getBool('almaz_notifications') ?? true;
      almazLightMode.value = p.getBool('almaz_light_mode') ?? false;
    });
  }
  Future<void> _editName() async {
    final controller = TextEditingController(text: displayName == 'Меҳмон' ? '' : displayName);
    final value = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Маълумоти шахсӣ'),
      content: TextField(controller: controller, autofocus: true, maxLength: 40, decoration: const InputDecoration(labelText: 'Номи шумо')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Бекор')),
        FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Нигоҳ доштан')),
      ],
    ));
    if (value == null || value.isEmpty) return;
    final p = await SharedPreferences.getInstance();
    await p.setString('almaz_display_name', value);
    if (mounted) setState(() => displayName = value);
  }
  Future<void> _toggleTheme() async {
    final next = !almazLightMode.value;
    almazLightMode.value = next;
    final p = await SharedPreferences.getInstance();
    await p.setBool('almaz_light_mode', next);
    if (mounted) setState(() {});
  }
  Future<void> _toggleNotifications(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('almaz_notifications', value);
    if (mounted) setState(() => notifications = value);
  }
  void _info(String title, String body) => showDialog<void>(context: context, builder: (ctx) => AlertDialog(
    title: Text(title), content: Text(body),
    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Фаҳмо'))],
  ));
  @override
  Widget build(BuildContext context) => PageShell(
    title: 'Профил', subtitle: 'Ҳисоб ва танзимот',
    child: ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF103B23), Color(0xFF102017)]),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: green.withOpacity(.35)),
        ),
        child: Row(children: [
          const AlmazMark(size: 58), const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(displayName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const Text('Профили Almaz TJ', style: TextStyle(color: Colors.white70, fontSize: 11)),
          ])),
          IconButton(onPressed: _editName, icon: const Icon(Icons.edit_outlined, color: green)),
        ]),
      ),
      const SizedBox(height: 16),
      const SectionTitle('ҲИСОБ', ''),
      const SizedBox(height: 8),
      ProfileRow(icon: Icons.person_outline, title: 'Маълумоти шахсӣ', onTap: _editName),
      ProfileRow(icon: Icons.login_rounded, title: 'Воридшавӣ / Сабти ном', onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthPage()));
      }),
      ProfileRow(icon: Icons.receipt_long_outlined, title: 'Таърихи фармоишҳо', onTap: () => _info('Фармоишҳо', 'Қисми «Фармоиш» аз менюи поён дастрас аст.')),
      const SizedBox(height: 12),
      const SectionTitle('ТАНЗИМОТ', ''),
      const SizedBox(height: 8),
      ProfileRow(icon: almazLightMode.value ? Icons.light_mode_outlined : Icons.dark_mode_outlined, title: almazLightMode.value ? 'Гузариш ба мавзӯи торик' : 'Гузариш ба мавзӯи равшан', onTap: _toggleTheme),
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14)),
        child: SwitchListTile(
          secondary: const Icon(Icons.notifications_active_outlined, color: green),
          title: const Text('Огоҳиномаҳо', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          value: notifications, activeColor: green, onChanged: _toggleNotifications,
        ),
      ),
      const SizedBox(height: 12),
      const SectionTitle('ДАСТГИРӢ', ''),
      const SizedBox(height: 8),
      ProfileRow(icon: Icons.support_agent, title: 'Маркази кӯмак', onTap: () => _info('Дастгирӣ', 'Барои гирифтани кӯмак ба масъули Almaz TJ муроҷиат намо.')),
      ProfileRow(icon: Icons.privacy_tip_outlined, title: 'Махфият', onTap: () => _info('Махфият', 'Сиёсати махфият аз сервер дастрас мешавад.')),
      ProfileRow(icon: Icons.info_outline, title: 'Дар бораи Almaz TJ', onTap: () => _info('Almaz TJ', 'Платформаи хизматрасониҳои рақамии бозӣ.')),
    ]),
  );
}
class ProfileRow extends StatelessWidget {
  final IconData icon; final String title; final VoidCallback onTap;
  const ProfileRow({super.key, required this.icon, required this.title, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
    child: ListTile(
      onTap: onTap, leading: Icon(icon, color: green),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.chevron_right, color: muted),
    ),
  );
}
class EmptyState extends StatelessWidget{final IconData icon;final String title,sub;const EmptyState({super.key,required this.icon,required this.title,required this.sub});@override Widget build(BuildContext c)=>Center(child:Padding(padding:const EdgeInsets.all(30),child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:55,color:green.withOpacity(.6)),const SizedBox(height:15),Text(title,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:17)),const SizedBox(height:7),Text(sub,textAlign:TextAlign.center,style:const TextStyle(color:muted,fontSize:12,height:1.5))])));}


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
            const Text('Almaz TJ • API', style: TextStyle(color: muted, fontSize: 10)),
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


class AlmazCartStore {
  static const _key = 'almaz_cart_v1';
  static final ValueNotifier<int> count = ValueNotifier<int>(0);
  static Future<List<Map<String, dynamic>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonDecode(prefs.getString(_key) ?? '[]');
    if (raw is! List) {
      count.value = 0;
      return [];
    }
    final items = raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    count.value = items.fold<int>(0, (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 1));
    return items;
  }
  static Future<void> _save(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items));
    count.value = items.fold<int>(0, (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 1));
  }
  static Future<void> add(Map<String, dynamic> product) async {
    final id = (product['id'] ?? product['product_id'] ?? '').toString();
    if (id.isEmpty) throw Exception('Маҳсулот ID надорад; ба сабад илова карда намешавад.');
    final items = await load();
    final index = items.indexWhere((e) => (e['id'] ?? e['product_id']).toString() == id);
    if (index >= 0) {
      items[index]['quantity'] = ((items[index]['quantity'] as num?)?.toInt() ?? 1) + 1;
    } else {
      items.add({...product, 'id': id, 'quantity': 1});
    }
    await _save(items);
  }
  static Future<void> setQuantity(String id, int quantity) async {
    final items = await load();
    if (quantity <= 0) {
      items.removeWhere((e) => (e['id'] ?? e['product_id']).toString() == id);
    } else {
      for (final item in items) {
        if ((item['id'] ?? item['product_id']).toString() == id) item['quantity'] = quantity;
      }
    }
    await _save(items);
  }
  static Future<void> remove(String id) async {
    final items = await load();
    items.removeWhere((e) => (e['id'] ?? e['product_id']).toString() == id);
    await _save(items);
  }
}
class CartPage extends StatefulWidget {
  const CartPage({super.key});
  @override State<CartPage> createState() => _CartPageState();
}
class _CartPageState extends State<CartPage> {
  late Future<List<Map<String, dynamic>>> _future;
  @override void initState() { super.initState(); _future = AlmazCartStore.load(); }
  void _refresh() => setState(() => _future = AlmazCartStore.load());
  double _price(Map<String, dynamic> item) {
    final value = item['price'] ?? item['sale_price'] ?? item['display_price'];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }
  @override Widget build(BuildContext context) => Column(children: [
    const BrandHeader(),
    Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 12), child: Row(children: [
      const Expanded(child: Text('Сабади харид', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
      IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh, color: green)),
    ])),
    Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: green));
        final items = snapshot.data ?? [];
        if (items.isEmpty) return const EmptyState(icon: Icons.shopping_bag_outlined, title: 'Сабад холӣ аст', sub: 'Аз рӯйхати маҳсулоти сервер мол интихоб карда, ба сабад илова кун.');
        final total = items.fold<double>(0, (sum, item) => sum + _price(item) * ((item['quantity'] as num?)?.toInt() ?? 1));
        final currency = (items.first['currency'] ?? 'с').toString();
        return ListView(padding: const EdgeInsets.fromLTRB(15, 4, 15, 20), children: [
          ...items.map((item) {
            final id = (item['id'] ?? item['product_id']).toString();
            final name = (item['name'] ?? item['title'] ?? item['product_name'] ?? 'Маҳсулот').toString();
            final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
            final price = _price(item);
            return Container(
              margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: green.withOpacity(.2))),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Container(
                    width: 58, height: 58,
                    color: green.withOpacity(.1),
                    child: ((item['image_url'] ?? item['image'] ?? item['thumbnail'])?.toString().startsWith('http') ?? false)
                      ? Image.network(
                          (item['image_url'] ?? item['image'] ?? item['thumbnail']).toString(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_outlined, color: green),
                        )
                      : const Icon(Icons.inventory_2_outlined, color: green),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(price > 0 ? '${price.toStringAsFixed(2)} $currency' : 'Нарх дар маълумоти маҳсулот нест', style: const TextStyle(color: green, fontSize: 11)),
                  Row(children: [
                    IconButton(onPressed: () async { await AlmazCartStore.setQuantity(id, quantity - 1); _refresh(); }, icon: const Icon(Icons.remove_circle_outline, size: 20, color: muted), visualDensity: VisualDensity.compact),
                    Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w900)),
                    IconButton(onPressed: () async { await AlmazCartStore.setQuantity(id, quantity + 1); _refresh(); }, icon: const Icon(Icons.add_circle_outline, size: 20, color: green), visualDensity: VisualDensity.compact),
                  ]),
                ])),
                IconButton(onPressed: () async { await AlmazCartStore.remove(id); _refresh(); }, icon: const Icon(Icons.delete_outline, color: Colors.redAccent)),
              ]),
            );
          }),
          Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: green.withOpacity(.25))), child: Column(children: [
            Row(children: [const Expanded(child: Text('Ҳамагӣ (ҳисоби тахминӣ)', style: TextStyle(fontWeight: FontWeight.w800))), Text('${total.toStringAsFixed(2)} $currency', style: const TextStyle(color: green, fontWeight: FontWeight.w900))]),
            const SizedBox(height: 9),
            const Text('Пардохт ва checkout то тасдиқи формати дақиқи API фаъол карда намешавад. Ин сабад ҳоло дар ҳамин дастгоҳ нигоҳ дошта мешавад.', style: TextStyle(color: gold, fontSize: 10, height: 1.5)),
          ])),
        ]);
      },
    )),
  ]);
}

class LiveProductsSection extends StatefulWidget {
  const LiveProductsSection({super.key});
  @override
  State<LiveProductsSection> createState() => _LiveProductsSectionState();
}

class _LiveProductsSectionState extends State<LiveProductsSection> {
  late Future<dynamic> _future;
  @override
  void initState() {
    super.initState();
    _future = AlmazApi.instance.getProducts(limit: 8);
  }

  List<Map<String, dynamic>> _items(dynamic value) {
    dynamic raw = value;
    if (raw is Map) {
      raw = raw['items'] ?? raw['products'] ?? raw['data'] ?? raw['results'] ?? [];
      if (raw is Map) raw = raw['items'] ?? raw['products'] ?? raw['results'] ?? [];
    }
    if (raw is! List) return [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  String _text(Map<String, dynamic> item, List<String> keys, String fallback) {
    for (final key in keys) {
      final value = item[key];
      if (value != null && value.toString().trim().isNotEmpty) return value.toString();
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<dynamic>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(color: green, strokeWidth: 2),
        ));
      }
      if (snapshot.hasError) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(15)),
          child: const Row(children: [
            Icon(Icons.cloud_off_outlined, color: muted),
            SizedBox(width: 9),
            Expanded(child: Text('Каталоги сервер ҳоло дастрас нест. Баъдтар аз нав санҷ.', style: TextStyle(color: muted, fontSize: 11))),
          ]),
        );
      }
      final products = _items(snapshot.data);
      if (products.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(15)),
          child: const Text('Дар сервер ҳоло маҳсулот нашр нашудааст.', style: TextStyle(color: muted, fontSize: 11)),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Маҳсулоти сервер', 'LIVE'),
          const SizedBox(height: 10),
          SizedBox(
            height: 154,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = products[index];
                final name = _text(item, ['name', 'title', 'product_name'], 'Маҳсулот');
                final price = _text(item, ['price', 'display_price', 'sale_price'], 'Нарх дастрас нест');
                final currency = _text(item, ['currency'], 'с');
                final image = _text(item, ['image_url', 'image', 'thumbnail'], '');
                return Container(
                  width: 158,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: green.withOpacity(.22)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Center(
                          child: image.startsWith('http')
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(image, fit: BoxFit.cover, width: 92, height: 72,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_outlined, color: green, size: 34)),
                              )
                            : const Icon(Icons.inventory_2_outlined, color: green, size: 34),
                        ),
                      ),
                      Row(children: [
                        Expanded(child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(width: 30, height: 30),
                          tooltip: 'Ба сабад илова кун',
                          onPressed: () async {
                            try {
                              await AlmazCartStore.add(item);
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ба сабад илова шуд')));
                            } catch (e) {
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                            }
                          },
                          icon: const Icon(Icons.add_shopping_cart, color: green, size: 18),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text('$price $currency', maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: green, fontSize: 10, fontWeight: FontWeight.w900)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      );
    },
  );
}


class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}
class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false, _busy = false, _hidePassword = true;
  String? _error;
  @override
  void dispose() { _name.dispose(); _email.dispose(); _password.dispose(); super.dispose(); }
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    try {
      if (_register) {
        await AlmazApi.instance.register(name: _name.text, email: _email.text, password: _password.text);
      } else {
        await AlmazApi.instance.login(email: _email.text, password: _password.text);
      }
      if (!mounted) return;
      if (await AlmazApi.instance.hasAccessToken()) { Navigator.pop(context, true); }
      else { setState(() => _error = 'Сервер токени воридшавиро нафиристод.'); }
    } catch (e) { if (mounted) setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_register ? 'Сабти ном' : 'Воридшавӣ')),
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const AlmazMark(size: 76), const SizedBox(height: 18),
        Text(_register ? 'Ҳисоби нав соз' : 'Ба Almaz TJ ворид шав', textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 22),
        if (_register) ...[
          TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Ном', prefixIcon: Icon(Icons.person_outline)), validator: (v) => (v == null || v.trim().isEmpty) ? 'Номро ворид кун' : null),
          const SizedBox(height: 12),
        ],
        TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Почтаи электронӣ', prefixIcon: Icon(Icons.email_outlined)), validator: (v) => (v == null || !v.contains('@') || !v.contains('.')) ? 'Почтаи электрониро дуруст ворид кун' : null),
        const SizedBox(height: 12),
        TextFormField(controller: _password, obscureText: _hidePassword, decoration: InputDecoration(labelText: 'Рамз', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => _hidePassword = !_hidePassword), icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined))), validator: (v) => (v == null || v.length < 8) ? 'Рамз бояд камаш 8 аломат бошад' : null),
        if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: Colors.redAccent))],
        const SizedBox(height: 20),
        SizedBox(height: 50, child: FilledButton(onPressed: _busy ? null : _submit, style: FilledButton.styleFrom(backgroundColor: green, foregroundColor: bg), child: _busy ? const CircularProgressIndicator(color: bg) : Text(_register ? 'Сабти ном' : 'Ворид шудан'))),
        TextButton(onPressed: _busy ? null : () => setState(() { _register = !_register; _error = null; }), child: Text(_register ? 'Аллакай ҳисоб дорӣ? Ворид шав' : 'Ҳисоб надорӣ? Сабти ном кун')),
      ])),
    ))),
  );
}
