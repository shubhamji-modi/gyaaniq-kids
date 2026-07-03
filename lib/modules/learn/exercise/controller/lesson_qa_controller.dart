import 'package:get/get.dart';

import '../../../../core/service/api_service.dart';

/// ViewModel for the lesson exercise (Q&A) screen.
///
/// Fetches every active Q&A pair for a single lesson from
/// `GET /user/lesson-qa/by-lesson/:lessonId`, in the exact `sequence` order the
/// question appears in the textbook, using server-side pagination. New pages are
/// appended so the list can grow as the student scrolls.
class LessonQaController extends GetxController {
  LessonQaController({required this.lessonId, this.lessonTitle = ''});

  final String lessonId;
  final String lessonTitle;

  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString resolvedLessonTitle = ''.obs;
  final RxInt totalCount = 0.obs;
  final RxList<LessonQaItem> rows = <LessonQaItem>[].obs;

  /// Index of the page currently visible in the book slider.
  final RxInt currentPage = 0.obs;

  /// `_id`s of the Q&A pages whose answer the student has revealed.
  final RxList<String> revealedIds = <String>[].obs;

  int _page = 1;
  int _totalPages = 1;
  static const int _limit = 20;

  bool get hasMore => _page < _totalPages;

  @override
  void onInit() {
    super.onInit();
    resolvedLessonTitle.value = lessonTitle;
    loadQa();
  }

  void setCurrentPage(int index) {
    currentPage.value = index;
    // Prefetch the next page of questions before the student swipes into it.
    if (index >= rows.length - 2) {
      loadMore();
    }
  }

  bool isRevealed(String id) => revealedIds.contains(id);

  void toggleRevealed(String id) {
    if (revealedIds.contains(id)) {
      revealedIds.remove(id);
    } else {
      revealedIds.add(id);
    }
  }

  Future<void> refreshQa() => loadQa(refresh: true);

  Future<void> loadQa({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _totalPages = 1;
    }

    if (_page == 1) {
      isLoading.value = true;
      errorMessage.value = '';
    } else {
      isLoadingMore.value = true;
    }

    final response = await LessonQaRepository.fetchByLesson(
      lessonId: lessonId,
      page: _page,
      limit: _limit,
    );

    if (_page == 1) {
      isLoading.value = false;
    } else {
      isLoadingMore.value = false;
    }

    if (!response.success || response.data == null) {
      if (_page == 1) {
        rows.clear();
        errorMessage.value = response.message;
      } else {
        // Roll back the optimistic page bump so loadMore can be retried.
        _page--;
      }
      return;
    }

    final page = response.data!;
    errorMessage.value = '';
    _totalPages = page.pagination.totalPages;
    totalCount.value = page.pagination.total;
    if (page.lessonTitle.isNotEmpty) {
      resolvedLessonTitle.value = page.lessonTitle;
    }

    if (_page == 1) {
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
    await loadQa();
  }
}

/// Data-layer access for student lesson Q&A.
class LessonQaRepository {
  static Future<ApiResponse<LessonQaPage>> fetchByLesson({
    required String lessonId,
    int page = 1,
    int limit = 20,
  }) async {
    final endpoint = ApiService.LESSON_QA_BY_LESSON.replaceFirst(
      ':lessonId',
      lessonId,
    );

    final response = await ApiService.instance.get<dynamic>(
      endpoint: endpoint,
      showLoader: false,
      fromJson: (json) => json,
      queryParameters: {'page': page, 'limit': limit},
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return ApiResponse<LessonQaPage>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    final body = response.data as Map<String, dynamic>;
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    final lessonJson = (data['lesson'] as Map<String, dynamic>?) ?? const {};
    final rowsJson = data['rows'] as List<dynamic>? ?? const [];
    final paginationJson =
        (data['pagination'] as Map<String, dynamic>?) ?? const {};

    return ApiResponse<LessonQaPage>(
      success: true,
      message: body['message']?.toString() ?? response.message,
      statusCode: response.statusCode,
      data: LessonQaPage(
        lessonTitle: _safeText(lessonJson['title']),
        rows: rowsJson
            .whereType<Map<String, dynamic>>()
            .map(LessonQaItem.fromApi)
            .toList(),
        pagination: LessonQaPagination.fromApi(paginationJson),
      ),
    );
  }

  /// Free-text search across question + answer. Optional [lessonId] (single
  /// lesson) or [subjectId] / [classLevel] (subject-wide) narrow the results.
  static Future<ApiResponse<LessonQaSearchPage>> search({
    required String query,
    String? lessonId,
    String? subjectId,
    String? classLevel,
    int page = 1,
    int limit = 20,
  }) async {
    // The API only accepts these exact class values; anything else 400s, so we
    // drop a malformed class rather than break the search (the subject filter
    // still scopes results).
    const allowedClasses = {'5th', '6th', '7th', '8th', '9th', '10th'};
    final normalizedClass = classLevel?.trim().toLowerCase();
    final classFilter = normalizedClass != null &&
            allowedClasses.contains(normalizedClass)
        ? normalizedClass
        : null;

    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.LESSON_QA_SEARCH,
      showLoader: false,
      fromJson: (json) => json,
      queryParameters: {
        'q': query,
        if (lessonId != null && lessonId.isNotEmpty) 'lessonId': lessonId,
        if (subjectId != null && subjectId.isNotEmpty) 'subject': subjectId,
        if (classFilter != null) 'classLevel': classFilter,
        'page': page,
        'limit': limit,
      },
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return ApiResponse<LessonQaSearchPage>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    final body = response.data as Map<String, dynamic>;
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    final rowsJson = data['rows'] as List<dynamic>? ?? const [];
    final paginationJson =
        (data['pagination'] as Map<String, dynamic>?) ?? const {};

    return ApiResponse<LessonQaSearchPage>(
      success: true,
      message: body['message']?.toString() ?? response.message,
      statusCode: response.statusCode,
      data: LessonQaSearchPage(
        query: _safeText(data['query'], fallback: query),
        rows: rowsJson
            .whereType<Map<String, dynamic>>()
            .map(LessonQaItem.fromApi)
            .toList(),
        pagination: LessonQaPagination.fromApi(paginationJson),
      ),
    );
  }
}

class LessonQaSearchPage {
  const LessonQaSearchPage({
    required this.query,
    required this.rows,
    required this.pagination,
  });

