import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Several colorful one-shot mesh-particle bursts falling from a wide band
/// above the scene — confetti. Each color is its own [ParticleSystem]
/// (`MeshParticleEmitterComponent` takes a single material per system), all
/// retriggered together via [trigger].
class ConfettiEffect {
  final List<ParticleSystem> _systems = [];

  static final _colors = [
    vm.Vector4(1.0, 0.25, 0.3, 1),
    vm.Vector4(1.0, 0.8, 0.15, 1),
    vm.Vector4(0.3, 0.6, 1.0, 1),
    vm.Vector4(0.4, 0.9, 0.45, 1),
    vm.Vector4(1.0, 0.45, 0.8, 1),
  ];

  void load(Scene scene, vm.Vector3 origin) {
    for (var i = 0; i < _colors.length; i++) {
      final system = ParticleSystem(
        maxParticles: 26,
        shape: BoxEmitterShape(
          halfExtents: vm.Vector3(3.2, 0.15, 1.2),
          direction: vm.Vector3(0, 1, 0),
        ),
        spawner: Spawner(bursts: const [ParticleBurst(time: 0.0, count: 20)]),
        looping: false,
        duration: 4.0,
        lifetime: const UniformFloat(2.4, 3.6),
        startSpeed: const UniformFloat(0.1, 0.6),
        startSize: const UniformFloat(0.5, 0.9),
        startAngularVelocity: const UniformFloat(-8.0, 8.0),
        gravity: vm.Vector3(0, -2.4, 0),
        modules: [LinearDragModule(0.15), const RotationModule()],
        seed: 100 + i,
      );

      final material = PhysicallyBasedMaterial()
        ..baseColorFactor = _colors[i]
        ..roughnessFactor = 0.6
        ..metallicFactor = 0.0
        ..doubleSided = true;

      final emitter = MeshParticleEmitterComponent(
        system: system,
        geometries: [CuboidGeometry(vm.Vector3(0.09, 0.09, 0.012))],
        material: material,
      );

      scene.add(
        Node()
          ..localTransform = vm.Matrix4.translation(origin)
          ..addComponent(emitter),
      );
      _systems.add(system);
    }
  }

  void trigger() {
    for (final system in _systems) {
      system.reset();
    }
  }
}
