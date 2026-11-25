part of '../../main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final searchController = TextEditingController();
  String query = '';
  String category = 'Ҳама';

  @override
  void dispose() { searchController.dispose(); super.dispose(); }

  List<String> get _freeFireProducts {
    final all = games.first.packs;
    if (category == 'Алмос') return all.where((e) => e.contains('алмаз') && !e.toLowerCase().contains('ваучер')).toList();
    if (category == 'Ваучер') return all.where((e) => e.toLowerCase().contains('ваучер')).toList();
    if (category == 'Level Up') return all.where((e) => e.toLowerCase().contains('level')).toList();
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = games.where((g) => g.name.toLowerCase().contains(query.toLowerCase())).toList();
    final products = _freeFireProducts;
    return Column(children: [
      const BrandHeader(),
      Expanded(child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
        children: [
          TextField(
            controller: searchController,
            onChanged: (v) => setState(() => query = v),
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Бозӣ ё маҳсулотро ҷустуҷӯ кун…',
              hintStyle: const TextStyle(color: muted, fontSize: 12),
              prefixIcon: const Icon(HeroiconsOutline.magnifyingGlass, color: muted, size: 20),
              filled: true, fillColor: const Color(0xFF10231E),
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Colors.white.withOpacity(.08))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Colors.white.withOpacity(.08))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: green)),
              suffixIcon: query.isEmpty ? null : IconButton(onPressed: () { searchController.clear(); setState(() => query = ''); }, icon: const Icon(Icons.close_rounded, color: muted, size: 18)),
            ),
          ),
          const SizedBox(height: 20),
          _HomeQuickActions(onTap: (i) {
            if (i == 0) Navigator.push(context, MaterialPageRoute(builder: (_) => const GamesPage()));
            if (i == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletPage()));
            if (i == 2) Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersPage()));
            if (i == 3) Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
          }),
          const SizedBox(height: 22),
          Row(children: [
            const Expanded(child: Text('Бозиҳои машҳур', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: -.4))),
            Text('${filtered.length}', style: const TextStyle(color: muted, fontSize: 12)),
          ]),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('Бозӣ ёфт нашуд', style: TextStyle(color: muted))))
          else
            GridView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: .78),
              itemBuilder: (context, index) {
                final game = filtered[index];
                final firstPrice = game.packs.isNotEmpty ? (almazCatalogPrices[game.packs.first] ?? '') : '';
                return InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GameDetail(game: game))),
                  borderRadius: BorderRadius.circular(19),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10231E),
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(color: Colors.white.withOpacity(.10)),
                      boxShadow: [BoxShadow(color: green.withOpacity(.055), blurRadius: 15)],
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      GameLogo(game: game, size: 72),
                      const SizedBox(height: 9),
                      Text(game.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, height: 1.15, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 7),
                      if (firstPrice.isNotEmpty)
                        Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: const Color(0xFF1B4437), borderRadius: BorderRadius.circular(20)), child: Text('аз $firstPrice', maxLines: 1, style: const TextStyle(color: Color(0xFFB8D9C9), fontSize: 9, fontWeight: FontWeight.w900)))
                      else
                        Text(game.sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 9)),
                    ]),
                  ),
                );
              },
            ),
          const SizedBox(height: 20),
          _FreeFireHero(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GameDetail(game: games.first)))),
          const SizedBox(height: 14),
          _VipBanner(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GameDetail(game: games.first)))),
          const SizedBox(height: 24),
          Row(children: [
            const Expanded(child: Text('Free Fire СНГ', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
            Text('${products.length} адад', style: const TextStyle(color: muted, fontSize: 11)),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: ['Ҳама', 'Алмос', 'Ваучер', 'Level Up'].map((value) {
            final selected = category == value;
            return ChoiceChip(
              label: Text(value),
              selected: selected,
              onSelected: (_) => setState(() => category = value),
              showCheckmark: false,
              labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70, fontSize: 12, fontWeight: FontWeight.w800),
              selectedColor: const Color(0xFF1B4437),
              backgroundColor: const Color(0xFF10231E),
              side: BorderSide(color: selected ? green.withOpacity(.55) : Colors.white10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            );
          }).toList()),
          const SizedBox(height: 13),
          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 11, crossAxisSpacing: 11, childAspectRatio: 1.12),
            itemBuilder: (context, index) {
              final name = products[index];
              final price = almazCatalogPrices[name] ?? 'Нарх дастрас нест';
              final isDiamond = name.contains('алмаз');
              return InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GameDetail(game: games.first))),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(.13)),
                    image: const DecorationImage(image: AssetImage('assets/logo/Banner_Free_Fire.png'), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Color(0xB8000000), BlendMode.darken)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(.25), blurRadius: 14, offset: const Offset(0, 6))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    isDiamond ? const DiamondGemIcon(size: 32) : Icon(name.toLowerCase().contains('level') ? HeroiconsOutline.chartBar : HeroiconsOutline.ticket, color: green, size: 29),
                    const Spacer(),
                    Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, height: 1.15, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    const Text('Free Fire СНГ', style: TextStyle(color: Colors.white70, fontSize: 10)),
                    const Spacer(),
                    Row(children: [
                      Expanded(child: Text(price, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900))),
                      Container(width: 36, height: 36, decoration: const BoxDecoration(color: Color(0xFF4D9B7C), shape: BoxShape.circle), child: const Icon(HeroiconsOutline.shoppingBag, size: 18, color: Colors.white)),
                    ]),
                  ]),
                ),
              );
            },
          ),
          const SizedBox(height: 22),
          const _HomeBenefits(),
          const SizedBox(height: 22),
          const Text('Андешаҳои харидорон', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          const _ReviewCard(),
          const SizedBox(height: 22),
          const Text('Чӣ тавр фармоиш додан?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          const _NexaStep(number: '01', title: 'Бозиро интихоб кун', description: 'Бозии лозимаро кушо ва номинали мувофиқро интихоб намо.'),
          const _NexaStep(number: '02', title: 'Маълумоти аккаунтро ворид кун', description: 'ID-и бозингарро ворид карда, маълумотро санҷ.'),
          const _NexaStep(number: '03', title: 'Фармоишро тасдиқ кун', description: 'Фармоишро сабт намо ва ҳолати онро дар қисмати фармоишҳо бин.'),
          const SizedBox(height: 18),
          const ApiStatusCard(),
        ],
      )),
    ]);
  }
}

