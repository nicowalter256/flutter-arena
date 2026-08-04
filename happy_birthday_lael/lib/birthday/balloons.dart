import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

class _Balloon {
  _Balloon(this.node, this.basePosition, this.phase, this.bobSpeed);
  final Node node;
  final vm.Vector3 basePosition;
  final double phase;
  final double bobSpeed;
}

/// A handful of bright, gently bobbing balloons (with hanging strings)
/// scattered around a center point.
class BalloonField {
  final List<_Balloon> _balloons = [];

  static final _colors = [
    vm.Vector4(1.0, 0.25, 0.3, 1), // red
    vm.Vector4(1.0, 0.78, 0.15, 1), // gold
    vm.Vector4(0.25, 0.55, 1.0, 1), // blue
    vm.Vector4(0.35, 0.9, 0.45, 1), // green
    vm.Vector4(1.0, 0.4, 0.75, 1), // pink
  ];

  static final _offsets = [
    vm.Vector3(-2.6, 1.6, -0.6),
    vm.Vector3(-1.6, 2.3, 0.4),
    vm.Vector3(1.7, 2.2, 0.2),
    vm.Vector3(2.7, 1.5, -0.5),
    vm.Vector3(0.2, 2.8, -1.0),
  ];

  void load(Scene scene, vm.Vector3 center) {
    for (var i = 0; i < _colors.length; i++) {
      final color = _colors[i];
      final material = PhysicallyBasedMaterial()
        ..baseColorFactor = color
        ..roughnessFactor = 0.25
        ..metallicFactor = 0.0
        ..emissiveFactor = vm.Vector4(
          color.x * 0.2,
          color.y * 0.2,
          color.z * 0.2,
          1,
        );

      final balloonNode = Node(
        mesh: Mesh(SphereGeometry(radius: 0.42), material),
      );
      balloonNode.add(
        Node(
          mesh: Mesh(
            CylinderGeometry(
              bottomRadius: 0.012,
              topRadius: 0.012,
              height: 0.9,
            ),
            UnlitMaterial()..baseColorFactor = vm.Vector4(0.75, 0.75, 0.75, 1),
          ),
          localTransform: vm.Matrix4.translation(vm.Vector3(0, -0.87, 0)),
        ),
      );
      scene.add(balloonNode);

      final base = center + _offsets[i];
      _balloons.add(_Balloon(balloonNode, base, i * 1.3, 0.6 + i * 0.07));
    }
  }

  void tick(double t) {
    for (final balloon in _balloons) {
      final y =
          balloon.basePosition.y +
          math.sin(t * balloon.bobSpeed + balloon.phase) * 0.18;
      final x =
          balloon.basePosition.x +
          math.sin(t * balloon.bobSpeed * 0.5 + balloon.phase) * 0.08;
      balloon.node.localTransform = vm.Matrix4.translation(
        vm.Vector3(x, y, balloon.basePosition.z),
      );
    }
  }
}
