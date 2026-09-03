import 'package:flutter/material.dart';

import 'screens/game_screen.dart';

void main() {
  runApp(const LineupApp());
}

class LineupApp extends StatelessWidget {
  const LineupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guess the Lineup',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const GameScreen(),
    );
  }
}
