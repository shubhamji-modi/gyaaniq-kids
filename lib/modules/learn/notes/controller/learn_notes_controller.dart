import 'package:flutter/material.dart';

import '../../../../core/service/api_service.dart';
import '../../chapter/controller/learn_chapter_controller.dart';

class LearnNotesRepository {
  static const List<String> filters = ['All Notes', 'Mathematics', 'Physics'];

  static final List<LearnNoteModel> notes = [
    LearnNoteModel(
      id: 'algebra_basics',
      subject: 'Mathematics',
      title: 'Algebra Basics',
      description:
          'Comprehensive guide to linear equations, variables, and balancing.',
      tag: 'TEACHER PROVIDED',
      tagColor: const Color(0xFFFFD6A7),
      accent: const Color(0xFF4A4FD9),
      chapterOrAuthor: 'Chapter 1',
      secondaryLabel: '15 Pages',
      fileCountLabel: '12 Files',
      cardStyle: LearnNoteCardStyle.simple,
      type: LearnNoteType.teacher,
      readTime: '5 min read',
      gradeLabel: 'Math • Grade 8',
      statusLabel: 'Finalized Notes',
      detailTitle: 'Chapter 1: The Beauty\nof Variables',
      detailParagraphs: const [
        'Algebra is the language of patterns. Instead of working with specific numbers, we use letters called variables to represent values that can change.',
        'When we solve for x, we are finding the exact value that makes the statement true. This helps us model real-life problems clearly and quickly.',
      ],
      figureCaption: 'Figure 1.1: Anatomy of a Linear Expression',
      stepTitle: 'Step 1: Subtract 5 from both sides',
      sectionHeading: '1.1 Core Components',
      bulletPoints: const [
        'Coefficient: The number multiplying the variable (e.g., the 3 in 3x).',
        'Variable: The unknown value, usually represented by x, y, or z.',
        'Constant: A fixed number that does not change.',
      ],
      secondSectionHeading: '1.2 Real-World Application',
      calloutTitle: 'Word Problem Translation:',
      calloutEquation: '5w + 15 = 60',
    ),
    LearnNoteModel(
      id: 'formula_cheat_sheet',
      subject: 'Mathematics',
      title: 'Formulas Cheat\nSheet',
      description: 'Trigonometry and Geometry quick reference guide for exams.',
      tag: 'STUDENT NOTE',
      tagColor: const Color(0xFFEBD2FF),
      accent: const Color(0xFFBEBFCB),
      chapterOrAuthor: 'Reference',
      secondaryLabel: 'Alex J.',
      fileCountLabel: '12 Files',
      cardStyle: LearnNoteCardStyle.simple,
      type: LearnNoteType.student,
      readTime: '3 min read',
      gradeLabel: 'Math • Grade 8',
      statusLabel: 'Quick Revision',
      detailTitle: 'Formula Reference and\nMemory Tricks',
      detailParagraphs: const [
        'This quick sheet brings together the most-used geometry and trigonometry formulas for last-minute revision.',
        'Use short visual memory tricks and grouped identities to revise faster before practice sessions or exams.',
      ],
      figureCaption: 'Figure 2.1: Formula Grouping Strategy',
      stepTitle: 'Tip: Group similar formulas for faster recall',
      sectionHeading: '2.1 What to Memorize',
      bulletPoints: const [
        'Area and perimeter formulas for common shapes.',
        'Basic trigonometric ratios and angle values.',
        'Shortcut identities used in exam-style problems.',
      ],
      secondSectionHeading: '2.2 Revision Strategy',
      calloutTitle: 'Memory Pattern:',
      calloutEquation: 'sin²x + cos²x = 1',
    ),
    LearnNoteModel(
      id: 'laws_of_motion_1',
      subject: 'Physics',
      title: 'Laws of Motion',
      description:
          'In-depth analysis of Newton’s three laws with real-world application examples and solved numerical problems.',
      tag: 'TEACHER PROVIDED',
      tagColor: const Color(0xFFFFD6A7),
      accent: const Color(0xFF4A4FD9),
      chapterOrAuthor: 'View PDF',
      secondaryLabel: 'Download',
      fileCountLabel: '8 Files',
      cardStyle: LearnNoteCardStyle.featured,
      type: LearnNoteType.teacher,
      readTime: '8 min read',
      gradeLabel: 'Physics • Grade 8',
      statusLabel: 'Teacher Notes',
      detailTitle: 'Newton’s Laws in Action',
      detailParagraphs: const [
        'Motion explains how forces change the state of rest or movement of an object. Newton’s laws help us predict these changes.',
        'From buses starting suddenly to rockets launching upward, the laws of motion give us the tools to describe and calculate what happens.',
      ],
      figureCaption: 'Figure 3.1: Force Interaction Diagram',
      stepTitle: 'Key Idea: Force equals mass multiplied by acceleration',
      sectionHeading: '3.1 Core Laws',
      bulletPoints: const [
        'First law explains inertia and resistance to change in motion.',
        'Second law connects force, mass, and acceleration.',
        'Third law states every action has an equal and opposite reaction.',
      ],
      secondSectionHeading: '3.2 Real-World Examples',
      calloutTitle: 'Equation:',
      calloutEquation: 'F = ma',
    ),
    LearnNoteModel(
      id: 'optics_summary',
      subject: 'Physics',
      title: 'Optics Summary',
      description:
          'Personal shorthand notes on light reflection, refraction, and lenses.',
      tag: 'STUDENT NOTE',
      tagColor: const Color(0xFFEBD2FF),
      accent: const Color(0xFF7D31E2),
      chapterOrAuthor: 'AJ  SK',
      secondaryLabel: '2 MB',
      fileCountLabel: '8 Files',
      cardStyle: LearnNoteCardStyle.author,
      type: LearnNoteType.student,
      readTime: '4 min read',
      gradeLabel: 'Physics • Grade 8',
      statusLabel: 'Student Summary',
      detailTitle: 'Optics: Light and Lenses',
      detailParagraphs: const [
        'Optics studies how light behaves when it travels, reflects, or bends through different materials.',
        'Understanding ray diagrams and lens behavior makes it easier to solve questions about images and vision.',
      ],
      figureCaption: 'Figure 4.1: Lens and Ray Path',
      stepTitle: 'Tip: Track the path of at least two rays',
      sectionHeading: '4.1 Important Terms',
      bulletPoints: const [
        'Reflection is the bouncing back of light.',
        'Refraction is the bending of light between media.',
        'Convex and concave lenses form different kinds of images.',
      ],
      secondSectionHeading: '4.2 Question Approach',
      calloutTitle: 'Formula Reminder:',
      calloutEquation: '1/f = 1/v - 1/u',
    ),
    LearnNoteModel(
      id: 'laws_of_motion_2',
      subject: 'Physics',
      title: 'Laws of Motion',
      description:
          'In-depth analysis of Newton’s three laws with real-world application examples and solved numerical problems.',
      tag: 'TEACHER PROVIDED',
      tagColor: const Color(0xFFFFD6A7),
      accent: const Color(0xFF4A4FD9),
      chapterOrAuthor: 'View PDF',
      secondaryLabel: 'Download',
      fileCountLabel: '8 Files',
      cardStyle: LearnNoteCardStyle.featured,
      type: LearnNoteType.teacher,
      readTime: '8 min read',
      gradeLabel: 'Physics • Grade 8',
      statusLabel: 'Teacher Notes',
      detailTitle: 'Newton’s Laws in Action',
      detailParagraphs: const [
        'Motion explains how forces change the state of rest or movement of an object. Newton’s laws help us predict these changes.',
        'From buses starting suddenly to rockets launching upward, the laws of motion give us the tools to describe and calculate what happens.',
      ],
      figureCaption: 'Figure 3.1: Force Interaction Diagram',
      stepTitle: 'Key Idea: Force equals mass multiplied by acceleration',
      sectionHeading: '3.1 Core Laws',
      bulletPoints: const [
        'First law explains inertia and resistance to change in motion.',
        'Second law connects force, mass, and acceleration.',
        'Third law states every action has an equal and opposite reaction.',
      ],
      secondSectionHeading: '3.2 Real-World Examples',
      calloutTitle: 'Equation:',
      calloutEquation: 'F = ma',
    ),
  ];

