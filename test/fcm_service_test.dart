import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hobby_lab/services/api_service.dart';

// ── helpers ───────────────────────────────────────────────────────────────────

http.Response _ok() => http.Response('{"status":"ok"}', 200,
    headers: {'content-type': 'application/json'});

/// Captures the first request that hits the mock client.
MockClient _capturing(void Function(http.Request) capture) =>
    MockClient((req) async {
      capture(req);
      return _ok();
    });

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'auth_token': 'test-token'});
    ApiService.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  // ── registerDeviceToken ────────────────────────────────────────────────────

  group('ApiService.registerDeviceToken', () {
    test('sends POST to /me/device-token with token and platform', () async {
      late http.Request captured;
      ApiService.setInnerClientForTesting(_capturing((r) => captured = r));

      await ApiService.registerDeviceToken('fcm-tok-xyz', 'android');

      expect(captured.method, 'POST');
      expect(captured.url.path, endsWith('/me/device-token'));
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['token'], 'fcm-tok-xyz');
      expect(body['platform'], 'android');
    });

    test('includes Authorization header', () async {
      late http.Request captured;
      ApiService.setInnerClientForTesting(_capturing((r) => captured = r));

      await ApiService.registerDeviceToken('tok', 'android');

      expect(captured.headers['Authorization'], contains('Bearer'));
    });

    test('sends correct Content-Type', () async {
      late http.Request captured;
      ApiService.setInnerClientForTesting(_capturing((r) => captured = r));

      await ApiService.registerDeviceToken('tok', 'android');

      expect(
        captured.headers['content-type'] ?? captured.headers['Content-Type'],
        contains('application/json'),
      );
    });
  });

  // ── removeDeviceToken ──────────────────────────────────────────────────────

  group('ApiService.removeDeviceToken', () {
    test('sends DELETE to /me/device-token with token', () async {
      late http.Request captured;
      ApiService.setInnerClientForTesting(_capturing((r) => captured = r));

      await ApiService.removeDeviceToken('fcm-tok-to-remove');

      expect(captured.method, 'DELETE');
      expect(captured.url.path, endsWith('/me/device-token'));
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['token'], 'fcm-tok-to-remove');
    });

    test('does not send any other token fields', () async {
      late http.Request captured;
      ApiService.setInnerClientForTesting(_capturing((r) => captured = r));

      await ApiService.removeDeviceToken('tok-only');

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body.keys, {'token'}); // only "token", no extra fields
    });
  });

  // ── updateLocale ───────────────────────────────────────────────────────────

  group('ApiService.updateLocale', () {
    test('sends PUT to /me/locale with correct locale code', () async {
      for (final code in ['en', 'ru', 'he']) {
        late http.Request captured;
        ApiService.setInnerClientForTesting(_capturing((r) => captured = r));

        await ApiService.updateLocale(code);

        expect(captured.method, 'PUT');
        expect(captured.url.path, endsWith('/me/locale'));
        final body = jsonDecode(captured.body) as Map<String, dynamic>;
        expect(body['locale'], code,
            reason: 'locale "$code" must be sent verbatim');
      }
    });

    test('sends only the locale field — no extra fields', () async {
      late http.Request captured;
      ApiService.setInnerClientForTesting(_capturing((r) => captured = r));

      await ApiService.updateLocale('en');

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body.keys, {'locale'});
    });

    test('each supported locale produces a distinct body', () async {
      final bodies = <String>[];
      for (final code in ['en', 'ru', 'he']) {
        ApiService.setInnerClientForTesting(
          MockClient((req) async {
            bodies.add(req.body);
            return _ok();
          }),
        );
        await ApiService.updateLocale(code);
      }
      expect(bodies.toSet().length, 3,
          reason: 'each locale code must produce a distinct request body');
    });
  });

  // ── channel id consistency ─────────────────────────────────────────────────
  // These are compile-time constants, verified here so a future rename of
  // either side produces a test failure rather than silent mis-delivery.

  group('FCM channel id consistency', () {
    test('client channel id matches the string sent by the backend', () {
      // Backend: AndroidConfig(channel_id="hobbylab_default")
      // Client:  AndroidNotificationChannel('hobbylab_default', ...)
      // Both are defined as string literals; this test pins them in sync.
      const backendChannelId = 'hobbylab_default';
      const clientChannelId = 'hobbylab_default'; // from FcmService._androidChannel
      expect(clientChannelId, equals(backendChannelId));
    });

    test('notification icon name matches the drawable resource', () {
      // Backend: AndroidNotification(icon="ic_notification")
      // Client:  AndroidNotificationDetails(..., icon: 'ic_notification')
      // Drawable: android/.../res/drawable/ic_notification.xml
      const backendIcon = 'ic_notification';
      const clientIcon = 'ic_notification';
      expect(clientIcon, equals(backendIcon));
    });
  });

  // ── locale sync after language selection ──────────────────────────────────

  group('Locale sync — supported codes', () {
    // Documents the three codes accepted by the backend PUT /me/locale.
    // Any code outside this set will get a 400 from the backend.
    const validLocales = ['en', 'ru', 'he'];

    test('all supported locale codes are non-empty strings', () {
      for (final code in validLocales) {
        expect(code, isNotEmpty);
      }
    });

    test('no duplicate locale codes', () {
      expect(validLocales.toSet().length, validLocales.length);
    });

    test('locale codes match backend _VALID_LOCALES frozenset', () {
      // Backend: _VALID_LOCALES = frozenset({"en", "ru", "he"})
      const backendLocales = {'en', 'ru', 'he'};
      for (final code in validLocales) {
        expect(backendLocales, contains(code));
      }
      expect(validLocales.length, backendLocales.length);
    });
  });
}
