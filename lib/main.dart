import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

const bg = Color(0xFF080808);
const surface = Color(0xFF151515);
const surface2 = Color(0xFF202020);
const orange = Color(0xFFFF6A00);
const amber = Color(0xFFFFB800);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: bg,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const AurixApp());
}

class AurixApp extends StatelessWidget {
  const AurixApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'AURIX',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(primary: orange, secondary: amber, surface: surface),
      useMaterial3: true,
      sliderTheme: const SliderThemeData(activeTrackColor: orange, thumbColor: orange, inactiveTrackColor: Colors.white12),
    ),
    home: const HomeScreen(),
  );
}

class ProjectMedia {
  ProjectMedia(this.file, this.isVideo);
  final XFile file;
  final bool isVideo;
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedTab = 0;
  @override
  Widget build(BuildContext context) {
    final pages = const [_HomeTab(), _TemplatesTab(), _LibraryTab(), _ProfileTab()];
    return Scaffold(
      body: IndexedStack(index: selectedTab, children: pages),
      bottomNavigationBar: NavigationBar(
        height: 68,
        backgroundColor: const Color(0xFF111111),
        indicatorColor: const Color(0x33FF6A00),
        selectedIndex: selectedTab,
        onDestinationSelected: (index) => setState(() => selectedTab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.dashboard_customize_outlined), selectedIcon: Icon(Icons.dashboard_customize_rounded), label: 'Templates'),
          NavigationDestination(icon: Icon(Icons.video_library_outlined), selectedIcon: Icon(Icons.video_library_rounded), label: 'Library'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();
  @override
  Widget build(BuildContext context) => const HomeContent();
}

class _TemplatesTab extends StatelessWidget {
  const _TemplatesTab();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Templates', style: TextStyle(fontWeight: FontWeight.w800))),
    body: ListView(padding: const EdgeInsets.all(18), children: const [
      Text('CREATIVE STARTING POINTS', style: TextStyle(color: orange, fontSize: 10, letterSpacing: 1.6, fontWeight: FontWeight.bold)),
      SizedBox(height: 12),
      _TemplateTile(icon: Icons.movie_filter_outlined, title: 'Cinematic', subtitle: 'Create a film-inspired project'),
      _TemplateTile(icon: Icons.sports_soccer_rounded, title: 'Sports edit', subtitle: 'A layout for match highlights'),
      _TemplateTile(icon: Icons.music_video_rounded, title: 'Music edit', subtitle: 'Build an edit around your soundtrack'),
      _TemplateTile(icon: Icons.smartphone_rounded, title: 'Reels & Shorts', subtitle: 'Vertical 9:16 project format'),
      SizedBox(height: 12),
      Text('These are project starters. Editable template packs will be added after the timeline and render engine are connected.', style: TextStyle(color: Colors.white54, fontSize: 12)),
    ]),
  );
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({required this.icon, required this.title, required this.subtitle});
  final IconData icon; final String title; final String subtitle;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
    child: Row(children: [Icon(icon, color: orange, size: 25), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11))])), const Icon(Icons.chevron_right, color: Colors.white38)]),
  );
}

class _LibraryTab extends StatelessWidget {
  const _LibraryTab();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Library', style: TextStyle(fontWeight: FontWeight.w800))),
    body: const Center(child: Padding(padding: EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.video_library_outlined, size: 48, color: Colors.white30),
      SizedBox(height: 14),
      Text('Your projects', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      SizedBox(height: 6),
      Text('Saved project persistence is not connected yet. Imported media currently opens directly in the editor.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12)),
    ]))),
  );
}

class _ProfileTab extends StatefulWidget {
  const _ProfileTab();
  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  String language = 'Тоҷикӣ';
  String displayName = 'AURIX Creator';

