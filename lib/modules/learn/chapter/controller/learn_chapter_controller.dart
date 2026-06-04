import 'package:flutter/material.dart';

import '../../../../core/service/api_service.dart';

class LearnCatalogData {
  static Future<ApiResponse<List<LearnSubjectModel>>> getUserSubjects() async {
    final summaryResponse = await getSubjectProgressSummary();

    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.GET_USER_SUBJECT,
      showLoader: false,
      fromJson: (json) => json,
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return ApiResponse<List<LearnSubjectModel>>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    final body = response.data as Map<String, dynamic>;
    final subjectsJson =
        ((body['data'] as Map<String, dynamic>?)?['subjects'])
            as List<dynamic>? ??
        const [];
    final summaryById =
        summaryResponse.data ?? const <String, SubjectProgressSummary>{};

    final subjects = subjectsJson
        .asMap()
        .entries
        .map(
          (entry) => LearnSubjectModel.fromApi(
            entry.value as Map<String, dynamic>,
            index: entry.key,
            summary:
                summaryById[_safeText(
                  (entry.value as Map<String, dynamic>)['_id'],
                )],
          ),
        )
        .toList();

    return ApiResponse<List<LearnSubjectModel>>(
      success: true,
      data: subjects,
      message: body['message']?.toString() ?? response.message,
      statusCode: response.statusCode,
    );
  }

  static Future<ApiResponse<List<LearnChapterModel>>> getUserLessons({
    required LearnSubjectModel subject,
  }) async {
    final response = await ApiService.instance.post<dynamic>(
      endpoint: ApiService.GET_USER_LESSON,
      showLoader: false,
      fromJson: (json) => json,
      data: {'classLevel': subject.classLevel, 'subjectId': subject.id},
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return ApiResponse<List<LearnChapterModel>>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    final body = response.data as Map<String, dynamic>;
    final lessonsJson =
        ((body['data'] as Map<String, dynamic>?)?['lessons'])
            as List<dynamic>? ??
        const [];

    final lessons = lessonsJson.whereType<Map<String, dynamic>>().toList();
    final progressResponses = await Future.wait(
      lessons.map((lesson) {
        final lessonId = _safeText(lesson['_id']);
        return lessonId.isEmpty
            ? Future.value(
                ApiResponse<LearnLessonProgress>(
                  success: false,
                  message: 'Missing lesson id',
                  statusCode: 0,
                ),
              )
            : getLessonProgress(lessonId: lessonId);
      }),
    );
    final progressByLessonId = <String, LearnLessonProgress>{};
    for (final response in progressResponses) {
      final progress = response.data;
      if (response.success && progress != null) {
        progressByLessonId[progress.lessonId] = progress;
      }
    }

    final chapters = lessons.asMap().entries.map((entry) {
      final lesson = entry.value;
      return LearnChapterModel.fromApiLesson(
        lesson,
        subject: subject,
        fallbackNumber: entry.key + 1,
        progress: progressByLessonId[_safeText(lesson['_id'])],
      );
    }).toList()..sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));

