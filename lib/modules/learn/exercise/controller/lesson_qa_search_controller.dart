import 'package:get/get.dart';

import 'lesson_qa_controller.dart';

/// ViewModel for the Q&A search screen.
///
/// Free-text search across question + answer via `GET /user/lesson-qa/search`.
/// Optionally scoped to a single [lessonId] (exercise search) or to a subject /
/// class ([subjectId] + [classLevel], chapter search). Input is debounced
/// (~300ms) and results are paginated; a monotonic request token drops stale
/// responses so fast typing can't leave an out-of-date result on screen.
class LessonQaSearchController extends GetxController {
  LessonQaSearchController({this.lessonId, this.subjectId, this.classLevel});

  /// When set, search is restricted to this single lesson.
  final String? lessonId;
  final String? subjectId;
  final String? classLevel;

  final RxString query = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool hasSearched = false.obs;
  final RxInt total = 0.obs;
  final RxList<LessonQaItem> rows = <LessonQaItem>[].obs;
  final RxList<String> expandedIds = <String>[].obs;

  /// True when a single lesson is being searched (hides per-lesson grouping).
  bool get isSingleLesson => (lessonId ?? '').isNotEmpty;

  int _page = 1;
  int _totalPages = 1;
  int _searchToken = 0;
  String _activeQuery = '';
  static const int _limit = 20;
  static const int _minChars = 2;

  Worker? _debounceWorker;

  bool get hasMore => _page < _totalPages;

  @override
  void onInit() {
    super.onInit();
    _debounceWorker = debounce<String>(
      query,
      _onQueryChanged,
      time: const Duration(milliseconds: 300),
    );
  }

  @override
  void onClose() {
    _debounceWorker?.dispose();
    super.onClose();
  }

  void onQueryInput(String value) => query.value = value;

  void clearQuery() {
    query.value = '';
  }

  bool isExpanded(String id) => expandedIds.contains(id);

  void toggleExpanded(String id) {
    if (expandedIds.contains(id)) {
      expandedIds.remove(id);
    } else {
      expandedIds.add(id);
    }
  }

  void _onQueryChanged(String value) {
    final trimmed = value.trim();
    if (trimmed.length < _minChars) {
      // Too short to search — reset to the prompt state.
      _activeQuery = '';
      _searchToken++;
      rows.clear();
      errorMessage.value = '';
      hasSearched.value = false;
      isLoading.value = false;
      isLoadingMore.value = false;
      total.value = 0;
      return;
    }
    _activeQuery = trimmed;
    search(refresh: true);
  }

  Future<void> search({bool refresh = false}) async {
    if (_activeQuery.length < _minChars) {
      return;
    }

    if (refresh) {
      _page = 1;
      _totalPages = 1;
      isLoadingMore.value = false;
    }

    final token = ++_searchToken;
    final requestQuery = _activeQuery;
    final requestPage = _page;

    if (requestPage == 1) {
      isLoading.value = true;
      errorMessage.value = '';
      hasSearched.value = true;
    } else {
      isLoadingMore.value = true;
    }

    final response = await LessonQaRepository.search(
      query: requestQuery,
      lessonId: lessonId,
      subjectId: subjectId,
      classLevel: classLevel,
      page: requestPage,
      limit: _limit,
    );

    // A newer search superseded this one — discard the stale response.
    if (token != _searchToken) {
      return;
    }

    if (requestPage == 1) {
      isLoading.value = false;
    } else {
      isLoadingMore.value = false;
    }

    if (!response.success || response.data == null) {
      if (requestPage == 1) {
        rows.clear();
        errorMessage.value = response.message;
      } else {
        _page--; // allow the failed page to be retried
      }
      return;
    }

    final page = response.data!;
    errorMessage.value = '';
    _totalPages = page.pagination.totalPages;
    total.value = page.pagination.total;

    if (requestPage == 1) {
      rows.assignAll(page.rows);
    } else {
      rows.addAll(page.rows);
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || isLoading.value || isLoadingMore.value) {
      return;
    }
    _page++;
    await search();
  }

  Future<void> retry() => search(refresh: true);

  /// Groups the current rows by their parent lesson, preserving first-seen
  /// order (server sorts newest-first, so a lesson can appear in several spots —
  /// this collapses them under one header).
  List<LessonQaSearchGroup> get groupedRows {
    final order = <String>[];
    final byLesson = <String, LessonQaSearchGroup>{};
    for (final row in rows) {
      final key = row.lessonId.isEmpty ? '_' : row.lessonId;
      final group = byLesson.putIfAbsent(key, () {
        order.add(key);
        return LessonQaSearchGroup(
          lessonId: row.lessonId,
          lessonTitle: row.lessonTitle,
        );
      });
      group.items.add(row);
    }
    return order.map((key) => byLesson[key]!).toList();
  }
}

class LessonQaSearchGroup {
  LessonQaSearchGroup({required this.lessonId, required this.lessonTitle});

  final String lessonId;
  final String lessonTitle;
  final List<LessonQaItem> items = [];
}
