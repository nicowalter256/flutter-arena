import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Real pitch dimensions (FIFA units, meters), centered on the origin at
/// y = 0. Shared with [OrbitPitch] for player placement.
class PitchDimensions {
  static const double halfWidth = 34.0;
  static const double halfLength = 52.5;
  static const double centerCircleRadius = 9.15;
  static const double penaltyAreaHalfWidth = 20.16;
  static const double penaltyAreaDepth = 16.5;
  static const double goalAreaHalfWidth = 9.16;
  static const double goalAreaDepth = 5.5;
  static const double penaltySpotDistance = 11.0;
  static const double cornerArcRadius = 2.0;

  /// Gap between the pitch boundary and the stands (room for a running
  /// track / advertising boards).
  static const double standMargin = 9.0;
  static const double standDepth = 34.0;
  static const double standHeight = 26.0;
  static const int standTierCount = 7;

  /// The nearest and farthest a stand's footprint reaches from the center
  /// (East/West sides are nearest, North/South farthest). Between these two
  /// radii, at or below [rooflineHeight], is solid stand structure — that
  /// combined band, not "close to center", is where the camera can end up
  /// embedded in the mesh.
  static const double standInnerEdge = halfWidth + standMargin;
  static const double standOuterEdge = halfLength + standMargin + standDepth;
  static const double rooflineHeight = standHeight + 6.0;
}

/// Club colors only — the actual crest, wordmark, and sponsor logos are
/// trademarked and aren't reproduced here; a red/black/white seat scheme is
/// just a color choice, not a protected mark.
class _StadiumTheme {
  static final vm.Vector4 pitchGreenLight = vm.Vector4(0.11, 0.34, 0.15, 1);
  static final vm.Vector4 pitchGreenDark = vm.Vector4(0.09, 0.30, 0.13, 1);
  static final vm.Vector4 lineWhite = vm.Vector4(0.92, 0.95, 0.92, 1);
  static final vm.Vector4 standColor = vm.Vector4(0.80, 0.14, 0.10, 1);
  static final vm.Vector4 standColorAlt = vm.Vector4(0.55, 0.08, 0.07, 1);
  static final vm.Vector4 standAccent = vm.Vector4(0.05, 0.05, 0.06, 1);
  static final vm.Vector4 tierEdgeGlow = vm.Vector4(0.95, 0.95, 0.98, 1);
  static final vm.Vector4 roofColor = vm.Vector4(0.06, 0.06, 0.07, 1);
  static final vm.Vector4 floodlightHousing = vm.Vector4(0.05, 0.05, 0.06, 1);
}

Float32List _polylineSegments(List<vm.Vector3> points, {bool closed = false}) {
  final segments = <double>[];
  for (var i = 0; i < points.length - 1; i++) {
    final a = points[i];
    final b = points[i + 1];
    segments.addAll([a.x, a.y, a.z, b.x, b.y, b.z]);
  }
  if (closed && points.length > 2) {
    final a = points.last;
    final b = points.first;
    segments.addAll([a.x, a.y, a.z, b.x, b.y, b.z]);
  }
  return Float32List.fromList(segments);
}

Node _lineNode(List<vm.Vector3> points, {bool closed = false, double width = 0.12}) {
  return Node(
    mesh: Mesh(
      LineSegmentsGeometry(
        LineSegmentData(positions: _polylineSegments(points, closed: closed)),
        width: width,
      ),
      UnlitMaterial()..baseColorFactor = _StadiumTheme.lineWhite,
    ),
  );
}

List<vm.Vector3> _circlePoints(vm.Vector3 center, double radius, {int segments = 56}) {
  return List.generate(segments + 1, (i) {
    final angle = 2 * math.pi * i / segments;
    return vm.Vector3(
      center.x + radius * math.cos(angle),
      0.01,
      center.z + radius * math.sin(angle),
    );
  });
}

