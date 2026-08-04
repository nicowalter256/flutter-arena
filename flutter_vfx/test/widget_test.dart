// The VFX scene loads real GPU resources (baked textures, shaders) through
// VfxController, which the plain widget-test binding can't provide, so this
// only checks the loading frame renders before that async work starts.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_vfx/main.dart';

void main() {
  testWidgets('shows a loading indicator while the VFX scene loads', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const VfxPlaygroundApp());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
