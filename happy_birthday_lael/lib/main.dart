import 'package:flutter/material.dart';

import 'birthday/birthday_screen.dart';

void main() {
  runApp(const HappyBirthdayApp());
}

class HappyBirthdayApp extends StatelessWidget {
  const HappyBirthdayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Happy Birthday Lael',
      home: BirthdayScreen(),
    );
  }
}
