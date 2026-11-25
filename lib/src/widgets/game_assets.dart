part of '../../main.dart';

class _AlmazBrandImage extends StatelessWidget {
  final Game game;
  final double size;
  const _AlmazBrandImage({required this.game, required this.size});
  String get asset => switch (game.name) {
    'Free Fire' => 'assets/logo/Free_Fire.png',
    'PUBG Mobile' => 'assets/logo/Pubg_Mobile.png',
    'Mobile Legends' => 'assets/logo/Mobile_Legends.png',
    'Standoff 2' => 'assets/logo/Stand_off.png',
    'Telegram' => 'assets/logo/Telegram_Premium.png',
    _ => '',
  };
  @override
  Widget build(BuildContext context) {
    if (asset.isEmpty) {
      return Image.network(
        'https://www.google.com/s2/favicons?domain=${game.domain}&sz=256',
        width: size, height: size, fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Center(child: Text(game.logoText, style: TextStyle(color: game.color, fontWeight: FontWeight.w900, fontSize: size * .30))),
      );
    }
    return Image.asset(asset, width: size, height: size, fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => Center(child: Text(game.logoText, style: TextStyle(color: game.color, fontWeight: FontWeight.w900, fontSize: size * .30))));
  }
}

class GameLogo extends StatelessWidget {
  final Game game;
  final double size;
  const GameLogo({super.key, required this.game, this.size = 76});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size, padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: const Color(0xFF07110D),
      borderRadius: BorderRadius.circular(size * .27),
      border: Border.all(color: const Color(0xFF278BFF).withOpacity(.85), width: 1.4),
      boxShadow: [
        BoxShadow(color: const Color(0xFF168BFF).withOpacity(.20), blurRadius: 16),
        BoxShadow(color: green.withOpacity(.08), blurRadius: 12),
      ],
    ),
    child: ClipRRect(borderRadius: BorderRadius.circular(size * .21), child: _AlmazBrandImage(game: game, size: size - 12)),
  );
}

class GameGrid extends StatelessWidget {
  const GameGrid({super.key});
  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
    itemCount: games.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.12),
    itemBuilder: (context, index) {
      final game = games[index];
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GameDetail(game: game))),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF101A16),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(.10)),
              boxShadow: [BoxShadow(color: green.withOpacity(.06), blurRadius: 18, offset: const Offset(0, 6))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [GameLogo(game: game, size: 62), const Spacer(), Icon(Icons.arrow_outward_rounded, size: 16, color: muted.withOpacity(.8))]),
              const Spacer(),
              Text(game.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 4),
              Text(game.sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 9)),
              const SizedBox(height: 10),
              Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: green.withOpacity(.10), borderRadius: BorderRadius.circular(20)),
                child: const Text('Бастаҳо', style: TextStyle(color: green, fontSize: 10, fontWeight: FontWeight.w700))),
            ]),
          ),
        ),
      );
    },
  );
}

class Benefit extends StatelessWidget {
  final IconData icon; final String title, sub;
  const Benefit({super.key, required this.icon, required this.title, required this.sub});
  @override Widget build(BuildContext c) => Expanded(child: Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: green, size: 20), const SizedBox(height: 7),
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      Text(sub, style: const TextStyle(color: muted, fontSize: 9)),
    ]),
  ));
}
