import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hobby_lab/l10n/app_localizations.dart';
import 'package:hobby_lab/services/api_service.dart';
import 'package:hobby_lab/screens/settings_screen.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

http.Response _json(int status, Map<String, dynamic> body) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );

// Pumps enough frames for a SnackBar entrance animation to complete without
// waiting for the auto-dismiss timer (which never fires in fake-async).
Future<void> _pumpSnackBar(WidgetTester tester) async {
  await tester.pump();                                        // trigger state change
  await tester.pump(const Duration(milliseconds: 400));      // animation frames
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({'auth_token': 'test-token'});
    ApiService.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  // Opens SettingsScreen, scrolls to and taps "Delete Account",
  // then returns once the confirmation dialog is visible.
  Future<void> _openDeleteDialog(WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Delete Account'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();
  }

  testWidgets('Delete Account tap opens confirmation dialog', (tester) async {
    await _openDeleteDialog(tester);

    // Both the page button and the dialog title match "Delete Account"
    expect(find.text('Delete Account'), findsWidgets);
    expect(find.textContaining('permanently delete'), findsOneWidget);
  });

  testWidgets('Cancel button dismisses dialog without calling API', (tester) async {
    var apiCalled = false;
    ApiService.setInnerClientForTesting(MockClient((_) async {
      apiCalled = true;
      return http.Response('', 204);
    }));

    await _openDeleteDialog(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(apiCalled, isFalse);
    // After dismiss: only the page button remains, not the dialog title
    expect(find.text('Delete Account'), findsOneWidget);
  });

  testWidgets('Successful deletion signs user out', (tester) async {
    ApiService.setInnerClientForTesting(MockClient((_) async =>
        http.Response('', 204)));

    await _openDeleteDialog(tester);
    await tester.tap(find.text('Delete'));
    // pumpAndSettle hangs when logout() drives platform-channel futures in
    // fake_async; advance manually to let the async chain complete.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(ApiService.authNotifier.value, isFalse,
        reason: 'authNotifier must be false after successful deletion');
  });

  testWidgets('Sole-owner 409 shows localized sole-owner message', (tester) async {
    ApiService.setInnerClientForTesting(MockClient((_) async =>
        _json(409, {'detail': 'You are the sole owner of Org.'})));

    await _openDeleteDialog(tester);
    await tester.tap(find.text('Delete'));
    // Use fixed pump durations — pumpAndSettle times out on SnackBar auto-dismiss timers
    await _pumpSnackBar(tester);

    // Dialog dismissed: only the page button matches "Delete Account" now
    expect(find.text('Delete Account'), findsOneWidget,
        reason: 'dialog should be dismissed, leaving only the page button');
    expect(
      find.textContaining('sole owner'),
      findsOneWidget,
      reason: 'deleteAccountSoleOwner message should appear in SnackBar',
    );
  });

  testWidgets('Generic error shows generic failure message', (tester) async {
    ApiService.setInnerClientForTesting(MockClient((_) async =>
        _json(500, {'detail': 'Internal server error'})));

    await _openDeleteDialog(tester);
    await tester.tap(find.text('Delete'));
    await _pumpSnackBar(tester);

    // Dialog dismissed: only the page button remains
    expect(find.text('Delete Account'), findsOneWidget,
        reason: 'dialog should be dismissed, leaving only the page button');
    expect(
      find.textContaining('Failed to delete account'),
      findsOneWidget,
      reason: 'deleteAccountFailed message should appear in SnackBar',
    );
  });

  testWidgets('Delete button shows loading spinner while request is in-flight',
      (tester) async {
    // Completer that never completes — no pending timer, unlike Future.delayed
    final blocker = Completer<http.Response>();
    ApiService.setInnerClientForTesting(MockClient((_) => blocker.future));

    await _openDeleteDialog(tester);
    await tester.tap(find.text('Delete'));
    await tester.pump(); // kick off async, don't settle

    expect(find.byType(CircularProgressIndicator), findsOneWidget,
        reason: 'spinner should appear while deletion is in progress');

    // Complete the blocker so the async chain can terminate before widget disposal,
    // but don't pumpAndSettle — logout() platform-channel futures hang in fake_async.
    blocker.complete(http.Response('', 204));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  });
}
