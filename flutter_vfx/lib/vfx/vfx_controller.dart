import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'effects/helix_effect.dart';
import 'effects/shard_burst_effect.dart';
import 'effects/shatter_effect.dart';
import 'effects/wisps_effect.dart';
import 'vfx_effect.dart';

/// Owns the [Scene], the stage (floor + lighting), and the four VFX
/// techniques on display: a sprite burst (shards), a continuous rate-driven
/// sprite stream (wisps), an instanced-mesh burst (shatter), and a
/// particle-free ribbon trail (helix).
class VfxController {
  final Scene scene = Scene();
  bool isLoaded = false;

  late final ShardBurstEffect shards;
  late final WispsEffect wisps;
  late final ShatterEffect shatter;
  late final HelixEffect helix;

  List<VfxEffect> get _effects => [shards, wisps, shatter, helix];

  Future<void> load() async {
    // Every effect below constructs geometry/materials directly (rather
    // than only via async asset loads), so the base shader library must be
    // ready first.
    await Scene.initializeStaticResources();

    scene.add(
      Node(
        mesh: Mesh(
          DiscGeometry(radius: 12.0, segments: 48),
          PhysicallyBasedMaterial()
            ..baseColorFactor = vm.Vector4(0.025, 0.02, 0.045, 1)
            ..roughnessFactor = 0.8
            ..metallicFactor = 0.05,
        ),
      ),
    );

    scene.directionalLight = DirectionalLight(
      direction: vm.Vector3(-0.3, -1.0, -0.4),
      color: vm.Vector3(0.75, 0.8, 1.0),
      intensity: 1.3,
    );

    shards = ShardBurstEffect(position: vm.Vector3(-3.2, 0.6, 0));
    wisps = WispsEffect(position: vm.Vector3(0, 0.3, 0));
    shatter = ShatterEffect(position: vm.Vector3(3.2, 0.6, 0));
    helix = HelixEffect(center: vm.Vector3(0, 0, -1.6));

    for (final effect in _effects) {
      await effect.load(scene);
    }

    scene.postProcess.bloom
      ..enabled = true
      ..threshold = 0.8
      ..intensity = 0.9
      ..scatter = 0.8;
    scene.postProcess.vignette
      ..enabled = true
      ..intensity = 0.35;

    isLoaded = true;
  }

  /// Advances every effect's custom per-frame motion. Called once per frame
  /// by [SceneView.onTick].
  void tick(Duration elapsed, double deltaSeconds) {
    final t = elapsed.inMicroseconds / 1e6;
    for (final effect in _effects) {
      effect.tick(t, deltaSeconds);
    }
  }

  /// A slow orbit around the whole stage, framing all three emitter spots
  /// and the helix's orbit at once.
  PerspectiveCamera cameraFor(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1e6;
    const radius = 7.5;
    final angle = t * 0.12;
    return PerspectiveCamera(
      position: vm.Vector3(
        math.sin(angle) * radius,
        3.0,
        math.cos(angle) * radius,
      ),
      target: vm.Vector3(0, 0.6, 0),
    );
  }

  void dispose() {
    scene.removeAll();
  }
}
