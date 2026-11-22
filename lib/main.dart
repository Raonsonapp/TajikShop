import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
class _AlmazHomeState extends State<AlmazHome>{int tab=0;final pages=const[HomePage(),GamesPage(),OrdersPage(),WalletPage(),ProfilePage()];@override Widget build(BuildContext c)=>Scaffold(body:SafeArea(child:IndexedStack(index:tab,children:pages)),bottomNavigationBar:GlassBottomNavigation(index:tab,onChanged:(v)=>setState(()=>tab=v)));}
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
    const labels = ['Дӯкон', 'Бозиҳо', 'Фармоиш', 'Ҳамён', 'Профил'];
    const icons = [
      Icons.home_outlined,
      Icons.sports_esports_outlined,
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
                          Icon(
                            icons[i],
                            size: 23,
                            color: index == i ? green : Colors.white,
                          ),
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
class Game{final String name,sub;final IconData icon;final Color color;final List<String> packs;const Game(this.name,this.sub,this.icon,this.color,this.packs);}
const games=[Game('Free Fire','Алмос • Ваучер • Membership',Icons.local_fire_department,Color(0xFFFFA52B),['100 алмос','210 алмос','520 алмос','Ваучери ҳафтаина']),Game('PUBG Mobile','UC • Royale Pass',Icons.military_tech,Color(0xFFFFD15C),['60 UC','325 UC','660 UC','Royale Pass']),Game('Mobile Legends','Diamonds • Pass',Icons.diamond,Color(0xFF5B9BFF),['86 Diamonds','172 Diamonds','Weekly Pass']),Game('Бозиҳои дигар','Хизматрасониҳои иловагӣ',Icons.sports_esports,green,['Фармоиши махсус'])];
class GameGrid extends StatelessWidget{const GameGrid({super.key});@override Widget build(BuildContext c)=>GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:games.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,mainAxisSpacing:10,crossAxisSpacing:10,childAspectRatio:1.35),itemBuilder:(c,i){final g=games[i];return InkWell(onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>GameDetail(game:g))),borderRadius:BorderRadius.circular(17),child:Container(padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:card,borderRadius:BorderRadius.circular(17),border:Border.all(color:g.color.withOpacity(.25))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Icon(g.icon,color:g.color,size:29),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(g.name,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:14)),Text(g.sub,style:const TextStyle(color:muted,fontSize:10))])])));});}
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
                  Icon(game.icon, color: game.color, size: 52),
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

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});
  Future<List<Map<String, dynamic>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final decoded = jsonDecode(prefs.getString('almaz_orders') ?? '[]') as List;
    return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const BrandHeader(),
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 0, 18, 14),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Фармоишҳои ман', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: load(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: green));
              final items = snapshot.data!;
              if (items.isEmpty) {
                return const EmptyState(icon: Icons.receipt_long, title: 'Ҳоло фармоиш нест', sub: 'Фармоишҳои ту дар ин ҷо пайдо мешаванд.');
              }
              return ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final order = items[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: green.withOpacity(.2))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(child: Text(order['game'] ?? '', style: const TextStyle(fontWeight: FontWeight.w900))),
                          Text(order['status'] ?? '', style: const TextStyle(color: gold, fontSize: 10, fontWeight: FontWeight.bold)),
                        ]),
                        const SizedBox(height: 7),
                        Text(order['pack'] ?? '', style: const TextStyle(color: muted, fontSize: 12)),
                        Text('ID: ${order['player'] ?? ''}', style: const TextStyle(color: muted, fontSize: 11)),
                        Text('#${order['id'] ?? ''} • ${order['date'] ?? ''}', style: const TextStyle(color: green, fontSize: 10)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});
  @override
  Widget build(BuildContext context) {
    const methods = ['Алиф', 'Душанбе Сити', 'Эсхата', 'Ориёнбонк', 'Бонкҳои дигар'];
    return Column(
      children: [
        const BrandHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(17),
            children: [
              const Text('Баланс', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
              const SizedBox(height: 15),
              Container(
                height: 160,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(colors: [Color(0xFF063F23), Color(0xFF122C1B), Color(0xFF25452B)]),
                  border: Border.all(color: green.withOpacity(.6)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('БАЛАНСИ ШУМО', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                    Spacer(),
                    Text('0.00 с', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
                    Spacer(),
                    Text('ALMAZ TJ • WALLET', style: TextStyle(color: green, fontWeight: FontWeight.w900, fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Тарзи пур кардани баланс', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 8),
                    ...methods.map((method) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.account_balance, color: green),
                      title: Text(method),
                      trailing: const Icon(Icons.lock_outline, color: muted),
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: Text(method),
                          content: const Text('Пайвасти пардохти расмӣ ҳоло танзим нашудааст. Пардохтро берун аз барнома анҷом надиҳед.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Фаҳмо')),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              const EmptyState(icon: Icons.history, title: 'Амалиёт нест', sub: 'Таърихи пуркунӣ ва хароҷот дар ин ҷо намоиш дода мешавад.'),
            ],
          ),
        ),
      ],
    );
  }
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
