import 'package:flutter/material.dart';

import 'molten_ink/molten_ink_screen.dart';
import 'vfx_controller.dart';

/// The control panel: a title, buttons to fire the one-shot effects, and a
/// switch for the continuous ember stream.
class VfxHud extends StatefulWidget {
  const VfxHud({super.key, required this.controller});

  final VfxController controller;

  @override
  State<VfxHud> createState() => _VfxHudState();
}

class _VfxHudState extends State<VfxHud> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'FLUTTER VFX PLAYGROUND',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: 4,
                      shadows: [Shadow(color: Colors.black, blurRadius: 12)],
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const MoltenInkScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.local_fire_department),
                  label: const Text('Molten Ink'),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilledButton.icon(
                  onPressed: controller.shards.trigger,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Shards'),
                ),
                FilledButton.icon(
                  onPressed: controller.shatter.trigger,
                  icon: const Icon(Icons.scatter_plot),
                  label: const Text('Shatter'),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Wisps', style: TextStyle(color: Colors.white)),
                    Switch(
                      value: controller.wisps.enabled,
                      onChanged: (value) {
                        setState(() => controller.wisps.enabled = value);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
