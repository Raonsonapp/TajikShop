import 'package:flutter_test/flutter_test.dart';
import 'package:aurix_editor/editor/models/timeline_clip.dart';

void main() {
  group('TimelineClip', () {
    test('trim and speed determine timeline duration', () {
      final clip = const TimelineClip(
        id: 'a',
        mediaPath: '/tmp/a.mp4',
        kind: MediaKind.video,
        sourceDurationMs: 10000,
      ).trim(startMs: 2000, endMs: 8000).setSpeed(2);
      expect(clip.sourceLengthMs, 6000);
      expect(clip.timelineDurationMs, 3000);
    });

    test('split preserves source ranges and clip settings', () {
      const clip = TimelineClip(
        id: 'source',
        mediaPath: '/tmp/a.mp4',
        kind: MediaKind.video,
        sourceDurationMs: 10000,
        trimStartMs: 1000,
        trimEndMs: 9000,
        speed: 1.5,
      );
      final pieces = clip.splitAt(5000, leftId: 'left', rightId: 'right');
      expect(pieces[0].trimStartMs, 1000);
      expect(pieces[0].trimEndMs, 5000);
      expect(pieces[1].trimStartMs, 5000);
      expect(pieces[1].trimEndMs, 9000);
      expect(pieces[1].speed, 1.5);
    });

    test('rejects invalid trim, split, speed and volume', () {
      const clip = TimelineClip(
        id: 'a',
        mediaPath: '/tmp/a.mp4',
        kind: MediaKind.video,
        sourceDurationMs: 10000,
      );
      expect(() => clip.trim(startMs: -1, endMs: 500), throwsRangeError);
      expect(() => clip.splitAt(0, leftId: 'l', rightId: 'r'), throwsRangeError);
      expect(() => clip.setSpeed(0), throwsRangeError);
      expect(() => clip.setVolume(2), throwsRangeError);
    });
  });

  group('TimelineProject', () {
    TimelineClip clip(String id, {int track = 0, MediaKind kind = MediaKind.video}) =>
        TimelineClip(
          id: id,
          mediaPath: '/tmp/$id',
          kind: kind,
          sourceDurationMs: 5000,
          trackIndex: track,
        );

    test('supports add, reorder, split and remove', () {
      final project = TimelineProject(clips: [clip('one'), clip('two')]);
      project.move('two', 0);
      expect(project.clips.first.id, 'two');
      project.split('two', 2000, leftId: 'two-a', rightId: 'two-b');
      expect(project.clips.map((item) => item.id).toList(),
          ['two-a', 'two-b', 'one']);
      project.remove('two-a');
      expect(project.clips.map((item) => item.id).toList(), ['two-b', 'one']);
    });

    test('duration excludes audio-only tracks and counts video time', () {
      final project = TimelineProject(clips: [
        clip('video'),
        clip('audio', track: 1, kind: MediaKind.audio),
      ]);
      expect(project.trackCount, 2);
      expect(project.durationMs, 5000);
    });
  });
}
