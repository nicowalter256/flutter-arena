import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../vfx_effect.dart';

/// Two glowing markers orbiting a common vertical axis 180° apart, rising
/// and falling in lockstep, each dragging a differently colored ribbon —
/// reads as a braided double helix. No particle system involved at all;
/// this is [TrailComponent] used as a particle-free VFX technique.
class HelixEffect extends VfxEffect {
  HelixEffect({required this.center});

  final vm.Vector3 center;
  late final Node _strandA;
  late final Node _strandB;

  @override
  String get label => 'Helix';

  @override
  Future<void> load(Scene scene) async {
    _strandA = _buildStrand(
      scene,
      markerColor: vm.Vector4(1.4, 0.35, 3.2, 1),
      trailHead: vm.Vector4(1.2, 0.3, 2.8, 0.9),
      trailTail: vm.Vector4(0.3, 0.08, 1.2, 0.0),
    );
    _strandB = _buildStrand(
      scene,
      markerColor: vm.Vector4(0.3, 2.6, 3.2, 1),
      trailHead: vm.Vector4(0.25, 2.4, 3.0, 0.9),
      trailTail: vm.Vector4(0.05, 0.7, 1.1, 0.0),
    );
  }

  Node _buildStrand(
    Scene scene, {
    required vm.Vector4 markerColor,
    required vm.Vector4 trailHead,
    required vm.Vector4 trailTail,
  }) {
    final trail = TrailComponent(
      width: 0.1,
      lifetime: 0.9,
      minVertexDistance: 0.03,
      maxPoints: 64,
      colorOverTrail: ColorGradient([
        ColorStop(0.0, trailHead),
        ColorStop(1.0, trailTail),
      ]),
    );
    final marker = Node(
      mesh: Mesh(
        SphereGeometry(radius: 0.07),
        UnlitMaterial()..baseColorFactor = markerColor,
      ),
    )..addComponent(trail);
    scene.add(marker);
    return marker;
  }

  @override
  void tick(double t, double deltaSeconds) {
    const radius = 1.1;
    const height = 1.4;
    final angle = t * 1.1;
    final y = 1.0 + math.sin(t * 0.7) * height * 0.5;

    _strandA.localTransform = vm.Matrix4.translation(
      center + vm.Vector3(math.cos(angle) * radius, y, math.sin(angle) * radius),
    );
    final opposite = angle + math.pi;
    _strandB.localTransform = vm.Matrix4.translation(
      center +
          vm.Vector3(
            math.cos(opposite) * radius,
            y,
            math.sin(opposite) * radius,
          ),
    );
  }
}
