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
  Widget build(BuildContext context) => SizedBox(
    width: size, height: size,
    child: _AlmazBrandImage(game: game, size: size),
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
              color: const Color(0xFF10231E),
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


class SectionTitle extends StatelessWidget {
  final String title;
  final String trailing;
  const SectionTitle(this.title, this.trailing, {super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: .55,
          ),
        ),
      ),
      if (trailing.isNotEmpty)
        Text(
          trailing,
          style: const TextStyle(
            color: green,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
    ],
  );
}

class _AlmazBankImage extends StatelessWidget {
  final String domain;
  final double size;
  const _AlmazBankImage({required this.domain, required this.size});

  @override
  Widget build(BuildContext context) => Image.network(
    'https://www.google.com/s2/favicons?domain=$domain&sz=128',
    width: size,
    height: size,
    fit: BoxFit.contain,
    errorBuilder: (_, __, ___) => Icon(
      Icons.account_balance_rounded,
      size: size,
      color: green,
    ),
  );
}


class DiamondGemIcon extends StatelessWidget {
  final double size;
  const DiamondGemIcon({super.key, this.size = 30});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size, height: size,
    child: CustomPaint(painter: _DiamondGemPainter()),
  );
}

class _DiamondGemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(w * .22, h * .12)
      ..lineTo(w * .78, h * .12)
      ..lineTo(w * .98, h * .40)
      ..lineTo(w * .50, h * .94)
      ..lineTo(w * .02, h * .40)
      ..close();
    final paint = Paint()..shader = const LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFFB8D9C9), Color(0xFF4D9B7C), Color(0xFF1E604B)],
    ).createShader(Offset.zero & size);
    canvas.drawPath(path, paint);
    final facets = Paint()..color = Colors.white.withOpacity(.25);
    final left = Path()..moveTo(w*.22,h*.12)..lineTo(w*.50,h*.12)..lineTo(w*.50,h*.94)..lineTo(w*.02,h*.40)..close();
    final right = Path()..moveTo(w*.50,h*.12)..lineTo(w*.78,h*.12)..lineTo(w*.98,h*.40)..lineTo(w*.50,h*.94)..close();
    canvas.drawPath(left, facets);
    canvas.drawPath(right, Paint()..color = const Color(0xFF0B2B26).withOpacity(.16));
    canvas.drawPath(path, Paint()..style=PaintingStyle.stroke..strokeWidth=1.1..color=Colors.white.withOpacity(.35));
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
