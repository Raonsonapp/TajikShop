import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

const _bg = Color(0xFF090909);
const _panel = Color(0xFF171717);
const _panel2 = Color(0xFF222222);
const _orange = Color(0xFFFF6A00);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: _bg,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: _bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const VeloraApp());
}

class VeloraApp extends StatelessWidget {
  const VeloraApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'VELORA EDITOR',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: _bg,
          colorScheme: const ColorScheme.dark(
            primary: _orange,
            secondary: _orange,
            surface: _panel,
          ),
          fontFamily: 'Roboto',
          useMaterial3: true,
        ),
        home: const EditorHome(),
      );
}

class MediaClip {
  MediaClip(this.file, this.isVideo);
  final XFile file;
  final bool isVideo;
}

class EditorHome extends StatefulWidget {
  const EditorHome({super.key});

  @override
  State<EditorHome> createState() => _EditorHomeState();
}

class _EditorHomeState extends State<EditorHome> {
  final _picker = ImagePicker();
  final List<MediaClip> _clips = [];
  VideoPlayerController? _video;
  int _selected = 0;
  bool _busy = false;

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file != null) await _addClip(MediaClip(file, true));
  }

  Future<void> _pickPhoto() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) await _addClip(MediaClip(file, false));
  }

  Future<void> _addClip(MediaClip clip) async {
    setState(() {
      _clips.add(clip);
      _selected = _clips.length - 1;
    });
    await _loadPreview();
  }

  Future<void> _loadPreview() async {
    final clip = _clips[_selected];
    final old = _video;
    _video = null;
    await old?.dispose();
    if (!clip.isVideo) {
      if (mounted) setState(() {});
      return;
    }
    setState(() => _busy = true);
    final controller = VideoPlayerController.file(File(clip.file.path));
    try {
      await controller.initialize();
      await controller.setLooping(true);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _video = controller;
        _busy = false;
      });
    } catch (_) {
      await controller.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeSelected() async {
    if (_clips.isEmpty) return;
    final old = _video;
    _video = null;
    await old?.dispose();
    setState(() {
      _clips.removeAt(_selected);
      _selected = _clips.isEmpty ? 0 : (_selected.clamp(0, _clips.length - 1).toInt());
    });
    if (_clips.isNotEmpty) await _loadPreview();
  }

  String _durationLabel(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final hasMedia = _clips.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _bg,
        titleSpacing: 18,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('VELORA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2)),
            Text('EDITOR', style: TextStyle(fontSize: 10, color: _orange, letterSpacing: 4, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => _showInfo('Settings', 'Project settings and export presets will be added in the next development phase.'),
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: hasMedia ? _editorBody() : _dashboard(),
      ),
    );
  }

  Widget _dashboard() => ListView(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
        children: [
          const Text('Create beyond limits.', style: TextStyle(fontSize: 29, height: 1.1, fontWeight: FontWeight.w900)),
          const SizedBox(height: 9),
          const Text('Your creative studio, right in your pocket.', style: TextStyle(color: Colors.white60, fontSize: 14)),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3A1908), Color(0xFF17100C), Color(0xFF171717)],
              ),
              border: Border.all(color: _orange.withOpacity(.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.movie_creation_outlined, color: _orange, size: 34),
                const SizedBox(height: 22),
                const Text('Start a new project', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 7),
                const Text('Import a video or photo to begin editing.', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.add),
                    label: const Text('New video project', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Import photo'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text('TOOLS', style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(child: _ToolTile(icon: Icons.speed_rounded, title: 'Speed ramp', subtitle: 'Coming next')),
              SizedBox(width: 10),
              Expanded(child: _ToolTile(icon: Icons.auto_awesome, title: 'Effects', subtitle: 'Coming next')),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(child: _ToolTile(icon: Icons.color_lens_outlined, title: 'Color grade', subtitle: 'Coming next')),
              SizedBox(width: 10),
              Expanded(child: _ToolTile(icon: Icons.graphic_eq, title: 'Audio', subtitle: 'Coming next')),
            ],
          ),
          const SizedBox(height: 24),
          const Text('RECENT PROJECTS', style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('Your projects will appear here.', style: TextStyle(color: Colors.white38)),
        ],
      );

  Widget _editorBody() {
    final clip = _clips[_selected];
    final controller = _video;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Row(
            children: [
              IconButton(onPressed: () => setState(() { _clips.clear(); _video?.dispose(); _video = null; }), icon: const Icon(Icons.arrow_back)),
              const Expanded(child: Text('Untitled project', style: TextStyle(fontWeight: FontWeight.bold))),
              TextButton(onPressed: () => _showInfo('Export', 'Export rendering is being implemented. No video has been exported yet.'), child: const Text('Export', style: TextStyle(color: _orange, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        Expanded(
          flex: 5,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: Center(
              child: _busy
                  ? const CircularProgressIndicator(color: _orange)
                  : clip.isVideo
                      ? (controller != null && controller.value.isInitialized
                          ? AspectRatio(
                              aspectRatio: controller.value.aspectRatio,
                              child: Stack(alignment: Alignment.center, children: [
                                VideoPlayer(controller),
                                IconButton.filled(
                                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                                  onPressed: () => setState(() => controller.value.isPlaying ? controller.pause() : controller.play()),
                                  icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow, size: 34),
                                ),
                              ]),
                            )
                          : const Text('Could not load this video', style: TextStyle(color: Colors.white70)))
                      : Image.file(File(clip.file.path), fit: BoxFit.contain),
            ),
          ),
        ),
        if (controller != null && controller.value.isInitialized)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 2),
            child: Row(
              children: [
                Text(_durationLabel(controller.value.position), style: const TextStyle(fontFeatures: [])),
                Expanded(child: VideoProgressIndicator(controller, allowScrubbing: true, colors: const VideoProgressColors(playedColor: _orange, bufferedColor: Colors.white24, backgroundColor: Colors.white12))),
                Text(_durationLabel(controller.value.duration)),
              ],
            ),
          ),
        const SizedBox(height: 10),
        Container(
          height: 178,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          decoration: const BoxDecoration(color: _panel, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Text('TIMELINE', style: TextStyle(fontSize: 11, color: Colors.white60, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(onPressed: _pickVideo, icon: const Icon(Icons.video_library_outlined, size: 20)),
                IconButton(onPressed: _pickPhoto, icon: const Icon(Icons.add_photo_alternate_outlined, size: 20)),
                IconButton(onPressed: _removeSelected, icon: const Icon(Icons.delete_outline, size: 20, color: Colors.white70)),
              ]),
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _clips.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final item = _clips[i];
                    return GestureDetector(
                      onTap: () async { setState(() => _selected = i); await _loadPreview(); },
                      child: Container(
                        width: 112,
                        decoration: BoxDecoration(
                          color: _panel2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: i == _selected ? _orange : Colors.white12, width: i == _selected ? 2 : 1),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(fit: StackFit.expand, children: [
                          if (!item.isVideo) Image.file(File(item.file.path), fit: BoxFit.cover),
                          if (item.isVideo) const Center(child: Icon(Icons.movie_outlined, color: Colors.white70, size: 28)),
                          Positioned(left: 6, bottom: 6, child: Icon(item.isVideo ? Icons.videocam : Icons.image, size: 14, color: Colors.white)),
                          if (i == _selected) const Positioned(right: 5, top: 5, child: Icon(Icons.check_circle, color: _orange, size: 17)),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Container(
          color: _bg,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomTool(icon: Icons.content_cut, label: 'Trim'),
              _BottomTool(icon: Icons.speed, label: 'Speed'),
              _BottomTool(icon: Icons.auto_awesome, label: 'Effects'),
              _BottomTool(icon: Icons.title, label: 'Text'),
              _BottomTool(icon: Icons.graphic_eq, label: 'Audio'),
            ],
          ),
        ),
      ],
    );
  }

  void _showInfo(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _panel,
        title: Text(title),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: _orange)))],
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: _orange, size: 23),
          const SizedBox(height: 13),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ]),
      );
}

class _BottomTool extends StatelessWidget {
  const _BottomTool({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white70, size: 22),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ]);
}
