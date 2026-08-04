import 'package:flutter/material.dart';

import 'birthday_controller.dart';

/// The birthday message and the confetti button, overlaid on the scene.
class BirthdayHud extends StatelessWidget {
  const BirthdayHud({super.key, required this.controller});

  final BirthdayController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Text(
                  'HAPPY 1ST BIRTHDAY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    letterSpacing: 4,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.7),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'LAEL',
                  style: TextStyle(
                    color: const Color(0xFFFFD873),
                    fontWeight: FontWeight.w900,
                    fontSize: 54,
                    letterSpacing: 10,
                    shadows: [
                      Shadow(
                        color: const Color(0xFFFFD873).withValues(alpha: 0.85),
                        blurRadius: 34,
                      ),
                      const Shadow(color: Colors.black, blurRadius: 18),
                    ],
                  ),
                ),
              ],
            ),
            FilledButton.icon(
              onPressed: controller.confetti.trigger,
              icon: const Icon(Icons.celebration),
              label: const Text('More confetti!'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
