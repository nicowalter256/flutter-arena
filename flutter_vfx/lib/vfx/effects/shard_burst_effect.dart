import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../vfx_effect.dart';
import '../vfx_textures.dart';

/// A one-shot burst of white-hot crystalline shards cooling through cyan
/// into violet, thrown out nearly flat (a wide cone angled close to
/// horizontal) rather than a classic upward spark shower.
class ShardBurstEffect extends VfxEffect {
  ShardBurstEffect({required this.position});

  final vm.Vector3 position;
  late final ParticleSystem _system;

  @override
  String get label => 'Shards';

  @override
  Future<void> load(Scene scene) async {
    final dot = GpuTextureSource(await gpuTextureFromImage(await bakeSoftDot()));

    _system = ParticleSystem(
      maxParticles: 96,
      shape: const ConeEmitterShape(angle: 1.5, radius: 0.04),
      spawner: Spawner(bursts: const [ParticleBurst(time: 0.0, count: 70)]),
      looping: false,
      duration: 2.0,
      lifetime: const UniformFloat(0.6, 1.2),
      startSpeed: const UniformFloat(4.0, 9.0),
      startSize: const UniformFloat(0.025, 0.05),
      gravity: vm.Vector3(0, -3.0, 0),
      modules: [
        LinearDragModule(0.6),
        SizeOverLifeModule(CurveFloat(ParticleCurve.linear(from: 1, to: 0.4))),
        ColorOverLifeModule(
          GradientColor(
            ColorGradient([
              ColorStop(0.0, vm.Vector4(3.4, 3.4, 3.8, 0.0)),
              ColorStop(0.12, vm.Vector4(3.4, 3.4, 3.8, 1.0)),
              ColorStop(0.4, vm.Vector4(1.0, 2.0, 3.8, 0.9)),
              ColorStop(0.75, vm.Vector4(1.7, 0.5, 3.6, 0.55)),
              ColorStop(1.0, vm.Vector4(0.7, 0.15, 2.4, 0.0)),
            ]),
          ),
        ),
      ],
      seed: 41,
    );

    final material = SpriteMaterial(colorTexture: dot)
      ..blendMode = SpriteBlendMode.additive;
    final emitter = ParticleEmitterComponent(system: _system, material: material)
      ..facing = BillboardFacing.velocityStretched
      ..velocityStretch = 0.04;

    scene.add(
      Node()
        ..localTransform = vm.Matrix4.translation(position)
        ..addComponent(emitter),
    );
  }

  @override
  void trigger() => _system.reset();
}
