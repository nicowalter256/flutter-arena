import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A short-lived burst of sparkle particles at [origin] — a tap-feedback
/// flourish, not tied to any player or real-world imagery.
class SparkleBurst extends StatefulWidget {
  const SparkleBurst({
    super.key,
    required this.origin,
    required this.onComplete,
  });

  final Offset origin;
  final VoidCallback onComplete;

  @override
  State<SparkleBurst> createState() => _SparkleBurstState();
}

class _SparkleBurstState extends State<SparkleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  static const _colors = [
    Colors.amberAccent,
    Colors.white,
    Colors.cyanAccent,
  ];

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    _particles = List.generate(10, (i) {
      final angle = (2 * math.pi * i / 10) + rng.nextDouble() * 0.4;
      return _Particle(
        angle: angle,
        distance: 34 + rng.nextDouble() * 28,
        size: 10 + rng.nextDouble() * 10,
        color: _colors[i % _colors.length],
        spin: (rng.nextBool() ? 1 : -1) * (1.5 + rng.nextDouble()),
      );
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..forward().whenComplete(widget.onComplete);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_controller.value);
        final fade = 1 - Curves.easeIn.transform(_controller.value);
        final popIn = Curves.easeOutBack.transform(
          (_controller.value * 2.5).clamp(0.0, 1.0),
        );
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final p in _particles)
              Positioned(
                left: widget.origin.dx + math.cos(p.angle) * p.distance * t,
                top: widget.origin.dy + math.sin(p.angle) * p.distance * t,
                child: Opacity(
                  opacity: fade.clamp(0, 1),
                  child: Transform.rotate(
                    angle: p.spin * t * math.pi,
                    child: Icon(
                      Icons.auto_awesome,
                      size: p.size * (0.6 + fade * 0.4),
                      color: p.color,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: widget.origin.dx,
              top: widget.origin.dy - 18,
              child: FractionalTranslation(
                translation: const Offset(-0.5, -1),
                child: Opacity(
                  opacity: fade.clamp(0, 1),
                  child: Transform.scale(
                    scale: 0.7 + popIn * 0.3,
                    child: const Text(
                      'flutter scene',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.4,
                        shadows: [
                          Shadow(color: Colors.black, blurRadius: 6),
                          Shadow(color: Colors.cyanAccent, blurRadius: 14),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Particle {
  _Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
    required this.spin,
  });

  final double angle;
  final double distance;
  final double size;
  final Color color;
  final double spin;
}
