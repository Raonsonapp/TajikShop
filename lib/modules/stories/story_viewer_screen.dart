import 'package:cached_network_image/cached_network_image.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/story_model.dart';

/// Намоишгари ҳикояҳо (story viewer) — экрани пурра бо навбарҳои прогресс,
/// худгузарӣ (5 сония барои ҳар расм) ва идора бо зеркунӣ (чап/рост).
class StoryViewerScreen extends StatefulWidget {
  final List<StoryUser> users;
  final int initialUserIndex;
  const StoryViewerScreen({
    super.key,
    required this.users,
    this.initialUserIndex = 0,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageCtrl;
  late final AnimationController _progress;
  int _userIndex = 0;
  int _storyIndex = 0;

  static const _duration = Duration(seconds: 5);

  StoryUser get _user => widget.users[_userIndex];

  @override
  void initState() {
    super.initState();
    _userIndex = widget.initialUserIndex.clamp(0, widget.users.length - 1);
    _pageCtrl = PageController(initialPage: _userIndex);
    _progress = AnimationController(vsync: this, duration: _duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _next();
      });
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _progress.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _start() {
    _progress
      ..reset()
      ..forward();
  }

  void _next() {
    if (_storyIndex < _user.stories.length - 1) {
      setState(() => _storyIndex++);
      _start();
    } else if (_userIndex < widget.users.length - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 280), curve: Curves.easeInOut);
    } else {
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _prev() {
    if (_storyIndex > 0) {
      setState(() => _storyIndex--);
      _start();
    } else if (_userIndex > 0) {
      _pageCtrl.previousPage(
          duration: const Duration(milliseconds: 280), curve: Curves.easeInOut);
    } else {
      _start();
    }
  }

  void _onUserChanged(int i) {
    setState(() {
      _userIndex = i;
      _storyIndex = 0;
    });
    _start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageCtrl,
        onPageChanged: _onUserChanged,
        itemCount: widget.users.length,
        itemBuilder: (_, i) {
          final u = widget.users[i];
          final story = (i == _userIndex && _storyIndex < u.stories.length)
              ? u.stories[_storyIndex]
              : u.stories.first;
          return _StoryPage(
            user: u,
            story: story,
            active: i == _userIndex,
            storyIndex: i == _userIndex ? _storyIndex : 0,
            progress: _progress,
            onTapLeft: _prev,
            onTapRight: _next,
            onPauseStart: () => _progress.stop(),
            onPauseEnd: () => _progress.forward(),
            onClose: () => Navigator.of(context).pop(),
            onShop: () => Navigator.of(context).pop(u.userId),
          );
        },
      ),
    );
  }
}

class _StoryPage extends StatelessWidget {
  final StoryUser user;
  final StoryModel story;
  final bool active;
  final int storyIndex;
  final AnimationController progress;
  final VoidCallback onTapLeft;
  final VoidCallback onTapRight;
  final VoidCallback onPauseStart;
  final VoidCallback onPauseEnd;
  final VoidCallback onClose;
  final VoidCallback onShop;

  const _StoryPage({
    required this.user,
    required this.story,
    required this.active,
    required this.storyIndex,
    required this.progress,
    required this.onTapLeft,
    required this.onTapRight,
    required this.onPauseStart,
    required this.onPauseEnd,
    required this.onClose,
    required this.onShop,
  });

  @override
  Widget build(BuildContext context) {
    final media = Center(
      child: story.isVideo
          ? const Icon(FeatherIcons.video, color: Colors.white38, size: 56)
          : CachedNetworkImage(
              imageUrl: story.mediaUrl,
              fit: BoxFit.contain,
              width: double.infinity,
              placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.4)),
              errorWidget: (_, __, ___) =>
                  const Icon(FeatherIcons.image, color: Colors.white38, size: 56),
            ),
    );

    return Stack(
      children: [
        Positioned.fill(child: media),

        // Занҷираҳои идора (чап/рост)
        Row(children: [
          Expanded(
              child: GestureDetector(
            onTap: onTapLeft,
            onLongPressStart: (_) => onPauseStart(),
            onLongPressEnd: (_) => onPauseEnd(),
            behavior: HitTestBehavior.opaque,
          )),
          Expanded(
              child: GestureDetector(
            onTap: onTapRight,
            onLongPressStart: (_) => onPauseStart(),
            onLongPressEnd: (_) => onPauseEnd(),
            behavior: HitTestBehavior.opaque,
          )),
        ]),

        // Навбарҳои прогресс + сарлавҳа
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(children: [
              Row(
                children: List.generate(user.stories.length, (i) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _ProgressBar(
                        fill: i < storyIndex
                            ? const AlwaysStoppedAnimation(1.0)
                            : (i == storyIndex && active
                                ? progress
                                : const AlwaysStoppedAnimation(0.0)),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              Row(children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: Colors.white24,
                  backgroundImage: user.avatarUrl.isNotEmpty
                      ? CachedNetworkImageProvider(user.avatarUrl)
                      : null,
                  child: user.avatarUrl.isEmpty
                      ? const Icon(FeatherIcons.shoppingBag,
                          color: Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(user.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(FeatherIcons.x, color: Colors.white, size: 24),
                  ),
                ),
              ]),
            ]),
          ),
        ),

        // Тугмаи «Ба мағоза»
        Positioned(
          left: 20,
          right: 20,
          bottom: 32,
          child: SafeArea(
            child: SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: onShop,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(FeatherIcons.shoppingBag,
                    color: Colors.white, size: 18),
                label: const Text('Ба мағоза',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final Animation<double> fill;
  const _ProgressBar({required this.fill});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: AnimatedBuilder(
        animation: fill,
        builder: (_, __) => LinearProgressIndicator(
          value: fill.value,
          minHeight: 2.6,
          backgroundColor: Colors.white38,
          valueColor: const AlwaysStoppedAnimation(Colors.white),
        ),
      ),
    );
  }
}
