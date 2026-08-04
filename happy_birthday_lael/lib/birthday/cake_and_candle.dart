import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// A simple two-tier cake with a single lit candle — one candle to
/// underscore "1", and a nod to the first-birthday cake-smash tradition.
class CakeAndCandle {
  late final PointLight flameLight;

  void load(Scene scene, vm.Vector3 position) {
    final root = Node()..localTransform = vm.Matrix4.translation(position);

    root.add(
      Node(
        mesh: Mesh(
          CylinderGeometry(bottomRadius: 1.3, topRadius: 1.2, height: 0.55),
          PhysicallyBasedMaterial()
            ..baseColorFactor = vm.Vector4(0.95, 0.85, 0.78, 1)
            ..roughnessFactor = 0.6,
        ),
      ),
    );

    root.add(
      Node(
        mesh: Mesh(
          CylinderGeometry(bottomRadius: 0.85, topRadius: 0.8, height: 0.45),
          PhysicallyBasedMaterial()
            ..baseColorFactor = vm.Vector4(1.0, 0.7, 0.78, 1)
            ..roughnessFactor = 0.55,
        ),
        localTransform: vm.Matrix4.translation(vm.Vector3(0, 0.5, 0)),
      ),
    );

    root.add(
      Node(
        mesh: Mesh(
          CylinderGeometry(bottomRadius: 0.05, topRadius: 0.05, height: 0.5),
          PhysicallyBasedMaterial()
            ..baseColorFactor = vm.Vector4(1.0, 1.0, 1.0, 1)
            ..roughnessFactor = 0.4,
        ),
        localTransform: vm.Matrix4.translation(vm.Vector3(0, 1.0, 0)),
      ),
    );

    root.add(
      Node(
        mesh: Mesh(
          SphereGeometry(radius: 0.07),
          UnlitMaterial()..baseColorFactor = vm.Vector4(3.2, 1.8, 0.4, 1),
        ),
        localTransform: vm.Matrix4.translation(vm.Vector3(0, 1.28, 0)),
      ),
    );

    flameLight = PointLight(
      color: vm.Vector3(1.0, 0.6, 0.25),
      intensity: 6.0,
      range: 5.0,
    );
    root.add(
      Node()
        ..localTransform = vm.Matrix4.translation(vm.Vector3(0, 1.3, 0))
        ..addComponent(PointLightComponent(flameLight)),
    );

    scene.add(root);
  }
}
