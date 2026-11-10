# AURIX — Create Beyond Limits

AURIX is an independent mobile video-editing application for Android and iOS. The supplied 360 Editor video is used as workflow inspiration; AURIX does not copy its proprietary source code, artwork, or branding.

## Current functional foundation

- AURIX dark cinematic home and editor UI.
- Import a video or image from the device library.
- Native video playback preview.
- Multiple imported clips in a selectable timeline strip.
- Remove the selected clip.
- Real-time preview playback speed control (0.25×–2×).
- Real-time preview volume control.
- Android target API 36 and NDK r28 toolchain for the 16 KB page-size release requirement.
- Legacy Marketplace Flutter modules, Go backend, Marketplace assets, and related deployment workflows removed from this repository.

## Not implemented yet

Timeline trimming/splitting and rendering, multi-track compositing, audio-track mixing, speed-ramp curves, keyframes, tracking, cut-out, masks, effects, color grading, captions, and final export are not implemented in this foundation. They must be connected to a real native media engine before being advertised as available.

## Engineering roadmap

1. Editor foundation, media import and preview.
2. Persistent project model, clip timeline, trim and split.
3. Native media render/export pipeline and audio tracks.
4. Speed ramp curves and keyframe engine.
5. Effects, masks and color grading.
6. Motion tracking and segmentation.
7. Hardware-accelerated export and 16 KB compatibility verification.
8. AI features only when backed by real models/services.
9. Device QA, memory profiling and Play/App Store release checks.

## Build

```bash
flutter pub get
dart run flutter_launcher_icons
flutter analyze
flutter test
flutter build appbundle --release
```

The existing Android application ID and iOS bundle identifier are intentionally preserved for continuity with the existing store listing. Change them only if AURIX is to be published as a separate new app.
