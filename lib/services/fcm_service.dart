import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api_service.dart';

/// Top-level handler required by FCM for background/terminated state messages.
/// Must be annotated @pragma('vm:entry-point') and registered before isolate
/// init so it runs outside the main isolate.
@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  // No UI work here — message is handled by the system notification tray.
}

class FcmService {
  FcmService._();

  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static const _androidChannel = AndroidNotificationChannel(
    'hobbylab_default',
    'HobbyLab Notifications',
    description: 'General HobbyLab push notifications',
    importance: Importance.high,
  );

  static bool _channelCreated = false;

  // Track active subscriptions so they can be cancelled on logout and
  // not duplicated when initForAuthenticatedUser() is called again.
  static StreamSubscription<String>? _tokenRefreshSub;
  static StreamSubscription<RemoteMessage>? _messageSub;

  /// Call once from main() before runApp — registers the background handler.
  static Future<void> initBackground() async {
    FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);
  }

  /// Call after the user successfully logs in.
  /// Requests permission, registers the token, sets up foreground display.
  /// Never throws — FCM setup failures must not block the login flow.
  static Future<void> initForAuthenticatedUser() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request permission (Android 13+ / iOS).
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      // Create the Android notification channel once.
      if (!_channelCreated) {
        await _createAndroidChannel();
        _channelCreated = true;
      }

      // Initialize flutter_local_notifications for foreground display.
      const androidInit = AndroidInitializationSettings('ic_notification');
      const initSettings = InitializationSettings(android: androidInit);
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Register the current token.
      final token = await messaging.getToken();
      if (token != null) {
        await _registerToken(token);
      }

      // Cancel any previous subscriptions before re-subscribing.
      // This prevents duplicate listeners when the user logs out and back in.
      await _tokenRefreshSub?.cancel();
      await _messageSub?.cancel();

      _tokenRefreshSub = messaging.onTokenRefresh.listen(_registerToken);
      _messageSub =
          FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    } catch (_) {
      // FCM setup failed — app works normally without push notifications.
    }
  }

  /// Call before logout — removes the token from the backend and cancels
  /// active FCM subscriptions.
  /// Never throws — cleanup failures must not block the logout flow.
  static Future<void> cleanup() async {
    try {
      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = null;
      await _messageSub?.cancel();
      _messageSub = null;

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await ApiService.removeDeviceToken(token);
      }
    } catch (_) {
      // Firebase not initialized or network error — safe to ignore.
    }
  }

  // ── private ────────────────────────────────────────────────────────────────

  static Future<void> _registerToken(String token) async {
    try {
      await ApiService.registerDeviceToken(token, 'android');
    } catch (_) {
      // Token registration is best-effort; never block the user flow.
    }
  }

  static Future<void> _createAndroidChannel() async {
    if (!Platform.isAndroid) return;
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_androidChannel);
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'hobbylab_default',
      'HobbyLab Notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(android: androidDetails),
      payload: message.data['type'],
    );
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Navigation on tap is handled per-screen via the notification stream;
    // no global router reference needed here.
  }
}
