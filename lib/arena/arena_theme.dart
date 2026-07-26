import 'dart:ui' show Color;

/// Visual and gameplay tuning constants for the arena scene.
abstract final class ArenaTheme {
  static const double arenaHalfWidth = 6.0;
  static const double arenaHalfDepth = 3.8;
  static const double catchDistance = 1.5;
  static const double chaseSpeed = 2.4;
  static const double logoScale = 1.3;

  // flutter_scene's own character-controller example adds a `math.pi`
  // offset here, but that correction is specific to its controller's own
  // heading convention — with our direct atan2(dir.x, dir.y) heading, no
  // offset is needed for Dash to face its direction of travel.
  static const double dashModelYawOffset = 0.0;

  static const Color logoAccent = Color(0xFF3FA0FF);
  static const Color dashAccent = Color(0xFF3CF0C8);
}
