import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../vfx_effect.dart';

/// A one-shot burst of translucent glass-like shards thrown out flat and
/// fast, rather than tumbling debris arcing under heavy gravity —
/// demonstrates [MeshParticleEmitterComponent] with a glassy, emissive-rim
/// material instead of an opaque, unlit one.
class ShatterEffect extends VfxEffect {
  ShatterEffect({required this.position});

  final vm.Vector3 position;
  late final ParticleSystem _system;

  @override
  String get label => 'Shatter';

  @override
  Future<void> load(Scene scene) async {
    _system = ParticleSystem(
      maxParticles: 36,
      shape: const ConeEmitterShape(angle: 1.4, radius: 0.1),
      spawner: Spawner(bursts: const [ParticleBurst(time: 0.0, count: 22)]),
      looping: false,
      duration: 2.5,
      lifetime: const UniformFloat(1.2, 1.8),
      startSpeed: const UniformFloat(3.0, 6.5),
      startSize: const UniformFloat(0.4, 1.0),
      startAngularVelocity: const UniformFloat(-10.0, 10.0),
      gravity: vm.Vector3(0, -4.0, 0),
      modules: const [RotationModule()],
      seed: 63,
    );

    final material = PhysicallyBasedMaterial()
      ..alphaMode = AlphaMode.blend
      ..baseColorFactor = vm.Vector4(0.55, 0.7, 1.0, 0.35)
      ..roughnessFactor = 0.15
      ..metallicFactor = 0.3
      ..emissiveFactor = vm.Vector4(0.5, 0.2, 1.4, 1);

    final emitter = MeshParticleEmitterComponent(
      system: _system,
      geometries: [
        WedgeGeometry(vm.Vector3(0.1, 0.06, 0.08)),
        CuboidGeometry(vm.Vector3(0.07, 0.09, 0.05)),
      ],
      material: material,
    );

    scene.add(
      Node()
        ..localTransform = vm.Matrix4.translation(position)
        ..addComponent(emitter),
    );
  }

  @override
  void trigger() => _system.reset();
}
