import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One telestrator-style arrow: a straight line with an arrowhead, in the
/// pitch view's local screen space. Meaningful only while the camera that
/// was frozen to draw it stays put — see [TacticalDrawingLayer].
class TacticalLine {
  const TacticalLine({
    required this.start,
    required this.end,
    required this.color,
  });

  final Offset start;
  final Offset end;
  final Color color;
}

/// Preset colors matching the white/yellow/cyan/red palette real broadcast
/// tactics cameras use.
const List<Color> tacticalLineColors = [
  Colors.white,
  Colors.amberAccent,
  Colors.cyanAccent,
  Color(0xFFFF5252),
];

class TacticalLinesPainter extends CustomPainter {
  const TacticalLinesPainter(this.lines, this.liveLine);

  final List<TacticalLine> lines;
  final TacticalLine? liveLine;

  static const double _strokeWidth = 3.5;
  static const double _arrowSize = 13;

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      _paintArrow(canvas, line);
    }
    if (liveLine != null) _paintArrow(canvas, liveLine!, dashed: true);
  }

  void _paintArrow(Canvas canvas, TacticalLine line, {bool dashed = false}) {
    final glow = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..strokeWidth = _strokeWidth + 2.5
      ..strokeCap = StrokeCap.round;
    final stroke = Paint()
      ..color = line.color.withValues(alpha: dashed ? 0.75 : 1.0)
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(line.start, line.end, glow);
    canvas.drawLine(line.start, line.end, stroke);

    final direction = line.end - line.start;
    if (direction.distance < 1) return;
    final angle = math.atan2(direction.dy, direction.dx);
    final path = Path()
      ..moveTo(line.end.dx, line.end.dy)
      ..lineTo(
        line.end.dx - _arrowSize * math.cos(angle - math.pi / 7),
        line.end.dy - _arrowSize * math.sin(angle - math.pi / 7),
      )
      ..lineTo(
        line.end.dx - _arrowSize * math.cos(angle + math.pi / 7),
        line.end.dy - _arrowSize * math.sin(angle + math.pi / 7),
      )
      ..close();
    canvas.drawPath(path, Paint()..color = stroke.color);
  }

  @override
  bool shouldRepaint(covariant TacticalLinesPainter oldDelegate) =>
      oldDelegate.lines != lines || oldDelegate.liveLine != liveLine;
}

/// The floating pencil/color/undo/clear toolbar. Collapses to just the
/// pencil toggle when drawing is off.
class TacticalDrawingToolbar extends StatelessWidget {
  const TacticalDrawingToolbar({
    super.key,
    required this.active,
    required this.onToggle,
    required this.selectedColor,
    required this.onColorSelected,
    required this.canUndo,
    required this.onUndo,
    required this.onClear,
  });

  final bool active;
  final VoidCallback onToggle;
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  final bool canUndo;
  final VoidCallback onUndo;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToolButton(
            icon: Icons.edit_rounded,
            active: active,
            onTap: onToggle,
            tooltip: active ? 'Stop drawing' : 'Draw on pitch',
          ),
          if (active) ...[
            const SizedBox(height: 8),
            for (final color in tacticalLineColors)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: () => onColorSelected(color),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selectedColor == color
                            ? Colors.white
                            : Colors.white24,
                        width: selectedColor == color ? 2.5 : 1,
                      ),
                    ),
                  ),
                ),
              ),
            const Divider(height: 6, color: Colors.white24),
            _ToolButton(
              icon: Icons.undo_rounded,
              active: false,
              onTap: canUndo ? onUndo : null,
              tooltip: 'Undo',
            ),
            const SizedBox(height: 6),
            _ToolButton(
              icon: Icons.layers_clear_rounded,
              active: false,
              onTap: canUndo ? onClear : null,
              tooltip: 'Clear all',
            ),
          ],
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.active,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final bool active;
  final VoidCallback? onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active ? Colors.amberAccent : Colors.white.withValues(alpha: 0.08),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 18,
              color: onTap == null
                  ? Colors.white24
                  : (active ? Colors.black : Colors.white70),
            ),
          ),
        ),
      ),
    );
  }
}