  void _message(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  Future<void> _chooseLanguage() async {
    final choice = await showModalBottomSheet<String>(context: context, backgroundColor: surface, builder: (context) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const ListTile(title: Text('App language', style: TextStyle(fontWeight: FontWeight.bold))),
      for (final item in ['Тоҷикӣ', 'Русский', 'English']) ListTile(title: Text(item), trailing: language == item ? const Icon(Icons.check, color: orange) : null, onTap: () => Navigator.pop(context, item)),
    ])));
    if (choice != null) setState(() => language = choice);
    if (choice != null && choice != 'Тоҷикӣ') _message('Language selection is saved for this session; full localization is still in progress.');
  }
  Future<void> _editName() async {
    final controller = TextEditingController(text: displayName);
    final value = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: const Text('Edit profile'),
      content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Display name')),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save'))],
    ));
    if (value != null && value.isNotEmpty) setState(() => displayName = value);
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profile & Settings', style: TextStyle(fontWeight: FontWeight.w800))),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF321707), surface]), borderRadius: BorderRadius.circular(18), border: Border.all(color: orange.withOpacity(.25))), child: Row(children: [
        const CircleAvatar(radius: 28, backgroundColor: orange, child: Icon(Icons.person, color: Colors.white, size: 30)),
        const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const Text('Local profile · Sign-in not connected', style: TextStyle(color: Colors.white60, fontSize: 11))])),
        IconButton(onPressed: _editName, icon: const Icon(Icons.edit_outlined, color: orange)),
      ])),
      const SizedBox(height: 22),
      const Text('ACCOUNT', style: TextStyle(color: orange, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5)),
      ListTile(leading: const Icon(Icons.person_outline), title: const Text('Edit profile'), onTap: _editName),
      ListTile(leading: const Icon(Icons.login_rounded), title: const Text('Continue with Google'), subtitle: const Text('Firebase Authentication setup required'), onTap: () => _message('Google sign-in is not active: Firebase project configuration and OAuth client IDs are missing.')),
      ListTile(leading: const Icon(Icons.notifications_none), title: const Text('Notifications'), onTap: () => _message('Notifications are not connected yet.')),
      ListTile(leading: const Icon(Icons.history), title: const Text('Editing history'), onTap: () => _message('Project history storage is not connected yet.')),
      const Divider(height: 26),
      const Text('APP SETTINGS', style: TextStyle(color: orange, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5)),
      ListTile(leading: const Icon(Icons.language), title: const Text('Language'), subtitle: Text(language), onTap: _chooseLanguage),
      ListTile(leading: const Icon(Icons.storage_outlined), title: const Text('Storage & cache'), subtitle: const Text('Cache manager not connected'), onTap: () => _message('There is no persistent media cache manager to clear yet.')),
      ListTile(leading: const Icon(Icons.share_outlined), title: const Text('Share AURIX'), onTap: () => _message('Share link will be available after the public app listing is created.')),
      ListTile(leading: const Icon(Icons.info_outline), title: const Text('About AURIX'), subtitle: const Text('Create beyond limits · Version 1.0.6')),
      const Divider(height: 26),
      ListTile(leading: const Icon(Icons.delete_outline, color: Colors.redAccent), title: const Text('Delete account', style: TextStyle(color: Colors.redAccent)), onTap: () => _message('Account deletion is unavailable until account registration and backend storage are implemented.')),
    ]),
  );
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});
  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final picker = ImagePicker();
  final List<ProjectMedia> recent = [];

  Future<void> importVideo() async {
    final file = await picker.pickVideo(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    openEditor([ProjectMedia(file, true)]);
  }

  Future<void> importPhoto() async {
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    openEditor([ProjectMedia(file, false)]);
  }

  void openEditor(List<ProjectMedia> media) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EditorScreen(initialMedia: media),
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: bg,
      titleSpacing: 18,
      title: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png', width: 42, height: 42, fit: BoxFit.cover)),
        const SizedBox(width: 11),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('AURIX', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2.4)),
          Text('VIDEO STUDIO', style: TextStyle(fontSize: 9, color: orange, letterSpacing: 2.7, fontWeight: FontWeight.bold)),
        ]),
      ]),
      actions: [
        IconButton(onPressed: () => showAboutDialog(context: context, applicationName: 'AURIX', applicationVersion: '1.0.4', applicationLegalese: 'Create beyond limits.'), icon: const Icon(Icons.info_outline_rounded)),
        const SizedBox(width: 6),
      ],
    ),
    body: SafeArea(child: ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
      children: [
        const Text('Your next edit.\nYour vision.', style: TextStyle(fontSize: 34, height: 1.05, fontWeight: FontWeight.w900, letterSpacing: -.8)),
        const SizedBox(height: 10),
        const Text('A focused workspace for cinematic video creation.', style: TextStyle(color: Colors.white60, fontSize: 14)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: orange.withOpacity(.32)),
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF351707), Color(0xFF1B100A), Color(0xFF151515)]),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(color: orange.withOpacity(.15), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.movie_creation_outlined, color: orange)),
              const Spacer(),
              const Text('CREATE  •  EDIT  •  EXPORT', style: TextStyle(color: Colors.white54, fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 23),
            const Text('Start a new project', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Bring your footage into the AURIX timeline.', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 19),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: importVideo,
              style: FilledButton.styleFrom(backgroundColor: orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              icon: const Icon(Icons.add_rounded), label: const Text('New video project', style: TextStyle(fontWeight: FontWeight.bold)),
            )),
            const SizedBox(height: 9),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              onPressed: importPhoto,
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              icon: const Icon(Icons.image_outlined), label: const Text('Start with a photo'),
            )),
          ]),
        ),
        const SizedBox(height: 29),
        const _SectionHeading('YOUR CREATIVE TOOLS', '01 / WORKSPACE'),
        const SizedBox(height: 13),
        const Row(children: [
          Expanded(child: _ToolCard(icon: Icons.speed_rounded, name: 'Speed control', detail: 'Smooth playback speed')),
          SizedBox(width: 10),
          Expanded(child: _ToolCard(icon: Icons.graphic_eq_rounded, name: 'Audio tools', detail: 'Volume and sound')),
        ]),
        const SizedBox(height: 10),
        const Row(children: [
          Expanded(child: _ToolCard(icon: Icons.auto_awesome_rounded, name: 'Visual effects', detail: 'Effects engine planned')),
          SizedBox(width: 10),
          Expanded(child: _ToolCard(icon: Icons.tune_rounded, name: 'Color studio', detail: 'Color tools planned')),
        ]),
        const SizedBox(height: 27),
        const _SectionHeading('RECENT PROJECTS', '02 / LIBRARY'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white10)),
          child: const Row(children: [
            Icon(Icons.video_library_outlined, color: Colors.white38, size: 25),
            SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('No projects yet', style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 3),
              Text('Your saved editing projects will appear here.', style: TextStyle(color: Colors.white38, fontSize: 12)),
            ])),
          ]),
        ),
        const SizedBox(height: 20),
        const Center(child: Text('AURIX  •  CREATE BEYOND LIMITS', style: TextStyle(color: Colors.white24, fontSize: 9, letterSpacing: 2))),
      ],
    )),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title, this.kicker);
  final String title;
  final String kicker;
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.3)),
    const Spacer(),
    Text(kicker, style: const TextStyle(color: Colors.white30, fontSize: 9, letterSpacing: 1)),
  ]);
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.icon, required this.name, required this.detail});
  final IconData icon;
  final String name;
  final String detail;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(17), border: Border.all(color: Colors.white10)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: orange, size: 22),
      const SizedBox(height: 13),
      Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(detail, style: const TextStyle(fontSize: 10, color: Colors.white38)),
    ]),
  );
}

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.initialMedia});
  final List<ProjectMedia> initialMedia;
  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final picker = ImagePicker();
  late final List<ProjectMedia> clips;
  VideoPlayerController? video;
  int selected = 0;
  bool loading = false;
  double speed = 1;
  double volume = 1;
  String activePanel = 'Speed';
  String overlayText = '';
  int filterIndex = 0;
  double trimStart = 0;
  double trimEnd = 1;
  static const List<List<double>> _filters = [
    [1,0,0,0,0, 0,1,0,0,0, 0,0,1,0,0, 0,0,0,1,0],
    [1.15,0,0,0,8, 0,1.05,0,0,4, 0,0,0.9,0,0, 0,0,0,1,0],
    [0.75,0,0,0,22, 0,0.82,0,0,18, 0,0,0.95,0,10, 0,0,0,1,0],
    [0.9,0,0,0,0, 0,0.95,0,0,0, 0,0,1.2,0,0, 0,0,0,1,0],
    [0.3,0,0,0,0, 0,0.3,0,0,0, 0,0,0.3,0,0, 0,0,0,1,0],
  ];

  @override
  void initState() {
    super.initState();
    clips = [...widget.initialMedia];
    _loadSelected();
  }

  @override
  void dispose() {
    video?.dispose();
    super.dispose();
  }

  Future<void> _loadSelected() async {
    if (clips.isEmpty) return;
    final old = video;
    video = null;
    await old?.dispose();
    if (!clips[selected].isVideo) { if (mounted) setState(() {}); return; }
    setState(() => loading = true);
    final next = VideoPlayerController.file(File(clips[selected].file.path));
    try {
      await next.initialize();
      await next.setLooping(true);
      await next.setPlaybackSpeed(speed);
      await next.setVolume(volume);
      if (!mounted) { await next.dispose(); return; }
      setState(() { video = next; loading = false; });
    } catch (_) {
      await next.dispose();
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _addVideo() async {
    final file = await picker.pickVideo(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    setState(() { clips.add(ProjectMedia(file, true)); selected = clips.length - 1; });
    await _loadSelected();
  }

  Future<void> _addPhoto() async {
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    setState(() { clips.add(ProjectMedia(file, false)); selected = clips.length - 1; });
    await _loadSelected();
  }

  Future<void> _remove() async {
    if (clips.isEmpty) return;
    final old = video; video = null; await old?.dispose();
    setState(() { clips.removeAt(selected); selected = clips.isEmpty ? 0 : selected.clamp(0, clips.length - 1).toInt(); });
    if (clips.isNotEmpty) await _loadSelected();
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _cycleFilter() {
    setState(() => filterIndex = (filterIndex + 1) % _filters.length);
    _message(['Original', 'Cinematic', 'Warm', 'Cool', 'Mono'][filterIndex] + ' preview filter selected.');
  }

  Future<void> _addText() async {
    final input = TextEditingController(text: overlayText);
    final value = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: const Text('Add text layer'),
      content: TextField(controller: input, autofocus: true, maxLines: 3, decoration: const InputDecoration(hintText: 'Write your title or caption')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, ''), child: const Text('Remove')),
        FilledButton(onPressed: () => Navigator.pop(context, input.text.trim()), child: const Text('Apply')),
      ],
    ));
    if (value != null && mounted) setState(() => overlayText = value);
  }

  String _time(Duration d) => '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final current = clips[selected];
    final controller = video;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('AURIX EDITOR', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          Text('Untitled project', style: TextStyle(fontSize: 10, color: Colors.white38)),
        ]),
        actions: [
          Container(margin: const EdgeInsets.only(right: 12, top: 10, bottom: 10), child: OutlinedButton(
            onPressed: null,
            style: OutlinedButton.styleFrom(disabledForegroundColor: Colors.white38, side: const BorderSide(color: Colors.white12), padding: const EdgeInsets.symmetric(horizontal: 13)),
            child: const Text('EXPORT'),
          )),
        ],
      ),
      body: SafeArea(child: Column(children: [
        Expanded(flex: 5, child: Container(
          margin: const EdgeInsets.fromLTRB(14, 2, 14, 8),
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
          clipBehavior: Clip.antiAlias,
          child: Stack(alignment: Alignment.center, children: [
            Positioned(top: 10, left: 12, child: _PreviewTag(text: current.isVideo ? 'VIDEO PREVIEW' : 'IMAGE PREVIEW')),
            if (loading) const CircularProgressIndicator(color: orange)
            else if (current.isVideo && controller != null && controller.value.isInitialized)
              Center(child: ColorFiltered(
                colorFilter: ColorFilter.matrix(_filters[filterIndex]),
                child: AspectRatio(aspectRatio: controller.value.aspectRatio, child: VideoPlayer(controller)),
              ))
            else if (!current.isVideo)
              Center(child: ColorFiltered(colorFilter: ColorFilter.matrix(_filters[filterIndex]), child: Image.file(File(current.file.path), fit: BoxFit.contain)))
            else
              const Center(child: Text('Preview unavailable', style: TextStyle(color: Colors.white54))),
            if (overlayText.isNotEmpty)
              Positioned(left: 20, right: 20, top: 0, bottom: 0, child: Center(child: Text(overlayText, textAlign: TextAlign.center, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 12, offset: Offset(1, 2))])))),
            if (current.isVideo && controller != null && controller.value.isInitialized)
              IconButton.filled(
                onPressed: () async { if (controller.value.isPlaying) { await controller.pause(); } else { await controller.play(); } setState(() {}); },
                style: IconButton.styleFrom(backgroundColor: Colors.black.withOpacity(.6), foregroundColor: Colors.white, fixedSize: const Size(58, 58)),
                icon: Icon(controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 30),
              ),
            Positioned(bottom: 12, left: 14, right: 14, child: Row(children: [
              Text(controller?.value.isInitialized == true ? _time(controller!.value.position) : '00:00', style: const TextStyle(fontSize: 10, color: Colors.white70)),
              const Spacer(),
              Text(controller?.value.isInitialized == true ? _time(controller!.value.duration) : '--:--', style: const TextStyle(fontSize: 10, color: Colors.white70)),
            ])),
          ]),
        )),
        if (controller != null && controller.value.isInitialized)
          Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: VideoProgressIndicator(controller, allowScrubbing: true, colors: const VideoProgressColors(playedColor: orange, bufferedColor: Colors.white24, backgroundColor: Colors.white12))),
        Container(
          height: 196,
          margin: const EdgeInsets.fromLTRB(12, 9, 12, 0),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 9),
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white10)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('TIMELINE', style: TextStyle(fontSize: 10, color: Colors.white60, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              const Spacer(),
              IconButton(onPressed: _addVideo, icon: const Icon(Icons.video_call_outlined, size: 20)),
              IconButton(onPressed: _addPhoto, icon: const Icon(Icons.add_photo_alternate_outlined, size: 19)),
              IconButton(onPressed: _remove, icon: const Icon(Icons.delete_outline_rounded, size: 19)),
            ]),
            const SizedBox(height: 4),
            Expanded(child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: clips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (context, index) {
                final item = clips[index];
                return GestureDetector(
                  onTap: () async { setState(() { selected = index; speed = 1; volume = 1; }); await _loadSelected(); },
                  child: Container(
                    width: 108,
                    decoration: BoxDecoration(color: surface2, borderRadius: BorderRadius.circular(10), border: Border.all(color: selected == index ? orange : Colors.white12, width: selected == index ? 2 : 1)),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(fit: StackFit.expand, children: [
                      if (!item.isVideo) Image.file(File(item.file.path), fit: BoxFit.cover),
                      if (item.isVideo) const Center(child: Icon(Icons.movie_outlined, size: 26, color: Colors.white70)),
                      Positioned(left: 6, bottom: 6, child: Text(item.isVideo ? 'VIDEO ${index + 1}' : 'PHOTO ${index + 1}', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold))),
                      if (selected == index) const Positioned(right: 5, top: 5, child: Icon(Icons.check_circle, color: orange, size: 16)),
                    ]),
                  ),
                );
              },
            )),
          ]),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(12, 9, 12, 0),
          padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white10)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _PanelTab(label: 'Speed', selected: activePanel == 'Speed', onTap: () => setState(() => activePanel = 'Speed')),
              _PanelTab(label: 'Volume', selected: activePanel == 'Volume', onTap: () => setState(() => activePanel = 'Volume')),
              _PanelTab(label: 'Trim', selected: activePanel == 'Trim', onTap: () => setState(() => activePanel = 'Trim')),
              const Spacer(),
              Text(activePanel == 'Speed' ? '${speed.toStringAsFixed(2)}×' : activePanel == 'Volume' ? '${(volume * 100).round()}%' : 'IN / OUT', style: const TextStyle(color: orange, fontWeight: FontWeight.bold, fontSize: 12)),
            ]),
            const SizedBox(height: 8),
            if (activePanel == 'Speed')
              Slider(value: speed, min: .25, max: 2, divisions: 35, onChanged: controller == null ? null : (v) async { setState(() => speed = v); await controller.setPlaybackSpeed(v); })
            else if (activePanel == 'Volume')
              Slider(value: volume, min: 0, max: 1, divisions: 20, onChanged: controller == null ? null : (v) async { setState(() => volume = v); await controller.setVolume(v); })
            else
              Column(children: [
                RangeSlider(values: RangeValues(trimStart, trimEnd), min: 0, max: 1, divisions: 100, labels: RangeLabels('${(trimStart * 100).round()}%', '${(trimEnd * 100).round()}%'), onChanged: controller == null ? null : (v) => setState(() { trimStart = v.start; trimEnd = v.end; })),
                SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: controller == null ? null : () async { final d = controller.value.duration; await controller.seekTo(Duration(milliseconds: (d.inMilliseconds * trimStart).round())); _message('Trim points selected for preview. Export rendering is not connected yet.'); }, icon: const Icon(Icons.play_arrow), label: const Text('Preview from IN point'))),
              ]),
            if (activePanel != 'Trim') Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(activePanel == 'Speed' ? '0.25×' : 'Mute', style: const TextStyle(color: Colors.white38, fontSize: 9)),
              Text(activePanel == 'Speed' ? '2.00×' : '100%', style: const TextStyle(color: Colors.white38, fontSize: 9)),
            ]),
          ]),
        ),
        Container(
          height: 76,
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _EditorAction(icon: Icons.content_cut_rounded, label: 'Trim', onTap: () => setState(() => activePanel = 'Trim')),
            _EditorAction(icon: Icons.auto_awesome_rounded, label: 'Effects', onTap: _cycleFilter),
            _EditorAction(icon: Icons.title_rounded, label: 'Text', onTap: _addText),
            _EditorAction(icon: Icons.graphic_eq_rounded, label: 'Audio', onTap: () => setState(() => activePanel = 'Volume')),
            _EditorAction(icon: Icons.palette_outlined, label: 'Color', onTap: _cycleFilter),
          ]),
        ),
      ])),
    );
  }
}

class _PreviewTag extends StatelessWidget {
  const _PreviewTag({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)), child: Text(text, style: const TextStyle(fontSize: 8, color: Colors.white70, letterSpacing: 1)));
}

class _PanelTab extends StatelessWidget {
  const _PanelTab({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(right: 7), child: TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(backgroundColor: selected ? orange.withOpacity(.16) : Colors.transparent, foregroundColor: selected ? orange : Colors.white54, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
    child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
  ));
}

class _EditorAction extends StatelessWidget {
  const _EditorAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: onTap,
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 21, color: orange),
      const SizedBox(height: 5),
      Text(label, style: const TextStyle(fontSize: 9, color: Colors.white70)),
    ])),
  );
}