class _HomeQuickActions extends StatelessWidget {
  final ValueChanged<int> onTap;
  const _HomeQuickActions({required this.onTap});
  @override Widget build(BuildContext context) {
    const items = [(HeroiconsOutline.squares2x2, 'Ҳамааш'), (HeroiconsOutline.creditCard, 'SmartPay'), (HeroiconsOutline.checkBadge, 'Исбот'), (HeroiconsOutline.questionMarkCircle, 'Чӣ тавр?')];
    return SizedBox(height: 104, child: Row(children: List.generate(items.length, (i) => Expanded(child: InkWell(
      onTap: () => onTap(i == 0 ? 0 : i == 1 ? 1 : i == 2 ? 2 : 3),
      borderRadius: BorderRadius.circular(18),
      child: Column(children: [
        Container(width: 62, height: 62, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF10231E), border: Border.all(color: const Color(0xFF4D9B7C), width: 2), boxShadow: [BoxShadow(color: const Color(0xFF4D9B7C).withOpacity(.16), blurRadius: 13)]), child: Icon(items[i].$1, color: const Color(0xFFB8D9C9), size: 29)),
        const SizedBox(height: 7), Text(items[i].$2, maxLines: 1, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
      ]),
    )))));
  }
}

class _FreeFireHero extends StatelessWidget {
  final VoidCallback onTap;
  const _FreeFireHero({required this.onTap});
  @override Widget build(BuildContext context) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(25),
    child: Container(
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(.17)),
        image: const DecorationImage(image: AssetImage('assets/logo/Banner_Free_Fire.png'), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Color(0x77000000), BlendMode.darken)),
        boxShadow: [BoxShadow(color: green.withOpacity(.07), blurRadius: 20)],
      ),
      child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Spacer(),
        Row(children: [
          SizedBox(width: 48, height: 48, child: Image.asset('assets/logo/Free_Fire.png', fit: BoxFit.contain)),
          const SizedBox(width: 12),
          const Expanded(child: Text('Free Fire СНГ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
        ]),
        const SizedBox(height: 10),
        const Text('Алмос ба ID  •  1–5 дақиқа', style: TextStyle(color: Colors.white70, fontSize: 12)),
        const Spacer(),
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8), decoration: BoxDecoration(color: Colors.black.withOpacity(.42), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white24)), child: const Text('аз 8,71 TJS', style: TextStyle(fontWeight: FontWeight.w800))),
          const SizedBox(width: 9),
          Container(padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 9), decoration: BoxDecoration(color: const Color(0xFF4D9B7C), borderRadius: BorderRadius.circular(30)), child: const Text('Харидан', style: TextStyle(fontWeight: FontWeight.w900))),
        ]),
      ])),
    ),
  );
}

