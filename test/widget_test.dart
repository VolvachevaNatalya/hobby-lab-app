import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hobby_lab/main.dart';

void main() {
  testWidgets('App renders splash screen without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const HobbyLabApp(isLoggedIn: false));
    // The app should build a MaterialApp without throwing.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
