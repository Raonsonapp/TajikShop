part of '../../main.dart';

class AlmazHome extends StatefulWidget{const AlmazHome({super.key});@override State<AlmazHome> createState()=>_AlmazHomeState();}

class _AlmazHomeState extends State<AlmazHome>{
  int tab=0;
  late final List<Widget> pages=[const HomePage(),const WalletPage(),const CartPage(),const OrdersPage(),const ProfilePage()];
  @override Widget build(BuildContext c)=>Scaffold(
    body:SafeArea(child:IndexedStack(index:tab,children:pages)),
    bottomNavigationBar:GlassBottomNavigation(index:tab,onChanged:(v)=>setState(()=>tab=v)),
  );
}

class GlassBottomNavigation extends StatelessWidget {
  final int index; final ValueChanged<int> onChanged;
  const GlassBottomNavigation({super.key,required this.index,required this.onChanged});
  @override Widget build(BuildContext context) {
    final labels=['Дӯкон','Баланс','Сабад','Фармоишҳо','Профил'].map(tr).toList();
    const icons=[HeroiconsOutline.shoppingBag,HeroiconsOutline.creditCard,HeroiconsOutline.shoppingCart,HeroiconsOutline.documentText,HeroiconsOutline.user];
    return Padding(padding:const EdgeInsets.fromLTRB(12,5,12,10),child:ClipRRect(
      borderRadius:BorderRadius.circular(26),
      child:BackdropFilter(filter:ImageFilter.blur(sigmaX:28,sigmaY:28),child:Container(
        height:74,
        decoration:BoxDecoration(color:const Color(0xFF0B2B26).withOpacity(.78),borderRadius:BorderRadius.circular(26),border:Border.all(color:Colors.white.withOpacity(.18)),boxShadow:[BoxShadow(color:green.withOpacity(.09),blurRadius:28),BoxShadow(color:Colors.black.withOpacity(.38),blurRadius:20,offset:const Offset(0,7))]),
        child:Row(children:List.generate(labels.length,(i)=>Expanded(child:InkWell(
          borderRadius:BorderRadius.circular(22),onTap:()=>onChanged(i),
          child:AnimatedContainer(duration:const Duration(milliseconds:240),curve:Curves.easeOutCubic,margin:const EdgeInsets.all(5),
            decoration:BoxDecoration(color:index==i?green.withOpacity(.13):Colors.transparent,borderRadius:BorderRadius.circular(20),border:index==i?Border.all(color:green.withOpacity(.38)):null,boxShadow:index==i?[BoxShadow(color:green.withOpacity(.12),blurRadius:16)]:[]),
            child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
              AnimatedScale(scale:index==i?1.10:1,duration:const Duration(milliseconds:220),child:Icon(icons[i],size:21,color:index==i?const Color(0xFFB8D9C9):Colors.white70)),
              const SizedBox(height:4),Text(labels[i],maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:9,fontWeight:FontWeight.w800,color:index==i?const Color(0xFFB8D9C9):Colors.white70)),
            ]),
          ),
        )))),
      )),
    ));
  }
}
