import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks how many pushes have arrived since the user last opened the
/// notifications screen.
///
/// The list API does not expose a read/unread flag, so the count is kept on the
/// device: every incoming push bumps it, opening the notifications screen
/// clears it. The value is mirrored to
///  * the launcher badge on the app icon (via [AppBadgePlus]), and
///  * [unreadCount], which the in-app bell listens to.
///
/// Pushes that arrive while the app is backgrounded are counted by the FCM
/// background handler, which runs in its own isolate and can only touch
/// SharedPreferences — hence [refresh], called again whenever the app resumes.
class NotificationBadgeService with WidgetsBindingObserver {
  NotificationBadgeService._();

  static final NotificationBadgeService instance = NotificationBadgeService._();

  static const String prefsKey = 'unread_notification_count';

  /// Unread pushes since the notifications screen was last opened.
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  bool _isInitialized = false;

  /// Loads the stored count and starts watching the app lifecycle. Safe to
  /// call more than once.
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    WidgetsBinding.instance.addObserver(this);
    await refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pushes counted by the background isolate only land in SharedPreferences,
    // so re-read them once the app comes back to the foreground.
    if (state == AppLifecycleState.resumed) {
      refresh();
    }
  }

  /// Re-reads the stored count and republishes it to the icon + the bell.
  Future<void> refresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _apply(prefs.getInt(prefsKey) ?? 0, persist: false);
    } catch (e) {
      debugPrint('NotificationBadgeService: refresh failed -> $e');
    }
  }

  /// Counts one more unread push.
  Future<void> increment() => _bump(1);

  /// Clears the badge — called when the user opens the notifications screen.
  Future<void> clear() async {
    if (unreadCount.value == 0) {
      // Still clear the launcher badge: the stored value can be ahead of the
      // in-memory one when the background isolate did the counting.
      await refresh();
      if (unreadCount.value == 0) return;
    }
    await _apply(0);
  }

  Future<void> _bump(int by) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(prefsKey) ?? 0;
      await _apply(current + by);
    } catch (e) {
      debugPrint('NotificationBadgeService: increment failed -> $e');
    }
  }

  Future<void> _apply(int count, {bool persist = true}) async {
    final next = count < 0 ? 0 : count;
    unreadCount.value = next;

    try {
      if (persist) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(prefsKey, next);
      }
      // Not every launcher supports numeric badges (stock Android shows only a
      // dot); isSupported keeps the unsupported ones from throwing.
      if (await AppBadgePlus.isSupported()) {
        await AppBadgePlus.updateBadge(next);
      }
    } catch (e) {
      debugPrint('NotificationBadgeService: badge update failed -> $e');
    }
  }

  /// Increments the stored count from an isolate that has no access to the
  /// singleton's in-memory state (the FCM background handler). Returns the new
  /// total so the caller can put it on the notification itself.
  static Future<int> incrementInBackground() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // The background isolate starts with a cold cache, but another isolate
      // may have written since — reload before reading.
      await prefs.reload();
      final next = (prefs.getInt(prefsKey) ?? 0) + 1;
      await prefs.setInt(prefsKey, next);
      try {
        if (await AppBadgePlus.isSupported()) {
          await AppBadgePlus.updateBadge(next);
        }
      } catch (_) {
        // Badge plugin is not always available in a background isolate.
      }
      return next;
    } catch (e) {
      debugPrint('NotificationBadgeService: background increment failed -> $e');
      return 0;
    }
  }
}
