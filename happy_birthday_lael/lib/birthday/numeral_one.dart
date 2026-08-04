import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Builds a big glowing "1" out of three primitive blocks — the main
/// vertical stroke, the base foot, and the small angled flag at the top —
/// parented under one node so the whole digit rotates as a unit.
Node buildNumeralOne({required vm.Vector4 color}) {
  final material = UnlitMaterial()..baseColorFactor = color;
  final root = Node();

  root.add(
    Node(mesh: Mesh(CuboidGeometry(vm.Vector3(0.55, 2.6, 0.4)), material)),
  );

  root.add(
    Node(
      mesh: Mesh(CuboidGeometry(vm.Vector3(1.3, 0.4, 0.4)), material),
      localTransform: vm.Matrix4.translation(vm.Vector3(0, -1.5, 0)),
    ),
  );

  root.add(
    Node(
      mesh: Mesh(CuboidGeometry(vm.Vector3(0.75, 0.4, 0.4)), material),
      localTransform:
          vm.Matrix4.translation(vm.Vector3(-0.55, 1.05, 0)) *
          vm.Matrix4.rotationZ(0.75),
    ),
  );

  return root;
}
