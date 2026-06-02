import 'package:flutter/material.dart';

import '../../../../core/service/api_service.dart';
import '../../chapter/controller/learn_chapter_controller.dart';

class LearnEbookRepository {
  static const List<String> filters = [
    'All Subject',
    "Math's",
    'Science',
    'Chemistry',
    'History',
    'English',
  ];

  static const List<LearnEbookModel> books = [
    LearnEbookModel(
      id: 'algebraic_essentials',
      subject: 'Mathematics',
      title: 'Algebraic\nEssentials',
      filter: "Math's",
      accent: Color(0xFFA46A00),
      coverStyle: LearnEbookCoverStyle.math,
      detailLabel: 'MATHEMATICS • MODULE 4',
      detailTitle: 'Chapter 4: Algebraic Foundations',
      detailParagraphs: [
        'Algebra helps us describe patterns, relationships, and unknown values using symbols and equations. In this chapter, we explore how expressions behave and how equations can be solved step by step with confidence.',
        'Through worked examples and guided reasoning, you will see how variables, coefficients, and constants fit together to build the language of algebra.',
        'As your understanding grows, algebra becomes a practical tool for solving real-world problems involving money, motion, and change.',
      ],
      quickFactTitle: 'QUICK FACT',
      quickFact:
          'Algebraic thinking is the foundation of higher mathematics, coding logic, and many scientific models used in everyday life.',
      pageText: 'Page 84 of 210',
      progressText: '40% Completed',
      progress: 0.40,
    ),
    LearnEbookModel(
      id: 'matter_reactions',
      subject: 'Chemistry',
      title: 'Matter &\nReactions',
      filter: 'Chemistry',
      accent: Color(0xFF7D31E2),
      coverStyle: LearnEbookCoverStyle.chemistry,
      detailLabel: 'CHEMISTRY • MODULE 2',
      detailTitle: 'Chapter 2: Understanding Matter',
      detailParagraphs: [
        'Matter is everything that occupies space and has mass. In chemistry, we study how matter is structured, how it changes, and why those changes happen under specific conditions.',
        'This chapter introduces atoms, bonding, and chemical reactions through simple visual explanations and everyday examples.',
        'By connecting particle-level ideas with lab observations, chemistry becomes easier to picture and remember.',
      ],
      quickFactTitle: 'QUICK FACT',
      quickFact:
          'A chemical reaction rearranges atoms into new combinations, but the total amount of matter stays conserved.',
      pageText: 'Page 52 of 180',
      progressText: '20% Completed',
      progress: 0.20,
    ),
    LearnEbookModel(
      id: 'global_civilizations',
      subject: 'History',
      title: 'Global\nCivilizations',
      filter: 'History',
      accent: Color(0xFFA46A00),
      coverStyle: LearnEbookCoverStyle.history,
      detailLabel: 'HISTORY • MODULE 5',
      detailTitle: 'Chapter 5: Ancient Worlds',
      detailParagraphs: [
        'Civilizations grow around ideas, resources, geography, and culture. Their rise and transformation help us understand the foundations of society today.',
        'From trade routes to political systems, history reveals how communities solved problems and shaped collective identity.',
        'Reading history closely helps students connect past decisions to present-day institutions and global relationships.',
      ],
      quickFactTitle: 'QUICK FACT',
      quickFact:
          'Many modern legal, civic, and architectural traditions can be traced back to ancient civilizations.',
      pageText: 'Page 101 of 240',
      progressText: '58% Completed',
      progress: 0.58,
    ),
    LearnEbookModel(
      id: 'modern_literature',
      subject: 'English',
      title: 'Modern\nLiterature',
      filter: 'English',
      accent: Color(0xFF4A4FD9),
      coverStyle: LearnEbookCoverStyle.english,
      detailLabel: 'ENGLISH • MODULE 3',
      detailTitle: 'Chapter 3: Voice and Meaning',
      detailParagraphs: [
        'Literature gives readers a way to explore voice, emotion, and perspective across different times and cultures. Every text invites interpretation through language and style.',
        'In this section, you will read selected passages and learn how imagery, tone, and symbolism shape meaning.',
        'Close reading improves both comprehension and writing, especially when supported by discussion and annotation.',
      ],
      quickFactTitle: 'QUICK FACT',
      quickFact:
          'Authors often reveal hidden themes through repeated images, symbols, and word choices rather than direct statements.',
      pageText: 'Page 63 of 170',
      progressText: '34% Completed',
      progress: 0.34,
    ),
    LearnEbookModel(
      id: 'powerhouse_cell',
      subject: 'Biology',
      title: 'Powerhouse of\nthe Cell',
      filter: 'Science',
      accent: Color(0xFF7D31E2),
      coverStyle: LearnEbookCoverStyle.biology,
      detailLabel: 'BIOLOGY • MODULE 4',
      detailTitle: 'Chapter 4: The Powerhouse of\nthe Cell',
      detailParagraphs: [
        'Deep within the microscopic landscape of every eukaryotic cell resides a structure of immense significance: the mitochondrion. Often referred to as the "powerhouse of the cell," these double-membrane-bound organelles are responsible for the vital process of cellular respiration.',
        'Through a complex series of biochemical pathways, mitochondria convert the chemical energy found in nutrients into adenosine triphosphate (ATP), the primary energy currency used by cells to fuel their biological functions.',
        'The number of mitochondria in a cell can vary significantly depending on the cell type\'s energy demands. For example, muscle cells, which require constant energy for contraction, contain significantly more mitochondria than skin cells.',
      ],
      quickFactTitle: 'QUICK FACT',
      quickFact:
          'Did you know that mitochondria have their own unique DNA (mtDNA), separate from the DNA found in the cell’s nucleus? This suggests an evolutionary origin through endosymbiosis.',
      pageText: 'Page 124 of 210',
      progressText: '65% Completed',
      progress: 0.65,
    ),
  ];

