import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';

/// Thin wrapper around [FirebaseAnalytics] so screens/controllers log events
/// through one place instead of touching the Firebase SDK directly.
///
/// Every method is a no-op until [enable] is called (which must only happen
/// after `Firebase.initializeApp` succeeds). This keeps the app crash-free on
/// platforms where Firebase isn't configured yet (e.g. iOS before its
/// GoogleService-Info.plist is added).
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics? _analytics;
  bool _enabled = false;

  bool get isEnabled => _enabled;

  /// Turn analytics on. Call once, only after Firebase has initialized.
  void enable() {
    _analytics = FirebaseAnalytics.instance;
    _enabled = true;
  }

  /// Route observer that auto-logs `screen_view` events on navigation.
  /// Returns a plain (no-op) observer when analytics is disabled.
  NavigatorObserver get observer => _enabled && _analytics != null
      ? FirebaseAnalyticsObserver(analytics: _analytics!)
      : NavigatorObserver();

  /// Log a custom event, e.g. `logEvent('quiz_completed', {'score': 8})`.
  Future<void> logEvent(
    String name, [
    Map<String, Object>? parameters,
  ]) async {
    if (!_enabled) return;
    await _analytics!.logEvent(name: name, parameters: parameters);
  }

  /// Log a manual screen view (for screens not pushed via the navigator).
  Future<void> logScreenView(String screenName) async {
    if (!_enabled) return;
    await _analytics!.logScreenView(screenName: screenName);
  }

  /// Attach a user id so events/crashes can be tied to an account.
  Future<void> setUserId(String? id) async {
    if (!_enabled) return;
    await _analytics!.setUserId(id: id);
  }
}
