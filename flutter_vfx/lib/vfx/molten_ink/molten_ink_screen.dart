import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'debris_pool.dart';
import 'fluid_painter.dart';
import 'fluid_simulation.dart';

/// Drag your finger to paint swirling, fluid fire; it cools into real 3D
/// obsidian chunks that tumble away.
///
/// Two layers, composited via a plain [Stack]: a [CustomPaint] running the
/// CPU fluid simulation as the background, and a [SceneView] with a
/// transparent background (flutter_scene's [Scene.skybox] is `null` by
/// default, which clears to transparent) on top, holding only the real 3D
/// debris. Both are driven from the same per-frame clock so they never
/// drift out of sync.
class MoltenInkScreen extends StatefulWidget {
  const MoltenInkScreen({super.key});

  @override
  State<MoltenInkScreen> createState() => _MoltenInkScreenState();
}

class _MoltenInkScreenState extends State<MoltenInkScreen> {
  final FluidSimulation _sim = FluidSimulation();
  final Scene _scene = Scene();
  late final DebrisPool _debris = DebrisPool(scene: _scene);
  // A repaint tick counter rather than a bare ChangeNotifier: notifying an
  // instance's own listeners from outside the class isn't allowed
  // (notifyListeners is protected), but ValueNotifier's public value
  // setter does the same job.
  final ValueNotifier<int> _repaintNotifier = ValueNotifier<int>(0);

  ui.Image? _fluidImage;
  bool _decodingImage = false;
  bool _loaded = false;

  Size _viewSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Scene.initializeStaticResources();
    _debris.load();
    if (!mounted) return;
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _scene.removeAll();
    _repaintNotifier.dispose();
    super.dispose();
  }

  int _debugSplatCount = 0;

  void _onPanUpdate(DragUpdateDetails details) {
    _debugSplatCount++;
    // ignore: avoid_print
    print(
      'DEBUG onPanUpdate #$_debugSplatCount viewSize=$_viewSize '
      'local=${details.localPosition} delta=${details.delta}',
    );
    if (_viewSize.isEmpty) return;
    final pos = details.localPosition;
    final gridX = (pos.dx / _viewSize.width).clamp(0.0, 1.0);
    final gridY = (pos.dy / _viewSize.height).clamp(0.0, 1.0);

    // Screen-pixel drag delta scaled into simulation velocity units.
    const sensitivity = 0.16;
    _sim.splat(
      gridX: gridX,
      gridY: gridY,
      dirX: details.delta.dx * sensitivity,
      dirY: details.delta.dy * sensitivity,
    );
  }

  /// Grid-normalized `[0, 1]` coordinates onto the plane the debris camera
  /// frames. Deliberately approximate — "falls from about where the fire
  /// was," not pixel-perfect registration between the 2D and 3D layers.
  vm.Vector3 _gridToWorld(double gx, double gy) {
    const planeWidth = 7.0;
    const planeHeight = 4.0;
    return vm.Vector3((gx - 0.5) * planeWidth, (0.5 - gy) * planeHeight, 0);
  }

  int _debugTickCount = 0;

  void _tick(Duration elapsed, double deltaSeconds) {
    final dt = deltaSeconds.clamp(0.0, 1 / 30);
    final coolingEvents = _sim.step(dt);
    for (final event in coolingEvents) {
      _debris.spawn(_gridToWorld(event.gridX, event.gridY));
    }
    _debris.tick(dt);

    _debugTickCount++;
    if (_debugTickCount % 30 == 0) {
      var maxHeat = 0.0;
      for (final h in _sim.heat) {
        if (h > maxHeat) maxHeat = h;
      }
      // ignore: avoid_print
      print('DEBUG tick #$_debugTickCount maxHeat=$maxHeat dt=$dt');
    }

    if (!_decodingImage) {
      _decodingImage = true;
      renderHeatFieldToImage(_sim).then((image) {
        _fluidImage = image;
        _decodingImage = false;
        _repaintNotifier.value++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: Color(0xFF08060D),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF08060D),
      body: LayoutBuilder(
        builder: (context, constraints) {
          _viewSize = constraints.biggest;
          return GestureDetector(
            onPanUpdate: _onPanUpdate,
            child: Stack(
              children: [
                // Debris layer behind: even though flutter_scene documents
                // a null skybox as "clears to transparent," Canvas alpha
                // compositing is the one guarantee here I don't have to
                // take on faith, so the layer whose transparency actually
                // matters (the fluid painter, below) goes on top instead.
                Positioned.fill(
                  child: SceneView(
                    _scene,
                    camera: PerspectiveCamera(
                      position: vm.Vector3(0, 0, 6),
                      target: vm.Vector3.zero(),
                    ),
                    onTick: _tick,
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: FluidPainter(
                      image: _fluidImage,
                      repaint: _repaintNotifier,
                    ),
                  ),
                ),
                _buildHud(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHud(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            const SizedBox(width: 4),
            const Text(
              'MOLTEN INK',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                fontSize: 16,
                shadows: [Shadow(color: Colors.black, blurRadius: 12)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