class _VipBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _VipBanner({required this.onTap});
  @override Widget build(BuildContext context) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Color(0xFF0B2B26), Color(0xFF155D4A), Color(0xFF10231E)]),
        border: Border.all(color: Colors.white.withOpacity(.12)),
      ),
      child: const Row(children: [
        Text('🎁', style: TextStyle(fontSize: 33)),
        SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Барои Free Fire харед —', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
          Text('танзими VIP тӯҳфа', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
          SizedBox(height: 4), Text('Танзимоти махсус барои телефони шумо', style: TextStyle(color: Colors.white70, fontSize: 10)),
        ])),
        Icon(Icons.arrow_forward_rounded, color: Colors.white),
      ]),
    ),
  );
}

class _HomeBenefits extends StatelessWidget {
  const _HomeBenefits();
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Чаро мо?', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
    const SizedBox(height: 11),
    Row(children: const [
      Expanded(child: _BenefitTile(icon: Icons.rocket_launch_rounded, title: 'Тез', sub: '1–5 дақиқа, худкор')),
      SizedBox(width: 10),
      Expanded(child: _BenefitTile(icon: Icons.verified_user_rounded, title: 'Бехатар', sub: 'Танҳо ID, бе парол')),
    ]),
    const SizedBox(height: 10),
    Row(children: const [
      Expanded(child: _BenefitTile(icon: Icons.support_agent_rounded, title: '24/7', sub: 'Дастгирии доимӣ')),
      SizedBox(width: 10),
      Expanded(child: _BenefitTile(icon: Icons.workspace_premium_rounded, title: 'Кафолат', sub: 'Хизматрасонии боэътимод')),
    ]),
  ]);
}

class _BenefitTile extends StatelessWidget {
  final IconData icon; final String title, sub;
  const _BenefitTile({required this.icon, required this.title, required this.sub});
  @override Widget build(BuildContext context) => Container(
    height: 112, padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(color: const Color(0xFF10231E), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(.08))),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: const Color(0xFF4D9B7C), size: 29), const SizedBox(height: 6),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
      const SizedBox(height: 3), Text(sub, textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 9)),
    ]),
  );
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard();
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFF10231E), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(.08))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
      Text('★★★★★', style: TextStyle(color: Color(0xFFFFC928), fontSize: 17, letterSpacing: 2)),
      SizedBox(height: 9),
      Text('Фармоиш зуд иҷро шуд. Хизматрасонӣ хуб ва қулай аст.', style: TextStyle(fontSize: 13, height: 1.45)),
      SizedBox(height: 9), Text('Харидори TAJ DONATE', style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w700)),
    ]),
  );
}

class _NexaStep extends StatelessWidget {
  final String number, title, description;
  const _NexaStep({required this.number, required this.title, required this.description});
  @override Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFF10231E), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(.08))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(number, style: const TextStyle(color: green, fontSize: 12, fontWeight: FontWeight.w900)),
      const SizedBox(width: 13),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 5), Text(description, style: const TextStyle(color: muted, fontSize: 11, height: 1.45)),
      ])),
    ]),
  );
}
