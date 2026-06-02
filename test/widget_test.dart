import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gachamerch/main.dart';

void main() {
  testWidgets('Verify Honkai Star Retail login screen title loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GachaMerchApp());

    // Verify that our login title text is present on the screen.
    expect(find.text('HONKAI STAR RETAIL'), findsOneWidget);

    // Verify that the regular login button is present.
    expect(find.text('Log In'), findsOneWidget);

    // Verify that the counter-specific widget that used to cause errors is gone.
    expect(find.byIcon(Icons.add), findsNothing);
  });
}