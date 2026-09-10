import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Push notifications — Android only for now.
///
/// Combines Firebase Cloud Messaging (remote push + device token) with
/// `flutter_local_notifications` (used to display notifications while the
/// app is in the foreground, and for any purely local/on-device reminders).
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String _channelId = 'general_channel';
  static const String _channelName = 'General';
  static const String _channelDescription =
      'General app notifications and reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Entry point — call once during app startup (Android only).
  Future<void> init() async {
    if (_isInitialized || !Platform.isAndroid) return;

    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const initSettings = InitializationSettings(android: androidSettings);

      await _plugin.initialize(initSettings);

      const androidChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      _isInitialized = true;

      await _initFcm();
    } catch (e) {
      debugPrint('NotificationService: init failed -> $e');
    }
  }

  /// Sets up Firebase Cloud Messaging: fetches + logs the device token,
  /// listens for token refreshes, and shows a local notification for any
  /// remote push that arrives while the app is in the foreground.
  Future<void> _initFcm() async {
    if (Firebase.apps.isEmpty) return;
    try {
      final messaging = FirebaseMessaging.instance;

      final token = await messaging.getToken();
      debugPrint('NotificationService: FCM token -> $token');

      messaging.onTokenRefresh.listen((newToken) {
        debugPrint('NotificationService: FCM token refreshed -> $newToken');
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification == null) return;
        showNotification(
          id: message.hashCode,
          title: notification.title ?? '',
          body: notification.body ?? '',
        );
      });
    } catch (e) {
      debugPrint('NotificationService: FCM init failed -> $e');
    }
  }

  /// Requests the runtime POST_NOTIFICATIONS permission (Android 13+).
  /// No-op / returns true on older Android versions.
  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return granted ?? true;
    } catch (e) {
      debugPrint('NotificationService: permission request failed -> $e');
      return false;
    }
  }

  /// Shows an immediate notification.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!Platform.isAndroid || !_isInitialized) return;
    try {
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      );
      const details = NotificationDetails(android: androidDetails);
      await _plugin.show(id, title, body, details, payload: payload);
    } catch (e) {
      debugPrint('NotificationService: showNotification failed -> $e');
    }
  }

  /// Cancels a previously scheduled/shown notification by [id].
  Future<void> cancel(int id) async {
    if (!Platform.isAndroid) return;
    await _plugin.cancel(id);
  }

  /// Cancels all notifications.
  Future<void> cancelAll() async {
    if (!Platform.isAndroid) return;
    await _plugin.cancelAll();
  }
}
