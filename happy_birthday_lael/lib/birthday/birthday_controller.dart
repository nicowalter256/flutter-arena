import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'balloons.dart';
import 'cake_and_candle.dart';
import 'confetti_effect.dart';
import 'numeral_one.dart';

/// Owns the [Scene]: the glowing "1" centerpiece, bobbing balloons, a cake
/// with its single candle, colorful confetti, and the lighting/bloom that
/// ties it all into one warm, celebratory scene.
class BirthdayController {
  final Scene scene = Scene();
  bool isLoaded = false;

  final BalloonField _balloons = BalloonField();
  final CakeAndCandle _cake = CakeAndCandle();
  final ConfettiEffect confetti = ConfettiEffect();

  Future<void> load() async {
    await Scene.initializeStaticResources();

    scene.directionalLight = DirectionalLight(
      direction: vm.Vector3(-0.35, -0.9, -0.3),
      color: vm.Vector3(1.0, 0.92, 0.8),
      intensity: 2.0,
    );

    // TEMP DEBUG: isolating the corner-crop bug — everything below the
    // directional light is commented out except one plain cuboid.
    scene.add(
      Node(
        mesh: Mesh(
          CuboidGeometry(vm.Vector3(1.5, 1.5, 1.5)),
          UnlitMaterial()..baseColorFactor = vm.Vector4(3.0, 2.2, 0.6, 1),
        ),
      ),
    );

    // scene.add(
    //   Node()
    //     ..localTransform = vm.Matrix4.translation(vm.Vector3(-3.2, 2.2, 2.2))
    //     ..addComponent(
    //       PointLightComponent(
    //         PointLight(
    //           color: vm.Vector3(1.0, 0.6, 0.3),
    //           intensity: 14.0,
    //           range: 8.0,
    //         ),
    //       ),
    //     ),
    // );
    // scene.add(
    //   Node()
    //     ..localTransform = vm.Matrix4.translation(vm.Vector3(3.2, 2.2, 2.2))
    //     ..addComponent(
    //       PointLightComponent(
    //         PointLight(
    //           color: vm.Vector3(0.4, 0.7, 1.0),
    //           intensity: 14.0,
    //           range: 8.0,
    //         ),
    //       ),
    //     ),
    // );

    // scene.add(
    //   buildNumeralOne(color: vm.Vector4(3.0, 2.2, 0.6, 1))
    //     ..localTransform = vm.Matrix4.translation(vm.Vector3(0, 1.4, 0)),
    // );

    // _balloons.load(scene, vm.Vector3.zero());
    // _cake.load(scene, vm.Vector3(0, -1.6, 0));
    // confetti.load(scene, vm.Vector3(0, 3.8, 0));

    scene.postProcess.bloom
      ..enabled = true
      ..threshold = 0.75
      ..intensity = 0.85
      ..scatter = 0.8;
    scene.postProcess.vignette
      ..enabled = true
      ..intensity = 0.32;
    // scene.postProcess.colorGrading
    //   ..enabled = true
    //   ..saturation = 1.15;

    isLoaded = true;
  }

  void tick(Duration elapsed, double deltaSeconds) {
    // TEMP DEBUG: no-op while isolating the corner-crop bug.
    return;
    // ignore: dead_code
    final t = elapsed.inMicroseconds / 1e6;
    _balloons.tick(t);

    // A gentle deterministic flicker — sine waves, not noise (see the
    // flutter_vfx sibling project for why noise-based flicker is avoided
    // on web).
    final flicker = 0.85 + 0.15 * math.sin(t * 9.0) + 0.08 * math.sin(t * 21.0);
    _cake.flameLight.intensity = 6.0 * flicker;
  }

  PerspectiveCamera cameraFor(Duration elapsed) {
    const radius = 7.0;
    const angle = 0.0; // TEMP DEBUG: force static front-on camera
    return PerspectiveCamera(
      position: vm.Vector3(
        math.sin(angle) * radius,
        1.6,
        math.cos(angle) * radius,
      ),
      target: vm.Vector3(0, 0.6, 0),
    );
  }

  void dispose() {
    scene.removeAll();
  }
}
