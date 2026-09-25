import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'session_manager.dart';

/// Which sections of the app are switched on for the signed-in student.
///
/// Admins flip each section on or off **per class**, so the answer depends on
/// the student's current class — it has to be refetched after profile setup
/// and after a class change, not just at launch.
///
/// Rules this follows (see `GET user/app-features`):
///  * A missing key means **on**. New keys can be added server-side and an
///    older build must keep showing what it already knows about.
///  * The last answer is cached on the device and reused when the call fails,
///    so a flaky network never blanks the home screen.
///  * `503` (settings unreadable) is not an answer — the cache stays as it is.
///  * Only `classChange` is enforced server-side; hiding the rest is on us.
class AppFeaturesService with WidgetsBindingObserver {
  AppFeaturesService._();

  static final AppFeaturesService instance = AppFeaturesService._();

  // Feature keys, as returned under `data.features`.
  static const String classChange = 'classChange';
  static const String funFact = 'funFact';
  static const String classPrizes = 'classPrizes';
  static const String notes = 'notes';
  static const String practiceQuiz = 'practiceQuiz';
  static const String mockTest = 'mockTest';
  static const String dailyQuiz = 'dailyQuiz';
  static const String quizHistory = 'quizHistory';
  static const String homework = 'homework';
  static const String attendance = 'attendance';
  static const String subscription = 'subscription';
  static const String googleAd = 'googleAd';
  static const String weakAreas = 'weakAreas';

  static const String _prefsFeaturesKey = 'app_features';
  static const String _prefsClassLevelKey = 'app_features_class_level';

  /// Bumped on every change so `Obx`/`ValueListenableBuilder` widgets that
  /// gate on a feature rebuild. Listening to the notifier rather than to a map
  /// keeps this usable from plain widgets as well as GetX ones.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  Map<String, bool> _features = const {};

  /// The class the current answer belongs to, or `null` when the student has
  /// not picked one yet.
  String? classLevel;

  bool _isLoaded = false;
  Future<void>? _inFlight;
  DateTime? _lastFetchedAt;

  /// How long a fetched answer is treated as current when the app comes back
  /// to the foreground. Admin changes take about a minute to reach the app
  /// anyway, so checking more often than this buys nothing.
  static const Duration _resumeTtl = Duration(minutes: 1);

  /// Loads the cached answer from disk. Called once at startup, before the
  /// first frame, so the very first build already gates correctly.
  Future<void> init() async {
    if (_isLoaded) return;
    _isLoaded = true;
    WidgetsBinding.instance.addObserver(this);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsFeaturesKey);
      classLevel = prefs.getString(_prefsClassLevelKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        _features = _asFlags(decoded);
        revision.value++;
      }
    } catch (e) {
      debugPrint('AppFeaturesService: cache read failed -> $e');
    }
  }

  /// `true` unless the admin switched [key] off for this student's class.
  ///
  /// Unknown keys — and everything before the first successful fetch — are on,
  /// so a new section never disappears on an older build.
  bool isEnabled(String key) => _features[key] ?? true;

  bool get isClassChangeEnabled => isEnabled(classChange);
  bool get isFunFactEnabled => isEnabled(funFact);
  bool get isClassPrizesEnabled => isEnabled(classPrizes);
  bool get isNotesEnabled => isEnabled(notes);
  bool get isPracticeQuizEnabled => isEnabled(practiceQuiz);
  bool get isMockTestEnabled => isEnabled(mockTest);
  bool get isDailyQuizEnabled => isEnabled(dailyQuiz);
  bool get isQuizHistoryEnabled => isEnabled(quizHistory);
  bool get isHomeworkEnabled => isEnabled(homework);
  bool get isAttendanceEnabled => isEnabled(attendance);
  bool get isSubscriptionEnabled => isEnabled(subscription);
  bool get isGoogleAdEnabled => isEnabled(googleAd);
  bool get isWeakAreasEnabled => isEnabled(weakAreas);

  /// Fetches the current answer. Safe to call from anywhere and as often as
  /// needed: concurrent calls share one request, and a failure leaves the
  /// cached values untouched.
  ///
  /// Never awaited on a screen's critical path — call it and let the gated
  /// widgets rebuild when [revision] changes.
  Future<void> refresh() {
    // Signed-out: there is nothing to ask about, and a 401 here would bounce
    // the student to the login screen they are already on.
    if (!Get.isRegistered<SessionManager>() ||
        SessionManager.instance.userToken.isEmpty) {
      return Future<void>.value();
    }
    return _inFlight ??= _fetch().whenComplete(() => _inFlight = null);
  }

  /// A warm launch — the app coming back to the foreground — is a launch too,
  /// so the switches are rechecked, throttled by [_resumeTtl].
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final last = _lastFetchedAt;
    if (last != null && DateTime.now().difference(last) < _resumeTtl) return;
    unawaited(refresh());
  }

  Future<void> _fetch() async {
    try {
      final response = await ApiService.instance.get<dynamic>(
        endpoint: ApiService.APP_FEATURES,
        showLoader: false,
        fromJson: (json) => json,
      );

      // 401 is handled by the API layer (session expiry), 403 is a Quick
      // Quiz-only account and 503 means the settings could not be read. None
      // of them is an answer about the sections, so the cache stands.
      if (!response.success || response.data is! Map<String, dynamic>) {
        debugPrint(
          'AppFeaturesService: keeping cached features '
          '(${response.statusCode} ${response.message})',
        );
        return;
      }

      final body = response.data as Map<String, dynamic>;
      final data = body['data'];
      if (data is! Map<String, dynamic>) return;

      final features = data['features'];
      if (features is! Map) return;

      _features = _asFlags(features);
      classLevel = data['classLevel']?.toString();
      _lastFetchedAt = DateTime.now();
      revision.value++;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsFeaturesKey, jsonEncode(_features));
      if (classLevel == null) {
        await prefs.remove(_prefsClassLevelKey);
      } else {
        await prefs.setString(_prefsClassLevelKey, classLevel!);
      }
    } catch (e) {
      debugPrint('AppFeaturesService: fetch failed -> $e');
    }
  }

  /// Drops everything on sign-out so the next student does not inherit the
  /// previous one's sections.
  Future<void> clear() async {
    _features = const {};
    classLevel = null;
    _lastFetchedAt = null;
    revision.value++;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsFeaturesKey);
      await prefs.remove(_prefsClassLevelKey);
    } catch (e) {
      debugPrint('AppFeaturesService: clear failed -> $e');
    }
  }

  /// Keeps only real booleans: anything else is dropped so it falls back to
  /// the "missing means on" default rather than being read as off.
  Map<String, bool> _asFlags(Map<dynamic, dynamic> source) {
    final flags = <String, bool>{};
    source.forEach((key, value) {
      if (value is bool) flags[key.toString()] = value;
    });
    return flags;
  }
}
