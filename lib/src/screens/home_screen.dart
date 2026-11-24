part of '../../main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState()=>_HomePageState();
}

class _HomePageState extends State<HomePage> {
  final searchController=TextEditingController(); String query='';
  @override void dispose(){searchController.dispose();super.dispose();}
  @override Widget build(BuildContext context) {
    final filtered=games.where((g)=>g.name.toLowerCase().contains(query.toLowerCase())).toList();
    return Column(children:[
      const BrandHeader(),
      Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(18,4,18,26),children:[
        Container(padding:const EdgeInsets.fromLTRB(18,18,18,17),decoration:BoxDecoration(
          color:const Color(0xFF1B1E21),borderRadius:BorderRadius.circular(20),
          border:Border.all(color:Colors.white.withOpacity(.09)),
          boxShadow:[BoxShadow(color:Colors.black.withOpacity(.22),blurRadius:24,offset:const Offset(0,10))],
        ),child:Stack(children:[
          Positioned(right:-12,top:-18,child:Container(width:150,height:150,decoration:BoxDecoration(shape:BoxShape.circle,gradient:RadialGradient(colors:[green.withOpacity(.15),Colors.transparent])))),
          Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),decoration:BoxDecoration(color:green.withOpacity(.11),borderRadius:BorderRadius.circular(30),border:Border.all(color:green.withOpacity(.22))),child:const Text('GAME TOP-UP • TAJIKISTAN',style:TextStyle(color:green,fontSize:9,fontWeight:FontWeight.w800,letterSpacing:1))),
            const SizedBox(height:15),const Text('Top up game,\nосон ва зуд.',style:TextStyle(fontSize:27,height:1.08,fontWeight:FontWeight.w800,letterSpacing:-.7)),
            const SizedBox(height:8),const Text('Бозиро интихоб кун, номиналро ёб ва фармоишатро дар чанд қадам сабт намо.',style:TextStyle(color:muted,fontSize:12,height:1.55)),
            const SizedBox(height:17),Row(children:[
              FilledButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const GamesPage())),icon:const Icon(Icons.sports_esports_rounded,size:17),label:const Text('Ҳамаи бозиҳо'),style:FilledButton.styleFrom(backgroundColor:green,foregroundColor:bg,padding:const EdgeInsets.symmetric(horizontal:15,vertical:12),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)))),
              const SizedBox(width:10),const Row(children:[Icon(Icons.verified_rounded,color:green,size:16),SizedBox(width:5),Text('TAJ DONATE',style:TextStyle(color:muted,fontSize:10,fontWeight:FontWeight.w700))]),
            ]),
          ]),
        ])),
        const SizedBox(height:20),
        TextField(controller:searchController,onChanged:(v)=>setState(()=>query=v),style:const TextStyle(fontSize:13),decoration:InputDecoration(
          hintText:'Бозӣ ё маҳсулотро ҷустуҷӯ кун…',hintStyle:const TextStyle(color:muted,fontSize:12),
          prefixIcon:const Icon(Icons.search_rounded,color:muted,size:20),filled:true,fillColor:const Color(0xFF1B1E21),
          contentPadding:const EdgeInsets.symmetric(vertical:13),
          border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide(color:Colors.white.withOpacity(.08))),
          enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide(color:Colors.white.withOpacity(.08))),
          focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:const BorderSide(color:green)),
          suffixIcon:query.isEmpty?null:IconButton(onPressed:(){searchController.clear();setState(()=>query='');},icon:const Icon(Icons.close_rounded,color:muted,size:18)),
        )),
        const SizedBox(height:23),
        Row(children:[const Expanded(child:Text('Бозиҳои интихобшуда',style:TextStyle(fontSize:17,fontWeight:FontWeight.w800,letterSpacing:-.3))),Text('${filtered.length}',style:const TextStyle(color:muted,fontSize:11,fontWeight:FontWeight.w700))]),
        const SizedBox(height:12),
        if(filtered.isEmpty) const Padding(padding:EdgeInsets.symmetric(vertical:24),child:Center(child:Text('Бозӣ ёфт нашуд',style:TextStyle(color:muted))))
        else SizedBox(height:154,child:ListView.separated(scrollDirection:Axis.horizontal,itemCount:filtered.length,separatorBuilder:(_,__)=>const SizedBox(width:10),itemBuilder:(context,index){
          final game=filtered[index];
          return InkWell(onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>GameDetail(game:game))),borderRadius:BorderRadius.circular(15),
            child:Container(width:132,padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:const Color(0xFF1B1E21),borderRadius:BorderRadius.circular(15),border:Border.all(color:Colors.white.withOpacity(.09))),
              child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[GameLogo(game:game,size:62),const Spacer(),Text(game.name,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w800)),const SizedBox(height:3),Text(game.sub,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:muted,fontSize:9))]),
            ),
          );
        })),
        const SizedBox(height:23),const LiveProductsSection(),
        const SizedBox(height:24),const Text('Чӣ тавр фармоиш додан?',style:TextStyle(fontSize:17,fontWeight:FontWeight.w800,letterSpacing:-.3)),
        const SizedBox(height:11),
        const _NexaStep(number:'01',title:'Бозиро интихоб кун',description:'Бозии лозимаро кушо ва номинали мувофиқро интихоб намо.'),
        const _NexaStep(number:'02',title:'Маълумоти аккаунтро ворид кун',description:'ID-и бозингарро ворид карда, маълумотро санҷ.'),
        const _NexaStep(number:'03',title:'Фармоишро тасдиқ кун',description:'Фармоишро сабт намо ва ҳолати онро дар қисмати фармоишҳо бин.'),
        const SizedBox(height:22),const Text('Саволҳои маъмул',style:TextStyle(fontSize:17,fontWeight:FontWeight.w800,letterSpacing:-.3)),
        const SizedBox(height:8),
        const _NexaFaq(question:'Оё сабти ном лозим аст?',answer:'Барои баъзе хизматрасониҳо воридшавӣ лозим мешавад. Агар фармоиш ба ҳисоб пайваст бошад, аз профил ворид шав.'),
        const _NexaFaq(question:'Фармоишро аз куҷо мебинам?',answer:'Ҳамаи фармоишҳои дастрас дар қисми «Фармоишҳо» нишон дода мешаванд.'),
        const _NexaFaq(question:'Чӣ тавр бо дастгирӣ тамос гирам?',answer:'Аз профил қисмати дастгирии Telegram-ро кушо.'),
        const SizedBox(height:14),const ApiStatusCard(),
      ])),
    ]);
  }
}

