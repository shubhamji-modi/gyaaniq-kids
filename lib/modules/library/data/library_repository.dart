import 'package:dio/dio.dart' show ProgressCallback;

import '../../../core/service/api_service.dart';
import 'library_models.dart';

/// Outcome of one Library call.
///
/// The Library leans on status codes (`200` vs `201`, `409`, `429`, …) and on
/// the server's `message`, which is always written for the student, so both
/// are kept along with the raw `error` payload.
class LibraryResult<T> {
  const LibraryResult({
    required this.ok,
    required this.statusCode,
    required this.message,
    this.data,
    this.error,
  });

  final bool ok;
  final int statusCode;

  /// Student-facing text from the server (or a network fallback).
  final String message;
  final T? data;

  /// `error` from a failed response: a map (`{ quota }`, `{ sessionId }`,
  /// `{ publication }`) or a list of `{ field, message }`.
  final dynamic error;

  bool get isNetworkError => statusCode == 0;

  /// `{ field: message }` from a `400` with a field list.
  Map<String, String> get fieldErrors {
    final err = error;
    if (err is! List) return const {};
    final out = <String, String>{};
    for (final item in err) {
      if (item is Map) {
        final field = item['field']?.toString() ?? '';
        final msg = item['message']?.toString() ?? '';
        if (field.isNotEmpty && msg.isNotEmpty) out[field] = msg;
      }
    }
    return out;
  }

  Map<String, dynamic> get errorMap =>
      error is Map<String, dynamic> ? error as Map<String, dynamic> : const {};

  /// What to show the student when this call failed.
  String get displayMessage {
    if (statusCode == 404) return 'This lesson is no longer available.';
    if (message.trim().isNotEmpty) return message;
    return 'Something went wrong. Please try again.';
  }
}

class LibraryRepository {
  const LibraryRepository._();

  static String _withId(String endpoint, String id) =>
      endpoint.replaceFirst(':id', id);

  static String _withSid(String endpoint, String sid) =>
      endpoint.replaceFirst(':sid', sid);

  /// Turns an [ApiResponse] carrying the raw `{ status, message, data|error }`
  /// body into a [LibraryResult], parsing `data` with [parse] on success.
  static LibraryResult<T> _wrap<T>(
    ApiResponse<dynamic> response,
    T Function(Map<String, dynamic> data)? parse,
  ) {
    final body = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : const <String, dynamic>{};
    final message = body['message']?.toString() ?? response.message;

    if (!response.success) {
      return LibraryResult<T>(
        ok: false,
        statusCode: response.statusCode,
        message: message,
        error: body['error'],
      );
    }

    final data = body['data'];
    try {
      return LibraryResult<T>(
        ok: true,
        statusCode: response.statusCode,
        message: message,
        data: parse == null
            ? null
            : parse(
                data is Map<String, dynamic> ? data : const <String, dynamic>{},
              ),
      );
    } catch (_) {
      return LibraryResult<T>(
        ok: false,
        statusCode: response.statusCode,
        message: 'Something went wrong while reading the answer.',
      );
    }
  }

  static Future<LibraryResult<T>> _get<T>(
    String endpoint, {
    Map<String, dynamic>? query,
    T Function(Map<String, dynamic> data)? parse,
  }) async {
    final response = await ApiService.instance.get<dynamic>(
      endpoint: endpoint,
      queryParameters: query,
      showLoader: false,
      fromJson: (json) => json,
    );
    return _wrap<T>(response, parse);
  }