  static Future<ApiResponse<List<LearnEbookModel>>> fetchStudentEbooks() async {
    final subjectsResponse = await LearnCatalogData.getUserSubjects();

    if (!subjectsResponse.success) {
      return ApiResponse<List<LearnEbookModel>>(
        success: false,
        message: subjectsResponse.message,
        statusCode: subjectsResponse.statusCode,
      );
    }

    final subjects = subjectsResponse.data ?? const <LearnSubjectModel>[];
    final ebooks = <LearnEbookModel>[];

    for (final subject in subjects) {
      final response = await fetchEbooksBySubject(subject: subject);
      if (!response.success) {
        return response;
      }
      ebooks.addAll(response.data ?? const <LearnEbookModel>[]);
    }

    return ApiResponse<List<LearnEbookModel>>(
      success: true,
      data: ebooks,
      message: 'Ebooks fetched successfully',
      statusCode: 200,
    );
  }

  static Future<ApiResponse<List<LearnEbookModel>>> fetchEbooksBySubject({
    required LearnSubjectModel subject,
  }) async {
    final response = await ApiService.instance.post<dynamic>(
      endpoint: ApiService.FETCH_EBOOKS_BY_CLASS_SUBJECT,
      showLoader: false,
      fromJson: (json) => json,
      data: {'classLevel': subject.classLevel, 'subjectId': subject.id},
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return ApiResponse<List<LearnEbookModel>>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    final body = response.data as Map<String, dynamic>;
    final ebooksJson =
        ((body['data'] as Map<String, dynamic>?)?['ebooks'])
            as List<dynamic>? ??
        const [];
    final ebooks = ebooksJson
        .whereType<Map<String, dynamic>>()
        .map((item) => LearnEbookModel.fromApi(item, fallbackSubject: subject))
        .toList();

    return ApiResponse<List<LearnEbookModel>>(
      success: true,
      data: ebooks,
      message: body['message']?.toString() ?? response.message,
      statusCode: response.statusCode,
    );
  }
}

enum LearnEbookCoverStyle { math, chemistry, history, english, biology }

class LearnEbookModel {
  final String id;
  final String subject;
  final String title;
  final String filter;
  final Color accent;
  final LearnEbookCoverStyle coverStyle;
  final String detailLabel;
  final String detailTitle;
  final List<String> detailParagraphs;
  final String quickFactTitle;
  final String quickFact;
  final String pageText;
  final String progressText;
  final double progress;
  final String videoUrl;
  final String pdfUrl;
  final List<LearnEbookMediaModel> media;
  final LearnEbookMediaModel? coverImage;
  final String teacherName;

