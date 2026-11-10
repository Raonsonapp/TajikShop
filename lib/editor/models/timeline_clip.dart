enum MediaKind { video, image, audio }

class TimelineClip {
  const TimelineClip({
    required this.id,
    required this.mediaPath,
    required this.kind,
    required this.sourceDurationMs,
    this.trimStartMs = 0,
    int? trimEndMs,
    this.trackIndex = 0,
    this.speed = 1,
    this.volume = 1,
  }) : trimEndMs = trimEndMs ?? sourceDurationMs;

  final String id;
  final String mediaPath;
  final MediaKind kind;
  final int sourceDurationMs;
  final int trimStartMs;
  final int trimEndMs;
  final int trackIndex;
  final double speed;
  final double volume;

  int get sourceLengthMs => trimEndMs - trimStartMs;
  int get timelineDurationMs => (sourceLengthMs / speed).round();

  TimelineClip copyWith({
    String? id,
    String? mediaPath,
    MediaKind? kind,
    int? sourceDurationMs,
    int? trimStartMs,
    int? trimEndMs,
    int? trackIndex,
    double? speed,
    double? volume,
  }) => TimelineClip(
    id: id ?? this.id,
    mediaPath: mediaPath ?? this.mediaPath,
    kind: kind ?? this.kind,
    sourceDurationMs: sourceDurationMs ?? this.sourceDurationMs,
    trimStartMs: trimStartMs ?? this.trimStartMs,
    trimEndMs: trimEndMs ?? this.trimEndMs,
    trackIndex: trackIndex ?? this.trackIndex,
    speed: speed ?? this.speed,
    volume: volume ?? this.volume,
  );

  TimelineClip trim({required int startMs, required int endMs}) {
    if (startMs < 0 || endMs > sourceDurationMs || endMs <= startMs) {
      throw RangeError('Trim range must be inside the source and have positive duration.');
    }
    return copyWith(trimStartMs: startMs, trimEndMs: endMs);
  }

  List<TimelineClip> splitAt(
    int sourcePositionMs, {
    required String leftId,
    required String rightId,
  }) {
    if (sourcePositionMs <= trimStartMs || sourcePositionMs >= trimEndMs) {
      throw RangeError('Split point must be inside the selected clip.');
    }
    return [
      copyWith(id: leftId, trimEndMs: sourcePositionMs),
      copyWith(id: rightId, trimStartMs: sourcePositionMs),
    ];
  }

  TimelineClip setSpeed(double value) {
    if (!value.isFinite || value < 0.1 || value > 10) {
      throw RangeError('Speed must be between 0.1x and 10x.');
    }
    return copyWith(speed: value);
  }

  TimelineClip setVolume(double value) {
    if (!value.isFinite || value < 0 || value > 1) {
      throw RangeError('Volume must be between 0% and 100%.');
    }
    return copyWith(volume: value);
  }
}

class TimelineProject {
  TimelineProject({List<TimelineClip> clips = const []})
      : _clips = List<TimelineClip>.of(clips) {
    _validateUniqueIds();
  }

  final List<TimelineClip> _clips;

  List<TimelineClip> get clips => List.unmodifiable(_clips);
  int get trackCount => _clips.isEmpty
      ? 0
      : _clips.map((clip) => clip.trackIndex).reduce((a, b) => a > b ? a : b) + 1;
  int get durationMs => _clips
      .where((clip) => clip.kind != MediaKind.audio)
      .fold(0, (sum, clip) => sum + clip.timelineDurationMs);

  void add(TimelineClip clip) {
    if (_clips.any((item) => item.id == clip.id)) {
      throw ArgumentError('Clip IDs must be unique.');
    }
    _clips.add(clip);
  }

  void remove(String id) => _clips.removeWhere((clip) => clip.id == id);

  void move(String id, int newIndex) {
    final oldIndex = _clips.indexWhere((clip) => clip.id == id);
    if (oldIndex < 0) throw ArgumentError.value(id, 'id', 'Clip not found.');
    if (newIndex < 0 || newIndex >= _clips.length) {
      throw RangeError.index(newIndex, _clips, 'newIndex');
    }
    final clip = _clips.removeAt(oldIndex);
    _clips.insert(newIndex, clip);
  }

  void split(
    String id,
    int sourcePositionMs, {
    required String leftId,
    required String rightId,
  }) {
    if (_clips.any((clip) => clip.id == leftId || clip.id == rightId)) {
      throw ArgumentError('New clip IDs must be unique.');
    }
    final index = _clips.indexWhere((clip) => clip.id == id);
    if (index < 0) throw ArgumentError.value(id, 'id', 'Clip not found.');
    final pieces = _clips[index].splitAt(
      sourcePositionMs,
      leftId: leftId,
      rightId: rightId,
    );
    _clips
      ..removeAt(index)
      ..insertAll(index, pieces);
  }

  void _validateUniqueIds() {
    final ids = _clips.map((clip) => clip.id).toSet();
    if (ids.length != _clips.length) {
      throw ArgumentError('Clip IDs must be unique.');
    }
  }
}
