# flutter_vfx

A particle systems & VFX playground built on
[flutter_scene](https://github.com/bdero/flutter_scene) — a general-purpose
3D engine for Flutter built directly on Flutter GPU and Impeller.

An original "arcane energy" look (violet/cyan/magenta, not fire), built
around four distinct techniques, each triggerable from the on-screen panel:

- **Shards** — a one-shot sprite burst thrown out nearly flat, cooling from
  white-hot through cyan into violet.
- **Wisps** — a continuous stream of cyan-green motes, wandering on a
  hand-written [`SineDriftModule`](lib/vfx/sine_drift_module.dart) instead
  of flutter_scene's noise-based turbulence (see below for why).
- **Shatter** — a one-shot burst of translucent, glassy *mesh* shards (real
  geometry, not sprites) via `MeshParticleEmitterComponent`.
- **Helix** — two markers orbiting a vertical axis 180° apart, each
  dragging a differently colored ribbon via `TrailComponent`, braiding into
  a double helix — no particle system involved at all.

## Why a custom particle module

flutter_scene ships a `TurbulenceModule` for organic drift, driven by curl
noise through `FastNoiseLite`. That noise relies on 32-bit integer hashing
that overflows in Dart-on-web (`int` is a JS `double` there — see the
caveat on `package:flutter_scene/noise.dart`), which produces `NaN`
particle positions and crashes the renderer. Hit that exact crash while
building the **Wisps** effect.

Rather than drop the organic motion, `SineDriftModule` gets there with pure
sine waves seeded per-particle from `ParticleStorage.random01` — no
hashing, nothing to overflow, and it renders identically on every platform.
It's a genuine `ParticleModule` subclass, using the same public
`spawn`/`update` hooks the built-in modules use, just with different math.

Every sprite in this project also uses a procedurally baked *soft dot*
(`vfx_textures.dart`) — a pure radial gradient — rather than a noise-baked
flipbook, for the same reason.

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
- `lib/vfx/vfx_controller.dart` — owns the `Scene`, the stage (floor +
  lighting), and the four effects.
- `lib/vfx/vfx_effect.dart` — the shared interface each effect implements
  (`load`, `trigger`, `tick`).
- `lib/vfx/sine_drift_module.dart` — the custom `ParticleModule` described
  above.
- `lib/vfx/effects/` — one file per effect.
- `lib/vfx/vfx_textures.dart` — the noise-free soft-dot sprite baker shared
  by every sprite effect.
- `lib/vfx/vfx_screen.dart` / `vfx_hud.dart` — the `SceneView` wiring and
  the control panel.

## Credits

Built on [flutter_scene](https://github.com/bdero/flutter_scene) by
Brandon DeRosier.
