import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';

import 'arena_controller.dart';
import 'arena_hud.dart';

/// Top-level page: wires the [ArenaController]'s scene into a [SceneView],
/// forwards drag gestures to it, and layers the [ArenaHud] on top.
class ArenaScreen extends StatefulWidget {
  const ArenaScreen({super.key});

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  final ArenaController _controller = ArenaController();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _controller.load().then((_) {
      if (!mounted) return;
      setState(() => _loaded = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onPanUpdate: (details) => _controller.dragLogo(details.delta),
        child: Stack(
          children: [
            Positioned.fill(
              child: SceneView(
                _controller.scene,
                cameraBuilder: _controller.cameraFor,
                onTick: _controller.tick,
              ),
            ),
            const ArenaHud(),
          ],
        ),
      ),
    );
  }
}
