import 'package:flutter/material.dart';

import 'arena_theme.dart';

/// The game-style overlay: title, character name tags, and the drag hint.
/// Pure presentation — no gameplay state lives here.
class ArenaHud extends StatelessWidget {
  const ArenaHud({super.key});

  static const _titleStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w900,
    fontSize: 28,
    letterSpacing: 6,
    shadows: [Shadow(color: Colors.black, blurRadius: 16)],
  );

  Widget _nameTag(String text, Color glowColor) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: 18,
        letterSpacing: 3,
        shadows: [Shadow(color: glowColor, blurRadius: 18)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            const Text('FLUTTER ARENA', style: _titleStyle),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _nameTag('FLUTTER', ArenaTheme.logoAccent),
                _nameTag('DASH', ArenaTheme.dashAccent),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'DRAG THE LOGO TO STAY AWAY FROM DASH',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontWeight: FontWeight.w600,
                fontSize: 11,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
