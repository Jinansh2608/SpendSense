import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendsense/main.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const PayNest());

    // Check that at least something basic is rendered (like LoginPage or Dashboard)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

