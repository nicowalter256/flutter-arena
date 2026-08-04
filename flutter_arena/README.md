# flutter_arena

A real-time 3D Flutter game: **Dash chases the Flutter logo** around a
lit arena, built on [flutter_scene](https://github.com/bdero/flutter_scene) —
a general-purpose 3D engine for Flutter built directly on Flutter GPU and
Impeller.

- Dash paths toward the Flutter logo in real time, playing its `Run`
  animation while chasing and `Idle` once it catches up.
- Drag the logo anywhere on the floor to relocate it and stay ahead of Dash.
- PBR lighting, colored accent lights, bloom/vignette/color-grading
  post-processing, and a camera that tracks the midpoint between the two
  characters.

## Requirements

flutter_scene depends on the Flutter GPU API, which currently requires the
Flutter **master** channel (not stable/beta):

```bash
flutter channel master
flutter upgrade
flutter config --enable-native-assets
flutter config --enable-dart-data-assets
```

## Running it

```bash
flutter pub get
flutter run -d chrome   # or any other connected device
```

## Project layout

- `lib/main.dart` — app entry point.
- `lib/arena/arena_controller.dart` — owns the `Scene`, the chase AI, and
  the drag-to-evade input handling. Plain Dart, no widget dependencies.
- `lib/arena/arena_scene_builder.dart` — builds the static parts of the
  scene (floor, pedestal rings, accent lights).
- `lib/arena/arena_screen.dart` — wires the controller into a `SceneView`.
- `lib/arena/arena_hud.dart` — the on-screen title/name-tags overlay.
- `lib/arena/arena_theme.dart` — tunable gameplay/visual constants.
- `assets/` — the Flutter logo and Dash models, reused directly from
  flutter_scene's own examples.

## Credits

Built on [flutter_scene](https://github.com/bdero/flutter_scene) by
Brandon DeRosier.
