import 'dart:async';
import 'dart:io';
import 'dart:ui' show Color;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../modules/notifications/controller/notification_controller.dart';
import 'device_token_service.dart';
import 'notification_badge_service.dart';

/// Runs in its own isolate for pushes that arrive while the app is backgrounded
/// or killed. The OS draws the notification itself; all we do here is keep the
/// unread badge in step (SharedPreferences is the only state both isolates
/// share — see [NotificationBadgeService]).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.notification == null && message.data.isEmpty) return;
  await NotificationBadgeService.incrementInBackground();
}

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

  /// Monochrome status-bar icon (res/drawable/ic_notification.xml) and the
  /// full-color brand mark shown next to the text.
  static const String _smallIcon = 'ic_notification';
  static const String _largeIcon = 'ic_notification_large';
  static const Color _accentColor = Color(0xFF4A4FD9);

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Last FCM token fetched on this device, kept for callers (e.g. after
  /// login) that need to (re)send it without waiting for a fresh fetch.
  String? currentToken;

  /// Entry point — call once during app startup (Android only).
  Future<void> init() async {
    if (_isInitialized || !Platform.isAndroid) return;

    try {
      const androidSettings = AndroidInitializationSettings(
        '@drawable/$_smallIcon',
      );
      const initSettings = InitializationSettings(android: androidSettings);

      await _plugin.initialize(initSettings);

      const androidChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        // Lets the launcher put a dot/count on the app icon for this channel.
        showBadge: true,
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

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final token = await messaging.getToken();
      debugPrint('NotificationService: FCM token -> $token');
      currentToken = token;
      unawaited(DeviceTokenService.instance.sendToken(token));

      messaging.onTokenRefresh.listen((newToken) {
        debugPrint('NotificationService: FCM token refreshed -> $newToken');
        currentToken = newToken;
        unawaited(DeviceTokenService.instance.sendToken(newToken));
      });

      // Foreground: FCM does not show anything by itself, so display it
      // ourselves via flutter_local_notifications.
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        final notification = message.notification;
        if (notification == null) return;
        await NotificationBadgeService.instance.increment();
        await showNotification(
          id: message.hashCode,
          title: notification.title ?? '',
          body: notification.body ?? '',
          number: NotificationBadgeService.instance.unreadCount.value,
        );
      });

      // Background / killed: the OS already showed the notification, so we
      // only need to react to the user tapping it.
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      debugPrint('NotificationService: FCM init failed -> $e');
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Tapping a push counts as reading it.
    unawaited(NotificationBadgeService.instance.clear());
    final notificationId = message.data['notificationId']?.toString();
    if (notificationId == null || notificationId.isEmpty) return;
    NotificationController.openDetail(notificationId);
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
      final isGranted = granted ?? true;
      unawaited(
        DeviceTokenService.instance.sendToken(
          currentToken,
          notificationsEnabled: isGranted,
        ),
      );
      return isGranted;
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
    int? number,
  }) async {
    if (!Platform.isAndroid || !_isInitialized) return;
    try {
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        // Status-bar silhouette + full-color brand mark inside the notification.
        icon: _smallIcon,
        largeIcon: const DrawableResourceAndroidBitmap(_largeIcon),
        color: _accentColor,
        // Badge count launchers that support numbers read off the notification.
        number: number,
      );
      final details = NotificationDetails(android: androidDetails);
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