    return ApiResponse<List<LearnChapterModel>>(
      success: true,
      data: chapters,
      message: body['message']?.toString() ?? response.message,
      statusCode: response.statusCode,
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> markLessonComplete({
    required String lessonId,
  }) async {
    final endpoint = ApiService.MARK_A_LESSON.replaceFirst(':id', lessonId);
    final response = await ApiService.instance.post<dynamic>(
      endpoint: endpoint,
      showLoader: false,
      fromJson: (json) => json,
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    final body = response.data as Map<String, dynamic>;
    return ApiResponse<Map<String, dynamic>>(
      success: true,
      data: (body['data'] as Map<String, dynamic>?) ?? const {},
      message: body['message']?.toString() ?? response.message,
      statusCode: response.statusCode,
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> markLessonStarted({
    required String lessonId,
  }) async {
    final endpoint = ApiService.MARK_START_LESSON.replaceFirst(':id', lessonId);
    final response = await ApiService.instance.post<dynamic>(
      endpoint: endpoint,
      showLoader: false,
      fromJson: (json) => json,
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    final body = response.data as Map<String, dynamic>;
    return ApiResponse<Map<String, dynamic>>(
      success: true,
      data: (body['data'] as Map<String, dynamic>?) ?? const {},
      message: body['message']?.toString() ?? response.message,
      statusCode: response.statusCode,
    );
  }

  static Future<ApiResponse<LearnLessonProgress>> getLessonProgress({
    required String lessonId,
  }) async {
    final endpoint = ApiService.GET_PROGRESS_ONE_LESSON.replaceFirst(
      ':id',
      lessonId,
    );
    final response = await ApiService.instance.get<dynamic>(
      endpoint: endpoint,
      showLoader: false,
      fromJson: (json) => json,
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return ApiResponse<LearnLessonProgress>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    final body = response.data as Map<String, dynamic>;
    return ApiResponse<LearnLessonProgress>(
      success: true,
      data: LearnLessonProgress.fromApi(
        (body['data'] as Map<String, dynamic>?) ?? const {},
        lessonId: lessonId,
      ),
      message: body['message']?.toString() ?? response.message,
      statusCode: response.statusCode,
    );
  }

  static Future<ApiResponse<Map<String, SubjectProgressSummary>>>
  getSubjectProgressSummary() async {
    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.DASHBOARD_PROGRESS_SUMMARY,
      showLoader: false,
      fromJson: (json) => json,
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return ApiResponse<Map<String, SubjectProgressSummary>>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    final body = response.data as Map<String, dynamic>;
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    final perSubjectJson = data['perSubject'] as List<dynamic>? ?? const [];

    final summaryById = <String, SubjectProgressSummary>{};
    for (final entry in perSubjectJson) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }
      final summary = SubjectProgressSummary.fromApi(entry);
      if (summary.subjectId.isEmpty) {
        continue;
      }
      summaryById[summary.subjectId] = summary;
    }

    return ApiResponse<Map<String, SubjectProgressSummary>>(
      success: true,
      data: summaryById,
      message: body['message']?.toString() ?? response.message,
      statusCode: response.statusCode,
    );
  }

  static LearnSubjectModel? subjectById(String id) => null;
}

class LearnSubjectModel {
  final String id;
  final String title;
  final String subtitle;
  final String? statusLabel;
  final IconData icon;
  final Color accent;
  final Color iconBackground;
  final List<LearnChapterModel> chapters;
  final String classLevel;
  final String description;
  final int completedLessons;
  final int totalLessons;

  LearnSubjectModel({
    required this.id,
    required this.title,
    required this.subtitle,
    this.statusLabel,
    required this.icon,
    required this.accent,
    required this.iconBackground,
    required this.chapters,
    required this.classLevel,
    required this.description,
    required this.completedLessons,
    required this.totalLessons,
  });

  factory LearnSubjectModel.fromApi(
    Map<String, dynamic> json, {
    required int index,
    SubjectProgressSummary? summary,
  }) {
    final palette = _subjectPalette(index);
    final description = _safeText(json['description']);

    return LearnSubjectModel(
      id: _safeText(json['_id']),
      title: _safeText(json['name'], fallback: 'Untitled Subject'),
      subtitle: description.isEmpty
          ? 'No description available for this subject yet.'
          : description,
      statusLabel: _statusLabelForIndex(index),
      icon: palette.icon,
      accent: palette.accent,
      iconBackground: palette.iconBackground,
      chapters: const [],
      classLevel: _safeText(json['classLevel'], fallback: '-'),
      description: description,
      completedLessons: summary?.lessonsCompleted ?? 0,
      totalLessons: summary?.lessonsTotal ?? 0,
    );
  }

  int get totalChapters => chapters.length;

  int get completedChapters => chapters
      .where((chapter) => chapter.status == LearnChapterStatus.completed)
      .length;

  double get progress =>
      totalLessons == 0 ? 0 : completedLessons / totalLessons;

  String get progressPercentage => '${(progress * 100).round()}%';

  String get progressText =>
      '$completedLessons/$totalLessons Lessons Completed';
}

class SubjectProgressSummary {
  final String subjectId;
  final String subjectName;
  final int lessonsTotal;
  final int lessonsCompleted;
  final int quizAttempts;
  final double avgPercentage;

  const SubjectProgressSummary({
    required this.subjectId,
    required this.subjectName,
    required this.lessonsTotal,
    required this.lessonsCompleted,
    required this.quizAttempts,
    required this.avgPercentage,
  });

  factory SubjectProgressSummary.fromApi(Map<String, dynamic> json) {
    final subject = (json['subject'] as Map<String, dynamic>?) ?? const {};
    return SubjectProgressSummary(
      subjectId: _safeText(subject['_id']),
      subjectName: _safeText(subject['name']),
      lessonsTotal: (json['lessonsTotal'] as num?)?.toInt() ?? 0,
      lessonsCompleted: (json['lessonsCompleted'] as num?)?.toInt() ?? 0,
      quizAttempts: (json['quizAttempts'] as num?)?.toInt() ?? 0,
      avgPercentage: (json['avgPercentage'] as num?)?.toDouble() ?? 0,
    );
  }
}

enum LearnChapterStatus { completed, inProgress, locked }

class LearnChapterModel {
  final String id;
  final int chapterNumber;
  final String title;
  final LearnChapterStatus status;
  final int completedLessons;
  final int totalLessons;
  final double progressValue;
  final int quizCount;
  final Color accent;
  final String summary;
  final List<LearnTopicModel> topics;

  const LearnChapterModel({
    required this.id,
    required this.chapterNumber,
    required this.title,
    required this.status,
    required this.completedLessons,
    required this.totalLessons,
    required this.progressValue,
    required this.quizCount,
    required this.accent,
    required this.summary,
    required this.topics,
  });

  factory LearnChapterModel.fromApiLesson(
    Map<String, dynamic> json, {
    required LearnSubjectModel subject,
    required int fallbackNumber,
    LearnLessonProgress? progress,
  }) {
    final order = (json['order'] as num?)?.toInt() ?? fallbackNumber;
    final lesson = LearnLessonModel.fromApi(
      json,
      subject: subject,
      order: order,
      progress: progress?.progressValue ?? 0,
    );
    final topicStatus = progress?.status ?? LearnTopicStatus.notStarted;
    final isCompleted = topicStatus == LearnTopicStatus.completed;
    final chapterStatus = topicStatus == LearnTopicStatus.locked
        ? LearnChapterStatus.locked
        : isCompleted
        ? LearnChapterStatus.completed
        : LearnChapterStatus.inProgress;

    return LearnChapterModel(
      id: _safeText(json['_id']),
      chapterNumber: order,
      title: _safeText(json['title'], fallback: 'Untitled Lesson'),
      status: chapterStatus,
      completedLessons: isCompleted ? 1 : 0,
      totalLessons: 1,
      progressValue: progress?.progressValue ?? 0,
      quizCount: 0,
      accent: subject.accent,
      summary: lesson.description,
      topics: [
        LearnTopicModel(
          id: lesson.id,
          title: lesson.title,
          status: topicStatus,
          progress: progress?.progressValue ?? 0,
          hasVideo: lesson.videoUrl.isNotEmpty,
          hasNotes: lesson.notes.isNotEmpty,
          hasWorksheet: lesson.pdfUrl.isNotEmpty,
          lesson: lesson,
        ),
      ],
    );
  }

  double get progress => progressValue.clamp(0, 1).toDouble();

  String get progressPercentage => '${(progress * 100).round()}%';

  String get lessonQuizMeta =>
      '$completedLessons/$totalLessons Lessons Completed';
}

enum LearnTopicStatus { notStarted, completed, inProgress, locked }

class LearnTopicModel {
  final String id;
  final String title;
  final LearnTopicStatus status;
  final double progress;
  final bool hasVideo;
  final bool hasNotes;
  final bool hasWorksheet;
  final LearnLessonModel lesson;

  const LearnTopicModel({
    required this.id,
    required this.title,
    required this.status,
    required this.progress,
    required this.hasVideo,
    required this.hasNotes,
    required this.hasWorksheet,
    required this.lesson,
  });
}

class LearnLessonProgress {
  final String lessonId;
  final LearnTopicStatus status;
  final String startedAt;
  final String completedAt;
  final String lastAccessedAt;

  const LearnLessonProgress({
    required this.lessonId,
    required this.status,
    required this.startedAt,
    required this.completedAt,
    required this.lastAccessedAt,
  });

  factory LearnLessonProgress.fromApi(
    Map<String, dynamic> json, {
    required String lessonId,
  }) {
    final lessonValue = json['lesson'];
    final progressLessonId = lessonValue is Map<String, dynamic>
        ? _safeText(lessonValue['_id'], fallback: lessonId)
        : _safeText(lessonValue, fallback: lessonId);

    return LearnLessonProgress(
      lessonId: progressLessonId,
      status: _topicStatusFromApi(_safeText(json['status'])),
      startedAt: _safeText(json['startedAt']),
      completedAt: _safeText(json['completedAt']),
      lastAccessedAt: _safeText(json['lastAccessedAt']),
    );
  }

  double get progressValue {
    switch (status) {
      case LearnTopicStatus.completed:
        return 1;
      case LearnTopicStatus.inProgress:
        return 0.5;
      case LearnTopicStatus.notStarted:
      case LearnTopicStatus.locked:
        return 0;
    }
  }
}

LearnTopicStatus _topicStatusFromApi(String value) {
  switch (value.trim().toLowerCase()) {
    case 'completed':
      return LearnTopicStatus.completed;
    case 'in_progress':
    case 'in progress':
      return LearnTopicStatus.inProgress;
    case 'locked':
      return LearnTopicStatus.locked;
    case 'not_started':
    case 'not started':
    default:
      return LearnTopicStatus.notStarted;
  }
}

class LearnLessonModel {
  final String id;
  final String title;
  final String chapterLabel;
  final String subjectLabel;
  final String description;
  final double progress;
  final String currentTime;
  final String totalTime;
  final String notes;
  final String videoUrl;
  final String pdfUrl;
  final String content;
  final List<LearnResourceModel> resources;

  const LearnLessonModel({
    required this.id,
    required this.title,
    required this.chapterLabel,
    required this.subjectLabel,
    required this.description,
    required this.progress,
    required this.currentTime,
    required this.totalTime,
    required this.notes,
    required this.videoUrl,
    required this.pdfUrl,
    required this.content,
    required this.resources,
  });

  factory LearnLessonModel.fromApi(
    Map<String, dynamic> json, {
    required LearnSubjectModel subject,
    required int order,
    double progress = 0,
  }) {
    final title = _safeText(json['title'], fallback: 'Untitled Lesson');
    final description = _safeText(json['description']);
    final content = _safeText(json['content']);
    final videoUrl = _safeText(json['videoUrl']);
    final pdfUrl = _safeText(json['pdfUrl']);
    debugPrint('LESSON API videoUrl [$title]: $videoUrl');
    final teacherName = _safeText(
      (json['teacher'] as Map<String, dynamic>?)?['name'],
    );
    final plainContent = _stripHtml(content);
    final notes = plainContent.isNotEmpty
        ? plainContent
        : (description.isNotEmpty
              ? description
              : 'Lesson notes will be available soon.');

    final resources = <LearnResourceModel>[
      if (pdfUrl.isNotEmpty)
        LearnResourceModel(
          title: 'Lesson PDF',
          meta: 'Study material',
          url: pdfUrl,
          icon: Icons.picture_as_pdf_outlined,
          accent: Color(0xFFD6332B),
          iconBackground: Color(0xFFFFD8D2),
        ),
    ];

    return LearnLessonModel(
      id: _safeText(json['_id']),
      title: title,
      chapterLabel: 'LESSON $order',
      subjectLabel: subject.title.toUpperCase(),
      description: description.isNotEmpty
          ? description
          : (plainContent.isNotEmpty
                ? plainContent
                : 'Lesson description will be available soon.'),
      progress: progress,
      currentTime: '00:00',
      totalTime: '00:00',
      notes: teacherName.isEmpty ? notes : '$notes\n\nTeacher: $teacherName',
      videoUrl: videoUrl,
      pdfUrl: pdfUrl,
      content: content,
      resources: resources,
    );
  }
}

class LearnResourceModel {
  final String title;
  final String meta;
  final String url;
  final IconData icon;
  final Color accent;
  final Color iconBackground;

  const LearnResourceModel({
    required this.title,
    required this.meta,
    required this.url,
    required this.icon,
    required this.accent,
    required this.iconBackground,
  });
}

class _SubjectPalette {
  final IconData icon;
  final Color accent;
  final Color iconBackground;

  const _SubjectPalette({
    required this.icon,
    required this.accent,
    required this.iconBackground,
  });
}

_SubjectPalette _subjectPalette(int index) {
  const palettes = [
    _SubjectPalette(
      icon: Icons.calculate_outlined,
      accent: Color(0xFF4A4FD9),
      iconBackground: Color(0xFFDCD9FF),
    ),
    _SubjectPalette(
      icon: Icons.science_outlined,
      accent: Color(0xFFFFA31A),
      iconBackground: Color(0xFFFFD8A8),
    ),
    _SubjectPalette(
      icon: Icons.menu_book_rounded,
      accent: Color(0xFF7D31E2),
      iconBackground: Color(0xFFE9D2FF),
    ),
    _SubjectPalette(
      icon: Icons.public_rounded,
      accent: Color(0xFF575867),
      iconBackground: Color(0xFFE0E3E7),
    ),
  ];

  return palettes[index % palettes.length];
}

String? _statusLabelForIndex(int index) {
  if (index == 0) {
    return 'Active';
  }
  if (index == 1) {
    return 'New Content';
  }
  return null;
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
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
