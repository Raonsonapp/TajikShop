part of '../../main.dart';

class _AlmazBrandImage extends StatelessWidget {
  final Game game;
  final double size;
  const _AlmazBrandImage({required this.game, required this.size});
  @override
  Widget build(BuildContext context) {
    final slug = switch (game.name) {
      'Free Fire' => 'free-fire',
      'PUBG Mobile' => 'pubg-mobile',
      'Mobile Legends' => 'mobile-legends',
      'Standoff 2' => 'standoff-2',
      'Telegram' => 'telegram',
      'IMO' => 'imo',
      _ => 'unknown',
    };
    final assetUrl = _almazAssetsBase.isNotEmpty
        ? '$_almazAssetsBase/games/$slug.png'
        : 'https://www.google.com/s2/favicons?domain=${switch (game.name) { 'Free Fire' => 'ff.garena.com', 'PUBG Mobile' => 'pubgmobile.com', 'Mobile Legends' => 'mobilelegends.com', 'Standoff 2' => 'standoff2.com', 'Telegram' => 'telegram.org', _ => 'imo.im' }}&sz=256';
    return Image.network(assetUrl, width: size, height: size, fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => Center(child: Text(game.logoText, style: TextStyle(color: game.color, fontWeight: FontWeight.w900, fontSize: size * .30))));
  }
}

class _AlmazBankImage extends StatelessWidget {
  final String domain;
  final double size;
  const _AlmazBankImage({required this.domain, required this.size});
  @override
  Widget build(BuildContext context) {
    final slug = switch (domain) {
      'alif.tj' => 'alif',
      'dc.tj' => 'dushanbe-city',
      'eskhata.com' => 'eskhata',
      'orienbank.tj' => 'orienbank',
      _ => 'bank',
    };
    final assetUrl = _almazAssetsBase.isNotEmpty
        ? '$_almazAssetsBase/banks/$slug.png'
        : 'https://www.google.com/s2/favicons?domain=$domain&sz=256';
    return Image.network(assetUrl, width: size, height: size, fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_outlined, color: green));
  }
}

class GameLogo extends StatelessWidget {
  final Game game;
  final double size;
  const GameLogo({super.key, required this.game, this.size = 76});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size, padding: const EdgeInsets.all(7),
    decoration: BoxDecoration(
      color: almazLightMode.value ? const Color(0xFFF1F6F2) : const Color(0xFF080D0A),
      borderRadius: BorderRadius.circular(size * .25),
      border: Border.all(color: game.color.withOpacity(.7), width: 1.3),
      boxShadow: [BoxShadow(color: game.color.withOpacity(.18), blurRadius: 16)],
    ),
    child: _AlmazBrandImage(game: game, size: size - 14),
  );
}

class GameGrid extends StatelessWidget {
  const GameGrid({super.key});
  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap:true,
    physics:const NeverScrollableScrollPhysics(),
    itemCount:games.length,
    gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount:2,mainAxisSpacing:12,crossAxisSpacing:12,childAspectRatio:1.12,
    ),
    itemBuilder:(context,index){
      final game=games[index];
      return Material(
        color:Colors.transparent,
        child:InkWell(
          onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>GameDetail(game:game))),
          borderRadius:BorderRadius.circular(16),
          child:Container(
            padding:const EdgeInsets.all(14),
            decoration:BoxDecoration(
              color:const Color(0xFF1B1E21),
              borderRadius:BorderRadius.circular(16),
              border:Border.all(color:Colors.white.withOpacity(.09)),
              boxShadow:[BoxShadow(color:Colors.black.withOpacity(.18),blurRadius:18,offset:const Offset(0,6))],
            ),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Row(children:[GameLogo(game:game,size:58),const Spacer(),Icon(Icons.arrow_outward_rounded,size:16,color:muted.withOpacity(.8))]),
              const Spacer(),
              Text(game.name,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:13)),
              const SizedBox(height:4),
              Text(game.sub,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:muted,fontSize:9)),
              const SizedBox(height:10),
              Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:5),decoration:BoxDecoration(color:green.withOpacity(.10),borderRadius:BorderRadius.circular(20)),
                child:const Text('Бастаҳо',style:TextStyle(color:green,fontSize:10,fontWeight:FontWeight.w700)),
              ),
            ]),
          ),
        ),
      );
    },
  );
}

class Benefit extends StatelessWidget{final IconData icon;final String title,sub;const Benefit({super.key,required this.icon,required this.title,required this.sub});@override Widget build(BuildContext c)=>Expanded(child:Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:card,borderRadius:BorderRadius.circular(14),border:Border.all(color:Colors.white10)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:green,size:20),const SizedBox(height:7),Text(title,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:12)),Text(sub,style:const TextStyle(color:muted,fontSize:9))])));}
