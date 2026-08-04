import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';

import 'vfx_controller.dart';
import 'vfx_hud.dart';

/// Top-level page: wires the [VfxController]'s scene into a [SceneView] and
/// layers the [VfxHud] control panel on top.
class VfxScreen extends StatefulWidget {
  const VfxScreen({super.key});

  @override
  State<VfxScreen> createState() => _VfxScreenState();
}

class _VfxScreenState extends State<VfxScreen> {
  final VfxController _controller = VfxController();
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
      body: Stack(
        children: [
          Positioned.fill(
            child: SceneView(
              _controller.scene,
              cameraBuilder: _controller.cameraFor,
              onTick: _controller.tick,
            ),
          ),
          VfxHud(controller: _controller),
        ],
      ),
    );
  }
}
