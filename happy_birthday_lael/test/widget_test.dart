// The birthday scene loads real GPU resources through BirthdayController,
// which the plain widget-test binding can't provide, so this only checks
// the loading frame renders before that async work starts.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:happy_birthday_lael/main.dart';

void main() {
  testWidgets('shows a loading indicator while the birthday scene loads', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const HappyBirthdayApp());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
