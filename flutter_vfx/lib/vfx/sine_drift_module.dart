import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';

/// A lateral "flutter" wander applied to each particle over its life —
/// deterministic sine waves seeded per-particle from
/// [ParticleStorage.random01], not noise.
///
/// This sidesteps flutter_scene's own `TurbulenceModule`, which drives curl
/// noise through `FastNoiseLite`: that noise relies on 32-bit integer
/// hashing that overflows in Dart-on-web (`int` is a JS `double` there),
/// which was producing `NaN` particle positions and crashing the renderer
/// (see the caveat documented on `package:flutter_scene/noise.dart`).
/// Sine waves are pure floating-point math, so there's nothing to overflow.
///
/// Pair this with a drag module placed *after* it in the module list: each
/// step adds a small oscillating acceleration, and drag bleeds it off before
/// it can accumulate into a runaway drift, which is what keeps the result a
/// bounded wobble rather than a random walk.
class SineDriftModule extends ParticleModule {
  SineDriftModule({this.amplitude = 0.6, this.frequencyX = 0.8, this.frequencyZ = 0.55});

  /// Acceleration magnitude of the wobble, in world units per second².
  final double amplitude;

  /// Oscillation rate along X and Z. Kept unequal so the wander traces a
  /// lazy figure-eight-ish path rather than a single straight line.
  final double frequencyX;
  final double frequencyZ;

  double _elapsed = 0;

  @override
  void update(ParticleStorage storage, double dt) {
    _elapsed += dt;
    final n = storage.aliveCount;
    for (var i = 0; i < n; i++) {
      // Each particle's random01 offsets its phase, so a whole burst
      // doesn't wobble in lockstep.
      final phase = storage.random01[i] * math.pi * 2;
      final swayX = math.sin(_elapsed * frequencyX + phase) * amplitude;
      final swayZ = math.cos(_elapsed * frequencyZ + phase * 1.3) * amplitude;
      storage.velX[i] += swayX * dt;
      storage.velZ[i] += swayZ * dt;
    }
  }
}