  static Future<ApiResponse<List<LearnNoteModel>>> fetchStudentNotes() async {
    final subjectsResponse = await LearnCatalogData.getUserSubjects();
    debugPrint(
      'NOTES DEBUG subjects success=${subjectsResponse.success} '
      'count=${subjectsResponse.data?.length ?? 0} '
      'message=${subjectsResponse.message}',
    );

    if (!subjectsResponse.success) {
      return ApiResponse<List<LearnNoteModel>>(
        success: false,
        message: subjectsResponse.message,
        statusCode: subjectsResponse.statusCode,
      );
    }

    final subjects = subjectsResponse.data ?? const <LearnSubjectModel>[];
    final notes = <LearnNoteModel>[];

    for (final subject in subjects) {
      debugPrint(
        'NOTES DEBUG loading lessons subjectId=${subject.id} '
        'subject=${subject.title}',
      );
      final lessonsResponse = await LearnCatalogData.getUserLessons(
        subject: subject,
      );
      debugPrint(
        'NOTES DEBUG lessons subject=${subject.title} '
        'success=${lessonsResponse.success} '
        'count=${lessonsResponse.data?.length ?? 0} '
        'message=${lessonsResponse.message}',
      );
      if (!lessonsResponse.success) {
        return ApiResponse<List<LearnNoteModel>>(
          success: false,
          message: lessonsResponse.message,
          statusCode: lessonsResponse.statusCode,
        );
      }

      for (final chapter
          in lessonsResponse.data ?? const <LearnChapterModel>[]) {
        for (final topic in chapter.topics) {
          final response = await fetchNotesByLesson(
            lessonId: topic.lesson.id,
            fallbackSubject: subject,
            fallbackLessonTitle: topic.lesson.title,
          );
          debugPrint(
            'NOTES DEBUG parsed lessonId=${topic.lesson.id} '
            'lesson=${topic.lesson.title} '
            'count=${response.data?.length ?? 0}',
          );
          if (!response.success) {
            return response;
          }
          notes.addAll(response.data ?? const <LearnNoteModel>[]);
        }
      }
    }

    debugPrint('NOTES DEBUG total parsed notes=${notes.length}');
    return ApiResponse<List<LearnNoteModel>>(
      success: true,
      data: notes,
      message: 'Notes fetched successfully',
      statusCode: 200,
    );
  }

