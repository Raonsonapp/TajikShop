import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/story_model.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;
  const StoryViewerScreen({super.key, required this.stories, this.initialIndex = 0});

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late int _index;
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.stories.length - 1);
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _next();
      });
    _start();
  }

  void _start() {
    _ctrl.forward(from: 0);
  }

  void _next() {
    if (_index < widget.stories.length - 1) {
      setState(() => _index++);
      _start();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _prev() {
    if (_index > 0) {
      setState(() => _index--);
      _start();
    } else {
      _start();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.stories[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (d) {
          final w = MediaQuery.of(context).size.width;
          if (d.globalPosition.dx < w * 0.33) {
            _prev();
          } else {
            _next();
          }
        },
        onLongPress: () => _ctrl.stop(),
        onLongPressUp: () => _ctrl.forward(),
        child: Stack(children: [
          // Media
          Positioned.fill(
            child: s.isVideo
                ? Container(color: Colors.black, child: const Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.play_circle_outline, color: Colors.white54, size: 64),
                      SizedBox(height: 8),
                      Text('Видео', style: TextStyle(color: Colors.white54)),
                    ])))
                : CachedNetworkImage(
                    imageUrl: s.mediaUrl, fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                    errorWidget: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image_outlined, color: Colors.white38, size: 60))),
          ),

          // Top gradient
          Positioned(top: 0, left: 0, right: 0, height: 120,
            child: Container(decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent])))),

          SafeArea(child: Column(children: [
            // Progress bars
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Row(children: List.generate(widget.stories.length, (i) => Expanded(
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ClipRRect(borderRadius: BorderRadius.circular(2),
                    child: i == _index
                        ? AnimatedBuilder(animation: _ctrl, builder: (_, __) => LinearProgressIndicator(
                            value: _ctrl.value, minHeight: 2.5,
                            backgroundColor: Colors.white24, color: Colors.white))
                        : Container(height: 2.5, color: i < _index ? Colors.white : Colors.white24)))))),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(shape: BoxShape.circle,
                    gradient: SweepGradient(colors: [
                      Color(0xFFFEDA77), Color(0xFFDD2A7B), Color(0xFF515BD4), Color(0xFFFEDA77)])),
                  child: CircleAvatar(radius: 16, backgroundColor: AppColors.bgSurface,
                    backgroundImage: (s.avatarUrl != null && s.avatarUrl!.isNotEmpty)
                        ? CachedNetworkImageProvider(s.avatarUrl!) : null,
                    child: (s.avatarUrl == null || s.avatarUrl!.isEmpty)
                        ? Text(s.userName.isNotEmpty ? s.userName[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontSize: 13)) : null)),
                const SizedBox(width: 10),
                Expanded(child: Text(s.userName, style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).maybePop()),
              ]),
            ),
          ])),
        ]),
      ),
    );
  }
}