List<vm.Vector3> _arcPoints(
  vm.Vector3 center,
  double radius,
  double startAngle,
  double sweep, {
  int segments = 24,
}) {
  return List.generate(segments + 1, (i) {
    final angle = startAngle + sweep * i / segments;
    return vm.Vector3(
      center.x + radius * math.cos(angle),
      0.01,
      center.z + radius * math.sin(angle),
    );
  });
}

Node _spotNode(vm.Vector3 world) {
  return Node(
    mesh: Mesh(
      DiscGeometry(radius: 0.35, segments: 16),
      UnlitMaterial()..baseColorFactor = _StadiumTheme.lineWhite,
    ),
    localTransform: vm.Matrix4.translation(world) * vm.Matrix4.rotationX(-math.pi / 2),
  );
}

Node buildPitchGround() {
  const stripeCount = 12;
  final stripeDepth = (PitchDimensions.halfLength * 2) / stripeCount;
  final root = Node();
  for (var i = 0; i < stripeCount; i++) {
    final z0 = -PitchDimensions.halfLength + i * stripeDepth;
    root.add(
      Node(
        mesh: Mesh(
          PlaneGeometry(width: PitchDimensions.halfWidth * 2, depth: stripeDepth),
          PhysicallyBasedMaterial()
            ..baseColorFactor = i.isEven
                ? _StadiumTheme.pitchGreenLight
                : _StadiumTheme.pitchGreenDark
            ..metallicFactor = 0.0
            ..roughnessFactor = 0.95,
        ),
        localTransform: vm.Matrix4.translation(
          vm.Vector3(0, 0, z0 + stripeDepth / 2),
        ),
      ),
    );
  }
  return root;
}

Node buildPitchLines() {
  final root = Node();
  final halfW = PitchDimensions.halfWidth;
  final halfL = PitchDimensions.halfLength;

  root.add(
    _lineNode([
      vm.Vector3(-halfW, 0.01, -halfL),
      vm.Vector3(halfW, 0.01, -halfL),
      vm.Vector3(halfW, 0.01, halfL),
      vm.Vector3(-halfW, 0.01, halfL),
    ], closed: true),
  );
  root.add(
    _lineNode([vm.Vector3(-halfW, 0.01, 0), vm.Vector3(halfW, 0.01, 0)]),
  );
  root.add(_lineNode(_circlePoints(vm.Vector3.zero(), PitchDimensions.centerCircleRadius), closed: true));
  root.add(_spotNode(vm.Vector3.zero()));

  for (final sign in [-1, 1]) {
    final goalLineZ = sign * halfL;
    final penaltyZ = goalLineZ - sign * PitchDimensions.penaltyAreaDepth;
    final goalZ = goalLineZ - sign * PitchDimensions.goalAreaDepth;
    final spotZ = goalLineZ - sign * PitchDimensions.penaltySpotDistance;

    root.add(
      _lineNode([
        vm.Vector3(-PitchDimensions.penaltyAreaHalfWidth, 0.01, goalLineZ),
        vm.Vector3(-PitchDimensions.penaltyAreaHalfWidth, 0.01, penaltyZ),
        vm.Vector3(PitchDimensions.penaltyAreaHalfWidth, 0.01, penaltyZ),
        vm.Vector3(PitchDimensions.penaltyAreaHalfWidth, 0.01, goalLineZ),
      ]),
    );
    root.add(
      _lineNode([
        vm.Vector3(-PitchDimensions.goalAreaHalfWidth, 0.01, goalLineZ),
        vm.Vector3(-PitchDimensions.goalAreaHalfWidth, 0.01, goalZ),
        vm.Vector3(PitchDimensions.goalAreaHalfWidth, 0.01, goalZ),
        vm.Vector3(PitchDimensions.goalAreaHalfWidth, 0.01, goalLineZ),
      ]),
    );
    root.add(_spotNode(vm.Vector3(0, 0, spotZ)));

    final toSpotAngle = sign < 0 ? -math.pi / 2 : math.pi / 2;
    root.add(
      _lineNode(
        _arcPoints(vm.Vector3(0, 0, spotZ), PitchDimensions.centerCircleRadius, toSpotAngle - 0.9, 1.8),
      ),
    );

    for (final dx in [-1.0, 1.0]) {
      root.add(
        _lineNode(
          _arcPoints(
            vm.Vector3(dx * halfW, 0.01, goalLineZ),
            PitchDimensions.cornerArcRadius,
            0,
            math.pi / 2,
          ),
        ),
      );
    }
  }
  return root;
}

