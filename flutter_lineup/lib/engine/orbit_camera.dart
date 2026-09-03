import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// A drag-to-orbit, scroll-to-zoom camera looking at a fixed ground target.
///
/// Positioned in spherical coordinates around [target]: [yaw] spins around
/// the vertical axis, [pitch] is elevation above the ground, [distance] is
/// how far back the eye sits. [toPerspectiveCamera] builds the real
/// `flutter_scene` camera used both for rendering and for the 2D overlay
/// (markers, the action spotlight) via its `worldToScreen`/`screenPointToRay`
/// helpers — one camera model, no separate projection math to keep in sync.
class OrbitCamera {
  OrbitCamera({
    this.yaw = 0.0,
    this.pitch = 0.62,
    this.distance = 105.0,
    vm.Vector3? target,
  }) : target = target ?? vm.Vector3.zero();

  double yaw;
  double pitch;
  double distance;
  final vm.Vector3 target;

  // Free orbit, deliberately unrestricted: yaw goes all the way around and
  // pitch nearly to ground level. At low pitch + low distance the eye ends
  // up inside the stadium's stand footprint — rather than block the camera
  // from getting there, [isViewObstructed] flags it so the caller can hide
  // the pitch and players instead of rendering a broken, clipped-into view.
  static const double minPitch = 0.05;
  static const double maxPitch = 1.45;
  static const double minDistance = 55.0;
  static const double maxDistance = 190.0;
  static const double fovYRadians = 42 * math.pi / 180;

  void orbit(Offset screenDelta) {
    yaw -= screenDelta.dx * 0.006;
    pitch = (pitch - screenDelta.dy * 0.006).clamp(minPitch, maxPitch);
  }

  void zoomBy(double factor) {
    distance = (distance * factor).clamp(minDistance, maxDistance);
  }

  vm.Vector3 get eye {
    final horizontal = distance * math.cos(pitch);
    final y = distance * math.sin(pitch);
    return vm.Vector3(
      target.x + horizontal * math.sin(yaw),
      target.y + y,
      target.z + horizontal * math.cos(yaw),
    );
  }

  /// True once the eye sits inside a stand's actual footprint — horizontally
  /// between [innerEdge] (where the nearest stand starts) and [outerEdge]
  /// (where the farthest one ends), and below [rooflineHeight]. That band is
  /// solid structure, so the pitch can't be shown sensibly from inside it.
  /// (Closer to center than [innerEdge] is the open margin *before* any
  /// stand — always safe, regardless of height.)
  bool isViewObstructed({
    required double innerEdge,
    required double outerEdge,
    required double rooflineHeight,
  }) {
    final e = eye;
    final horizontalDistance = math.sqrt(e.x * e.x + e.z * e.z);
    return horizontalDistance > innerEdge &&
        horizontalDistance < outerEdge &&
        e.y < rooflineHeight;
  }

  PerspectiveCamera toPerspectiveCamera() {
    return PerspectiveCamera(
      fovRadiansY: fovYRadians,
      position: eye,
      target: target,
      fovNear: 0.5,
      fovFar: 500.0,
    );
  }

  /// Casts a ray from [screenPosition] and intersects it with the ground
  /// plane (y = 0), for drag-to-move-player. Returns null if the ray is
  /// (near-)parallel to the ground, which shouldn't happen at any allowed
  /// [pitch].
  vm.Vector3? screenToGround(Offset screenPosition, Size viewport) {
    final camera = toPerspectiveCamera();
    final ray = camera.screenPointToRay(screenPosition, viewport);
    final direction = ray.direction;
    if (direction.y.abs() < 1e-6) return null;
    final t = -ray.origin.y / direction.y;
    if (t < 0) return null;
    return ray.origin + direction.scaled(t);
  }
}
