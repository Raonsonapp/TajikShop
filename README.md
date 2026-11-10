# VELORA EDITOR

Create Beyond Limits.

VELORA is being developed as an independent mobile video editor for Android and iOS, inspired by the workflow and feature categories of professional mobile editors such as 360 Editor. It does not copy proprietary code, assets, or artwork.

## Phase 1 foundation currently in the repository

- Premium dark editor shell with orange accents.
- New project entry point.
- Import a video or photo from the device library.
- Video playback preview using the platform video player.
- Basic media clip strip with clip selection and removal.
- Android and iOS display name changed to VELORA EDITOR.
- Existing application ID and iOS bundle identifier are retained so this rebrand does not silently create a different store app identity.

## Not implemented yet

This is not yet a complete nonlinear editor. Trimming, splitting, multi-track compositing, speed curves, tracking, masks, effects, color grading, audio mixing, and final export are later engineering phases. The UI must not claim those operations work until their media engine is connected.

## Planned phases

1. Project architecture, editor shell, media import and preview.
2. Timeline model, clip operations, playback synchronization and autosave.
3. Trim, split, audio tracks and native media pipeline.
4. Speed ramp curves, keyframes and frame interpolation.
5. Effects, masks and color grading.
6. Motion/object tracking and background segmentation.
7. Export pipeline with hardware encoding and verified output.
8. Optional on-device AI tools.
9. Device compatibility, memory/performance tests and store release validation.

## Native media engine

Use native Android/iOS codecs and GPU APIs where practical. Select a maintained FFmpeg integration only after checking licensing, ABI support, 16 KB page compatibility, and maintenance status. Review codec distribution obligations before release.

## Build

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```
