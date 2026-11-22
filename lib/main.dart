import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const bg=Color(0xFF050907), surface=Color(0xFF0C1710), card=Color(0xFF101F16), green=Color(0xFF39FF72), lime=Color(0xFFB6FF38), muted=Color(0xFF91A69A), gold=Color(0xFFFFD65A);
void main(){WidgetsFlutterBinding.ensureInitialized();SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor:bg,statusBarIconBrightness:Brightness.light,systemNavigationBarColor:bg,systemNavigationBarIconBrightness:Brightness.light));runApp(const AlmazApp());}
class AlmazApp extends StatelessWidget{const AlmazApp({super.key});@override Widget build(BuildContext c)=>MaterialApp(title:'Almaz TJ',debugShowCheckedModeBanner:false,theme:ThemeData(brightness:Brightness.dark,scaffoldBackgroundColor:bg,colorScheme:const ColorScheme.dark(primary:green,surface:surface),useMaterial3:true,fontFamily:'Roboto'),home:const AlmazSplash());}
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
class _AlmazHomeState extends State<AlmazHome>{int tab=0;final pages=const[HomePage(),GamesPage(),OrdersPage(),WalletPage(),ProfilePage()];@override Widget build(BuildContext c)=>Scaffold(body:SafeArea(child:IndexedStack(index:tab,children:pages)),bottomNavigationBar:Container(decoration:BoxDecoration(color:surface,border:Border(top:BorderSide(color:green.withOpacity(.18))),boxShadow:[BoxShadow(color:green.withOpacity(.06),blurRadius:22)]),child:NavigationBar(height:68,backgroundColor:surface,indicatorColor:green.withOpacity(.14),labelBehavior:NavigationDestinationLabelBehavior.alwaysShow,selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:const[NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home_rounded),label:'Асосӣ'),NavigationDestination(icon:Icon(Icons.sports_esports_outlined),selectedIcon:Icon(Icons.sports_esports),label:'Бозиҳо'),NavigationDestination(icon:Icon(Icons.receipt_long_outlined),selectedIcon:Icon(Icons.receipt_long),label:'Фармоиш'),NavigationDestination(icon:Icon(Icons.account_balance_wallet_outlined),selectedIcon:Icon(Icons.account_balance_wallet),label:'Ҳамён'),NavigationDestination(icon:Icon(Icons.person_outline),selectedIcon:Icon(Icons.person),label:'Профил')])));}
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
class Game{final String name,sub;final IconData icon;final Color color;const Game(this.name,this.sub,this.icon,this.color);}
const games=[Game('Free Fire','Алмос ва бастаҳо',Icons.local_fire_department,Color(0xFFFFA52B)),Game('PUBG Mobile','UC ва ваучерҳо',Icons.military_tech,Color(0xFFFFD15C)),Game('Mobile Legends','Diamonds',Icons.diamond,Color(0xFF5B9BFF)),Game('Бозиҳои дигар','Дигар хизматрасониҳо',Icons.sports_esports,green)];
class GameGrid extends StatelessWidget{const GameGrid({super.key});@override Widget build(BuildContext c)=>GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:games.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,mainAxisSpacing:10,crossAxisSpacing:10,childAspectRatio:1.35),itemBuilder:(c,i){final g=games[i];return InkWell(onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>GameDetail(game:g))),borderRadius:BorderRadius.circular(17),child:Container(padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:card,borderRadius:BorderRadius.circular(17),border:Border.all(color:g.color.withOpacity(.25))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Icon(g.icon,color:g.color,size:29),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(g.name,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:14)),Text(g.sub,style:const TextStyle(color:muted,fontSize:10))])])));});}
class Benefit extends StatelessWidget{final IconData icon;final String title,sub;const Benefit({super.key,required this.icon,required this.title,required this.sub});@override Widget build(BuildContext c)=>Expanded(child:Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:card,borderRadius:BorderRadius.circular(14),border:Border.all(color:Colors.white10)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:green,size:20),const SizedBox(height:7),Text(title,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:12)),Text(sub,style:const TextStyle(color:muted,fontSize:9))])));}
class GamesPage extends StatelessWidget{const GamesPage({super.key});@override Widget build(BuildContext c)=>PageShell(title:'Бозиҳо',subtitle:'Бозиро интихоб намо ва бастаҳои дастрасро бин',child:ListView(padding:const EdgeInsets.all(16),children:[const GameGrid(),const SizedBox(height:18),Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:card,borderRadius:BorderRadius.circular(14)),child:const Text('Барои фармоиш ID-и бозингарро дуруст ворид намо. Пеш аз пардохт маълумоти фармоишро санҷ.',style:TextStyle(color:muted,fontSize:11,height:1.5)))]));}
class GameDetail extends StatelessWidget{final Game game;const GameDetail({super.key,required this.game});@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text(game.name)),body:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(height:125,width:double.infinity,decoration:BoxDecoration(color:game.color.withOpacity(.12),borderRadius:BorderRadius.circular(20),border:Border.all(color:game.color.withOpacity(.35))),child:Icon(game.icon,size:62,color:game.color)),const SizedBox(height:18),Text(game.sub,style:const TextStyle(color:muted)),const SizedBox(height:15),const Text('Бастаҳо',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),const SizedBox(height:8),const Text('Рӯйхати бастаҳо баъд аз пайваст кардани нархнома ва API-и фармоиш намоиш дода мешавад.',style:TextStyle(color:muted,height:1.5)),const Spacer(),SizedBox(width:double.infinity,child:FilledButton(onPressed:()=>ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content:Text('Системаи фармоиш ҳоло пайваст нашудааст'))),style:FilledButton.styleFrom(backgroundColor:green,foregroundColor:bg,padding:const EdgeInsets.all(15)),child:const Text('Оғози фармоиш')))])));}
class OrdersPage extends StatelessWidget{const OrdersPage({super.key});@override Widget build(BuildContext c)=>const PageShell(title:'Фармоишҳои ман',subtitle:'Ҳолат ва таърихи фармоишҳо',child:EmptyState(icon:Icons.receipt_long,title:'Ҳоло фармоиш нест',sub:'Фармоишҳои ту дар ин ҷо нишон дода мешаванд.'));}
class WalletPage extends StatelessWidget{const WalletPage({super.key});@override Widget build(BuildContext c)=>const PageShell(title:'Ҳамён',subtitle:'Баланс ва амалиётҳо',child:EmptyState(icon:Icons.account_balance_wallet_outlined,title:'Ҳамён ҳоло холӣ аст',sub:'Пас аз пайваст шудани пардохт баланс дар ин ҷо пайдо мешавад.'));}
class ProfilePage extends StatelessWidget{const ProfilePage({super.key});@override Widget build(BuildContext c)=>PageShell(title:'Профил',subtitle:'Ҳисоб ва танзимот',child:ListView(padding:const EdgeInsets.all(16),children:[Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:card,borderRadius:BorderRadius.circular(18)),child:const Row(children:[AlmazMark(size:58),SizedBox(width:13),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Меҳмон',style:TextStyle(fontWeight:FontWeight.w900,fontSize:17)),Text('Ба ҳисоб ворид нашудаӣ',style:TextStyle(color:muted,fontSize:11))])])),const SizedBox(height:12),const ProfileRow(icon:Icons.person_outline,title:'Маълумоти шахсӣ'),const ProfileRow(icon:Icons.history,title:'Таърихи фаъолият'),const ProfileRow(icon:Icons.help_outline,title:'Маркази кӯмак'),const ProfileRow(icon:Icons.settings_outlined,title:'Танзимот') ]));}
class ProfileRow extends StatelessWidget{final IconData icon;final String title;const ProfileRow({super.key,required this.icon,required this.title});@override Widget build(BuildContext c)=>Container(margin:const EdgeInsets.only(bottom:8),decoration:BoxDecoration(color:card,borderRadius:BorderRadius.circular(13)),child:ListTile(leading:Icon(icon,color:green),title:Text(title,style:const TextStyle(fontSize:13,fontWeight:FontWeight.w700)),trailing:const Icon(Icons.chevron_right,color:muted)));}
class EmptyState extends StatelessWidget{final IconData icon;final String title,sub;const EmptyState({super.key,required this.icon,required this.title,required this.sub});@override Widget build(BuildContext c)=>Center(child:Padding(padding:const EdgeInsets.all(30),child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:55,color:green.withOpacity(.6)),const SizedBox(height:15),Text(title,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:17)),const SizedBox(height:7),Text(sub,textAlign:TextAlign.center,style:const TextStyle(color:muted,fontSize:12,height:1.5))])));}