  static Future<ApiResponse<List<LearnNoteModel>>> fetchNotesByLesson({
    required String lessonId,
    required LearnSubjectModel fallbackSubject,
    required String fallbackLessonTitle,
  }) async {
    final response = await ApiService.instance.post<dynamic>(
      endpoint: ApiService.FETCH_NOTES_BY_LESSON,
      showLoader: false,
      fromJson: (json) => json,
      data: {'lessonId': lessonId},
    );
    debugPrint(
      'NOTES DEBUG API lessonId=$lessonId '
      'success=${response.success} '
      'status=${response.statusCode} '
      'message=${response.message} '
      'raw=${response.data}',
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return ApiResponse<List<LearnNoteModel>>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    final body = response.data as Map<String, dynamic>;
    final notesJson =
        ((body['data'] as Map<String, dynamic>?)?['notes']) as List<dynamic>? ??
        const [];
    debugPrint(
      'NOTES DEBUG raw notes lessonId=$lessonId count=${notesJson.length} '
      'data=$notesJson',
    );
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
    for (final note in notes) {
      debugPrint(
        'NOTES DEBUG note id=${note.id} title=${note.title} '
        'subject=${note.subject} lessonId=${note.lessonId} '
        'lesson=${note.lessonTitle} pdf=${note.pdfUrl} '
        'media=${note.media.length}',
      );
    }

    return ApiResponse<List<LearnNoteModel>>(
      success: true,
      data: notes,
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
  final String fileCountLabel;
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
    required this.fileCountLabel,
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
      fileCountLabel: '${media.length} File${media.length == 1 ? '' : 's'}',
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
