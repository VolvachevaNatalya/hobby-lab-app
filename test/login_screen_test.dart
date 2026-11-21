import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hobby_lab/l10n/app_localizations.dart';
import 'package:hobby_lab/screens/login_screen.dart';

// Minimal app wrapper for testing LoginScreen in isolation.
Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

void main() {
  // On the Linux test platform, Platform.isIOS and Platform.isMacOS are both
  // false — this is intentional and lets us assert that the Apple button is
  // absent on Android/Linux without any platform mocking.

  testWidgets('Apple sign-in button is absent on non-iOS/macOS platforms', (tester) async {
    await tester.pumpWidget(_wrap(const LoginScreen()));
    await tester.pump();

    // The Apple button uses the l10n key continueWithApple.
    // We look for the text to avoid tight coupling to widget type.
    expect(find.text('Continue with Apple'), findsNothing);
  });

  testWidgets('Google and Facebook buttons are present on Android/Linux', (tester) async {
    await tester.pumpWidget(_wrap(const LoginScreen()));
    await tester.pump();

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Facebook'), findsOneWidget);
  });

  testWidgets('Terms RichText widget is present on login screen', (tester) async {
    await tester.pumpWidget(_wrap(const LoginScreen()));
    await tester.pumpAndSettle();

    // _TermsText renders as a RichText with terms + privacy tappable spans.
    final termsWidget = find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().contains('Terms of Service'),
    );
    expect(termsWidget, findsOneWidget);
  });

  testWidgets('Privacy Policy text is present in the terms RichText', (tester) async {
    await tester.pumpWidget(_wrap(const LoginScreen()));
    await tester.pumpAndSettle();

    final privacyWidget = find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().contains('Privacy Policy'),
    );
    expect(privacyWidget, findsOneWidget);
  });
}
