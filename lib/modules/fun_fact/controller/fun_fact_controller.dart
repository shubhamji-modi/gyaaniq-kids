import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/service/api_service.dart';

/// A subject the Home strip can show a fun-fact story for.
typedef FunFactSubjectRef = ({String id, String title});

/// One subject's fun facts for the day, plus how far the child has watched.
class FunFactBatch {
  const FunFactBatch({required this.urls, this.watchedCount = 0});

  final List<String> urls;

  /// How many facts the child has actually seen, counted from the start.
  final int watchedCount;

  /// Only true once every fact in the batch has been seen — this is what turns
  /// the story ring grey, so a partial watch must not qualify.
  bool get isCompleted => urls.isNotEmpty && watchedCount >= urls.length;

  /// Where a re-open should start: the first unwatched fact. A finished batch
  /// replays from the top, the way Instagram re-opens a fully-watched story.
  int get resumeIndex =>
      isCompleted ? 0 : watchedCount.clamp(0, urls.length - 1);

  FunFactBatch copyWith({int? watchedCount}) =>
      FunFactBatch(urls: urls, watchedCount: watchedCount ?? this.watchedCount);

  Map<String, dynamic> toJson() => {'urls': urls, 'watched': watchedCount};

  static FunFactBatch? fromJson(dynamic json) {
    if (json is! Map) {
      return null;
    }
    final urls = (json['urls'] as List<dynamic>?)?.whereType<String>().toList();
    if (urls == null || urls.isEmpty) {
      return null;
    }
    return FunFactBatch(
      urls: urls,
      watchedCount: (json['watched'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Owns the child's fun-fact batches for the current day.
///
/// The server hands out a *different* batch on every call and records each
/// served image as seen for 15 days. So a batch is fetched at most once per
/// subject per day and then cached — refetching would both burn the child's
/// seen budget and make "resume where you left off" impossible.
///
/// Watch progress is client-side for the same reason: the server's seen window
/// exists but is never exposed, so the ring colour cannot come from the API.
class FunFactController extends GetxController {
  static FunFactController get instance => Get.find<FunFactController>();

  static const String _prefsKey = 'fun_fact_batches';

  /// The subjects the last preload ran for. Remembered so a fresh launch can
  /// request fun facts straight away, instead of waiting on the dashboard's
  /// other calls to reveal what the child studies.
  static const String _subjectsPrefsKey = 'fun_fact_subjects';

  static const int _factsPerSubject = 3;

  /// subjectId -> today's batch. Observable so the rings recolour themselves.
  final RxMap<String, FunFactBatch> _batchBySubjectId =
      <String, FunFactBatch>{}.obs;

  /// The day [_batchBySubjectId] belongs to. A new day means new facts.
  String _cacheDate = '';

  bool _isRestored = false;

  /// In-progress fetches, keyed by subject. A tap that lands mid-preload joins
  /// the running call instead of starting a second one — every call burns the
  /// child's 15-day seen budget, so duplicates are not harmless.
  final Map<String, Future<FunFactBatch?>> _inFlightBySubjectId =
      <String, Future<FunFactBatch?>>{};

  @override
  void onInit() {
    super.onInit();
    _restore();
  }

  FunFactBatch? batchFor(String subjectId) => _batchBySubjectId[subjectId];

  /// The image each subject's story would open on. Fetching the batch only
  /// buys us the URLs, so these are worth precaching too — otherwise the first
  /// frame of a story is still a download.
  List<String> get openingImageUrls => [
    for (final batch in _batchBySubjectId.values)
      if (batch.urls.isNotEmpty) batch.urls[batch.resumeIndex],
  ];

  /// Grey ring only after the whole batch has been watched.
  bool isCompleted(String subjectId) =>
      _batchBySubjectId[subjectId]?.isCompleted ?? false;

  /// Warms today's batches so tapping a subject opens instantly instead of
  /// showing a spinner. Subjects already cached for today are skipped, so a
  /// Home-tab reload costs no extra API calls.
  Future<void> preloadForSubjects(List<FunFactSubjectRef> subjects) async {
    await _ensureRestored();
    await _rememberSubjects(subjects);
    await Future.wait(subjects.map((s) => _ensureBatch(s.id, s.title)));
  }

  /// Starts fetching fun facts the instant the dashboard opens, using the
  /// subject list left over from last time.
  ///
  /// Without this the first request cannot even be sent until the progress and
  /// subjects APIs have both answered — several seconds before the images
  /// start downloading, which is exactly the wait the child sees on first tap.
  ///
  /// Does nothing on a first-ever launch; [preloadForSubjects] covers that once
  /// the real list arrives, and any overlap is de-duplicated.
  Future<void> preloadFromCachedSubjects() async {
    await _ensureRestored();

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_subjectsPrefsKey);
    if (raw == null || raw.isEmpty) {
      return;
    }

    final subjects = <FunFactSubjectRef>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return;
      }
      for (final entry in decoded) {
        if (entry is Map) {
          final id = entry['id'];
          final title = entry['title'];
          if (id is String && title is String && id.isNotEmpty) {
            subjects.add((id: id, title: title));
          }
        }
      }
    } catch (_) {
      // A corrupt list just means we wait for the subjects API, as before.
      return;
    }

    await Future.wait(subjects.map((s) => _ensureBatch(s.id, s.title)));
  }

  Future<void> _rememberSubjects(List<FunFactSubjectRef> subjects) async {
    if (subjects.isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _subjectsPrefsKey,
      jsonEncode([
        for (final subject in subjects)
          {'id': subject.id, 'title': subject.title},
      ]),
    );
  }

  /// Returns today's batch for a subject, fetching it only if the preload has
  /// not already done so.
  Future<FunFactBatch?> ensureBatch(String subjectId, String subjectTitle) =>
      _ensureBatch(subjectId, subjectTitle);

  Future<FunFactBatch?> _ensureBatch(String subjectId, String title) async {
    await _ensureRestored();

    final cached = _batchBySubjectId[subjectId];
    if (cached != null) {
      return cached;
    }
    // Await the preload's own call rather than firing a duplicate.
    final inFlight = _inFlightBySubjectId[subjectId];
    if (inFlight != null) {
      return inFlight;
    }

    final request = _fetchAndCache(subjectId, title);
    _inFlightBySubjectId[subjectId] = request;
    try {
      return await request;
    } finally {
      _inFlightBySubjectId.remove(subjectId);
    }
  }

  Future<FunFactBatch?> _fetchAndCache(String subjectId, String title) async {
    final startedAt = DateTime.now();
    final urls = await _fetchFunFacts(
      subject: subjectCategoryFor(title),
      count: _factsPerSubject,
    );
    debugPrint(
      '[FunFact] API "$title": ${urls.length} url(s) in '
      '${DateTime.now().difference(startedAt).inMilliseconds}ms',
    );
    // Valid response, not an error: this class/subject has no images yet.
    if (urls.isEmpty) {
      return null;
    }
    final batch = FunFactBatch(urls: urls);
    _batchBySubjectId[subjectId] = batch;
    await _persist();
    return batch;
  }

  /// Records that the child has now seen [watchedCount] facts of this subject.
  /// Never moves backwards, so re-watching an old fact cannot un-grey a ring.
  Future<void> saveProgress(String subjectId, int watchedCount) async {
    final batch = _batchBySubjectId[subjectId];
    if (batch == null || watchedCount <= batch.watchedCount) {
      return;
    }
    _batchBySubjectId[subjectId] = batch.copyWith(
      watchedCount: watchedCount.clamp(0, batch.urls.length),
    );
    await _persist();
  }

  Future<List<String>> _fetchFunFacts({String? subject, int count = 3}) async {
    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.FUN_FACTS,
      showLoader: false,
      queryParameters: {'subject': ?subject, 'count': count.clamp(1, 20)},
      fromJson: (json) => json,
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return const [];
    }

    final body = response.data as Map<String, dynamic>;
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    final list = data['funFacts'] as List<dynamic>? ?? const [];

    final urls = <String>[];
    for (final item in list) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final image = item['image'];
      final url = image is Map<String, dynamic>
          ? (image['url'] as String?) ?? ''
          : '';
      if (url.isNotEmpty) {
        urls.add(url);
      }
    }
    return urls;
  }

