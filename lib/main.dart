import 'package:flutter/material.dart';

import 'arena/arena_screen.dart';

void main() {
  runApp(const LogoShowpieceApp());
}

class LogoShowpieceApp extends StatelessWidget {
  const LogoShowpieceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Arena',
      home: ArenaScreen(),
    );
  }
}
