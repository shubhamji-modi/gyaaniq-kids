import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'api_service.dart';
import 'notification_service.dart';
import 'session_manager.dart';

/// Saves this device's FCM token on the backend (`POST /user/device-token`)
/// so push notifications can be sent to it. Storage only — fire-and-forget,
/// idempotent, safe to call as often as needed.
///
/// Sent on every app open (cold start + coming back from the background),
/// on login and on register, and whenever FCM rotates the token.
class DeviceTokenService with WidgetsBindingObserver {
  DeviceTokenService._();

  static final DeviceTokenService instance = DeviceTokenService._();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  bool _isObservingLifecycle = false;
  bool _wasInBackground = false;

  /// Starts re-sending the token each time the app comes back to the
  /// foreground. Safe to call more than once.
  void init() {
    if (_isObservingLifecycle) return;
    _isObservingLifecycle = true;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only a real trip to the background counts as "opening" the app again —
    // system dialogs (e.g. the permission prompt) just go inactive → resumed.
    if (state == AppLifecycleState.paused) {
      _wasInBackground = true;
    } else if (state == AppLifecycleState.resumed && _wasInBackground) {
      _wasInBackground = false;
      sync();
    }
  }

  /// Sends the current FCM token together with the current notification
  /// permission. Used on app open, login and register.
  Future<void> sync() async {
    if (Firebase.apps.isEmpty) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final token =
          NotificationService.instance.currentToken ?? await messaging.getToken();
      if (token == null || token.isEmpty) return;
      NotificationService.instance.currentToken = token;

      final settings = await messaging.getNotificationSettings();
      await sendToken(
        token,
        notificationsEnabled:
            settings.authorizationStatus == AuthorizationStatus.authorized ||
                settings.authorizationStatus == AuthorizationStatus.provisional,
      );
    } catch (e) {
      debugPrint('DeviceTokenService: sync failed -> $e');
    }
  }

  /// Sends [fcmToken] to the server, enriched with whatever device/app info
  /// is available on this platform. Never throws — errors are swallowed and
  /// logged, since this must never block login/navigation/app start.
  ///
  /// Pass [notificationsEnabled] once known (e.g. after the permission
  /// prompt is answered) to keep that flag up to date server-side.
  Future<void> sendToken(
    String? fcmToken, {
    bool? notificationsEnabled,
  }) async {
    if (fcmToken == null || fcmToken.trim().isEmpty) return;
    if (!Get.isRegistered<SessionManager>()) return;
    if (!SessionManager.instance.isLoggedIn) return;

    try {
      final data = <String, dynamic>{
        'fcmToken': fcmToken,
        'platform': Platform.operatingSystem,
      };

      final deviceInfo = await _collectDeviceInfo();
      data.addAll(deviceInfo);

      try {
        final packageInfo = await PackageInfo.fromPlatform();
        data['appVersion'] = packageInfo.version;
        data['appBuildNumber'] = packageInfo.buildNumber;
      } catch (e) {
        debugPrint('DeviceTokenService: package info failed -> $e');
      }

      try {
        data['locale'] = Platform.localeName;
      } catch (e) {
        debugPrint('DeviceTokenService: locale lookup failed -> $e');
      }

      try {
        data['timezone'] = await FlutterTimezone.getLocalTimezone();
      } catch (e) {
        debugPrint('DeviceTokenService: timezone lookup failed -> $e');
      }

      if (notificationsEnabled != null) {
        data['notificationsEnabled'] = notificationsEnabled;
      }

      final response = await ApiService.instance.post(
        endpoint: ApiService.DEVICE_TOKEN,
        data: data,
        showLoader: false,
      );

      if (response.success) {
        debugPrint('DeviceTokenService: token saved -> ${response.data}');
      } else {
        debugPrint('DeviceTokenService: save failed -> ${response.message}');
      }
    } catch (e) {
      debugPrint('DeviceTokenService: unexpected error -> $e');
    }
  }

  Future<Map<String, dynamic>> _collectDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return {
          'deviceId': info.id,
          'deviceModel': info.model,
          'deviceBrand': info.brand,
          'osVersion': info.version.release,
        };
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return {
          'deviceId': info.identifierForVendor,
          'deviceModel': info.utsname.machine,
          'deviceBrand': 'Apple',
          'osVersion': info.systemVersion,
        };
      }
    } catch (e) {
      debugPrint('DeviceTokenService: device info failed -> $e');
    }
    return {};
  }
}