class _NexaStep extends StatelessWidget {
  final String number,title,description;
  const _NexaStep({required this.number,required this.title,required this.description});
  @override Widget build(BuildContext context)=>Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.all(14),
    decoration:BoxDecoration(color:const Color(0xFF1B1E21),borderRadius:BorderRadius.circular(14),border:Border.all(color:Colors.white.withOpacity(.08))),
    child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(number,style:const TextStyle(color:green,fontSize:11,fontWeight:FontWeight.w800)),const SizedBox(width:13),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w800)),const SizedBox(height:5),Text(description,style:const TextStyle(color:muted,fontSize:11,height:1.45))])),
    ]),
  );
}

class _NexaFaq extends StatelessWidget {
  final String question,answer;
  const _NexaFaq({required this.question,required this.answer});
  @override Widget build(BuildContext context)=>Theme(
    data:Theme.of(context).copyWith(dividerColor:Colors.white.withOpacity(.08),colorScheme:Theme.of(context).colorScheme.copyWith(primary:green)),
    child:ExpansionTile(tilePadding:const EdgeInsets.symmetric(horizontal:2),childrenPadding:const EdgeInsets.fromLTRB(12,0,12,14),
      title:Text(question,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700)),iconColor:green,collapsedIconColor:muted,
      children:[Align(alignment:Alignment.centerLeft,child:Text(answer,style:const TextStyle(color:muted,fontSize:11,height:1.55)))],
    ),
  );
}

class SectionTitle extends StatelessWidget{final String title,action;const SectionTitle(this.title,this.action,{super.key});@override Widget build(BuildContext c)=>Row(children:[Expanded(child:Text(title,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w900))),if(action.isNotEmpty)Text(action,style:const TextStyle(color:green,fontSize:11,fontWeight:FontWeight.bold))]);}
