import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart' hide Material;
import 'package:vector_math/vector_math.dart' as vm;

import '../engine/orbit_camera.dart';
import '../game/stadium_scene_builder.dart';
import '../models/match_data.dart';
import 'player_action_spotlight.dart';
import 'player_marker.dart';
import 'sparkle_burst.dart';
import 'tactical_drawing.dart';

/// The full-bleed 3D board: a real GPU-rendered stadium (pitch, markings,
/// stands, floodlights, fog) you orbit and zoom, with 2D marker/spotlight
/// overlays projected through the same camera via `worldToScreen` — so the
/// interactive layer always lines up with what the GPU actually rendered.
class OrbitPitch extends StatefulWidget {
  const OrbitPitch({
    super.key,
    required this.slots,
    required this.selectedSlotId,
    required this.onSelect,
    this.onBackgroundTap,
  });

  final List<PlayerSlot> slots;
  final String? selectedSlotId;
  final ValueChanged<PlayerSlot> onSelect;
  final VoidCallback? onBackgroundTap;

  @override
  State<OrbitPitch> createState() => _OrbitPitchState();
}

class _OrbitPitchState extends State<OrbitPitch> {
  final OrbitCamera _camera = OrbitCamera();
  late final Map<String, vm.Vector3> _world = {
    for (final slot in widget.slots)
      slot.id: vm.Vector3(
        slot.x * PitchDimensions.halfWidth,
        0,
        slot.y * PitchDimensions.halfLength,
      ),
  };

  // `LineSegmentsGeometry` (used for every pitch marking) touches the base
  // shader library synchronously in its constructor, so the scene can't be
  // built until that library has actually finished loading.
  Scene? _scene;
  Node? _pitchNode;
  bool _pitchAttached = true;
  Node? _stadiumNode;
  bool _stadiumAttached = true;
  bool _showStadium = true;

  double _scaleStartDistance = 0;
  String? _draggingId;
  Offset? _dragScreenPos;

  bool _drawMode = false;
  Color _drawColor = tacticalLineColors[1];
  final List<TacticalLine> _lines = [];
  Offset? _drawStart;
  Offset? _drawCurrent;

  final List<({Key key, Offset origin})> _sparkles = [];

  @override
  void initState() {
    super.initState();
    Scene.initializeStaticResources().then((_) {
      if (!mounted) return;
      final build = buildStadiumScene();
      setState(() {
        _scene = build.scene;
        _pitchNode = build.pitch;
        _stadiumNode = build.stadium;
      });
    });
  }

  /// Pitch-only mode: hide the stands entirely and pull the camera into a
  /// closer, more top-down framing so the pitch fills the whole view. Back
  /// to "both": restore the stands and the wider tactical framing.
  void _toggleStadium() {
    setState(() {
      _showStadium = !_showStadium;
      final scene = _scene;
      final stadium = _stadiumNode;
      if (scene != null && stadium != null) {
        if (_showStadium && !_stadiumAttached) {
          scene.add(stadium);
          _stadiumAttached = true;
        } else if (!_showStadium && _stadiumAttached) {
          scene.remove(stadium);
          _stadiumAttached = false;
        }
      }
      if (_showStadium) {
        _camera.distance = 105.0;
        _camera.pitch = 0.62;
      } else {
        _camera.distance = 68.0;
        _camera.pitch = 1.05;
      }
    });
  }