  /// Maps a subject title from the child's syllabus onto the server's fixed
  /// category enum. Returns null when there is no confident match, which makes
  /// the request omit `subject` (server then returns a mixed batch) instead of
  /// sending an out-of-enum value and getting a 400.
  static String? subjectCategoryFor(String subjectTitle) {
    final s = subjectTitle.trim().toLowerCase();
    if (s.isEmpty) {
      return null;
    }
    if (s.contains('math')) return 'Mathematics';
    if (s.contains('comput')) return 'Computer Science';
    if (s.contains('science') && s.contains('social')) return 'Social Studies';
    if (s.contains('social') || s.contains('sst') || s.contains('civics')) {
      return 'Social Studies';
    }
    if (s.contains('history') || s.contains('geograph')) {
      return 'Social Studies';
    }
    if (s.contains('science') || s.contains('evs')) return 'Science';
    if (s.contains('english')) return 'English';
    if (s.contains('hindi')) return 'Hindi';
    if (s.contains('gk') || s.contains('general')) return 'General Knowledge';
    return null;
  }

  Future<void> _ensureRestored() async {
    if (_isRestored) {
      _dropStaleCache();
      return;
    }
    await _restore();
  }

  /// Yesterday's batch is thrown away rather than replayed: the strip is a
  /// daily habit, and a fresh day should hand out fresh facts.
  void _dropStaleCache() {
    if (_cacheDate != _todayKey()) {
      _cacheDate = _todayKey();
      _batchBySubjectId.clear();
    }
  }

  Future<void> _restore() async {
    _isRestored = true;
    _cacheDate = _todayKey();

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['date'] != _todayKey()) {
        return;
      }
      // Batches fetched under a different _factsPerSubject are the wrong size,
      // and the cache would otherwise keep serving them for the rest of the
      // day — silently ignoring the new setting. Drop them and refetch.
      if (decoded['count'] != _factsPerSubject) {
        debugPrint(
          '[FunFact] Cache dropped: built for ${decoded['count']} facts per '
          'subject, now $_factsPerSubject.',
        );
        return;
      }
      final subjects = decoded['subjects'];
      if (subjects is! Map) {
        return;
      }
      final restored = <String, FunFactBatch>{};
      subjects.forEach((key, value) {
        final batch = FunFactBatch.fromJson(value);
        if (key is String && batch != null) {
          restored[key] = batch;
        }
      });
      _batchBySubjectId.assignAll(restored);
    } catch (_) {
      // A corrupt cache just means today's facts get fetched again.
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({
        'date': _cacheDate,
        // Stamped so a change to _factsPerSubject invalidates the cache
        // instead of being masked by it until midnight.
        'count': _factsPerSubject,
        'subjects': _batchBySubjectId.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
      }),
    );
  }

  static String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }
}
