// The arena scene loads real GPU resources (glb assets, shaders) through
// ArenaController, which the plain widget-test binding can't provide, so
// this only checks the loading frame renders before that async work starts.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_arena/main.dart';

void main() {
  testWidgets('shows a loading indicator while the arena scene loads', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LogoShowpieceApp());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
