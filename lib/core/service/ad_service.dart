import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/ad_config_data.dart';
import 'api_service.dart';
import 'app_features_service.dart';

class AdService extends GetxService {
  static AdService get instance => Get.find<AdService>();

  AdConfigData _config = const AdConfigData();
  Future<InitializationStatus>? _initializeFuture;

  bool get _isMobilePlatform {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  Future<void> initialize() async {
    if (!_isMobilePlatform) {
      return;
    }
    _initializeFuture ??= MobileAds.instance.initialize();
    await _initializeFuture;
  }

  Future<void> showQuizResultAdIfEnabled() async {
    if (!_isMobilePlatform) {
      return;
    }

    // Ads need both switches: the class-level one from `user/app-features`
    // and the platform-level one from the ad settings checked below.
    if (!AppFeaturesService.instance.isGoogleAdEnabled) {
      debugPrint('Quiz result ad skipped: googleAd is off for this class.');
      return;
    }

    final config = await _loadConfig();
    if (config.hasQuizResultAdEnabledSetting && !config.quizResultAdEnabled) {
      debugPrint('Quiz result ad skipped: disabled from admin config.');
      return;
    }

    final configuredAdUnitId = config.quizResultRewardedAdUnitId;
    final adUnitId = configuredAdUnitId.isNotEmpty
        ? configuredAdUnitId
        : _debugRewardedAdUnitId;
    if (adUnitId.isEmpty) {
      debugPrint('Quiz result ad skipped: rewarded ad unit id is missing.');
      return;
    }

    try {
      await initialize();
      await _loadAndShowRewardedAd(adUnitId);
    } catch (e) {
      debugPrint('Quiz result ad skipped: $e');
    }
  }

  String get _debugRewardedAdUnitId {
    if (!kDebugMode) {
      return '';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ca-app-pub-3940256099942544/1033173712'; //	ca-app-pub-4271519308644982/1285110127
      case TargetPlatform.iOS:
        return 'ca-app-pub-4271519308644982/1582291892';
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return '';
    }
  }

  Future<AdConfigData> _loadConfig() async {
    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.GET_ADMIN_AD_CONFIG,
      showLoader: false,
      fromJson: (json) => json,
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return _config;
    }

    final body = response.data as Map<String, dynamic>;
    final data = body['data'];
    final config = data is Map<String, dynamic> ? data['config'] : null;
    if (config is Map<String, dynamic>) {
      _config = AdConfigData.fromApi(config);
    }
    return _config;
  }

  /// How long we wait for an ad to *load* before giving up on it. Only the
  /// load is on a clock — see [_loadAndShowRewardedAd].
  static const Duration _loadTimeout = Duration(seconds: 12);

  /// Last-resort guard in case the dismiss callback never arrives, so a stuck
  /// ad can't strand the student on the quiz screen forever. Comfortably
  /// longer than any rewarded ad.
  static const Duration _displayGuard = Duration(minutes: 3);

  /// Breathing room after the ad is dismissed, so Android has finished tearing
  /// the ad activity down before the caller pushes the result screen.
  static const Duration _teardownDelay = Duration(milliseconds: 350);

  /// Loads a rewarded ad and, if it arrives in time, shows it — returning only
  /// once the ad is really gone from the screen.
  ///
  /// The timeout deliberately covers the load only. It used to cover the whole
  /// thing at 12 seconds, but a rewarded ad runs longer than that, so the
  /// timeout kept firing *while the ad was still playing*: it disposed the ad
  /// mid-display and let the caller navigate underneath it. The ad activity
  /// was then still on top of the Flutter view when it came back, which is why
  /// the bottom tab bar stopped responding to taps after an ad.
  Future<void> _loadAndShowRewardedAd(String adUnitId) async {
    final loadCompleter = Completer<RewardedAd?>();
    var hasLoadTimedOut = false;

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          // Arrived after we stopped waiting — throw it away rather than
          // interrupt a student who has already moved on.
          if (hasLoadTimedOut) {
            ad.dispose();
            return;
          }
          if (!loadCompleter.isCompleted) {
            loadCompleter.complete(ad);
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint('Quiz result ad failed to load: $error');
          if (!loadCompleter.isCompleted) {
            loadCompleter.complete(null);
          }
        },
      ),
    );

    final ad = await loadCompleter.future.timeout(
      _loadTimeout,
      onTimeout: () {
        hasLoadTimedOut = true;
        return null;
      },
    );

    if (ad == null) {
      return;
    }

    final dismissed = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!dismissed.isCompleted) {
          dismissed.complete();
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Quiz result ad failed to show: $error');
        ad.dispose();
        if (!dismissed.isCompleted) {
          dismissed.complete();
        }
      },
    );

    await ad.show(onUserEarnedReward: (adWithoutView, rewardItem) {});
    // No disposing here on timeout: an ad that is on screen must be left
    // alone. This only stops us waiting forever.
    await dismissed.future.timeout(_displayGuard, onTimeout: () {});
    await Future<void>.delayed(_teardownDelay);
  }
}
