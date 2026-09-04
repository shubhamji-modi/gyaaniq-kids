import 'package:flutter/foundation.dart';

class AdConfigData {
  const AdConfigData({
    this.quizResultAdEnabled = false,
    this.hasQuizResultAdEnabledSetting = false,
    this.androidQuizResultRewardedAdUnitId = '',
    this.iosQuizResultRewardedAdUnitId = '',
  });

  final bool quizResultAdEnabled;
  final bool hasQuizResultAdEnabledSetting;
  final String androidQuizResultRewardedAdUnitId;
  final String iosQuizResultRewardedAdUnitId;

  String get quizResultRewardedAdUnitId {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return androidQuizResultRewardedAdUnitId;
      case TargetPlatform.iOS:
        return iosQuizResultRewardedAdUnitId.isNotEmpty
            ? iosQuizResultRewardedAdUnitId
            : androidQuizResultRewardedAdUnitId;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return '';
    }
  }

  factory AdConfigData.fromApi(Map<String, dynamic> json) {
    final ads =
        _asMap(json['ads']) ??
        _asMap(json['adConfig']) ??
        _asMap(json['adMob']) ??
        json;
    final quizResult = _asMap(ads['quizResult']) ?? ads;
    final rewarded = _asMap(quizResult['rewarded']) ?? quizResult;

    final commonAdUnitId = _asString(
      rewarded['adUnitId'] ??
          rewarded['rewardedAdUnitId'] ??
          quizResult['adUnitId'] ??
          ads['quizResultRewardedAdUnitId'],
    );

    final enabledValue =
        rewarded['enabled'] ??
        quizResult['enabled'] ??
        ads['quizResultAdEnabled'] ??
        ads['enabled'];

    return AdConfigData(
      quizResultAdEnabled: _asBool(enabledValue),
      hasQuizResultAdEnabledSetting: enabledValue != null,
      androidQuizResultRewardedAdUnitId: _asString(
        rewarded['androidAdUnitId'] ??
            quizResult['androidAdUnitId'] ??
            ads['androidQuizResultRewardedAdUnitId'] ??
            commonAdUnitId,
      ),
      iosQuizResultRewardedAdUnitId: _asString(
        rewarded['iosAdUnitId'] ??
            quizResult['iosAdUnitId'] ??
            ads['iosQuizResultRewardedAdUnitId'] ??
            commonAdUnitId,
      ),
    );
  }
}

Map<String, dynamic>? _asMap(dynamic value) {
  return value is Map<String, dynamic> ? value : null;
}

String _asString(dynamic value) => value?.toString().trim() ?? '';

bool _asBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  final text = value?.toString().trim().toLowerCase();
  return text == 'true' || text == '1' || text == 'yes' || text == 'on';
}
