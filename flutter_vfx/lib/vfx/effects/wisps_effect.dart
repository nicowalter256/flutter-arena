import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../sine_drift_module.dart';
import '../vfx_effect.dart';
import '../vfx_textures.dart';

/// A continuous stream of cyan-green bioluminescent motes, wandering on
/// [SineDriftModule] rather than rising in a straight cone — demonstrates a
/// hand-written module standing in for the noise-based turbulence
/// flutter_scene ships (see that module's doc comment for why).
class WispsEffect extends VfxEffect {
  WispsEffect({required this.position});

  final vm.Vector3 position;
  static const double _baseRate = 16.0;

  late final ParticleSystem _system;
  bool _enabled = true;

  @override
  String get label => 'Wisps';

  bool get enabled => _enabled;
  set enabled(bool value) {
    _enabled = value;
    _system.spawner.rate = value ? _baseRate : 0.0;
  }

  @override
  Future<void> load(Scene scene) async {
    final dot = GpuTextureSource(await gpuTextureFromImage(await bakeSoftDot()));

    _system = ParticleSystem(
      maxParticles: 56,
      shape: const SphereEmitterShape(radius: 0.35, hemisphere: true),
      spawner: Spawner(rate: _baseRate),
      lifetime: const UniformFloat(2.2, 3.4),
      startSpeed: const UniformFloat(0.15, 0.4),
      startSize: const UniformFloat(0.02, 0.045),
      gravity: vm.Vector3(0, 0.35, 0),
      modules: [
        // Order matters: the wobble adds velocity, drag bleeds it back off,
        // so the motion stays a bounded meander instead of drifting away.
        SineDriftModule(amplitude: 0.5, frequencyX: 0.9, frequencyZ: 0.6),
        LinearDragModule(0.6),
        SizeOverLifeModule(CurveFloat(ParticleCurve.linear(from: 1, to: 0.3))),
        ColorOverLifeModule(
          GradientColor(
            ColorGradient([
              ColorStop(0.0, vm.Vector4(0.2, 3.2, 2.3, 0.0)),
              ColorStop(0.15, vm.Vector4(0.3, 3.6, 2.6, 1.0)),
              ColorStop(0.55, vm.Vector4(0.2, 2.4, 2.8, 0.55)),
              ColorStop(1.0, vm.Vector4(0.1, 0.9, 1.4, 0.0)),
            ]),
          ),
        ),
      ],
      seed: 17,
    );

    final material = SpriteMaterial(colorTexture: dot)
      ..blendMode = SpriteBlendMode.additive;
    final emitter = ParticleEmitterComponent(system: _system, material: material);

    scene.add(
      Node()
        ..localTransform = vm.Matrix4.translation(position)
        ..addComponent(emitter),
    );
  }
}
