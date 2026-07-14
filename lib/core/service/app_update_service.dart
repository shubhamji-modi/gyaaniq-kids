import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/app_update_dialog.dart';

/// Handles checking for a newer app version and driving the update flow.
///
/// * **Android** – uses Google Play's native in-app-update APIs
///   ([in_app_update]) to detect an available update and perform it.
/// * **iOS** – queries the App Store (iTunes lookup API) to compare the store
///   version against the installed one, then deep-links to the App Store.
///
/// In both cases the custom [AppUpdateDialog] is shown first so the prompt
/// matches the app's design language.
class AppUpdateService {
  AppUpdateService._();

  static final AppUpdateService instance = AppUpdateService._();

  /// App Store numeric id used to build the iTunes lookup + store URLs.
  /// Replace with the real App Store id once the app is live on iOS.
  static const String _iosAppStoreId = '0000000000';

  static const String _androidPackage = 'com.gyaaniqkids.app';
  static const String _iosBundleId = 'org.gyaaniqkids.ai';

  final Dio _dio = Dio();
  bool _isChecking = false;

  /// Entry point – call this after the first frame of your landing screen.
  ///
  /// Pass [forceUpdate] to make the prompt non-dismissible (used for a
  /// mandatory / breaking update).
  Future<void> checkForUpdate({bool forceUpdate = false}) async {
    if (_isChecking) return;
    _isChecking = true;
    try {
      if (Platform.isAndroid) {
        await _checkAndroid(forceUpdate: forceUpdate);
      } else if (Platform.isIOS) {
        await _checkIOS(forceUpdate: forceUpdate);
      }
    } catch (e) {
      debugPrint('AppUpdateService: update check failed -> $e');
    } finally {
      _isChecking = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Android – Google Play in-app update
  // ---------------------------------------------------------------------------
  Future<void> _checkAndroid({required bool forceUpdate}) async {
    final info = await InAppUpdate.checkForUpdate();
    if (info.updateAvailability != UpdateAvailability.updateAvailable) {
      return;
    }

    final versionCode = info.availableVersionCode;
    final shouldUpdate = await AppUpdateDialog.show(
      version: versionCode != null ? 'v$versionCode' : '',
      forceUpdate: forceUpdate,
    );
    if (!shouldUpdate) return;

    // Prefer an immediate (blocking) update for forced updates, otherwise a
    // flexible (background) update. Fall back to the store if neither is
    // allowed for this device/update.
    if (forceUpdate && info.immediateUpdateAllowed) {
      await InAppUpdate.performImmediateUpdate();
    } else if (info.flexibleUpdateAllowed) {
      await InAppUpdate.startFlexibleUpdate();
      await InAppUpdate.completeFlexibleUpdate();
    } else if (info.immediateUpdateAllowed) {
      await InAppUpdate.performImmediateUpdate();
    } else {
      await _openStore();
    }
  }

  // ---------------------------------------------------------------------------
  // iOS – App Store lookup
  // ---------------------------------------------------------------------------
  Future<void> _checkIOS({required bool forceUpdate}) async {
    final storeInfo = await _fetchAppStoreInfo();
    if (storeInfo == null) return;

    final info = await PackageInfo.fromPlatform();
    if (!_isRemoteNewer(info.version, storeInfo.version)) return;

    final shouldUpdate = await AppUpdateDialog.show(
      version: 'v${storeInfo.version}',
      forceUpdate: forceUpdate,
    );
    if (shouldUpdate) {
      await _openStore(fallbackUrl: storeInfo.trackViewUrl);
    }
  }

  Future<_AppStoreInfo?> _fetchAppStoreInfo() async {
    try {
      final response = await _dio.get(
        'https://itunes.apple.com/lookup',
        queryParameters: {'bundleId': _iosBundleId},
      );
      final data = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;
      final results = (data['results'] as List?) ?? const [];
      if (results.isEmpty) return null;
      final first = results.first as Map<String, dynamic>;
      return _AppStoreInfo(
        version: (first['version'] ?? '').toString(),
        trackViewUrl: (first['trackViewUrl'] ?? '').toString(),
      );
    } catch (e) {
      debugPrint('AppUpdateService: App Store lookup failed -> $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  Future<void> _openStore({String? fallbackUrl}) async {
    final uri = Platform.isIOS
        ? Uri.parse(
            (fallbackUrl != null && fallbackUrl.isNotEmpty)
                ? fallbackUrl
                : 'https://apps.apple.com/app/id$_iosAppStoreId',
          )
        : Uri.parse(
            'https://play.google.com/store/apps/details?id=$_androidPackage',
          );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Compares two dotted version strings (e.g. `1.0.1` vs `1.2.0`).
  bool _isRemoteNewer(String current, String remote) {
    if (remote.isEmpty) return false;
    final currentParts = _parseVersion(current);
    final remoteParts = _parseVersion(remote);
    final length = currentParts.length > remoteParts.length
        ? currentParts.length
        : remoteParts.length;
    for (var i = 0; i < length; i++) {
      final c = i < currentParts.length ? currentParts[i] : 0;
      final r = i < remoteParts.length ? remoteParts[i] : 0;
      if (r > c) return true;
      if (r < c) return false;
    }
    return false;
  }

  List<int> _parseVersion(String version) {
    return version
        .split('+')
        .first
        .split('.')
        .map((part) => int.tryParse(part.trim()) ?? 0)
        .toList();
  }
}

class _AppStoreInfo {
  const _AppStoreInfo({required this.version, required this.trackViewUrl});

  final String version;
  final String trackViewUrl;
}
