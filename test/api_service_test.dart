import 'dart:convert';

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
  setUp(() {
    ApiService.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  // ── login ──────────────────────────────────────────────────────────────────

  group('login', () {
    test('stores access token and refresh token in prefs on success', () async {
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

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), 'access-abc');
      expect(prefs.getString('refresh_token'), 'refresh-xyz');
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
    test('removes access token, refresh token, and user id from prefs', () async {
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
  });

  // ── getSavedToken ──────────────────────────────────────────────────────────

  group('getSavedToken', () {
    test('returns null when nothing stored', () async {
      expect(await ApiService.getSavedToken(), isNull);
    });

    test('loads and caches access token from prefs on cold start', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'stored-tok'});
      final token = await ApiService.getSavedToken();
      expect(token, 'stored-tok');
      // Second call uses in-memory cache (prefs not read again).
      expect(await ApiService.getSavedToken(), 'stored-tok');
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
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), 'new-access');
      expect(prefs.getString('refresh_token'), 'new-refresh');
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
}