  static Future<LibraryResult<T>> _post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic> data)? parse,
  }) async {
    final response = await ApiService.instance.post<dynamic>(
      endpoint: endpoint,
      data: body,
      showLoader: false,
      fromJson: (json) => json,
    );
    return _wrap<T>(response, parse);
  }

  static Future<LibraryResult<T>> _put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic> data)? parse,
  }) async {
    final response = await ApiService.instance.put<dynamic>(
      endpoint: endpoint,
      data: body,
      showLoader: false,
      fromJson: (json) => json,
    );
    return _wrap<T>(response, parse);
  }

  static Future<LibraryResult<T>> _delete<T>(
    String endpoint, {
    T Function(Map<String, dynamic> data)? parse,
  }) async {
    final response = await ApiService.instance.delete<dynamic>(
      endpoint: endpoint,
      showLoader: false,
      fromJson: (json) => json,
    );
    return _wrap<T>(response, parse);
  }

  static LibraryLessonPage _lessonPage(Map<String, dynamic> data) {
    final rows = data['lessons'];
    return LibraryLessonPage(
      lessons: rows is List
          ? rows
                .whereType<Map<String, dynamic>>()
                .map(LibraryLesson.fromApi)
                .toList()
          : const [],
      pagination: LibraryPagination.fromApi(data['pagination']),
    );
  }

  /// The lesson is either the whole `data` or nested under `data.lesson`.
  static LibraryLesson? _lessonFrom(Map<String, dynamic> data) {
    final nested = data['lesson'];
    if (nested is Map<String, dynamic> && nested['_id'] != null) {
      return LibraryLesson.fromApi(nested);
    }
    if (data['_id'] != null) return LibraryLesson.fromApi(data);
    return null;
  }

  static LibraryUploadSession _sessionFrom(Map<String, dynamic> data) {
    final nested = data['session'];
    if (nested is Map<String, dynamic>) {
      return LibraryUploadSession.fromApi(nested);
    }
    return LibraryUploadSession.fromApi(data);
  }

  // ---------------------------------------------------------------------------
  // Catalogue
  // ---------------------------------------------------------------------------

  static Future<LibraryResult<LibraryMeta>> fetchMeta() =>
      _get(ApiService.LIBRARY_META, parse: LibraryMeta.fromApi);

  static Future<LibraryResult<List<LibraryRef>>> searchPublications(
    String query,
  ) => _get(
    ApiService.LIBRARY_PUBLICATIONS,
    query: {if (query.trim().isNotEmpty) 'q': query.trim()},
    parse: (data) {
      final rows = data['publications'];
      return rows is List
          ? rows
                .whereType<Map<String, dynamic>>()
                .map(LibraryRef.fromApi)
                .toList()
          : const <LibraryRef>[];
    },
  );

  /// `201` new request · `200` already asked (now following) · `409` already
  /// listed (`error.publication`) or not accepted.
  static Future<LibraryResult<LibraryPublicationRequest?>> requestPublication({
    required String name,
    String note = '',
  }) => _post(
    ApiService.LIBRARY_PUBLICATION_REQUESTS,
    body: {
      'name': name.trim(),
      if (note.trim().isNotEmpty) 'note': note.trim(),
    },
    parse: (data) {
      final req = data['request'];
      if (req is Map<String, dynamic>) {
        return LibraryPublicationRequest.fromApi(req);
      }
      return data['_id'] == null
          ? null
          : LibraryPublicationRequest.fromApi(data);
    },
  );

  static Future<LibraryResult<List<LibraryPublicationRequest>>>
  fetchPublicationRequests() => _get(
    ApiService.LIBRARY_PUBLICATION_REQUESTS,
    parse: (data) {
      final rows = data['requests'];
      return rows is List
          ? rows
                .whereType<Map<String, dynamic>>()
                .map(LibraryPublicationRequest.fromApi)
                .toList()
          : const <LibraryPublicationRequest>[];
    },
  );

  /// [status] is `available`, `pending` or `null` for everything.
  static Future<LibraryResult<LibraryLessonPage>> fetchLessons({
    String? publicationId,
    String? subjectId,
    String? status,
    String? query,
    int page = 1,
    int limit = 20,
  }) => _get(
    ApiService.LIBRARY_LESSONS,
    query: {
      if (publicationId != null && publicationId.isNotEmpty)
        'publication': publicationId,
      if (subjectId != null && subjectId.isNotEmpty) 'subject': subjectId,
      if (status != null && status.isNotEmpty) 'status': status,
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      'page': page,
      'limit': limit,
    },
    parse: _lessonPage,
  );

  static Future<LibraryResult<LibraryLessonPage>> fetchMyList(
    String endpoint, {
    int page = 1,
    int limit = 20,
  }) =>
      _get(endpoint, query: {'page': page, 'limit': limit}, parse: _lessonPage);

  static Future<LibraryResult<LibraryLesson?>> fetchLesson(String id) =>
      _get(_withId(ApiService.LIBRARY_LESSON, id), parse: _lessonFrom);

  /// `201` created · `200` already exists (now following, no limit used) ·
  /// `400` field errors · `429` daily limit.
  static Future<LibraryResult<LibraryLesson?>> requestLesson({
    required String publicationId,
    required String subjectId,
    required int chapterNumber,
    required String title,
    String note = '',
  }) => _post(
    ApiService.LIBRARY_LESSON_REQUESTS,
    body: {
      'publicationId': publicationId,
      'subjectId': subjectId,
      'chapterNumber': chapterNumber,
      'title': title.trim(),
      if (note.trim().isNotEmpty) 'note': note.trim(),
    },
    parse: _lessonFrom,
  );

  static Future<LibraryResult<LibraryLesson?>> follow(String id) =>
      _post(_withId(ApiService.LIBRARY_LESSON_FOLLOW, id), parse: _lessonFrom);

  static Future<LibraryResult<LibraryLesson?>> unfollow(String id) => _delete(
    _withId(ApiService.LIBRARY_LESSON_FOLLOW, id),
    parse: _lessonFrom,
  );

  // ---------------------------------------------------------------------------
  // Uploads
  // ---------------------------------------------------------------------------

  /// `201` new session · `200` resume the existing one.
  static Future<LibraryResult<LibraryUploadSession>> startUpload(
    String lessonId,
  ) => _post(
    _withId(ApiService.LIBRARY_START_UPLOAD, lessonId),
    parse: _sessionFrom,
  );

  static Future<LibraryResult<LibraryUploadSession>> fetchSession(String sid) =>
      _get(_withSid(ApiService.LIBRARY_SESSION, sid), parse: _sessionFrom);

  static Future<LibraryResult<LibraryUploadSession>> addPage({
    required String sid,
    required String filePath,
    String? replacePageId,
    ProgressCallback? onSendProgress,
  }) async {
    // Prepared pages are JPEGs; an original PNG/WebP is only sent as-is when
    // it could not be re-encoded.
    final lower = filePath.toLowerCase();
    final type = lower.endsWith('.png')
        ? (ext: 'png', mime: 'image/png')
        : lower.endsWith('.webp')
        ? (ext: 'webp', mime: 'image/webp')
        : (ext: 'jpg', mime: 'image/jpeg');
    final response = await ApiService.instance.uploadMultipart<dynamic>(
      endpoint: _withSid(ApiService.LIBRARY_SESSION_PAGES, sid),
      filePath: filePath,
      fieldName: 'page',
      fileName: 'page_${DateTime.now().millisecondsSinceEpoch}.${type.ext}',
      contentType: type.mime,
      fields: {
        if (replacePageId != null && replacePageId.isNotEmpty)
          'replacePageId': replacePageId,
      },
      onSendProgress: onSendProgress,
      fromJson: (json) => json,
    );
    return _wrap(response, _sessionFrom);
  }

  static Future<LibraryResult<LibraryUploadSession>> removePage({
    required String sid,
    required String pageId,
  }) => _delete(
    _withSid(
      ApiService.LIBRARY_SESSION_PAGE,
      sid,
    ).replaceFirst(':pageId', pageId),
    parse: _sessionFrom,
  );

  static Future<LibraryResult<LibraryUploadSession>> reorderPages({
    required String sid,
    required List<String> pageIds,
  }) => _put(
    _withSid(ApiService.LIBRARY_SESSION_ORDER, sid),
    body: {'pageIds': pageIds},
    parse: _sessionFrom,
  );

  /// `202` accepted · `200` already submitted.
  static Future<LibraryResult<LibraryUploadSession?>> submit(String sid) =>
      _post(
        _withSid(ApiService.LIBRARY_SESSION_SUBMIT, sid),
        parse: (data) => data.isEmpty ? null : _sessionFrom(data),
      );

  static Future<LibraryResult<void>> cancel(String sid) =>
      _delete(_withSid(ApiService.LIBRARY_SESSION, sid));

  // ---------------------------------------------------------------------------
  // Reading
  // ---------------------------------------------------------------------------

  static Future<LibraryResult<LibraryQuiz>> fetchQuiz(String lessonId) => _get(
    _withId(ApiService.LIBRARY_LESSON_QUIZ, lessonId),
    parse: LibraryQuiz.fromApi,
  );

  /// [answers] maps question index → selected option (or `null`).
  static Future<LibraryResult<LibraryQuizResult>> submitQuiz({
    required String lessonId,
    required Map<int, int?> answers,
  }) => _post(
    _withId(ApiService.LIBRARY_QUIZ_ATTEMPTS, lessonId),
    body: {
      'answers': answers.entries
          .map((e) => {'index': e.key, 'selectedIndex': e.value})
          .toList(),
    },
    parse: LibraryQuizResult.fromApi,
  );

  static Future<LibraryResult<List<LibraryQuizAttemptSummary>>> fetchAttempts(
    String lessonId,
  ) => _get(
    _withId(ApiService.LIBRARY_QUIZ_ATTEMPTS, lessonId),
    parse: (data) {
      final rows = data['attempts'];
      if (rows is! List) return const <LibraryQuizAttemptSummary>[];
      return rows
          .map(LibraryQuizAttemptSummary.fromApi)
          .whereType<LibraryQuizAttemptSummary>()
          .toList();
    },
  );
}
