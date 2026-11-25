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
    context: context,
    backgroundColor: const Color(0xFF10231E),
    showDragHandle: true,
    builder: (sheet) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const ListTile(title: Text('TAJ DONATE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1))),
      ListTile(leading: const Icon(HeroiconsOutline.squares2x2, color: green), title: const Text('Ҳамаи бозиҳо'), onTap: () { Navigator.pop(sheet); Navigator.push(context, MaterialPageRoute(builder: (_) => const GamesPage())); }),
      ListTile(leading: const Icon(HeroiconsOutline.documentText, color: green), title: const Text('Фармоишҳо'), onTap: () { Navigator.pop(sheet); Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersPage())); }),
      ListTile(leading: const Icon(HeroiconsOutline.bell, color: green), title: const Text('Огоҳиномаҳо'), onTap: () { Navigator.pop(sheet); Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage())); }),
      ListTile(leading: const Icon(HeroiconsOutline.user, color: green), title: const Text('Профил'), onTap: () { Navigator.pop(sheet); Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())); }),
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
          borderRadius: BorderRadius.circular(28),
          child: _GlassSurface(
            radius: 28,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Text('0 TJS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
              SizedBox(width: 8),
              Icon(HeroiconsOutline.plusCircle, color: green, size: 22),
            ]),
          ),
        ),
        const SizedBox(width: 5),
        _GlassHeaderIcon(icon: almazLightMode.value ? HeroiconsOutline.moon : HeroiconsOutline.sun, tooltip: 'Тағйири мавзӯъ', onTap: _toggleTheme),
        _GlassHeaderIcon(icon: HeroiconsOutline.bell, tooltip: 'Огоҳиномаҳо', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage())), showDot: true),
        _GlassHeaderIcon(icon: HeroiconsOutline.ellipsisHorizontal, tooltip: 'Меню', onTap: () => _menu(context)),
      ],
    ]),
  );
}

class _GlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  const _GlassSurface({required this.child, this.padding = EdgeInsets.zero, this.radius = 18});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: const Color(0xFF173A30).withOpacity(.52),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.white.withOpacity(.17)),
          boxShadow: [BoxShadow(color: surface.withOpacity(.28), blurRadius: 18, offset: const Offset(0, 5))],
        ),
        child: child,
      ),
    ),
  );
}

class _GlassHeaderIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool showDot;
  const _GlassHeaderIcon({required this.icon, required this.tooltip, required this.onTap, this.showDot = false});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 38, height: 42,
    child: Stack(alignment: Alignment.center, children: [
      Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: _GlassSurface(radius: 14, padding: const EdgeInsets.all(8), child: Icon(icon, size: 20, color: Colors.white.withOpacity(.94))),
        ),
      ),
      if (showDot) Positioned(right: 7, top: 6, child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: green, shape: BoxShape.circle))),
    ]),
  );
}

class AlmazMark extends StatelessWidget {
  final double size;
  const AlmazMark({super.key, this.size = 54});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      color: const Color(0xFF07110D),
      borderRadius: BorderRadius.circular(size * .24),
      boxShadow: [BoxShadow(color: green.withOpacity(.14), blurRadius: 14)],
    ),
    clipBehavior: Clip.antiAlias,
    child: Image.asset('assets/logo/ic_launcher.png', fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Center(child: Text('TD', style: TextStyle(color: green, fontSize: size * .35, fontWeight: FontWeight.w900)))),
  );
}
