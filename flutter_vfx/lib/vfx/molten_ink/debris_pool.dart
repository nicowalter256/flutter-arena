import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

class _DebrisChunk {
  _DebrisChunk(this.node, this.material);

  final Node node;
  final PhysicallyBasedMaterial material;

  bool active = false;
  vm.Vector3 position = vm.Vector3.zero();
  vm.Vector3 velocity = vm.Vector3.zero();
  double rotationSeed = 0;
  double spin = 0;
  double age = 0;
  double lifetime = 1.0;
}

/// A small fixed-size pool of real 3D obsidian chunks — freshly cooled slag
/// still glowing faintly, fading to plain dark glossy stone as it tumbles
/// and falls.
///
/// Deliberately *not* a [ParticleSystem]: that API spawns from one emitter
/// shape/origin at a rate or in bursts, which doesn't fit "spawn exactly
/// one chunk at this arbitrary point, whenever a fluid cell happens to
/// cool" — the fluid sim decides spawn timing and position, not a spawner
/// curve. A hand-managed pool of ordinary [Node]s is the more direct tool
/// for that, recycling the oldest chunk once [maxChunks] are in flight.
class DebrisPool {
  DebrisPool({required this.scene, this.maxChunks = 48});

  final Scene scene;
  final int maxChunks;

  final List<_DebrisChunk> _chunks = [];
  int _nextIndex = 0;
  final math.Random _rng = math.Random();

  void load() {
    final geometries = [
      CuboidGeometry(vm.Vector3(0.12, 0.09, 0.1)),
      WedgeGeometry(vm.Vector3(0.11, 0.08, 0.09)),
    ];
    for (var i = 0; i < maxChunks; i++) {
      final material = PhysicallyBasedMaterial()
        ..alphaMode = AlphaMode.blend
        ..baseColorFactor = vm.Vector4(0.04, 0.03, 0.045, 1)
        ..roughnessFactor = 0.2
        ..metallicFactor = 0.15
        ..emissiveFactor = vm.Vector4(0, 0, 0, 1);
      final node = Node(mesh: Mesh(geometries[i % geometries.length], material))
        ..visible = false;
      scene.add(node);
      _chunks.add(_DebrisChunk(node, material));
    }
  }

  /// Spawns (or recycles) a chunk at [worldPosition], falling and tumbling
  /// away, still glowing hot for its first ~1.5s before cooling to dark
  /// stone and then fading out entirely.
  void spawn(vm.Vector3 worldPosition) {
    if (_chunks.isEmpty) return;
    final chunk = _chunks[_nextIndex];
    _nextIndex = (_nextIndex + 1) % _chunks.length;

    chunk.active = true;
    chunk.age = 0;
    chunk.lifetime = 2.4 + _rng.nextDouble() * 1.4;
    chunk.position = worldPosition.clone();
    chunk.velocity = vm.Vector3(
      (_rng.nextDouble() - 0.5) * 0.5,
      -0.3 - _rng.nextDouble() * 0.35,
      (_rng.nextDouble() - 0.5) * 0.25,
    );
    chunk.rotationSeed = _rng.nextDouble() * math.pi * 2;
    chunk.spin = (_rng.nextDouble() - 0.5) * 5.0;
    chunk.node.visible = true;
    chunk.material.baseColorFactor = vm.Vector4(0.04, 0.03, 0.045, 1);
  }

  void tick(double dt) {
    for (final chunk in _chunks) {
      if (!chunk.active) continue;
      chunk.age += dt;
      if (chunk.age >= chunk.lifetime) {
        chunk.active = false;
        chunk.node.visible = false;
        continue;
      }

      chunk.velocity.y -= 1.4 * dt;
      chunk.position += chunk.velocity * dt;

      // Glows hot orange/red right after cooling from the fluid, then
      // fades to plain dark stone over its first ~1.5s.
      final glow = (1.0 - chunk.age / 1.5).clamp(0.0, 1.0);
      chunk.material.emissiveFactor = vm.Vector4(
        1.6 * glow,
        0.35 * glow,
        0.05 * glow,
        1,
      );

      // Fades out over its last 0.4s instead of popping out of existence.
      final fadeOut = (1.0 - (chunk.lifetime - chunk.age) / 0.4).clamp(
        0.0,
        1.0,
      );
      final alpha = 1.0 - fadeOut;
      chunk.material.baseColorFactor = vm.Vector4(0.04, 0.03, 0.045, alpha);

      final t = chunk.rotationSeed + chunk.age * chunk.spin;
      chunk.node.localTransform =
          vm.Matrix4.translation(chunk.position) *
          vm.Matrix4.rotationY(t) *
          vm.Matrix4.rotationX(t * 0.6);
    }
  }
}
