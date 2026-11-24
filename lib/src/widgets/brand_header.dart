part of '../../main.dart';

class BrandHeader extends StatelessWidget {
  final bool showActions;
  const BrandHeader({super.key,this.showActions=true});
  Future<void> _toggleTheme() async {
    almazLightMode.value=!almazLightMode.value;
    final p=await SharedPreferences.getInstance(); await p.setBool('almaz_light_mode',almazLightMode.value);
  }
  void _menu(BuildContext context)=>showModalBottomSheet<void>(
    context:context,backgroundColor:const Color(0xFF202326),showDragHandle:true,
    builder:(sheet)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[
      const ListTile(title:Text('TAJ DONATE',style:TextStyle(fontWeight:FontWeight.w900,letterSpacing:1))),
      ListTile(leading:const Icon(Icons.sports_esports_rounded,color:green),title:const Text('Ҳамаи бозиҳо'),onTap:(){Navigator.pop(sheet);Navigator.push(context,MaterialPageRoute(builder:(_)=>const GamesPage()));}),
      ListTile(leading:const Icon(Icons.receipt_long_rounded,color:green),title:const Text('Фармоишҳо'),onTap:(){Navigator.pop(sheet);Navigator.push(context,MaterialPageRoute(builder:(_)=>const OrdersPage()));}),
      ListTile(leading:const Icon(Icons.support_agent_rounded,color:green),title:const Text('Дастгирӣ'),onTap:(){Navigator.pop(sheet);Navigator.push(context,MaterialPageRoute(builder:(_)=>const ProfilePage()));}),
      const SizedBox(height:8),
    ])),
  );
  void _favorites(BuildContext context)=>showModalBottomSheet<void>(
    context:context,backgroundColor:const Color(0xFF202326),showDragHandle:true,
    builder:(_)=>const SafeArea(child:Padding(padding:EdgeInsets.fromLTRB(24,12,24,34),child:Column(mainAxisSize:MainAxisSize.min,children:[
      Icon(Icons.favorite_border_rounded,color:green,size:34),SizedBox(height:12),
      Text('Маҳсулоти писандида',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),SizedBox(height:7),
      Text('Маҳсулоти дӯстдоштаат дар ин қисмат нишон дода мешавад.',textAlign:TextAlign.center,style:TextStyle(color:muted,height:1.5)),
    ]))),
  );
  @override Widget build(BuildContext c)=>Padding(
    padding:const EdgeInsets.fromLTRB(16,10,12,12),
    child:Row(children:[
      const AlmazMark(size:38),const SizedBox(width:10),
      const Expanded(child:Text('TAJ DONATE',maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:17,fontWeight:FontWeight.w800,letterSpacing:-.3))),
      if(showActions)...[
        _NexaHeaderIcon(icon:Icons.qr_code_scanner_rounded,tooltip:'Пайгирии фармоиш',onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const OrdersPage()))),
        _NexaHeaderIcon(icon:Icons.favorite_border_rounded,tooltip:'Писандидаҳо',onTap:()=>_favorites(c)),
        ValueListenableBuilder<int>(valueListenable:AlmazCartStore.count,builder:(context,total,_)=>Stack(clipBehavior:Clip.none,children:[
          _NexaHeaderIcon(icon:Icons.shopping_cart_outlined,tooltip:'Сабад',onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const CartPage()))),
          if(total>0)Positioned(right:0,top:0,child:Container(width:15,height:15,alignment:Alignment.center,decoration:const BoxDecoration(color:green,shape:BoxShape.circle),child:Text(total>9?'9+':'$total',style:const TextStyle(color:bg,fontSize:8,fontWeight:FontWeight.w900)))),
        ])),
        ValueListenableBuilder<bool>(valueListenable:almazLightMode,builder:(context,light,_)=>_NexaHeaderIcon(icon:light?Icons.dark_mode_outlined:Icons.light_mode_outlined,tooltip:'Тағйири мавзӯъ',onTap:_toggleTheme)),
        _NexaHeaderIcon(icon:Icons.menu_rounded,tooltip:'Меню',onTap:()=>_menu(c)),
      ],
    ]),
  );
}

class _NexaHeaderIcon extends StatelessWidget {
  final IconData icon; final String tooltip; final VoidCallback onTap;
  const _NexaHeaderIcon({required this.icon,required this.tooltip,required this.onTap});
  @override Widget build(BuildContext context)=>SizedBox(width:34,height:38,child:IconButton(
    tooltip:tooltip,padding:EdgeInsets.zero,visualDensity:VisualDensity.compact,onPressed:onTap,
    icon:Icon(icon,size:19,color:Colors.white.withOpacity(.88)),
  ));
}

class AlmazMark extends StatelessWidget {
  final double size;
  const AlmazMark({super.key,this.size=54});
  @override
  Widget build(BuildContext c)=>Container(
    width:size,height:size,
    decoration:BoxDecoration(color:Colors.black,borderRadius:BorderRadius.circular(size*.23),border:Border.all(color:green.withOpacity(.8)),boxShadow:[BoxShadow(color:green.withOpacity(.18),blurRadius:15)]),
    clipBehavior:Clip.antiAlias,
    child:Image.asset('assets/brand/taj_donate_logo.webp',fit:BoxFit.cover,errorBuilder:(_,__,___)=>Center(child:Text('TD',style:TextStyle(color:green,fontSize:size*.35,fontWeight:FontWeight.w900)))),
  );
}
