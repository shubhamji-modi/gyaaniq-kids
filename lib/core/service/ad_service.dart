import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/ad_config_data.dart';
import 'api_service.dart';

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

  Future<void> _loadAndShowRewardedAd(String adUnitId) {
    final completer = Completer<void>();
    RewardedAd? rewardedAd;
    var shouldShowAd = true;

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          rewardedAd = ad;
          if (!shouldShowAd) {
            ad.dispose();
            if (!completer.isCompleted) {
              completer.complete();
            }
            return;
          }
          ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) {
                completer.complete();
              }
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (!completer.isCompleted) {
                completer.complete();
              }
            },
          );
          ad.show(onUserEarnedReward: (adWithoutView, rewardItem) {});
        },
        onAdFailedToLoad: (error) {
          rewardedAd?.dispose();
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      ),
    );

    return completer.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        shouldShowAd = false;
        rewardedAd?.dispose();
      },
    );
  }
}
