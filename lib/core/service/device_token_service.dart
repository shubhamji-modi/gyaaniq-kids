import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'api_service.dart';
import 'session_manager.dart';

/// Saves this device's FCM token on the backend (`POST /user/device-token`)
/// so push notifications can be sent to it. Storage only — fire-and-forget,
/// idempotent, safe to call as often as needed (login, app launch, token
/// refresh, permission change).
class DeviceTokenService {
  DeviceTokenService._();

  static final DeviceTokenService instance = DeviceTokenService._();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  String? _lastSentToken;

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
    if (fcmToken == _lastSentToken && notificationsEnabled == null) return;

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
        _lastSentToken = fcmToken;
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