  final String query;
  final List<LessonQaItem> rows;
  final LessonQaPagination pagination;
}

class LessonQaPage {
  const LessonQaPage({
    required this.lessonTitle,
    required this.rows,
    required this.pagination,
  });

  final String lessonTitle;
  final List<LessonQaItem> rows;
  final LessonQaPagination pagination;
}

class LessonQaPagination {
  const LessonQaPagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  final int total;
  final int page;
  final int limit;
  final int totalPages;

  factory LessonQaPagination.fromApi(Map<String, dynamic> json) {
    return LessonQaPagination(
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

class LessonQaItem {
  const LessonQaItem({
    required this.id,
    required this.sequence,
    required this.question,
    required this.answer,
    required this.source,
    required this.subjectName,
    required this.classLevel,
    required this.lessonId,
    required this.lessonTitle,
  });

  final String id;
  final int sequence;
  final String question;
  final String answer;

  /// `"pdf"` (auto-extracted) or `"manual"` (teacher-authored).
  final String source;
  final String subjectName;
  final String classLevel;

  /// Parent lesson — populated by the search endpoint (per-row `lesson`), used
  /// to group search hits. Empty for the by-lesson endpoint (lesson is
  /// top-level there).
  final String lessonId;
  final String lessonTitle;

  factory LessonQaItem.fromApi(Map<String, dynamic> json) {
    final subject = (json['subject'] as Map<String, dynamic>?) ?? const {};
    final lesson = (json['lesson'] as Map<String, dynamic>?) ?? const {};
    return LessonQaItem(
      id: _safeText(json['_id']),
      sequence: (json['sequence'] as num?)?.toInt() ?? 0,
      question: _stripHtml(_safeText(json['question'])),
      answer: _stripHtml(_safeText(json['answer'])),
      source: _safeText(json['source']).toLowerCase(),
      subjectName: _safeText(subject['name']),
      classLevel: _safeText(
        json['classLevel'],
        fallback: _safeText(subject['classLevel']),
      ),
      lessonId: _safeText(lesson['_id']),
      lessonTitle: _safeText(lesson['title']),
    );
  }

  bool get isPdf => source == 'pdf';

  String get sourceLabel => isPdf ? 'From Textbook' : 'Teacher';
}

String _safeText(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _stripHtml(String value) {
  return value
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r' *\n *'), '\n')
      .trim();
}
