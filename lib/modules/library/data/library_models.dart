/// Data shapes for the Student Library (`/api/v1/user/library`).
///
/// Parsing is deliberately forgiving: every field falls back to a safe default
/// so a missing or renamed key never crashes a screen.
library;

String _text(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _int(dynamic value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _intOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double _double(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

bool _bool(dynamic value) => value == true;

DateTime? _date(dynamic value) {
  final raw = value?.toString() ?? '';
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toLocal();
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map<String, dynamic> ? value : const <String, dynamic>{};

List<Map<String, dynamic>> _list(dynamic value) => value is List
    ? value.whereType<Map<String, dynamic>>().toList()
    : const <Map<String, dynamic>>[];

/// A publication or a subject — both arrive as `{ _id, name }`.
class LibraryRef {
  const LibraryRef({required this.id, required this.name});

  final String id;
  final String name;

  factory LibraryRef.fromApi(dynamic json) {
    if (json is String) return LibraryRef(id: json, name: '');
    final map = _map(json);
    return LibraryRef(id: _text(map['_id']), name: _text(map['name']));
  }

  static const empty = LibraryRef(id: '', name: '');

  @override
  bool operator ==(Object other) => other is LibraryRef && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class LibraryQuotaItem {
  const LibraryQuotaItem({
    required this.limit,
    required this.used,
    required this.remaining,
    this.resetsAt,
  });

  final int limit;
  final int used;
  final int remaining;
  final DateTime? resetsAt;

  factory LibraryQuotaItem.fromApi(dynamic json, {int defaultLimit = 0}) {
    final map = _map(json);
    final limit = _int(map['limit'], fallback: defaultLimit);
    final used = _int(map['used']);
    return LibraryQuotaItem(
      limit: limit,
      used: used,
      remaining: _int(
        map['remaining'],
        fallback: (limit - used).clamp(0, limit),
      ),
      resetsAt: _date(map['resetsAt']),
    );
  }
}

class LibraryRules {
  const LibraryRules({
    this.requestsPerDay = 5,
    this.uploadsPerDay = 3,
    this.maxPages = 30,
    this.maxPhotoBytes = 10485760,
    this.minPhotoLongEdge = 600,
    this.recommendedLongEdge = 1600,
    this.photoTypes = const ['image/jpeg', 'image/png', 'image/webp'],
    this.uploadWindowDays = 3,
    this.uploadSessionMinutes = 120,
    this.retakeHours = 24,
    this.titleMax = 120,
    this.noteMax = 300,
    this.chapterMax = 99,
  });

  final int requestsPerDay;
  final int uploadsPerDay;
  final int maxPages;
  final int maxPhotoBytes;
  final int minPhotoLongEdge;
  final int recommendedLongEdge;
  final List<String> photoTypes;
  final int uploadWindowDays;
  final int uploadSessionMinutes;
  final int retakeHours;
  final int titleMax;
  final int noteMax;
  final int chapterMax;

  factory LibraryRules.fromApi(dynamic json) {
    final map = _map(json);
    const d = LibraryRules();
    final types = map['photoTypes'];
    return LibraryRules(
      requestsPerDay: _int(map['requestsPerDay'], fallback: d.requestsPerDay),
      uploadsPerDay: _int(map['uploadsPerDay'], fallback: d.uploadsPerDay),
      maxPages: _int(map['maxPages'], fallback: d.maxPages),
      maxPhotoBytes: _int(map['maxPhotoBytes'], fallback: d.maxPhotoBytes),
      minPhotoLongEdge: _int(
        map['minPhotoLongEdge'],
        fallback: d.minPhotoLongEdge,
      ),
      recommendedLongEdge: _int(
        map['recommendedLongEdge'],
        fallback: d.recommendedLongEdge,
      ),
      photoTypes: types is List
          ? types.map((e) => e.toString()).toList()
          : d.photoTypes,
      uploadWindowDays: _int(
        map['uploadWindowDays'],
        fallback: d.uploadWindowDays,
      ),
      uploadSessionMinutes: _int(
        map['uploadSessionMinutes'],
        fallback: d.uploadSessionMinutes,
      ),
      retakeHours: _int(map['retakeHours'], fallback: d.retakeHours),
      titleMax: _int(map['titleMax'], fallback: d.titleMax),
      noteMax: _int(map['noteMax'], fallback: d.noteMax),
      chapterMax: _int(map['chapterMax'], fallback: d.chapterMax),
    );
  }
}

/// `GET /meta` — everything the Library needs before it can list lessons.
class LibraryMeta {
  const LibraryMeta({
    required this.classLevel,
    required this.subjects,
    required this.publications,
    required this.requests,
    required this.uploads,
    required this.rules,
    required this.uploadsAvailable,
  });

  /// `null` when the student has not picked a class yet.
  final String? classLevel;
  final List<LibraryRef> subjects;
  final List<LibraryRef> publications;
  final LibraryQuotaItem requests;
  final LibraryQuotaItem uploads;
  final LibraryRules rules;

  /// `false` when the AI is not set up on the server: hide "Upload pages".
  final bool uploadsAvailable;

  factory LibraryMeta.fromApi(Map<String, dynamic> json) {
    final rules = LibraryRules.fromApi(json['rules']);
    final quota = _map(json['quota']);
    final classLevel = _text(json['classLevel']);
    return LibraryMeta(
      classLevel: classLevel.isEmpty ? null : classLevel,
      subjects: _list(json['subjects']).map(LibraryRef.fromApi).toList(),
      publications: _list(
        json['publications'],
      ).map(LibraryRef.fromApi).toList(),
      requests: LibraryQuotaItem.fromApi(
        quota['requests'],
        defaultLimit: rules.requestsPerDay,
      ),
      uploads: LibraryQuotaItem.fromApi(
        quota['uploads'],
        defaultLimit: rules.uploadsPerDay,
      ),
      rules: rules,
      uploadsAvailable: json['uploadsAvailable'] != false,
    );
  }
}

/// Every `myState` the server can send. The server decides it — the app only
/// maps it to a button.
enum LibraryLessonState {
  requested,
  waitingForUpload,
  youCanUpload,
  yourUploadInProgress,
  beingUploaded,
  yourUploadInReview,
  inReview,
  available,
  unavailable,
  rejected,
  unknown;

  static LibraryLessonState parse(String raw) {
    switch (raw) {
      case 'requested':
        return requested;
      case 'waiting_for_upload':
        return waitingForUpload;
      case 'you_can_upload':
        return youCanUpload;
      case 'your_upload_in_progress':
        return yourUploadInProgress;
      case 'being_uploaded':
        return beingUploaded;
      case 'your_upload_in_review':
        return yourUploadInReview;
      case 'in_review':
        return inReview;
      case 'available':
        return available;
      case 'unavailable':
        return unavailable;
      case 'rejected':
        return rejected;
      default:
        return unknown;
    }
  }

  /// States where "Follow" makes sense: the lesson is not ready yet and the
  /// student is not the one who has to act on it.
  bool get offersFollow =>
      this == requested ||
      this == waitingForUpload ||
      this == beingUploaded ||
      this == inReview;
}

class LibraryProgress {
  const LibraryProgress({
    required this.stage,
    required this.pagesRead,
    required this.pagesTotal,
  });

  /// `reading` → `writing`.
  final String stage;
  final int pagesRead;
  final int pagesTotal;

  bool get isWriting => stage == 'writing';

  double get fraction {
    if (isWriting) return 1;
    if (pagesTotal <= 0) return 0;
    return (pagesRead / pagesTotal).clamp(0, 1).toDouble();
  }

  static LibraryProgress? fromApi(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    return LibraryProgress(
      stage: _text(json['stage'], fallback: 'reading'),
      pagesRead: _int(json['pagesRead']),
      pagesTotal: _int(json['pagesTotal']),
    );
  }
}

class LibraryHtmlBlock {
  const LibraryHtmlBlock({required this.title, required this.content});

  final String title;
  final String content;

  bool get isEmpty => content.trim().isEmpty;

  static LibraryHtmlBlock? fromApi(dynamic json, {String titleKey = 'title'}) {
    if (json is! Map<String, dynamic>) return null;
    return LibraryHtmlBlock(
      title: _text(json[titleKey]),
      content: _text(json['content']),
    );
  }
}

/// A lesson row (Browse / My lists) and, with the extra fields filled, the
/// lesson detail from `GET /lessons/:id`.
class LibraryLesson {
  const LibraryLesson({
    required this.id,
    required this.classLevel,
    required this.publication,
    required this.subject,
    required this.chapterNumber,
    required this.title,
    required this.status,
    required this.myState,
    required this.rawState,
    required this.message,
    required this.canRead,
    required this.canUpload,
    required this.isFollowing,
    required this.isRequester,
    required this.isUploader,
    required this.uploadOpensAt,
    required this.mySessionId,
    required this.followerCount,
    required this.pageCount,
    required this.qaCount,
    required this.hasOverview,
    required this.hasNotes,
    required this.quizQuestionCount,
    required this.requestedAt,
    required this.publishedAt,
    this.overview,
    this.notes,
    this.quizDescription = '',
    this.progress,
  });

  final String id;
  final String classLevel;
  final LibraryRef publication;
  final LibraryRef subject;
  final int chapterNumber;
  final String title;

  /// The lesson's own status (`published`, `uploading`, …) — informational.
  final String status;
  final LibraryLessonState myState;
  final String rawState;

  /// Ready-made, student-facing explanation of [myState].
  final String message;
  final bool canRead;
  final bool canUpload;
  final bool isFollowing;
  final bool isRequester;
  final bool isUploader;
  final DateTime? uploadOpensAt;
  final String? mySessionId;
  final int followerCount;
  final int pageCount;
  final int qaCount;
  final bool hasOverview;
  final bool hasNotes;
  final int quizQuestionCount;
  final DateTime? requestedAt;
  final DateTime? publishedAt;

  // Detail-only fields.
  final LibraryHtmlBlock? overview;
  final LibraryHtmlBlock? notes;
  final String quizDescription;
  final LibraryProgress? progress;

  /// "S. Chand · Maths · Ch 4"
  String get sourceLine {
    final parts = <String>[
      if (publication.name.isNotEmpty) publication.name,
      if (subject.name.isNotEmpty) subject.name,
      'Ch $chapterNumber',
    ];
    return parts.join(' · ');
  }

  factory LibraryLesson.fromApi(Map<String, dynamic> json) {
    final rawState = _text(json['myState']);
    final quiz = _map(json['quiz']);
    final sessionId = _text(json['mySessionId']);
    return LibraryLesson(
      id: _text(json['_id']),
      classLevel: _text(json['classLevel']),
      publication: json['publication'] == null
          ? LibraryRef.empty
          : LibraryRef.fromApi(json['publication']),
      subject: json['subject'] == null
          ? LibraryRef.empty
          : LibraryRef.fromApi(json['subject']),
      chapterNumber: _int(json['chapterNumber']),
      title: _text(json['title']),
      status: _text(json['status']),
      myState: LibraryLessonState.parse(rawState),
      rawState: rawState,
      message: _text(json['message']),
      canRead: _bool(json['canRead']),
      canUpload: _bool(json['canUpload']),
      isFollowing: _bool(json['isFollowing']),
      isRequester: _bool(json['isRequester']),
      isUploader: _bool(json['isUploader']),
      uploadOpensAt: _date(json['uploadOpensAt']),
      mySessionId: sessionId.isEmpty ? null : sessionId,
      followerCount: _int(json['followerCount']),
      pageCount: _int(json['pageCount']),
      qaCount: _int(json['qaCount']),
      hasOverview: _bool(json['hasOverview']),
      hasNotes: _bool(json['hasNotes']),
      quizQuestionCount: _int(
        json['quizQuestionCount'],
        fallback: _int(quiz['questionCount']),
      ),
      requestedAt: _date(json['requestedAt']),
      publishedAt: _date(json['publishedAt']),
      overview: LibraryHtmlBlock.fromApi(
        json['overview'],
        titleKey: 'description',
      ),
      notes: LibraryHtmlBlock.fromApi(json['notes']),
      quizDescription: _text(quiz['description']),
      progress: LibraryProgress.fromApi(json['progress']),
    );
  }

  /// Local, optimistic follow toggle until the next re-fetch.
  LibraryLesson withFollowing(bool following) {
    if (following == isFollowing) return this;
    final count = followerCount + (following ? 1 : -1);
    return LibraryLesson(
      id: id,
      classLevel: classLevel,
      publication: publication,
      subject: subject,
      chapterNumber: chapterNumber,
      title: title,
      status: status,
      myState: myState,
      rawState: rawState,
      message: message,
      canRead: canRead,
      canUpload: canUpload,
      isFollowing: following,
      isRequester: isRequester,
      isUploader: isUploader,
      uploadOpensAt: uploadOpensAt,
      mySessionId: mySessionId,
      followerCount: count < 0 ? 0 : count,
      pageCount: pageCount,
      qaCount: qaCount,
      hasOverview: hasOverview,
      hasNotes: hasNotes,
      quizQuestionCount: quizQuestionCount,
      requestedAt: requestedAt,
      publishedAt: publishedAt,
      overview: overview,
      notes: notes,
      quizDescription: quizDescription,
      progress: progress,
    );
  }
}

class LibraryPagination {
  const LibraryPagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  final int total;
  final int page;
  final int limit;
  final int totalPages;

  factory LibraryPagination.fromApi(dynamic json) {
    final map = _map(json);
    return LibraryPagination(
      total: _int(map['total']),
      page: _int(map['page'], fallback: 1),
      limit: _int(map['limit'], fallback: 20),
      totalPages: _int(map['totalPages'], fallback: 1),
    );
  }
}

class LibraryLessonPage {
  const LibraryLessonPage({required this.lessons, required this.pagination});

  final List<LibraryLesson> lessons;
  final LibraryPagination pagination;
}

/// One page photo inside an upload session.
class LibrarySessionPage {
  const LibrarySessionPage({
    required this.id,
    required this.position,
    required this.url,
    required this.width,
    required this.height,
    required this.state,
    required this.reason,
    required this.printedPageNumber,
  });

  final String id;
  final int position;
  final String url;
  final int width;
  final int height;

  /// `new`, `retake`, … — only `retake` needs the student's attention.
  final String state;
  final String? reason;
  final int? printedPageNumber;

  bool get needsRetake => state == 'retake';

  factory LibrarySessionPage.fromApi(Map<String, dynamic> json) {
    final reason = _text(json['reason']);
    return LibrarySessionPage(
      id: _text(json['_id']),
      position: _int(json['position']),
      url: _text(json['url']),
      width: _int(json['width']),
      height: _int(json['height']),
      state: _text(json['state'], fallback: 'new'),
      reason: reason.isEmpty ? null : reason,
      printedPageNumber: _intOrNull(json['printedPageNumber']),
    );
  }
}

enum LibrarySessionStatus {
  open,
  submitted,
  needsRetake,
  done,
  failed,
  expired,
  cancelled,
  rejected,
  unknown;

  static LibrarySessionStatus parse(String raw) {
    switch (raw) {
      case 'open':
        return open;
      case 'submitted':
        return submitted;
      case 'needs_retake':
        return needsRetake;
      case 'done':
        return done;
      case 'failed':
        return failed;
      case 'expired':
        return expired;
      case 'cancelled':
        return cancelled;
      case 'rejected':
        return rejected;
      default:
        return unknown;
    }
  }

  /// Pages can still be added / replaced / removed.
  bool get isEditable => this == open || this == needsRetake;

  /// The session is over for good.
  bool get isEnded =>
      this == done ||
      this == failed ||
      this == expired ||
      this == cancelled ||
      this == rejected;
}

class LibrarySessionLesson {
  const LibrarySessionLesson({
    required this.id,
    required this.title,
    required this.chapterNumber,
    required this.publication,
    required this.subject,
    required this.status,
  });

  final String id;
  final String title;
  final int chapterNumber;
  final LibraryRef publication;
  final LibraryRef subject;
  final String status;

  factory LibrarySessionLesson.fromApi(dynamic json) {
    if (json is String) {
      return LibrarySessionLesson(
        id: json,
        title: '',
        chapterNumber: 0,
        publication: LibraryRef.empty,
        subject: LibraryRef.empty,
        status: '',
      );
    }
    final map = _map(json);
    return LibrarySessionLesson(
      id: _text(map['_id']),
      title: _text(map['title']),
      chapterNumber: _int(map['chapterNumber']),
      publication: map['publication'] == null
          ? LibraryRef.empty
          : LibraryRef.fromApi(map['publication']),
      subject: map['subject'] == null
          ? LibraryRef.empty
          : LibraryRef.fromApi(map['subject']),
      status: _text(map['status']),
    );
  }
}

class LibraryUploadSession {
  const LibraryUploadSession({
    required this.id,
    required this.status,
    required this.rawStatus,
    required this.expiresAt,
    required this.lesson,
    required this.pages,
    required this.pageCount,
    required this.retakeCount,
    required this.canSubmit,
    required this.progress,
    required this.endReason,
  });

  final String id;
  final LibrarySessionStatus status;
  final String rawStatus;
  final DateTime? expiresAt;
  final LibrarySessionLesson lesson;
  final List<LibrarySessionPage> pages;
  final int pageCount;
  final int retakeCount;
  final bool canSubmit;
  final LibraryProgress? progress;
  final String? endReason;

  List<LibrarySessionPage> get retakePages =>
      pages.where((p) => p.needsRetake).toList();

  factory LibraryUploadSession.fromApi(Map<String, dynamic> json) {
    final rawStatus = _text(json['status']);
    final pages = _list(json['pages']).map(LibrarySessionPage.fromApi).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    final endReason = _text(json['endReason']);
    return LibraryUploadSession(
      id: _text(json['_id']),
      status: LibrarySessionStatus.parse(rawStatus),
      rawStatus: rawStatus,
      expiresAt: _date(json['expiresAt']),
      lesson: LibrarySessionLesson.fromApi(json['lesson']),
      pages: pages,
      pageCount: _int(json['pageCount'], fallback: pages.length),
      retakeCount: _int(json['retakeCount']),
      canSubmit: _bool(json['canSubmit']),
      progress: LibraryProgress.fromApi(json['progress']),
      endReason: endReason.isEmpty ? null : endReason,
    );
  }
}

class LibraryPublicationRequest {
  const LibraryPublicationRequest({
    required this.id,
    required this.name,
    required this.status,
    required this.reason,
    required this.publication,
    required this.isMine,
    required this.followerCount,
    required this.createdAt,
  });

  final String id;
  final String name;

  /// `pending` | `added` | `rejected`
  final String status;
  final String reason;
  final LibraryRef? publication;
  final bool isMine;
  final int followerCount;
  final DateTime? createdAt;

  factory LibraryPublicationRequest.fromApi(Map<String, dynamic> json) {
    final pub = json['publication'];
    return LibraryPublicationRequest(
      id: _text(json['_id']),
      name: _text(json['name']),
      status: _text(json['status'], fallback: 'pending'),
      reason: _text(json['reason']),
      publication: pub == null ? null : LibraryRef.fromApi(pub),
      isMine: _bool(json['isMine']),
      followerCount: _int(json['followerCount']),
      createdAt: _date(json['createdAt']),
    );
  }
}

class LibraryQuizQuestion {
  const LibraryQuizQuestion({
    required this.index,
    required this.questionText,
    required this.options,
    required this.marks,
    required this.difficulty,
  });

  final int index;
  final String questionText;
  final List<String> options;
  final int marks;
  final String difficulty;

  factory LibraryQuizQuestion.fromApi(Map<String, dynamic> json) {
    final options = json['options'];
    return LibraryQuizQuestion(
      index: _int(json['index']),
      questionText: _text(json['questionText']),
      options: options is List
          ? options.map((e) => e?.toString() ?? '').toList()
          : const [],
      marks: _int(json['marks'], fallback: 1),
      difficulty: _text(json['difficulty']),
    );
  }
}

class LibraryQuizAttemptSummary {
  const LibraryQuizAttemptSummary({
    required this.id,
    required this.score,
    required this.maxScore,
    required this.percentage,
    required this.correct,
    required this.total,
    required this.createdAt,
  });

  final String id;
  final double score;
  final double maxScore;
  final double percentage;
  final int correct;
  final int total;
  final DateTime? createdAt;

  static LibraryQuizAttemptSummary? fromApi(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    return LibraryQuizAttemptSummary(
      id: _text(json['_id']),
      score: _double(json['score']),
      maxScore: _double(json['maxScore']),
      percentage: _double(json['percentage']),
      correct: _int(json['correct']),
      total: _int(json['total']),
      createdAt: _date(json['createdAt'] ?? json['submittedAt']),
    );
  }
}

class LibraryQuiz {
  const LibraryQuiz({
    required this.lessonTitle,
    required this.description,
    required this.totalMarks,
    required this.questions,
    required this.lastAttempt,
  });

  final String lessonTitle;
  final String description;
  final double totalMarks;
  final List<LibraryQuizQuestion> questions;
  final LibraryQuizAttemptSummary? lastAttempt;

  factory LibraryQuiz.fromApi(Map<String, dynamic> json) {
    return LibraryQuiz(
      lessonTitle: _text(_map(json['lesson'])['title']),
      description: _text(json['description']),
      totalMarks: _double(json['totalMarks']),
      questions: _list(
        json['questions'],
      ).map(LibraryQuizQuestion.fromApi).toList(),
      lastAttempt: LibraryQuizAttemptSummary.fromApi(json['lastAttempt']),
    );
  }
}

class LibraryQuizResultItem {
  const LibraryQuizResultItem({
    required this.index,
    required this.selectedIndex,
    required this.correctIndex,
    required this.isCorrect,
  });

  final int index;
  final int? selectedIndex;
  final int? correctIndex;
  final bool isCorrect;

  factory LibraryQuizResultItem.fromApi(Map<String, dynamic> json) {
    return LibraryQuizResultItem(
      index: _int(json['index']),
      selectedIndex: _intOrNull(json['selectedIndex']),
      correctIndex: _intOrNull(json['correctIndex']),
      isCorrect: _bool(json['isCorrect']),
    );
  }
}

class LibraryQuizResult {
  const LibraryQuizResult({required this.attempt, required this.results});

  final LibraryQuizAttemptSummary attempt;
  final List<LibraryQuizResultItem> results;

  factory LibraryQuizResult.fromApi(Map<String, dynamic> json) {
    return LibraryQuizResult(
      attempt:
          LibraryQuizAttemptSummary.fromApi(json['attempt']) ??
          const LibraryQuizAttemptSummary(
            id: '',
            score: 0,
            maxScore: 0,
            percentage: 0,
            correct: 0,
            total: 0,
            createdAt: null,
          ),
      results: _list(
        json['results'],
      ).map(LibraryQuizResultItem.fromApi).toList(),
    );
  }
}
