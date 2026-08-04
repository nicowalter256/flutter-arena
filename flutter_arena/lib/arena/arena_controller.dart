import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'arena_scene_builder.dart';
import 'arena_theme.dart';

/// Owns the [Scene], the two characters, and the chase-AI / drag-to-evade
/// gameplay loop: Dash continuously paths toward the Flutter logo, and the
/// player can drag the logo elsewhere on the floor to stay ahead of it.
///
/// This is plain Dart (no widget dependencies) so it can be driven from
/// [SceneView]'s `cameraBuilder`/`onTick` callbacks and unit-tested on its
/// own.
class ArenaController {
  final Scene scene = Scene();
  bool isLoaded = false;

  Node? _logoNode;
  Node? _dashNode;
  AnimationClip? _dashIdle;
  AnimationClip? _dashRun;

  // World X/Z positions (Vector2.y stands in for world Z throughout).
  vm.Vector2 _logoXZ = vm.Vector2(-3.2, 1.4);
  vm.Vector2 _dashXZ = vm.Vector2(3.2, -1.4);
  double _dashDisplayYaw = 0.0;
  bool _dashChasing = false;

  Future<void> load() async {
    scene.add(buildArenaFloor());

    // Decorative spawn-marker rings + colored accent lights.
    scene.add(buildGlowRing(vm.Vector3(-3.2, 0, 1.4), ArenaTheme.logoAccent));
    scene.add(buildGlowRing(vm.Vector3(3.2, 0, -1.4), ArenaTheme.dashAccent));
    scene.add(
      buildAccentLight(vm.Vector3(-3.2, 2.2, 3.2), ArenaTheme.logoAccent),
    );
    scene.add(
      buildAccentLight(vm.Vector3(3.2, 2.2, 0.4), ArenaTheme.dashAccent),
    );

    scene.directionalLight = DirectionalLight(
      direction: vm.Vector3(-0.3, -1.0, -0.4),
      intensity: 3.0,
    );

    // Flutter logo — the "prey", repositioned by dragging.
    final logo = await Node.fromGlbAsset('assets/flutter_logo.glb');
    logo.name = 'FlutterLogo';
    scene.add(logo);
    _logoNode = logo;

    // Dash — the "chaser".
    final dash = await Node.fromGlbAsset('assets/dash.glb');
    dash.name = 'Dash';
    scene.add(dash);
    _dashNode = dash;

    final idleAnim = dash.findAnimationByName('Idle');
    final runAnim = dash.findAnimationByName('Run');
    if (idleAnim != null) {
      _dashIdle = dash.createAnimationClip(idleAnim)
        ..loop = true
        ..weight = 1.0
        ..play();
    }
    if (runAnim != null) {
      _dashRun = dash.createAnimationClip(runAnim)
        ..loop = true
        ..weight = 0.0
        ..play();
    }

    scene.postProcess.bloom
      ..enabled = true
      ..threshold = 0.85
      ..intensity = 0.8
      ..scatter = 0.8;
    scene.postProcess.vignette
      ..enabled = true
      ..intensity = 0.4;
    scene.postProcess.colorGrading
      ..enabled = true
      ..saturation = 1.2
      ..contrast = 1.1;

    isLoaded = true;
  }

  /// Repositions the logo from a screen-space drag delta. The camera looks
  /// down -Z with +X reading as screen-left, so screen-right drags need to
  /// *subtract* world X to track the finger.
  void dragLogo(Offset screenDelta) {
    const sensitivity = 0.018;
    var x = _logoXZ.x - screenDelta.dx * sensitivity;
    var y = _logoXZ.y + screenDelta.dy * sensitivity;
    x = x.clamp(-ArenaTheme.arenaHalfWidth, ArenaTheme.arenaHalfWidth);
    y = y.clamp(-ArenaTheme.arenaHalfDepth, ArenaTheme.arenaHalfDepth);
    _logoXZ = vm.Vector2(x, y);
  }

  double _lerpAngle(double from, double to, double t) {
    var diff = (to - from) % (2 * math.pi);
    if (diff > math.pi) diff -= 2 * math.pi;
    if (diff < -math.pi) diff += 2 * math.pi;
    return from + diff * t.clamp(0.0, 1.0);
  }

  /// Advances the logo's idle spin and Dash's chase step. Called once per
  /// frame by [SceneView.onTick].
  void tick(Duration elapsed, double deltaSeconds) {
    final t = elapsed.inMicroseconds / 1e6;

    final logo = _logoNode;
    if (logo != null) {
      logo.localTransform =
          vm.Matrix4.translation(vm.Vector3(_logoXZ.x, 1.0, _logoXZ.y)) *
          vm.Matrix4.rotationY(t * 0.8) *
          vm.Matrix4.diagonal3Values(
            ArenaTheme.logoScale,
            ArenaTheme.logoScale,
            ArenaTheme.logoScale,
          );
    }

    final dash = _dashNode;
    if (dash != null) {
      final toTarget = _logoXZ - _dashXZ;
      final dist = toTarget.length;
      final chasing = dist > ArenaTheme.catchDistance;

      if (chasing) {
        final dir = toTarget.normalized();
        final step = math.min(
          ArenaTheme.chaseSpeed * deltaSeconds,
          dist - ArenaTheme.catchDistance,
        );
        _dashXZ = _dashXZ + dir.scaled(step);
        final targetYaw =
            math.atan2(dir.x, dir.y) + ArenaTheme.dashModelYawOffset;
        _dashDisplayYaw = _lerpAngle(
          _dashDisplayYaw,
          targetYaw,
          12.0 * deltaSeconds,
        );
      }

      if (chasing != _dashChasing) {
        _dashChasing = chasing;
        _dashRun?.weight = chasing ? 1.0 : 0.0;
        _dashIdle?.weight = chasing ? 0.0 : 1.0;
      }

      dash.localTransform =
          vm.Matrix4.translation(vm.Vector3(_dashXZ.x, 0, _dashXZ.y)) *
          vm.Matrix4.rotationY(_dashDisplayYaw);
    }
  }

  /// Builds the per-frame camera, framing the midpoint between the two
  /// characters so neither runs off-screen as they move around the arena.
  PerspectiveCamera cameraFor(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1e6;
    final sway = math.sin(t * 0.25) * 0.5;
    final bob = math.sin(t * 0.6) * 0.15;
    final midX = (_logoXZ.x + _dashXZ.x) / 2;
    final midZ = (_logoXZ.y + _dashXZ.y) / 2;
    return PerspectiveCamera(
      position: vm.Vector3(midX + sway, 2.4 + bob, midZ + 8.5),
      target: vm.Vector3(midX, 1.1, midZ),
    );
  }

  void dispose() {
    scene.removeAll();
  }
}