  const LearnEbookModel({
    required this.id,
    required this.subject,
    required this.title,
    required this.filter,
    required this.accent,
    required this.coverStyle,
    required this.detailLabel,
    required this.detailTitle,
    required this.detailParagraphs,
    required this.quickFactTitle,
    required this.quickFact,
    required this.pageText,
    required this.progressText,
    required this.progress,
    this.videoUrl = '',
    this.pdfUrl = '',
    this.media = const [],
    this.coverImage,
    this.teacherName = '',
  });

  factory LearnEbookModel.fromApi(
    Map<String, dynamic> json, {
    required LearnSubjectModel fallbackSubject,
  }) {
    final subjectJson = (json['subject'] as Map<String, dynamic>?) ?? const {};
    final subjectName = _safeText(
      subjectJson['name'],
      fallback: fallbackSubject.title,
    );
    final title = _safeText(json['title'], fallback: 'Untitled E-book');
    final description = _stripHtml(_safeText(json['description']));
    final teacherName = _safeText(
      (json['teacher'] as Map<String, dynamic>?)?['name'],
    );
    final media = (json['media'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(LearnEbookMediaModel.fromApi)
        .toList();
    final coverJson = json['coverImage'];
    final paragraphs = _paragraphsFromText(
      description,
      fallback:
          'This e-book is available for $subjectName. Open the attached PDF, video, or teacher-uploaded files to continue studying.',
      minCount: 3,
    );

    return LearnEbookModel(
      id: _safeText(json['_id']),
      subject: subjectName,
      title: title,
      filter: subjectName,
      accent: fallbackSubject.accent,
      coverStyle: _coverStyleForSubject(subjectName),
      detailLabel:
          '${subjectName.toUpperCase()} • ${_safeText(json['classLevel'], fallback: fallbackSubject.classLevel)}',
      detailTitle: title,
      detailParagraphs: paragraphs,
      quickFactTitle: teacherName.isEmpty ? 'REFERENCE' : 'TEACHER',
      quickFact: teacherName.isEmpty
          ? 'Use the available links and attachments for this reference material.'
          : 'Prepared by $teacherName.',
      pageText: '${media.length} File${media.length == 1 ? '' : 's'}',
      progressText: 'Available Now',
      progress: 1,
      videoUrl: _safeText(json['videoUrl']),
      pdfUrl: _safeText(json['pdfUrl']),
      media: media,
      coverImage: coverJson is Map<String, dynamic>
          ? LearnEbookMediaModel.fromApi(coverJson)
          : null,
      teacherName: teacherName,
    );
  }
}

class LearnEbookMediaModel {
  final String key;
  final String url;
  final String mimeType;
  final int size;
  final String originalName;

  const LearnEbookMediaModel({
    required this.key,
    required this.url,
    required this.mimeType,
    required this.size,
    required this.originalName,
  });

  factory LearnEbookMediaModel.fromApi(Map<String, dynamic> json) {
    return LearnEbookMediaModel(
      key: _safeText(json['key']),
      url: _safeText(json['url']),
      mimeType: _safeText(json['mimeType']),
      size: (json['size'] as num?)?.toInt() ?? 0,
      originalName: _safeText(json['originalName'], fallback: 'Attachment'),
    );
  }
}

LearnEbookCoverStyle _coverStyleForSubject(String value) {
  final subject = value.toLowerCase();
  if (subject.contains('math')) {
    return LearnEbookCoverStyle.math;
  }
  if (subject.contains('chem')) {
    return LearnEbookCoverStyle.chemistry;
  }
  if (subject.contains('history') || subject.contains('social')) {
    return LearnEbookCoverStyle.history;
  }
  if (subject.contains('english')) {
    return LearnEbookCoverStyle.english;
  }
  return LearnEbookCoverStyle.biology;
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
