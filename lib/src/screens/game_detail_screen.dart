part of '../../main.dart';

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
      'id': 'A${DateTime.now().millisecondsSinceEpoch}',
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
                          Text(almazCatalogPrices[game.packs[index]] ?? 'Нархнома ҳоло дастрас нест', style: TextStyle(color: almazCatalogPrices.containsKey(game.packs[index]) ? green : muted, fontSize: 11, fontWeight: FontWeight.w800)),
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