double _standSpan({required bool alongX}) {
  return alongX
      ? (PitchDimensions.halfLength + PitchDimensions.standMargin + PitchDimensions.standDepth) * 2.25
      : (PitchDimensions.halfWidth + PitchDimensions.standMargin + PitchDimensions.standDepth) * 2.25;
}

double _standNear({required bool alongX}) {
  return (alongX ? PitchDimensions.halfWidth : PitchDimensions.halfLength) +
      PitchDimensions.standMargin;
}

/// Ascending terrace blocks (a stylized amphitheater silhouette) instead of
/// one smooth ramp — reads as tiered seating from any camera angle.
Node _standTiers({required bool alongX, required int sign}) {
  final span = _standSpan(alongX: alongX);
  const tiers = PitchDimensions.standTierCount;
  final stepDepth = PitchDimensions.standDepth / tiers;
  final stepHeight = PitchDimensions.standHeight / tiers;

  final root = Node()..localTransform = _standTransform(alongX: alongX, sign: sign);
  for (var i = 0; i < tiers; i++) {
    final tierHeight = (i + 1) * stepHeight;
    final localZ = i * stepDepth + stepDepth / 2;
    root.add(
      Node(
        mesh: Mesh(
          CuboidGeometry(vm.Vector3(span, tierHeight, stepDepth)),
          PhysicallyBasedMaterial()
            ..baseColorFactor =
                i.isEven ? _StadiumTheme.standColor : _StadiumTheme.standColorAlt
            ..metallicFactor = 0.15
            ..roughnessFactor = 0.85,
        ),
        localTransform: vm.Matrix4.translation(
          vm.Vector3(0, tierHeight / 2, localZ),
        ),
      ),
    );
    // A thin glowing strip along each tier's front lip — a walkway-light
    // detail that makes the steps legible even where direct light is weak.
    root.add(
      Node(
        mesh: Mesh(
          CuboidGeometry(vm.Vector3(span * 0.985, 0.18, 0.18)),
          UnlitMaterial()..baseColorFactor = _StadiumTheme.tierEdgeGlow,
        ),
        localTransform: vm.Matrix4.translation(
          vm.Vector3(0, tierHeight + 0.05, i * stepDepth),
        ),
      ),
    );
  }
  return root;
}

vm.Matrix4 _standTransform({required bool alongX, required int sign}) {
  final near = _standNear(alongX: alongX);
  final rotation = alongX
      ? vm.Matrix4.rotationY(sign > 0 ? math.pi / 2 : -math.pi / 2)
      : vm.Matrix4.rotationY(sign > 0 ? 0 : math.pi);
  final translation = alongX
      ? vm.Matrix4.translation(vm.Vector3(sign * near, 0, 0))
      : vm.Matrix4.translation(vm.Vector3(0, 0, sign * near));
  return translation * rotation;
}

