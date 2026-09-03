import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/match_data.dart';
import 'player_photo.dart';

/// The dynamic figure that appears at a selected player's pitch position:
/// their real photo (bottom-faded into a standing cutout), tied to the
/// actual orbit camera — it scales with distance, tilts with yaw/pitch, and
/// casts a camera-angle-aware shadow, so it reads as standing *in* the 3D
/// scene rather than a flat sticker over it. A bob/lean loop and speed-line
/// streaks add motion on top. This is real photography given motion and
/// perspective *effects* — not fabricated footage of the player actually
/// running, which isn't something synthetic media of a real, identifiable
/// person should be used for.
class PlayerActionSpotlight extends StatefulWidget {
  const PlayerActionSpotlight({
    super.key,
    required this.slot,
    required this.depthScale,
    required this.cameraYaw,
    required this.cameraPitch,
  });

  final PlayerSlot slot;

  /// >1 nearer the camera than the pitch center, <1 farther — matches how
  /// markers are sized, so the figure and its marker agree on distance.
  final double depthScale;

  final double cameraYaw;
  final double cameraPitch;

  static const double width = 108;
  static const double height = 190;

  @override
  State<PlayerActionSpotlight> createState() => _PlayerActionSpotlightState();
}

class _PlayerActionSpotlightState extends State<PlayerActionSpotlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _initials {
    final parts = widget.slot.fullName.split(' ').where((p) => p.isNotEmpty);
    return parts.map((p) => p[0]).take(2).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // Reads camera orientation into a small billboard tilt (a "cardboard
    // cutout" that partially turns with you, not a full free rotation) and
    // an angle-aware ground shadow.
    final yawTilt = math.sin(widget.cameraYaw) * 0.14;
    final pitchTilt = (widget.cameraPitch - 0.62).clamp(-0.4, 0.4) * 0.5;
    final shadowStretch = 1 + (1.1 - widget.cameraPitch).clamp(0.0, 1.0) * 1.6;
    final scale = widget.depthScale.clamp(0.5, 1.8);

    return Transform.scale(
      scale: scale,
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: PlayerActionSpotlight.width,
        height: PlayerActionSpotlight.height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value * 2 * math.pi;
            final bob = math.sin(t) * 5;
            final lean = math.sin(t + 0.6) * 0.035;
            final squash = 1 - (math.sin(t).abs() * 0.25);
            final glint = (math.sin(t * 0.6) + 1) / 2;

            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                ..._speedLines(t),
                Positioned(
                  bottom: 14,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateZ(yawTilt * 0.3),
                    child: Container(
                      width: 70 * squash * shadowStretch,
                      height: 16 * squash,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.45),
                            Colors.black.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 18,
                  child: Transform(
                    alignment: Alignment.bottomCenter,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0016)
                      ..rotateX(pitchTilt)
                      ..rotateY(yawTilt),
                    child: Transform.translate(
                      offset: Offset(0, bob),
                      child: Transform.rotate(
                        angle: lean,
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amberAccent.withValues(
                                  alpha: 0.25,
                                ),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Stack(
                              children: [
                                PlayerPhoto(
                                  slug: widget.slot.photoAssetSlug,
                                  initials: _initials,
                                  width: PlayerActionSpotlight.width,
                                  height: 150,
                                  round: false,
                                  fadeBottom: true,
                                ),
                                IgnorePointer(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment(-1 + glint * 3, -1),
                                        end: Alignment(-0.3 + glint * 3, -0.3),
                                        colors: [
                                          Colors.white.withValues(alpha: 0),
                                          Colors.white.withValues(alpha: 0.28),
                                          Colors.white.withValues(alpha: 0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _speedLines(double t) {
    return List.generate(3, (i) {
      final phase = (t + i * 2.1) % (2 * math.pi);
      final progress = phase / (2 * math.pi);
      final opacity = (1 - progress) * 0.4;
      return Positioned(
        bottom: 40 + i * 24.0,
        right: PlayerActionSpotlight.width * 0.55 + progress * 46,
        child: Container(
          width: 28 + progress * 10,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity.clamp(0, 0.4)),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
    });
  }
}
