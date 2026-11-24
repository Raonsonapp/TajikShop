part of '../../main.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String displayName = 'Меҳмон';
  bool notifications = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      displayName = p.getString('almaz_display_name') ?? 'Меҳмон';
      notifications = p.getBool('almaz_notifications') ?? true;
      almazLightMode.value = p.getBool('almaz_light_mode') ?? false;
      almazLanguage.value = p.getString('almaz_language') ?? 'tg';
    });
  }
  Future<void> _editName() async {
    final controller = TextEditingController(text: displayName == 'Меҳмон' ? '' : displayName);
    final value = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Маълумоти шахсӣ'),
      content: TextField(controller: controller, autofocus: true, maxLength: 40, decoration: const InputDecoration(labelText: 'Номи шумо')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Бекор')),
        FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Нигоҳ доштан')),
      ],
    ));
    if (value == null || value.isEmpty) return;
    final p = await SharedPreferences.getInstance();
    await p.setString('almaz_display_name', value);
    if (mounted) setState(() => displayName = value);
  }
  Future<void> _toggleTheme() async {
    final next = !almazLightMode.value;
    almazLightMode.value = next;
    final p = await SharedPreferences.getInstance();
    await p.setBool('almaz_light_mode', next);
    if (mounted) setState(() {});
  }
  Future<void> _chooseLanguage() async {
    final selected = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: Text(tr('Забон')),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(title: const Text('Тоҷикӣ'), trailing: almazLanguage.value == 'tg' ? const Icon(Icons.check,color:green) : null, onTap: () => Navigator.pop(ctx,'tg')),
        ListTile(title: const Text('Русский'), trailing: almazLanguage.value == 'ru' ? const Icon(Icons.check,color:green) : null, onTap: () => Navigator.pop(ctx,'ru')),
        ListTile(title: const Text('O‘zbekcha'), trailing: almazLanguage.value == 'uz' ? const Icon(Icons.check,color:green) : null, onTap: () => Navigator.pop(ctx,'uz')),
      ]),
    ));
    if (selected == null) return;
    final p = await SharedPreferences.getInstance();
    await p.setString('almaz_language', selected);
    almazLanguage.value = selected;
    if (mounted) setState(() {});
  }
  Future<void> _leaveReview() async {
    final controller=TextEditingController();
    int rating=5;
    final result=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setDialog)=>AlertDialog(
      title:const Text('Отзив гузоштан'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        const Text('Ба TAJ DONATE чанд ситора медиҳӣ?'),
        const SizedBox(height:10),
        Row(mainAxisAlignment:MainAxisAlignment.center,children:List.generate(5,(i)=>IconButton(
          onPressed:()=>setDialog(()=>rating=i+1),
          icon:Icon(i<rating?Icons.star_rounded:Icons.star_outline_rounded,color:green,size:28),
        ))),
        TextField(controller:controller,maxLines:3,maxLength:500,decoration:const InputDecoration(hintText:'Назари худро нависед...',border:OutlineInputBorder())),
      ]),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Бекор')),
        FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Нигоҳ доштан')),
      ],
    )));
    if(result!=true||controller.text.trim().isEmpty){controller.dispose();return;}
    final prefs=await SharedPreferences.getInstance();
    final list=prefs.getStringList('taj_donate_reviews')??<String>[];
    list.insert(0,jsonEncode({'rating':rating,'text':controller.text.trim(),'created_at':DateTime.now().toIso8601String()}));
    await prefs.setStringList('taj_donate_reviews',list);
    controller.dispose();
    if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Отзив дар телефон нигоҳ дошта шуд. Барои фиристодан ба сервер API лозим аст.')));
  }
  Future<void> _toggleNotifications(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('almaz_notifications', value);
    if (mounted) setState(() => notifications = value);
  }
  void _info(String title, String body) => showDialog<void>(context: context, builder: (ctx) => AlertDialog(
    title: Text(title), content: Text(body),
    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Фаҳмо'))],
  ));
  @override
  Widget build(BuildContext context) => PageShell(
    title: tr('Профил'), subtitle: 'Ҳисоб ва танзимот',
    child: ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: almazLightMode.value ? const LinearGradient(colors: [Color(0xFFF0F4F1), Color(0xFFE1E9E4)]) : const LinearGradient(colors: [Color(0xFF1B1E21), Color(0xFF252A2E)]),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: green.withOpacity(.35)),
        ),
        child: Row(children: [
          const AlmazMark(size: 58), const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(displayName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const Text('Профили TAJ DONATE', style: TextStyle(color: Colors.white70, fontSize: 11)),
          ])),
          IconButton(onPressed: _editName, icon: const Icon(Icons.edit_outlined, color: green)),
        ]),
      ),
      const SizedBox(height: 16),
      const SectionTitle('ҲИСОБ', ''),
      const SizedBox(height: 8),
      ProfileRow(icon: Icons.person_outline, title: 'Маълумоти шахсӣ', onTap: _editName),
      ProfileRow(icon: Icons.login_rounded, title: 'Воридшавӣ / Сабти ном', onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthPage()));
      }),
      ProfileRow(icon: Icons.receipt_long_outlined, title: 'Таърихи фармоишҳо', onTap: () => _info('Фармоишҳо', 'Қисми «Фармоиш» аз менюи поён дастрас аст.')),
      const SizedBox(height: 12),
      const SectionTitle('ТАНЗИМОТ', ''),
      const SizedBox(height: 8),
      ProfileRow(icon: almazLightMode.value ? Icons.light_mode_outlined : Icons.dark_mode_outlined, title: almazLightMode.value ? tr('Мавзӯи торик') : tr('Мавзӯи равшан'), onTap: _toggleTheme),
      ProfileRow(icon: Icons.language_rounded, title: '${tr('Забон')}: ${almazLanguage.value.toUpperCase()}', onTap: _chooseLanguage),
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14)),
        child: SwitchListTile(
          secondary: const Icon(Icons.notifications_active_outlined, color: green),
          title: Text(tr('Огоҳиномаҳо'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          value: notifications, activeColor: green, onChanged: _toggleNotifications,
        ),
      ),
      const SizedBox(height: 12),
      const SectionTitle('ДАСТГИРӢ', ''),
      const SizedBox(height: 8),
      ProfileRow(icon: Icons.support_agent, title: 'Дастгирии Telegram', onTap: () => _info('Telegram дастгирӣ', 'Линки расмии Telegram-и дастгириро илова кардан лозим аст.')),
      ProfileRow(icon: Icons.star_outline_rounded, title: 'Отзив гузоштан', onTap: _leaveReview),
      ProfileRow(icon: Icons.privacy_tip_outlined, title: 'Махфият', onTap: () => _info('Махфият', 'Сиёсати махфият аз сервер дастрас мешавад.')),
      ProfileRow(icon: Icons.info_outline, title: 'Дар бораи TAJ DONATE', onTap: () => _info('TAJ DONATE', 'Платформаи хизматрасониҳои рақамии бозӣ.')),
    ]),
  );
}