  /// Detaches/reattaches the pitch mesh to match [obstructed] — cheap, since
  /// it only touches the scene graph when the state actually flips.
  void _syncPitchVisibility(bool obstructed) {
    final scene = _scene;
    final pitch = _pitchNode;
    if (scene == null || pitch == null) return;
    if (obstructed && _pitchAttached) {
      scene.remove(pitch);
      _pitchAttached = false;
    } else if (!obstructed && !_pitchAttached) {
      scene.add(pitch);
      _pitchAttached = true;
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    _scaleStartDistance = _camera.distance;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      if (details.pointerCount >= 2) {
        _camera.distance = (_scaleStartDistance / details.scale).clamp(
          OrbitCamera.minDistance,
          OrbitCamera.maxDistance,
        );
      }
      _camera.orbit(details.focalPointDelta);
    });
  }

  void _onScroll(PointerScrollEvent event) {
    setState(() => _camera.zoomBy(event.scrollDelta.dy > 0 ? 1.08 : 0.93));
  }

  void _toggleDrawMode() {
    setState(() {
      _drawMode = !_drawMode;
      if (!_drawMode) _lines.clear();
      _drawStart = null;
      _drawCurrent = null;
    });
  }

  void _onDrawPanStart(DragStartDetails details) {
    setState(() {
      _drawStart = details.localPosition;
      _drawCurrent = details.localPosition;
    });
  }

  void _onDrawPanUpdate(DragUpdateDetails details) {
    setState(() => _drawCurrent = details.localPosition);
  }

  void _onDrawPanEnd(DragEndDetails details) {
    final start = _drawStart;
    final end = _drawCurrent;
    setState(() {
      if (start != null && end != null && (end - start).distance > 8) {
        _lines.add(TacticalLine(start: start, end: end, color: _drawColor));
      }
      _drawStart = null;
      _drawCurrent = null;
    });
  }

  void _undoLine() => setState(() => _lines.removeLast());
  void _clearLines() => setState(_lines.clear);

  void _spawnSparkle(Offset origin) {
    if (_drawMode) return;
    setState(() => _sparkles.add((key: UniqueKey(), origin: origin)));
  }

  void _removeSparkle(Key key) {
    setState(() => _sparkles.removeWhere((s) => s.key == key));
  }

  void _dragMarker(String slotId, Offset delta, Size viewport) {
    final dragPos = (_dragScreenPos ?? Offset.zero) + delta;
    _dragScreenPos = dragPos;
    final ground = _camera.screenToGround(dragPos, viewport);
    if (ground == null) return;
    setState(() {
      _world[slotId] = vm.Vector3(
        ground.x.clamp(
          -PitchDimensions.halfWidth + 1,
          PitchDimensions.halfWidth - 1,
        ),
        0,
        ground.z.clamp(
          -PitchDimensions.halfLength + 1,
          PitchDimensions.halfLength - 1,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scene;
    if (scene == null) {
      return const ColoredBox(
        color: Color(0xFF0B0F0C),
        child: Center(
          child: CircularProgressIndicator(color: Colors.white38),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = constraints.biggest;
        final camera = _camera.toPerspectiveCamera();
        final refDistance = (camera.position - camera.target).length;
        // No stands to clip into in pitch-only mode, so nothing to hide for.
        final obstructed = _showStadium &&
            _camera.isViewObstructed(
              innerEdge: PitchDimensions.standInnerEdge,
              outerEdge: PitchDimensions.standOuterEdge,
              rooflineHeight: PitchDimensions.rooflineHeight,
            );
        _syncPitchVisibility(obstructed);

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Listener(
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) _onScroll(event);
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onBackgroundTap,
                  onTapDown: (details) => _spawnSparkle(details.localPosition),
                  onScaleStart: _drawMode ? null : _onScaleStart,
                  onScaleUpdate: _drawMode ? null : _onScaleUpdate,
                  child: SceneView(scene, camera: camera),
                ),
              ),
            ),
            // Drawing catches pan gestures on *empty* pitch — placed below
            // the markers in the stack so a marker's own opaque hit region
            // claims a drag that starts on it first (move the player) and
            // only touches outside every marker fall through to here (draw
            // a line). That's what lets dragging players and drawing work
            // at the same time instead of one blocking the other.
            if (_drawMode)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: _onDrawPanStart,
                  onPanUpdate: _onDrawPanUpdate,
                  onPanEnd: _onDrawPanEnd,
                ),
              ),
            if (!obstructed && widget.selectedSlotId != null)
              _buildFocusDim(widget.selectedSlotId!, camera, viewport),
            if (!obstructed)
              for (final slot in widget.slots)
                _buildMarker(slot, camera, refDistance, viewport),
            if (!obstructed && widget.selectedSlotId != null)
              _buildSpotlight(widget.selectedSlotId!, camera, refDistance, viewport),
            if (_lines.isNotEmpty || _drawStart != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: TacticalLinesPainter(
                      _lines,
                      _drawStart != null && _drawCurrent != null
                          ? TacticalLine(
                              start: _drawStart!,
                              end: _drawCurrent!,
                              color: _drawColor,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            for (final sparkle in _sparkles)
              IgnorePointer(
                child: SparkleBurst(
                  key: sparkle.key,
                  origin: sparkle.origin,
                  onComplete: () => _removeSparkle(sparkle.key),
                ),
              ),
            Positioned(
              top: 12,
              left: 12,
              child: _StadiumViewToggle(
                showStadium: _showStadium,
                onToggle: _toggleStadium,
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: TacticalDrawingToolbar(
                active: _drawMode,
                onToggle: _toggleDrawMode,
                selectedColor: _drawColor,
                onColorSelected: (color) => setState(() => _drawColor = color),
                canUndo: _lines.isNotEmpty,
                onUndo: _undoLine,
                onClear: _clearLines,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFocusDim(
    String slotId,
    PerspectiveCamera camera,
    Size viewport,
  ) {
    final screen = camera.worldToScreen(_world[slotId]!, viewport);
    if (screen == null) return const SizedBox.shrink();
    final center = Alignment(
      (screen.dx / viewport.width) * 2 - 1,
      (screen.dy / viewport.height) * 2 - 1,
    );
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: center,
              radius: 0.75,
              colors: [
                Colors.black.withValues(alpha: 0),
                Colors.black.withValues(alpha: 0.55),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarker(
    PlayerSlot slot,
    PerspectiveCamera camera,
    double refDistance,
    Size viewport,
  ) {
    final world = _world[slot.id]!;
    final screen = camera.worldToScreen(world, viewport);
    if (screen == null) return const SizedBox.shrink();
    final depthScale = refDistance / (camera.position - world).length;
    return Positioned(
      left: screen.dx,
      top: screen.dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onSelect(slot),
          onPanStart: (_) => setState(() {
            _draggingId = slot.id;
            _dragScreenPos = screen;
          }),
          onPanUpdate: (details) =>
              _dragMarker(slot.id, details.delta, viewport),
          onPanEnd: (_) => setState(() {
            _draggingId = null;
            _dragScreenPos = null;
          }),
          child: PlayerMarker(
            slot: slot,
            selected: slot.id == widget.selectedSlotId,
            dragging: slot.id == _draggingId,
            depthScale: depthScale,
          ),
        ),
      ),
    );
  }

  Widget _buildSpotlight(
    String slotId,
    PerspectiveCamera camera,
    double refDistance,
    Size viewport,
  ) {
    final world = _world[slotId]!;
    final screen = camera.worldToScreen(world, viewport);
    if (screen == null) return const SizedBox.shrink();
    final slot = widget.slots.firstWhere((s) => s.id == slotId);
    final depthScale = refDistance / (camera.position - world).length;

    const w = PlayerActionSpotlight.width;
    const h = PlayerActionSpotlight.height;
    final maxLeft = (viewport.width - w).clamp(0.0, double.infinity);
    final maxTop = (viewport.height - h).clamp(0.0, double.infinity);
    final left = (screen.dx - w / 2).clamp(0.0, maxLeft);
    final top = (screen.dy - h - 8).clamp(0.0, maxTop);

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: PlayerActionSpotlight(
          slot: slot,
          depthScale: depthScale,
          cameraYaw: _camera.yaw,
          cameraPitch: _camera.pitch,
        ),
      ),
    );
  }
}

/// Pitch-only vs. pitch-and-stadium switch.
class _StadiumViewToggle extends StatelessWidget {
  const _StadiumViewToggle({
    required this.showStadium,
    required this.onToggle,
  });

  final bool showStadium;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: showStadium ? 'Show pitch only' : 'Show stadium',
      child: Material(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Icon(
              showStadium
                  ? Icons.stadium_outlined
                  : Icons.crop_square_rounded,
              size: 20,
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}
