import 'package:flutter/material.dart';

import '../models/match_data.dart';

/// The shirt-number token on the pitch. Purely presentational — dragging and
/// tap-to-select are wired up by [TacticalPitch], which owns each marker's
/// on-pitch position.
class PlayerMarker extends StatelessWidget {
  const PlayerMarker({
    super.key,
    required this.slot,
    required this.selected,
    required this.dragging,
    this.depthScale = 1.0,
  });

  final PlayerSlot slot;
  final bool selected;
  final bool dragging;

  /// Perspective foreshortening from [OrbitCamera.project] — >1 when nearer
  /// the camera than the pitch center, <1 when farther.
  final double depthScale;

  static const _clubRed = Color(0xFFDA291C);

  @override
  Widget build(BuildContext context) {
    final scale = (dragging ? 1.18 : 1.0) * depthScale.clamp(0.55, 1.6);
    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 120),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _clubRed,
              border: Border.all(
                color: dragging
                    ? Colors.cyanAccent
                    : selected
                        ? Colors.amberAccent
                        : Colors.white,
                width: selected || dragging ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dragging ? 0.55 : 0.35),
                  blurRadius: dragging ? 14 : 6,
                  offset: Offset(0, dragging ? 6 : 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '${slot.shirtNumber}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              slot.shortName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