/// A cantilevered roof panel over each stand, tilted down toward the pitch —
/// the silhouette detail that reads as "stadium" rather than "wall."
Node _standRoof({required bool alongX, required int sign}) {
  final span = _standSpan(alongX: alongX) * 0.92;
  const roofDepth = PitchDimensions.standDepth * 1.2;
  const roofClearance = 3.0;
  final localZ = PitchDimensions.standDepth / 2 - 4.0;

  final roof = Node(
    mesh: Mesh(
      CuboidGeometry(vm.Vector3(span, 1.3, roofDepth)),
      PhysicallyBasedMaterial()
        ..baseColorFactor = _StadiumTheme.roofColor
        ..metallicFactor = 0.5
        ..roughnessFactor = 0.55,
    ),
    localTransform: vm.Matrix4.translation(
          vm.Vector3(0, PitchDimensions.standHeight + roofClearance, localZ),
        ) *
        vm.Matrix4.rotationX(-0.09),
  );

  // Under-roof floodwash lights, aimed down at the terraces — otherwise the
  // stands only get whatever spill reaches them from the pitch floodlights
  // and render as an unlit, undetailed mass. Kept few and wide-reaching:
  // flutter_scene only shades the 16 strongest punctual lights per object,
  // and 4 corner floodlights are already in that budget.
  final washCount = (span / 70).ceil().clamp(1, 3);
  final washNodes = List.generate(washCount, (i) {
    final x = -span / 2 + span * (i + 0.5) / washCount;
    final position = vm.Vector3(
      x,
      PitchDimensions.standHeight + roofClearance - 1.0,
      localZ - roofDepth * 0.15,
    );
    return Node(localTransform: vm.Matrix4.translation(position))
      ..addComponent(
        SpotLightComponent(
          SpotLight(
            color: vm.Vector3(0.85, 0.82, 0.7),
            intensity: 260.0,
            range: 90.0,
            direction: vm.Vector3(0, -1, 0.4),
            innerConeAngle: 0.3,
            outerConeAngle: 0.95,
          ),
        ),
      );
  });

  return Node()
    ..add(roof)
    ..addAll(washNodes)
    ..localTransform = _standTransform(alongX: alongX, sign: sign);
}

/// A stylized four-sided stadium bowl: no real crowd imagery (none is
/// available to license for this), just tiered structure, a roof, floodlights,
/// and atmosphere — enough to read as "stadium at night" around the pitch.
Node buildStadiumBowl() {
  final root = Node();
  for (final entry in [
    (alongX: false, sign: 1),
    (alongX: false, sign: -1),
    (alongX: true, sign: 1),
    (alongX: true, sign: -1),
  ]) {
    root.add(_standTiers(alongX: entry.alongX, sign: entry.sign));
    root.add(_standRoof(alongX: entry.alongX, sign: entry.sign));
  }

  // A low accent band at the pitch-facing edge of each stand.
  for (final entry in [
    (alongX: false, sign: 1),
    (alongX: false, sign: -1),
    (alongX: true, sign: 1),
    (alongX: true, sign: -1),
  ]) {
    final near = (entry.alongX ? PitchDimensions.halfWidth : PitchDimensions.halfLength) +
        PitchDimensions.standMargin;
    final span = entry.alongX
        ? (PitchDimensions.halfLength + PitchDimensions.standMargin) * 2.1
        : (PitchDimensions.halfWidth + PitchDimensions.standMargin) * 2.1;
    final board = Node(
      mesh: Mesh(
        CuboidGeometry(vm.Vector3(entry.alongX ? 0.4 : span, 1.4, entry.alongX ? span : 0.4)),
        PhysicallyBasedMaterial()
          ..baseColorFactor = _StadiumTheme.standAccent
          ..metallicFactor = 0.4
          ..roughnessFactor = 0.5,
      ),
      localTransform: vm.Matrix4.translation(
        entry.alongX
            ? vm.Vector3(entry.sign * near, 0.7, 0)
            : vm.Vector3(0, 0.7, entry.sign * near),
      ),
    );
    root.add(board);
  }
  return root;
}

