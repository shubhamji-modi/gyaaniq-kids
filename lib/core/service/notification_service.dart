import 'dart:async';
import 'dart:io';
import 'dart:ui' show Color;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../modules/coins/coin_service.dart';
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

/// Push notifications — Android and iOS.
///
/// Combines Firebase Cloud Messaging (remote push + device token) with
/// `flutter_local_notifications` (used to display notifications while the
/// app is in the foreground, and for any purely local/on-device reminders).
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  /// Message ids of pushes whose tap has already been acted on, so a
  /// re-delivered launch intent cannot reopen the same notification.
  static const String _handledPushIdsKey = 'handled_push_message_ids';
  static const int _handledPushIdsLimit = 20;

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

  static bool get _isSupportedPlatform => Platform.isAndroid || Platform.isIOS;

  /// Entry point — call once during app startup.
  Future<void> init() async {
    if (_isInitialized || !_isSupportedPlatform) return;

    try {
      const androidSettings = AndroidInitializationSettings(
        '@drawable/$_smallIcon',
      );
      // The permission is asked through FCM in [requestPermission], not here,
      // so the prompt does not appear before the app has started.
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onLocalNotificationTap,
      );

      if (Platform.isAndroid) {
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
      }

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

      if (Platform.isIOS) {
        // iOS draws a push that arrives in the foreground itself once this is
        // set, so onMessage below must not draw it a second time.
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      // Listen before asking for the token: on iOS a token that only shows up
      // once APNs answers arrives here, and is sent from here.
      messaging.onTokenRefresh.listen((newToken) {
        debugPrint('NotificationService: FCM token refreshed -> $newToken');
        currentToken = newToken;
        unawaited(DeviceTokenService.instance.sendToken(newToken));
      });

      // Not awaited: on iOS fetchToken() can wait seconds for APNs, and init()
      // runs before runApp(). Sent to the server by DeviceTokenService.sync()
      // once the permission prompt is answered — see main().
      unawaited(
        fetchToken().then((token) {
          if (token == null) return;
          currentToken ??= token;
          debugPrint('NotificationService: FCM token -> $token');
        }),
      );

      // Foreground: FCM does not show anything by itself, so display it
      // ourselves via flutter_local_notifications.
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        // Same rule as the background handler, so a data-only push bumps the
        // bell too instead of being counted only while the app is closed.
        if (message.notification == null && message.data.isEmpty) return;
        await NotificationBadgeService.instance.increment();

        // Coins were just credited: re-read the balance once (never polled).
        if (message.data['linkType']?.toString() == _coinsLinkType) {
          unawaited(CoinService.instance.refresh());
        }

        // Already shown by iOS — see setForegroundNotificationPresentationOptions.
        if (Platform.isIOS && message.notification != null) return;

        final title =
            message.notification?.title ?? message.data['title']?.toString();
        final body =
            message.notification?.body ?? message.data['body']?.toString();
        if ((title ?? '').isEmpty && (body ?? '').isEmpty) return;
        await showNotification(
          id: message.hashCode,
          title: title ?? '',
          body: body ?? '',
          number: NotificationBadgeService.instance.unreadCount.value,
          payload: _linkPayload(message.data),
        );
      });

      // Background / killed: the OS already showed the notification, so we
      // only need to react to the user tapping it.
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // A push that launched the app from the killed state. Android keeps the
      // launching intent attached to the task, so this same message comes back
      // on later plain launches from the launcher too — opening Notifications
      // for a student who just tapped the app icon. Handling each message id
      // only once keeps a normal launch on the Home tab.
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null &&
          !await _hasAlreadyHandled(initialMessage)) {
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      debugPrint('NotificationService: FCM init failed -> $e');
    }
  }

  /// This device's FCM token, or null when it cannot be had yet.
  ///
  /// On iOS FCM only hands out a token once Apple has issued the APNs token,
  /// which can take a moment after launch or after the permission prompt —
  /// asking earlier throws. [onTokenRefresh] covers it arriving later still.
  Future<String?> fetchToken() async {
    if (Firebase.apps.isEmpty) return null;
    try {
      final messaging = FirebaseMessaging.instance;
      if (Platform.isIOS) {
        var apnsToken = await messaging.getAPNSToken();
        for (var attempt = 0; apnsToken == null && attempt < 5; attempt++) {
          await Future<void>.delayed(const Duration(seconds: 1));
          apnsToken = await messaging.getAPNSToken();
        }
        if (apnsToken == null) {
          debugPrint('NotificationService: APNs token not available yet');
          return null;
        }
      }
      return await messaging.getToken();
    } catch (e) {
      debugPrint('NotificationService: getToken failed -> $e');
      return null;
    }
  }

  /// Whether this push was already opened once, remembered across launches.
  ///
  /// Only used for `getInitialMessage()`: a real tap arriving through
  /// `onMessageOpenedApp` is always a fresh one.
  Future<bool> _hasAlreadyHandled(RemoteMessage message) async {
    final messageId = message.messageId ?? '';
    if (messageId.isEmpty) {
      // Nothing to match on — treat it as new rather than swallow a real tap.
      return false;
    }

    try {
      final preferences = await SharedPreferences.getInstance();
      final handled =
          preferences.getStringList(_handledPushIdsKey) ?? <String>[];
      if (handled.contains(messageId)) {
        return true;
      }

      handled.add(messageId);
      // A short tail is enough: only the most recent launch intent can come
      // back, and the list must not grow forever.
      if (handled.length > _handledPushIdsLimit) {
        handled.removeRange(0, handled.length - _handledPushIdsLimit);
      }
      await preferences.setStringList(_handledPushIdsKey, handled);
      return false;
    } catch (e) {
      debugPrint('NotificationService: handled-push check failed -> $e');
      return false;
    }
  }

  /// Payload of a foreground notification that should open a screen when
  /// tapped: a Library lesson (`linkType = "libraryLesson"`, `linkId`) or the
  /// coin wallet (`linkType = "studentCoins"`).
  static String? _linkPayload(Map<String, dynamic> data) {
    final linkType = data['linkType']?.toString();
    final linkId = data['linkId']?.toString() ?? '';
    if (linkType == _coinsLinkType) return '$_coinsLinkType:$linkId';
    if (linkType != _libraryLinkType || linkId.isEmpty) return null;
    return '$_libraryLinkType:$linkId';
  }

  static const String _libraryLinkType = 'libraryLesson';
  static const String _coinsLinkType = 'studentCoins';

  /// Tap on a notification we drew ourselves while the app was open.
  void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload ?? '';
    if (payload.startsWith('$_coinsLinkType:')) {
      unawaited(NotificationBadgeService.instance.clear());
      NotificationController.handleStudentCoinsTap();
      return;
    }
    if (!payload.startsWith('$_libraryLinkType:')) return;
    unawaited(NotificationBadgeService.instance.clear());
    NotificationController.handleLibraryLessonTap(
      payload.substring(_libraryLinkType.length + 1),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Tapping a push counts as reading it.
    unawaited(NotificationBadgeService.instance.clear());

    final linkType = message.data['linkType']?.toString();

    // Coins credited: open the wallet, which fetches the real balance.
    if (linkType == _coinsLinkType) {
      NotificationController.handleStudentCoinsTap();
      return;
    }

    // Library pushes are about one lesson: open it, not the notification.
    final linkId = message.data['linkId']?.toString() ?? '';
    if (linkType == _libraryLinkType && linkId.isNotEmpty) {
      NotificationController.handleLibraryLessonTap(linkId);
      return;
    }

    final notificationId = message.data['notificationId']?.toString();
    if (notificationId == null || notificationId.isEmpty) return;
    // Never opens the detail straight away: when the app was killed this runs
    // while the splash screen is still up. The controller parks the id and
    // opens it on the Notifications screen once the app is ready.
    NotificationController.handlePushTap(notificationId);
  }

  /// Requests the runtime POST_NOTIFICATIONS permission (Android 13+), or the
  /// alert/badge/sound permission on iOS. Returns true on older Android
  /// versions, where no prompt exists.
  Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      if (Firebase.apps.isEmpty) return false;
      try {
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        return settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
      } catch (e) {
        debugPrint('NotificationService: permission request failed -> $e');
        return false;
      }
    }
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
    int? number,
  }) async {
    if (!_isSupportedPlatform || !_isInitialized) return;
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
      final darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        badgeNumber: number,
      );
      final details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );
      await _plugin.show(id, title, body, details, payload: payload);
    } catch (e) {
      debugPrint('NotificationService: showNotification failed -> $e');
    }
  }

  /// Cancels a previously scheduled/shown notification by [id].
  Future<void> cancel(int id) async {
    if (!_isSupportedPlatform) return;
    await _plugin.cancel(id);
  }

  /// Cancels all notifications.
  Future<void> cancelAll() async {
    if (!_isSupportedPlatform) return;
    await _plugin.cancelAll();
  }
}
