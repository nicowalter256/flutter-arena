import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Free functions that build the static (non-gameplay) parts of the arena:
/// the floor, the decorative spawn-marker rings, and the colored accent
/// lights. Kept separate from [ArenaController] since none of this depends
/// on per-frame state.
Node buildArenaFloor() {
  return Node(
    mesh: Mesh(
      CuboidGeometry(vm.Vector3(14.0, 0.2, 9.0)),
      PhysicallyBasedMaterial()
        ..baseColorFactor = vm.Vector4(0.03, 0.035, 0.05, 1)
        ..metallicFactor = 0.7
        ..roughnessFactor = 0.2,
    ),
    localTransform: vm.Matrix4.translation(vm.Vector3(0, -0.11, 0)),
  );
}

Node buildGlowRing(vm.Vector3 position, Color color) {
  return Node(
    mesh: Mesh(
      RingGeometry(innerRadius: 0.9, outerRadius: 1.15, segments: 48),
      UnlitMaterial()
        ..baseColorFactor = vm.Vector4(
          color.r.toDouble(),
          color.g.toDouble(),
          color.b.toDouble(),
          1,
        ),
    ),
    localTransform:
        vm.Matrix4.translation(vm.Vector3(position.x, 0.01, position.z)) *
        vm.Matrix4.rotationX(-math.pi / 2),
  );
}

Node buildAccentLight(vm.Vector3 position, Color color) {
  final c = vm.Vector3(
    color.r.toDouble(),
    color.g.toDouble(),
    color.b.toDouble(),
  );
  return Node()
    ..addComponent(
      PointLightComponent(PointLight(color: c, intensity: 24.0, range: 7.0)),
    )
    ..localTransform = vm.Matrix4.translation(position);
}