Node _floodlight(vm.Vector3 basePosition, vm.Vector3 aimAt) {
  const poleHeight = 46.0;
  final root = Node()
    ..localTransform = vm.Matrix4.translation(basePosition);

  root.add(
    Node(
      mesh: Mesh(
        CylinderGeometry(bottomRadius: 1.1, topRadius: 0.7, height: poleHeight),
        PhysicallyBasedMaterial()
          ..baseColorFactor = _StadiumTheme.floodlightHousing
          ..metallicFactor = 0.6
          ..roughnessFactor = 0.4,
      ),
      localTransform: vm.Matrix4.translation(vm.Vector3(0, poleHeight / 2, 0)),
    ),
  );

  final headPosition = vm.Vector3(0, poleHeight, 0);
  root.add(
    Node(
      mesh: Mesh(
        CuboidGeometry(vm.Vector3(4.5, 2.2, 2.5)),
        PhysicallyBasedMaterial()
          ..baseColorFactor = _StadiumTheme.floodlightHousing
          ..metallicFactor = 0.5
          ..roughnessFactor = 0.5,
      ),
      localTransform: vm.Matrix4.translation(headPosition),
    ),
  );

  final direction = (aimAt - (basePosition + headPosition)).normalized();
  root.add(
    Node(localTransform: vm.Matrix4.translation(headPosition))
      ..addComponent(
        SpotLightComponent(
          SpotLight(
            color: vm.Vector3(1.0, 0.97, 0.88),
            intensity: 420.0,
            range: 220.0,
            direction: direction,
            innerConeAngle: 0.35,
            outerConeAngle: 0.62,
          ),
        ),
      ),
  );

  return root;
}

Node buildFloodlights() {
  final root = Node();
  final corner = PitchDimensions.halfWidth + PitchDimensions.standMargin + PitchDimensions.standDepth - 3;
  final cornerZ = PitchDimensions.halfLength + PitchDimensions.standMargin + PitchDimensions.standDepth - 3;
  final target = vm.Vector3(0, 1.5, 0);
  for (final x in [-corner, corner]) {
    for (final z in [-cornerZ, cornerZ]) {
      root.add(_floodlight(vm.Vector3(x, 0, z), target));
    }
  }
  return root;
}

/// A built [scene] plus handles on its [pitch] node (ground + markings) and
/// its [stadium] node (bowl + floodlights), so the caller can detach and
/// reattach either independently — see [OrbitCamera.isViewObstructed] and
/// the pitch/stadium view toggle in `OrbitPitch`.
class StadiumBuild {
  const StadiumBuild(this.scene, this.pitch, this.stadium);

  final Scene scene;
  final Node pitch;
  final Node stadium;
}

/// Assembles the pitch, markings, stadium bowl, floodlights, and night
/// atmosphere (fog + dim moonlight + bloom) into a ready-to-render [Scene].
StadiumBuild buildStadiumScene() {
  final scene = Scene();
  final pitch = Node()
    ..add(buildPitchGround())
    ..add(buildPitchLines());
  final stadium = Node()
    ..add(buildStadiumBowl())
    ..add(buildFloodlights());
  scene.add(pitch);
  scene.add(stadium);

  scene.directionalLight = DirectionalLight(
    direction: vm.Vector3(-0.3, -1.0, -0.25),
    intensity: 1.7,
    color: vm.Vector3(0.6, 0.65, 0.8),
  );

  scene.fog
    ..enabled = true
    ..mode = FogMode.exponential
    ..color = vm.Vector3(0.05, 0.055, 0.08)
    ..density = Fog.visibilityDensity(230)
    ..height = 20
    ..heightFalloff = 0.02;

  scene.postProcess.bloom
    ..enabled = true
    ..threshold = 0.7
    ..intensity = 1.0
    ..scatter = 0.7;
  scene.postProcess.vignette
    ..enabled = true
    ..intensity = 0.45;
  scene.postProcess.colorGrading
    ..enabled = true
    ..saturation = 1.05
    ..contrast = 1.08;

  return StadiumBuild(scene, pitch, stadium);
}
