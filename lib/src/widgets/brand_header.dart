part of '../../main.dart';

class BrandHeader extends StatelessWidget {
  final bool showActions;
  const BrandHeader({super.key, this.showActions = true});

  Future<void> _toggleTheme() async {
    almazLightMode.value = !almazLightMode.value;
    final p = await SharedPreferences.getInstance();
    await p.setBool('almaz_light_mode', almazLightMode.value);
  }

  void _menu(BuildContext context) => showModalBottomSheet<void>(
    context: context, backgroundColor: const Color(0xFF101A16), showDragHandle: true,
    builder: (sheet) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const ListTile(title: Text('TAJ DONATE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1))),
      ListTile(leading: const Icon(Icons.sports_esports_rounded, color: green), title: const Text('Ҳамаи бозиҳо'), onTap: () { Navigator.pop(sheet); Navigator.push(context, MaterialPageRoute(builder: (_) => const GamesPage())); }),
      ListTile(leading: const Icon(Icons.receipt_long_rounded, color: green), title: const Text('Фармоишҳо'), onTap: () { Navigator.pop(sheet); Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersPage())); }),
      ListTile(leading: const Icon(Icons.support_agent_rounded, color: green), title: const Text('Дастгирӣ'), onTap: () { Navigator.pop(sheet); Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())); }),
      const SizedBox(height: 8),
    ])),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 12, 14),
    child: Row(children: [
      const AlmazMark(size: 43),
      const SizedBox(width: 10),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TAJ DONATE', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -.3)),
        SizedBox(height: 2),
        Row(children: [Icon(Icons.circle, color: green, size: 7), SizedBox(width: 5), Text('ONLINE • TJ', style: TextStyle(color: muted, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: .6))]),
      ])),
      if (showActions) ...[
        InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletPage())),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(color: const Color(0xFF151D1A), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white.withOpacity(.14))),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Text('0 TJS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
              SizedBox(width: 7),
              Icon(Icons.add_circle, color: Color(0xFF168BFF), size: 23),
            ]),
          ),
        ),
        const SizedBox(width: 6),
        _NexaHeaderIcon(icon: almazLightMode.value ? Icons.dark_mode_outlined : Icons.light_mode_outlined, tooltip: 'Тағйири мавзӯъ', onTap: _toggleTheme),
        _NexaHeaderIcon(icon: Icons.notifications_none_rounded, tooltip: 'Огоҳиномаҳо', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersPage()))),
        _NexaHeaderIcon(icon: Icons.menu_rounded, tooltip: 'Меню', onTap: () => _menu(context)),
      ],
    ]),
  );
}

class _NexaHeaderIcon extends StatelessWidget {
  final IconData icon; final String tooltip; final VoidCallback onTap;
  const _NexaHeaderIcon({required this.icon, required this.tooltip, required this.onTap});
  @override Widget build(BuildContext context) => SizedBox(width: 34, height: 40, child: IconButton(
    tooltip: tooltip, padding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
    onPressed: onTap, icon: Icon(icon, size: 20, color: Colors.white.withOpacity(.90)),
  ));
}

class AlmazMark extends StatelessWidget {
  final double size;
  const AlmazMark({super.key, this.size = 54});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      color: const Color(0xFF07110D), borderRadius: BorderRadius.circular(size * .24),
      border: Border.all(color: green.withOpacity(.65)),
      boxShadow: [BoxShadow(color: green.withOpacity(.14), blurRadius: 14)],
    ),
    clipBehavior: Clip.antiAlias,
    child: Image.asset('assets/logo/ic_launcher.png', fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Center(child: Text('TD', style: TextStyle(color: green, fontSize: size * .35, fontWeight: FontWeight.w900)))),
  );
}
