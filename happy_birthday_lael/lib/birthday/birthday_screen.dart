import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';

import 'birthday_controller.dart';
import 'birthday_hud.dart';

/// Top-level page: wires the [BirthdayController]'s scene into a
/// [SceneView] and layers the birthday message + confetti button on top.
class BirthdayScreen extends StatefulWidget {
  const BirthdayScreen({super.key});

  @override
  State<BirthdayScreen> createState() => _BirthdayScreenState();
}

class _BirthdayScreenState extends State<BirthdayScreen> {
  final BirthdayController _controller = BirthdayController();
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
              pixelRatio: 1.0,
            ),
          ),
          BirthdayHud(controller: _controller),
        ],
      ),
    );
  }
}
