import 'package:flutter/material.dart';

import 'vfx/vfx_screen.dart';

void main() {
  runApp(const VfxPlaygroundApp());
}

class VfxPlaygroundApp extends StatelessWidget {
  const VfxPlaygroundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter VFX Playground',
      home: VfxScreen(),
    );
  }
}
