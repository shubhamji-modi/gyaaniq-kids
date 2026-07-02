import 'package:flutter/material.dart';

import '../../../../core/service/api_service.dart';
import '../../chapter/controller/learn_chapter_controller.dart';
import '../../common/learn_media.dart';

/// One page of lesson notes plus the server pagination metadata.
class LearnNotesPage {
  const LearnNotesPage({
    required this.notes,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<LearnNoteModel> notes;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;
}

class LearnNotesRepository {
  /// Fetch a single page of notes for a SINGLE lesson.
  ///
  /// This is the only notes endpoint the UI should call, and it is triggered
  /// lazily when the user opens a specific lesson — never in bulk for every
  /// lesson of every subject. That keeps `FETCH_NOTES_BY_LESSON` to one call
  /// per opened page instead of dozens on screen load.
  static Future<ApiResponse<LearnNotesPage>> fetchNotesByLesson({
    required String lessonId,
    required LearnSubjectModel fallbackSubject,
    required String fallbackLessonTitle,
    int page = 1,
    int limit = 10,
  }) async {
    final response = await ApiService.instance.post<dynamic>(
      endpoint: ApiService.FETCH_NOTES_BY_LESSON,
      showLoader: false,
      fromJson: (json) => json,
      data: {'lessonId': lessonId, 'page': page, 'limit': limit},
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return ApiResponse<LearnNotesPage>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    final body = response.data as Map<String, dynamic>;
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    final notesJson = (data['notes']) as List<dynamic>? ?? const [];
    final pagination = (data['pagination'] as Map<String, dynamic>?) ?? const {};

    final notes = notesJson
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => LearnNoteModel.fromApi(
            item,
            fallbackSubject: fallbackSubject,
            fallbackLessonTitle: fallbackLessonTitle,
          ),
        )
        .toList();

    final resolvedPage = (pagination['page'] as num?)?.toInt() ?? page;
    final resolvedLimit = (pagination['limit'] as num?)?.toInt() ?? limit;
    final total = (pagination['total'] as num?)?.toInt() ?? notes.length;
    final totalPages =
        (pagination['totalPages'] as num?)?.toInt() ??
        (notes.isEmpty ? resolvedPage : resolvedPage + (notes.length < resolvedLimit ? 0 : 1));

    return ApiResponse<LearnNotesPage>(
      success: true,
      data: LearnNotesPage(
        notes: notes,
        page: resolvedPage,
        limit: resolvedLimit,
        total: total,
        totalPages: totalPages,
      ),
      message: body['message']?.toString() ?? response.message,
      statusCode: response.statusCode,
    );
  }
}

enum LearnNoteCardStyle { simple, featured, author }

enum LearnNoteType { teacher, student }

class LearnNoteModel {
  final String id;
  final String subject;
  final String title;
  final String description;
  final String tag;
  final Color tagColor;
  final Color accent;
  final String chapterOrAuthor;
  final String secondaryLabel;
  final LearnNoteCardStyle cardStyle;
  final LearnNoteType type;
  final String readTime;
  final String gradeLabel;
  final String statusLabel;
  final String detailTitle;
  final List<String> detailParagraphs;
  final String figureCaption;
  final String stepTitle;
  final String sectionHeading;
  final List<String> bulletPoints;
  final String secondSectionHeading;
  final String calloutTitle;
  final String calloutEquation;
  final String content;
  final String videoUrl;
  final String pdfUrl;
  final List<LearnNoteMediaModel> media;
  final String teacherName;
  final String lessonId;
  final String lessonTitle;

  const LearnNoteModel({
    required this.id,
    required this.subject,
    required this.title,
    required this.description,
    required this.tag,
    required this.tagColor,
    required this.accent,
    required this.chapterOrAuthor,
    required this.secondaryLabel,
    required this.cardStyle,
    required this.type,
    required this.readTime,
    required this.gradeLabel,
    required this.statusLabel,
    required this.detailTitle,
    required this.detailParagraphs,
    required this.figureCaption,
    required this.stepTitle,
    required this.sectionHeading,
    required this.bulletPoints,
    required this.secondSectionHeading,
    required this.calloutTitle,
    required this.calloutEquation,
    this.content = '',
    this.videoUrl = '',
    this.pdfUrl = '',
    this.media = const [],
    this.teacherName = '',
    this.lessonId = '',
    this.lessonTitle = '',
  });

  factory LearnNoteModel.fromApi(
    Map<String, dynamic> json, {
    required LearnSubjectModel fallbackSubject,
    required String fallbackLessonTitle,
  }) {
    final subjectJson = (json['subject'] as Map<String, dynamic>?) ?? const {};
    final lessonJson = (json['lesson'] as Map<String, dynamic>?) ?? const {};
    final subjectName = _safeText(
      subjectJson['name'],
      fallback: fallbackSubject.title,
    );
    final lessonTitle = _safeText(
      lessonJson['title'],
      fallback: fallbackLessonTitle,
    );
    final title = _safeText(json['title'], fallback: 'Untitled Note');
    final content = _safeText(json['content']);
    final plainContent = _stripHtml(content);
    final description = _safeText(
      json['description'],
      fallback: plainContent.isEmpty
          ? 'Teacher note for $lessonTitle.'
          : plainContent,
    );
    final teacherName = _safeText(
      (json['teacher'] as Map<String, dynamic>?)?['name'],
    );
    final media = (json['media'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(LearnNoteMediaModel.fromApi)
        .toList();
    final paragraphs = _paragraphsFromText(
      plainContent,
      fallback: description,
      minCount: 2,
    );

    return LearnNoteModel(
      id: _safeText(json['_id']),
      subject: subjectName,
      title: title,
      description: description,
      tag: 'TEACHER PROVIDED',
      tagColor: const Color(0xFFFFD6A7),
      accent: fallbackSubject.accent,
      chapterOrAuthor: lessonTitle,
      secondaryLabel: teacherName.isEmpty ? 'Teacher' : teacherName,
      cardStyle: LearnNoteCardStyle.simple,
      type: LearnNoteType.teacher,
      readTime: _readTimeLabel(plainContent),
      gradeLabel:
          '$subjectName • ${_safeText(json['classLevel'], fallback: fallbackSubject.classLevel)}',
      statusLabel: 'Teacher Notes',
      detailTitle: title,
      detailParagraphs: paragraphs,
      figureCaption: lessonTitle,
      stepTitle: 'Review the teacher note and attachments.',
      sectionHeading: 'Key Points',
      bulletPoints: _bulletPointsFromText(plainContent),
      secondSectionHeading: 'Reference Material',
      calloutTitle: teacherName.isEmpty ? 'Shared Note' : 'Shared by',
      calloutEquation: teacherName.isEmpty ? subjectName : teacherName,
      content: content,
      videoUrl: _safeText(json['videoUrl']),
      pdfUrl: _safeText(json['pdfUrl']),
      media: media,
      teacherName: teacherName,
      lessonId: _safeText(lessonJson['_id']),
      lessonTitle: lessonTitle,
    );
  }

  /// All openable resources (PDFs, videos, images) for this note, combining
  /// `media[]` with the single `pdfUrl` / `videoUrl` fields, de-duplicated.
  List<LearnResource> get resources {
    final list = <LearnResource>[];
    final seen = <String>{};

    void add(String url, String name, LearnMediaKind kind, int size) {
      final trimmed = url.trim();
      if (trimmed.isEmpty || !seen.add(trimmed)) return;
      list.add(
        LearnResource(
          title: name.trim().isEmpty ? fileNameFromUrl(trimmed) : name,
          url: trimmed,
          kind: kind,
          size: size,
        ),
      );
    }

    for (final item in media) {
      add(
        item.url,
        item.originalName,
        classifyMedia(item.mimeType, item.url),
        item.size,
      );
    }
    if (videoUrl.trim().isNotEmpty) {
      add(videoUrl, 'Lesson video', LearnMediaKind.video, 0);
    }
    if (pdfUrl.trim().isNotEmpty) {
      add(pdfUrl, 'Document', LearnMediaKind.pdf, 0);
    }
    return list;
  }

  List<LearnResource> get imageResources =>
      resources.where((r) => r.kind == LearnMediaKind.image).toList();

  List<LearnResource> get videoResources =>
      resources.where((r) => r.kind == LearnMediaKind.video).toList();

  List<LearnResource> get documentResources => resources
      .where(
        (r) => r.kind == LearnMediaKind.pdf || r.kind == LearnMediaKind.other,
      )
      .toList();

  /// Total attachments (used for the dynamic "N Files" label).
  int get resourceCount => resources.length;

  /// Whether the note carries any real HTML body worth rendering.
  bool get hasHtmlContent => _stripHtml(content).trim().isNotEmpty;
}

class LearnNoteMediaModel {
  final String key;
  final String url;
  final String mimeType;
  final int size;
  final String originalName;

  const LearnNoteMediaModel({
    required this.key,
    required this.url,
    required this.mimeType,
    required this.size,
    required this.originalName,
  });

  factory LearnNoteMediaModel.fromApi(Map<String, dynamic> json) {
    return LearnNoteMediaModel(
      key: _safeText(json['key']),
      url: _safeText(json['url']),
      mimeType: _safeText(json['mimeType']),
      size: (json['size'] as num?)?.toInt() ?? 0,
      originalName: _safeText(json['originalName'], fallback: 'Attachment'),
    );
  }
}

List<String> _paragraphsFromText(
  String value, {
  required String fallback,
  required int minCount,
}) {
  final parts = value
      .split(RegExp(r'[\n.]+'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .map((part) => part.endsWith('.') ? part : '$part.')
      .toList();

  if (parts.isEmpty) {
    parts.add(fallback);
  }
  while (parts.length < minCount) {
    parts.add(parts.last);
  }
  return parts.take(minCount).toList();
}

List<String> _bulletPointsFromText(String value) {
  final points = _paragraphsFromText(
    value,
    fallback: 'Read the note carefully and revise the attached resources.',
    minCount: 3,
  );
  return points.take(3).toList();
}

String _readTimeLabel(String value) {
  final wordCount = value
      .split(RegExp(r'\s+'))
      .where((word) => word.trim().isNotEmpty)
      .length;
  final minutes = (wordCount / 180).ceil().clamp(1, 99);
  return '$minutes min read';
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
