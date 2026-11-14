import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hobby_lab/services/api_service.dart';

http.Response _json(int status, Map<String, dynamic> body) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    ApiService.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  // ── login ──────────────────────────────────────────────────────────────────

  group('login', () {
    test('stores access token and refresh token in secure storage on success', () async {
      ApiService.setRawClientForTesting(
        MockClient((_) async => _json(200, {
              'access_token': 'access-abc',
              'refresh_token': 'refresh-xyz',
            })),
      );
      // getMe() fires internally; stub it so it doesn't hit the real server.
      ApiService.setInnerClientForTesting(
        MockClient((_) async => _json(200, {
              'id': 'u1',
              'full_name': 'Alice',
              'email': 'alice@example.com',
            })),
      );

      await ApiService.login('alice@example.com', 'secret');

      const storage = FlutterSecureStorage();
      expect(await storage.read(key: 'auth_token'), 'access-abc');
      expect(await storage.read(key: 'refresh_token'), 'refresh-xyz');
    });

    test('clears sessionExpiredOnce on successful login', () async {
      ApiService.sessionExpiredOnce = true;
      ApiService.setRawClientForTesting(
        MockClient((_) async => _json(200, {
              'access_token': 'tok',
              'refresh_token': 'rtok',
            })),
      );
      ApiService.setInnerClientForTesting(
        MockClient((_) async => _json(200, {
              'id': 'u1',
              'full_name': 'Alice',
              'email': 'alice@example.com',
            })),
      );

      await ApiService.login('a@b.com', 'pw');
      expect(ApiService.sessionExpiredOnce, false);
    });

    test('throws on invalid credentials', () async {
      ApiService.setRawClientForTesting(
        MockClient((_) async => http.Response('Unauthorized', 401)),
      );
      expect(ApiService.login('bad@user.com', 'wrong'), throwsException);
    });
  });

  // ── logout ─────────────────────────────────────────────────────────────────

  group('logout', () {
    test('clears tokens from secure storage (primary path)', () async {
      const storage = FlutterSecureStorage();
      await storage.write(key: 'auth_token', value: 'stored-access');
      await storage.write(key: 'refresh_token', value: 'stored-refresh');

      await ApiService.logout();

      expect(await storage.read(key: 'auth_token'), isNull);
      expect(await storage.read(key: 'refresh_token'), isNull);
    });

    test('clears legacy SharedPreferences tokens and user id (defensive cleanup)', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'old-access',
        'refresh_token': 'old-refresh',
        'current_user_id': 'uid-1',
      });

      await ApiService.logout();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), isNull);
      expect(prefs.getString('refresh_token'), isNull);
      expect(prefs.getString('current_user_id'), isNull);
    });

    test('clears both secure storage and legacy prefs when both are populated', () async {
      const storage = FlutterSecureStorage();
      await storage.write(key: 'auth_token', value: 'secure-access');
      await storage.write(key: 'refresh_token', value: 'secure-refresh');
      SharedPreferences.setMockInitialValues({
        'auth_token': 'legacy-access',
        'refresh_token': 'legacy-refresh',
        'current_user_id': 'uid-99',
      });

      await ApiService.logout();

      expect(await storage.read(key: 'auth_token'), isNull);
      expect(await storage.read(key: 'refresh_token'), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), isNull);
      expect(prefs.getString('refresh_token'), isNull);
      expect(prefs.getString('current_user_id'), isNull);
    });

    // Regression: notification preference keys must be cleared on logout so
    // that the next user does not briefly see the previous user's cached prefs.
    test('clears notification preference cache keys from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'notif_appointments': true,
        'notif_chat': false,
        'notif_activity': true,
        'notif_offers': false,
      });

      await ApiService.logout();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('notif_appointments'), isFalse);
      expect(prefs.containsKey('notif_chat'), isFalse);
      expect(prefs.containsKey('notif_activity'), isFalse);
      expect(prefs.containsKey('notif_offers'), isFalse);
    });
  });

  // ── getSavedToken ──────────────────────────────────────────────────────────

  group('getSavedToken', () {
    test('returns null when nothing stored', () async {
      expect(await ApiService.getSavedToken(), isNull);
    });

    test('migrates legacy SharedPreferences token to secure storage on cold start', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'stored-tok'});
      final token = await ApiService.getSavedToken();
      expect(token, 'stored-tok');
      // Second call uses in-memory cache.
      expect(await ApiService.getSavedToken(), 'stored-tok');
      // Legacy key must be removed from SharedPreferences after migration.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), isNull);
    });
  });

  // ── 401 handling ──────────────────────────────────────────────────────────

  group('401 / refresh', () {
    test('sets sessionExpiredOnce when no refresh token is available', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'tok'});
      ApiService.setInnerClientForTesting(
        MockClient((_) async => http.Response('Unauthorized', 401)),
      );
      // _tryRefresh uses _rawClient; no refresh token in prefs → returns false.
      ApiService.setRawClientForTesting(
        MockClient((_) async => http.Response('', 500)),
      );

      try {
        await ApiService.getMe();
      } catch (_) {}

      expect(ApiService.sessionExpiredOnce, isTrue);
    });

    test('retries request after successful token refresh', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'expired-access',
        'refresh_token': 'valid-refresh',
      });

      // _rawClient handles the refresh endpoint.
      ApiService.setRawClientForTesting(
        MockClient((_) async => _json(200, {
              'access_token': 'new-access',
              'refresh_token': 'new-refresh',
            })),
      );

      var callCount = 0;
      ApiService.setInnerClientForTesting(
        MockClient((request) async {
          callCount++;
          if (callCount == 1) return http.Response('Unauthorized', 401);
          return _json(200, {
            'id': 'u1',
            'full_name': 'Alice',
            'email': 'alice@example.com',
          });
        }),
      );

      final profile = await ApiService.getMe();

      expect(callCount, 2);
      expect(profile.fullName, 'Alice');
      expect(ApiService.sessionExpiredOnce, isFalse);
      const storage = FlutterSecureStorage();
      expect(await storage.read(key: 'auth_token'), 'new-access');
      expect(await storage.read(key: 'refresh_token'), 'new-refresh');
    });

    test('navigates to login when refresh endpoint itself returns 401', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'expired',
        'refresh_token': 'also-expired',
      });

      // Refresh endpoint returns 401 (refresh token expired).
      ApiService.setRawClientForTesting(
        MockClient((_) async => http.Response('Unauthorized', 401)),
      );
      ApiService.setInnerClientForTesting(
        MockClient((_) async => http.Response('Unauthorized', 401)),
      );

      bool authExpired = false;
      ApiService.authNotifier.addListener(() {
        if (!ApiService.authNotifier.value) authExpired = true;
      });

      try {
        await ApiService.getMe();
      } catch (_) {}

      expect(authExpired, isTrue);
      expect(ApiService.sessionExpiredOnce, isTrue);
    });
  });

  // ── getReviews ─────────────────────────────────────────────────────────────
  // Contract: returns a flat List<Map> — original format, backward-compatible
  // with all previously released Flutter app versions.

  group('getReviews', () {
    test('parses flat JSON array and returns list', () async {
      ApiService.setInnerClientForTesting(
        MockClient((_) async => http.Response(
              '[{"id":1,"rating":5,"comment":"Great!"},{"id":2,"rating":4,"comment":"Good"}]',
              200,
              headers: {'content-type': 'application/json'},
            )),
      );

      final result = await ApiService.getReviews(42);

      expect(result, isA<List<Map<String, dynamic>>>());
      expect(result.length, 2);
      expect(result[0]['rating'], 5);
    });

    test('returns empty list for org with no reviews', () async {
      ApiService.setInnerClientForTesting(
        MockClient((_) async => http.Response(
              '[]',
              200,
              headers: {'content-type': 'application/json'},
            )),
      );

      final result = await ApiService.getReviews(99);

      expect(result, isEmpty);
    });

    test('throws on non-200 response', () async {
      ApiService.setInnerClientForTesting(
        MockClient((_) async => http.Response('Not Found', 404)),
      );

      expect(ApiService.getReviews(1), throwsException);
    });
  });

  // ── getReviewStats ─────────────────────────────────────────────────────────
  // Contract: returns {"total": int, "average_rating": double|null}
  // Aggregates ALL active reviews — not bounded by any pagination limit.

  group('getReviewStats', () {
    test('parses stats envelope with total and average_rating', () async {
      ApiService.setInnerClientForTesting(
        MockClient((_) async => _json(200, {
              'total': 47,
              'average_rating': 4.32,
            })),
      );

      final result = await ApiService.getReviewStats(42);

      expect(result['total'], 47);
      expect(result['average_rating'], 4.32);
    });

    test('handles null average_rating for org with no reviews', () async {
      ApiService.setInnerClientForTesting(
        MockClient((_) async => _json(200, {
              'total': 0,
              'average_rating': null,
            })),
      );

      final result = await ApiService.getReviewStats(99);

      expect(result['total'], 0);
      expect(result['average_rating'], isNull);
    });

    test('throws on non-200 response', () async {
      ApiService.setInnerClientForTesting(
        MockClient((_) async => http.Response('Server Error', 500)),
      );

      expect(ApiService.getReviewStats(1), throwsException);
    });
  });

  // ── searchClasses — query param serialisation ─────────────────────────────

  http.Response searchOk([List<Map<String, dynamic>> items = const []]) =>
      http.Response(
        '{"items":${items.map((i) => '{"class":${jsonEncode(i)},"rating":null}').toList()},"total":${items.length}}',
        200,
        headers: {'content-type': 'application/json'},
      );

  group('searchClasses — age params', () {
    test('sends min_age and max_age when both are provided', () async {
      late Uri captured;
      ApiService.setInnerClientForTesting(
        MockClient((req) async { captured = req.url; return searchOk(); }),
      );

      await ApiService.searchClasses('', minAge: 5, maxAge: 12);

      expect(captured.queryParameters['min_age'], '5');
      expect(captured.queryParameters['max_age'], '12');
    });

    test('omits min_age and max_age when both are null (no age filter)', () async {
      late Uri captured;
      ApiService.setInnerClientForTesting(
        MockClient((req) async { captured = req.url; return searchOk(); }),
      );

      await ApiService.searchClasses('');

      expect(captured.queryParameters.containsKey('min_age'), isFalse);
      expect(captured.queryParameters.containsKey('max_age'), isFalse);
    });

    test('sends only min_age when max_age is null', () async {
      late Uri captured;
      ApiService.setInnerClientForTesting(
        MockClient((req) async { captured = req.url; return searchOk(); }),
      );

      await ApiService.searchClasses('', minAge: 4);

      expect(captured.queryParameters['min_age'], '4');
      expect(captured.queryParameters.containsKey('max_age'), isFalse);
    });

    test('sends only max_age when min_age is null', () async {
      late Uri captured;
      ApiService.setInnerClientForTesting(
        MockClient((req) async { captured = req.url; return searchOk(); }),
      );

      await ApiService.searchClasses('', maxAge: 15);

      expect(captured.queryParameters.containsKey('min_age'), isFalse);
      expect(captured.queryParameters['max_age'], '15');
    });

    test('combines age with day_of_week in a single request', () async {
      late Uri captured;
      ApiService.setInnerClientForTesting(
        MockClient((req) async { captured = req.url; return searchOk(); }),
      );

      await ApiService.searchClasses('', minAge: 4, maxAge: 10, dayOfWeek: 1);

      expect(captured.queryParameters['min_age'], '4');
      expect(captured.queryParameters['max_age'], '10');
      expect(captured.queryParameters['day_of_week'], '1');
    });

    test('combines age with price range', () async {
      late Uri captured;
      ApiService.setInnerClientForTesting(
        MockClient((req) async { captured = req.url; return searchOk(); }),
      );

      await ApiService.searchClasses(
        '',
        minAge: 6,
        maxAge: 14,
        minPrice: 50.0,
        maxPrice: 300.0,
      );

      expect(captured.queryParameters['min_age'], '6');
      expect(captured.queryParameters['max_age'], '14');
      expect(captured.queryParameters['min_price'], '50.0');
      expect(captured.queryParameters['max_price'], '300.0');
    });

    test('combines age with distance and city', () async {
      late Uri captured;
      ApiService.setInnerClientForTesting(
        MockClient((req) async { captured = req.url; return searchOk(); }),
      );

      await ApiService.searchClasses(
        '',
        minAge: 3,
        maxAge: 8,
        lat: 32.08,
        lng: 34.78,
        distanceKm: 7,
        cityId: 42,
      );

      expect(captured.queryParameters['min_age'], '3');
      expect(captured.queryParameters['max_age'], '8');
      expect(captured.queryParameters['lat'], '32.08');
      expect(captured.queryParameters['lng'], '34.78');
      expect(captured.queryParameters['distance_km'], '7');
      expect(captured.queryParameters['city_id'], '42');
    });

    test('parses returned items and injects rating', () async {
      ApiService.setInnerClientForTesting(
        MockClient((_) async => http.Response(
          '{"items":[{"class":{"id":7,"name":"Yoga"},"rating":4.5}],"total":1}',
          200,
          headers: {'content-type': 'application/json'},
        )),
      );

      final results = await ApiService.searchClasses('yoga', minAge: 5, maxAge: 10);

      expect(results, hasLength(1));
      expect(results.first.id, '7');
      expect(results.first.averageRating, 4.5);
    });
  });

  // ── addFavorite — currency-safe ID parsing ─────────────────────────────────

  group('addFavorite — currency-safe ID', () {
    test('throws ArgumentError for a non-numeric class ID', () async {
      // No mock client needed — the guard fires before any network call.
      expect(
        ApiService.addFavorite('uuid-not-an-int'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError for a non-numeric org ID', () async {
      expect(
        ApiService.addOrgFavorite('uuid-not-an-int'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError for a non-numeric event ID', () async {
      expect(
        ApiService.addEventFavorite('uuid-not-an-int'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('sends request for a valid numeric class ID', () async {
      late Uri captured;
      ApiService.setInnerClientForTesting(
        MockClient((req) async {
          captured = req.url;
          return _json(200, {'id': '1', 'entity_id': '42', 'entity_type': 'class'});
        }),
      );

      final fav = await ApiService.addFavorite('42');

      expect(captured.path, contains('/favorites/'));
      expect(fav.entityId, '42');
      expect(fav.entityType, 'class');
    });
  });

  // ── social login — platform guard ─────────────────────────────────────────
  //
  // Backend contracts verified by direct source inspection (HobbyLab/app/api/auth.py):
  //   POST /auth/google-login   body {"id_token": str}
  //   POST /auth/facebook-login body {"access_token": str}
  //   POST /auth/apple-login    body {"id_token": str}
  // All three return {"access_token": str, "refresh_token": str, "token_type": "bearer"}.
  // Flutter sends exactly these paths, keys, and reads those fields — contracts match.

  group('loginWithApple — platform guard', () {
    test('throws on non-iOS/macOS platforms (guard fires before any network call)', () async {
      // This test runs on Linux where Platform.isIOS and Platform.isMacOS are both
      // false, so the platform guard should fire immediately.
      await expectLater(
        ApiService.loginWithApple(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('iOS'),
          ),
        ),
      );
    });
  });

  // ── forgotPassword ────────────────────────────────────────────────────────

  group('forgotPassword', () {
    test('succeeds on 200', () async {
      ApiService.setRawClientForTesting(
        MockClient((_) async => _json(200, {'message': 'ok'})),
      );
      await expectLater(ApiService.forgotPassword('user@test.com'), completes);
    });

    test('throws on 429 rate limit', () async {
      ApiService.setRawClientForTesting(
        MockClient((_) async => http.Response('Too Many Requests', 429)),
      );
      expect(
        ApiService.forgotPassword('user@test.com'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'message', contains('Too many'),
        )),
      );
    });

    test('throws on non-200 non-429', () async {
      ApiService.setRawClientForTesting(
        MockClient((_) async => http.Response('Server Error', 500)),
      );
      expect(ApiService.forgotPassword('user@test.com'), throwsException);
    });

    test('normalizes email to lowercase before sending', () async {
      late Uri capturedUri;
      late String capturedBody;
      ApiService.setRawClientForTesting(
        MockClient((req) async {
          capturedUri = req.url;
          capturedBody = req.body;
          return _json(200, {'message': 'ok'});
        }),
      );
      await ApiService.forgotPassword('USER@TEST.COM');
      expect(capturedUri.path, contains('forgot-password'));
      expect(capturedBody, contains('user@test.com'));
    });
  });

  // ── resetPassword ─────────────────────────────────────────────────────────

  group('resetPassword', () {
    test('succeeds on 200', () async {
      ApiService.setRawClientForTesting(
        MockClient((_) async => _json(200, {'message': 'Password reset successfully'})),
      );
      await expectLater(
        ApiService.resetPassword(
          email: 'user@test.com',
          otp: '123456',
          newPassword: 'newpass123',
        ),
        completes,
      );
    });

    test('throws on 400 invalid code and includes detail from server', () async {
      ApiService.setRawClientForTesting(
        MockClient((_) async =>
            _json(400, {'detail': 'Invalid or expired code'})),
      );
      expect(
        ApiService.resetPassword(
          email: 'user@test.com',
          otp: '000000',
          newPassword: 'newpass',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'message', contains('Invalid or expired code'),
        )),
      );
    });

    test('throws on 429 rate limit', () async {
      ApiService.setRawClientForTesting(
        MockClient((_) async => http.Response('Too Many Requests', 429)),
      );
      expect(
        ApiService.resetPassword(
          email: 'user@test.com',
          otp: '123456',
          newPassword: 'newpass',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'message', contains('Too many'),
        )),
      );
    });

    test('throws on 500', () async {
      ApiService.setRawClientForTesting(
        MockClient((_) async => http.Response('Server Error', 500)),
      );
      expect(
        ApiService.resetPassword(
          email: 'user@test.com',
          otp: '123456',
          newPassword: 'newpass',
        ),
        throwsException,
      );
    });
  });

  // ── getNotificationPreferences ────────────────────────────────────────────

  group('getNotificationPreferences', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues(
        {'auth_token': 'valid-token'},
      );
    });

    test('returns parsed preferences on 200', () async {
      ApiService.setInnerClientForTesting(
        MockClient((_) async => _json(200, {
              'notif_appointments': false,
              'notif_chat': true,
              'notif_activity': true,
              'notif_offers': false,
            })),
      );
      final prefs = await ApiService.getNotificationPreferences();
      expect(prefs['notif_appointments'], false);
      expect(prefs['notif_chat'], true);
      expect(prefs['notif_activity'], true);
      expect(prefs['notif_offers'], false);
    });

    test('applies default values for missing fields', () async {
      ApiService.setInnerClientForTesting(
        MockClient((_) async => _json(200, {
              'notif_appointments': null,
              'notif_chat': null,
              'notif_activity': null,
              'notif_offers': null,
            })),
      );
      final prefs = await ApiService.getNotificationPreferences();
      expect(prefs['notif_appointments'], true);
      expect(prefs['notif_chat'], true);
      expect(prefs['notif_activity'], false);
      expect(prefs['notif_offers'], true);
    });

    test('throws on non-200', () async {
      ApiService.setInnerClientForTesting(
        MockClient((_) async => http.Response('Unauthorized', 401)),
      );
      expect(ApiService.getNotificationPreferences(), throwsException);
    });
  });

  // ── updateNotificationPreferences ─────────────────────────────────────────

  group('updateNotificationPreferences', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues(
        {'auth_token': 'valid-token'},
      );
    });

    test('succeeds on 200', () async {
      ApiService.setInnerClientForTesting(
        MockClient((_) async => _json(200, {
              'notif_appointments': false,
              'notif_chat': true,
              'notif_activity': false,
              'notif_offers': true,
            })),
      );
      await expectLater(
        ApiService.updateNotificationPreferences({
          'notif_appointments': false,
          'notif_chat': true,
          'notif_activity': false,
          'notif_offers': true,
        }),
        completes,
      );
    });

    test('throws on non-200', () async {
      ApiService.setInnerClientForTesting(
        MockClient((_) async => http.Response('Server Error', 500)),
      );
      expect(
        ApiService.updateNotificationPreferences({'notif_appointments': false}),
        throwsException,
      );
    });

    test('sends correct JSON body', () async {
      late String capturedBody;
      ApiService.setInnerClientForTesting(
        MockClient((req) async {
          capturedBody = req.body;
          return _json(200, {
            'notif_appointments': true,
            'notif_chat': false,
            'notif_activity': false,
            'notif_offers': true,
          });
        }),
      );
      await ApiService.updateNotificationPreferences({
        'notif_appointments': true,
        'notif_chat': false,
        'notif_activity': false,
        'notif_offers': true,
      });
      expect(capturedBody, contains('"notif_chat":false'));
    });
  });
}
