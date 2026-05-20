import 'package:flutter/material.dart';

class LearnCatalogData {
  static final List<LearnSubjectModel> subjects = [
    LearnSubjectModel(
      id: 'mathematics',
      title: 'Mathematics',
      subtitle: 'Geometry, Algebra, and Statistics',
      statusLabel: 'Active',
      icon: Icons.calculate_outlined,
      accent: const Color(0xFF4A4FD9),
      iconBackground: const Color(0xFFDCD9FF),
      chapters: [
        LearnChapterModel(
          id: 'math_ch_1',
          chapterNumber: 1,
          title: 'Real Numbers & Logic',
          status: LearnChapterStatus.completed,
          completedLessons: 12,
          totalLessons: 12,
          quizCount: 4,
          accent: const Color(0xFFA46A00),
          summary:
              'Build number sense with reasoning, divisibility, and foundational logic.',
          topics: [
            LearnTopicModel(
              id: 'topic_1_1',
              title: 'Natural and Whole Numbers',
              status: LearnTopicStatus.completed,
              progress: 1,
              hasVideo: true,
              hasNotes: true,
              hasWorksheet: false,
              lesson: _defaultLesson(
                title: 'Natural and Whole Numbers',
                chapterLabel: 'CHAPTER 1',
              ),
            ),
            LearnTopicModel(
              id: 'topic_1_2',
              title: 'Divisibility Rules',
              status: LearnTopicStatus.completed,
              progress: 1,
              hasVideo: true,
              hasNotes: true,
              hasWorksheet: true,
              lesson: _defaultLesson(
                title: 'Divisibility Rules',
                chapterLabel: 'CHAPTER 1',
              ),
            ),
          ],
        ),
        LearnChapterModel(
          id: 'math_ch_2',
          chapterNumber: 2,
          title: 'Polynomials',
          status: LearnChapterStatus.completed,
          completedLessons: 8,
          totalLessons: 8,
          quizCount: 2,
          accent: const Color(0xFFA46A00),
          summary:
              'Understand variables, terms, and expressions through visual examples.',
          topics: [
            LearnTopicModel(
              id: 'topic_2_1',
              title: 'Understanding Terms',
              status: LearnTopicStatus.completed,
              progress: 1,
              hasVideo: true,
              hasNotes: true,
              hasWorksheet: true,
              lesson: _defaultLesson(
                title: 'Understanding Terms',
                chapterLabel: 'CHAPTER 2',
              ),
            ),
          ],
        ),
        LearnChapterModel(
          id: 'math_ch_3',
          chapterNumber: 3,
          title: 'Linear Equations',
          status: LearnChapterStatus.inProgress,
          completedLessons: 10,
          totalLessons: 15,
          quizCount: 5,
          accent: const Color(0xFF4A4FD9),
          summary:
              'Master the language of numbers through interactive visualization and AI-powered practice sessions.',
          topics: [
            LearnTopicModel(
              id: 'topic_3_1',
              title: 'Introduction to Quadratics',
              status: LearnTopicStatus.completed,
              progress: 1,
              hasVideo: false,
              hasNotes: true,
              hasWorksheet: true,
              lesson: _defaultLesson(
                title: 'Introduction to Quadratics',
                chapterLabel: 'CHAPTER 3',
              ),
            ),
            LearnTopicModel(
              id: 'topic_3_2',
              title: 'Solving by Factoring',
              status: LearnTopicStatus.inProgress,
              progress: 0.4,
              hasVideo: true,
              hasNotes: true,
              hasWorksheet: true,
              lesson: LearnLessonModel(
                title: 'Mastering the Quadratic Split',
                chapterLabel: 'CHAPTER 4',
                subjectLabel: 'MATHEMATICS',
                description:
                    'In this session, we break down the complex process of finding roots for quadratic equations by splitting the middle term. Learn the "Magic Pair" method to identify factors quickly and accurately.',
                progress: 0.71,
                currentTime: '08:42',
                totalTime: '12:15',
                notes:
                    'Notes tab can include quick formulas, examples, and teacher highlights for revision.',
                resources: const [
                  LearnResourceModel(
                    title: 'Factoring Cheat Sheet',
                    meta: 'PDF • 1.2 MB',
                    icon: Icons.picture_as_pdf_outlined,
                    accent: Color(0xFFD6332B),
                    iconBackground: Color(0xFFFFD8D2),
                  ),
                  LearnResourceModel(
                    title: 'Example Problems',
                    meta: 'PDF • 850 KB',
                    icon: Icons.task_alt_outlined,
                    accent: Color(0xFF4A4FD9),
                    iconBackground: Color(0xFFDAD8FF),
                  ),
                ],
              ),
            ),
            LearnTopicModel(
              id: 'topic_3_3',
              title: 'The Quadratic Formula',
              status: LearnTopicStatus.locked,
              progress: 0,
              hasVideo: true,
              hasNotes: true,
              hasWorksheet: false,
              lesson: _defaultLesson(
                title: 'The Quadratic Formula',
                chapterLabel: 'CHAPTER 3',
              ),
            ),
            LearnTopicModel(
              id: 'topic_3_4',
              title: 'Nature of Roots',
              status: LearnTopicStatus.locked,
              progress: 0,
              hasVideo: false,
              hasNotes: true,
              hasWorksheet: false,
              lesson: _defaultLesson(
                title: 'Nature of Roots',
                chapterLabel: 'CHAPTER 3',
              ),
            ),
          ],
        ),
        LearnChapterModel(
          id: 'math_ch_4',
          chapterNumber: 4,
          title: 'Coordinate Geometry',
          status: LearnChapterStatus.locked,
          completedLessons: 0,
          totalLessons: 11,
          quizCount: 3,
          accent: const Color(0xFFCACED8),
          summary: 'Starts after Chapter 3',
          topics: const [],
        ),
        LearnChapterModel(
          id: 'math_ch_5',
          chapterNumber: 5,
          title: 'Arithmetic Progressions',
          status: LearnChapterStatus.locked,
          completedLessons: 0,
          totalLessons: 13,
          quizCount: 4,
          accent: const Color(0xFFCACED8),
          summary: 'Starts after Chapter 4',
          topics: const [],
        ),
        LearnChapterModel(
          id: 'math_ch_6',
          chapterNumber: 6,
          title: 'Triangles & Similarity',
          status: LearnChapterStatus.locked,
          completedLessons: 0,
          totalLessons: 14,
          quizCount: 4,
          accent: const Color(0xFFCACED8),
          summary: 'Starts after Chapter 5',
          topics: const [],
        ),
      ],
    ),
    LearnSubjectModel(
      id: 'science',
      title: 'Science',
      subtitle: 'Biology, Chemistry, and Physics',
      statusLabel: 'New Content',
      icon: Icons.science_outlined,
      accent: const Color(0xFFFFA31A),
      iconBackground: const Color(0xFFFFD8A8),
      chapters: List.generate(
        16,
        (index) => LearnChapterModel(
          id: 'science_ch_$index',
          chapterNumber: index + 1,
          title: 'Science Chapter ${index + 1}',
          status: index < 4
              ? LearnChapterStatus.completed
              : LearnChapterStatus.locked,
          completedLessons: index < 4 ? 8 : 0,
          totalLessons: 8,
          quizCount: 2,
          accent: const Color(0xFFFFA31A),
          summary: index < 4
              ? 'Explore core science fundamentals.'
              : 'Unlock after previous chapter',
          topics: const [],
        ),
      ),
    ),
    LearnSubjectModel(
      id: 'english',
      title: 'English Literature',
      subtitle: 'Grammar, Fiction, and Poetry',
      icon: Icons.menu_book_rounded,
      accent: const Color(0xFF7D31E2),
      iconBackground: const Color(0xFFE9D2FF),
      chapters: List.generate(
        15,
        (index) => LearnChapterModel(
          id: 'english_ch_$index',
          chapterNumber: index + 1,
          title: 'English Chapter ${index + 1}',
          status: LearnChapterStatus.completed,
          completedLessons: 6,
          totalLessons: 6,
          quizCount: 1,
          accent: const Color(0xFF7D31E2),
          summary: 'Grammar drills and reading practice.',
          topics: const [],
        ),
      ),
    ),
    LearnSubjectModel(
      id: 'social',
      title: 'Social Studies',
      subtitle: 'History, Civics, and Geography',
      icon: Icons.public_rounded,
      accent: const Color(0xFF575867),
      iconBackground: const Color(0xFFE0E3E7),
      chapters: List.generate(
        12,
        (index) => LearnChapterModel(
          id: 'social_ch_$index',
          chapterNumber: index + 1,
          title: 'Social Chapter ${index + 1}',
          status: LearnChapterStatus.locked,
          completedLessons: 0,
          totalLessons: 7,
          quizCount: 2,
          accent: const Color(0xFF575867),
          summary: 'Begin your social science path soon.',
          topics: const [],
        ),
      ),
    ),
  ];

  static LearnSubjectModel? subjectById(String id) {
    for (final subject in subjects) {
      if (subject.id == id) {
        return subject;
      }
    }
    return null;
  }
}

LearnLessonModel _defaultLesson({
  required String title,
  required String chapterLabel,
}) {
  return LearnLessonModel(
    title: title,
    chapterLabel: chapterLabel,
    subjectLabel: 'MATHEMATICS',
    description:
        'This lesson walks you through the concept with examples, guided practice, and recap notes.',
    progress: 0.3,
    currentTime: '03:10',
    totalTime: '10:00',
    notes: 'Use the notes tab for formulas, examples, and revision points.',
    resources: const [
      LearnResourceModel(
        title: 'Lesson Summary',
        meta: 'PDF • 420 KB',
        icon: Icons.description_outlined,
        accent: Color(0xFF4A4FD9),
        iconBackground: Color(0xFFDAD8FF),
      ),
    ],
  );
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

  LearnSubjectModel({
    required this.id,
    required this.title,
    required this.subtitle,
    this.statusLabel,
    required this.icon,
    required this.accent,
    required this.iconBackground,
    required this.chapters,
  });

  int get totalChapters => chapters.length;

  int get completedChapters =>
      chapters.where((chapter) => chapter.status == LearnChapterStatus.completed).length;

  double get progress =>
      totalChapters == 0 ? 0 : completedChapters / totalChapters;

  String get progressPercentage => '${(progress * 100).round()}%';

  String get progressText =>
      '$completedChapters/$totalChapters Chapters Completed';
}

enum LearnChapterStatus { completed, inProgress, locked }

class LearnChapterModel {
  final String id;
  final int chapterNumber;
  final String title;
  final LearnChapterStatus status;
  final int completedLessons;
  final int totalLessons;
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
    required this.quizCount,
    required this.accent,
    required this.summary,
    required this.topics,
  });

  double get progress =>
      totalLessons == 0 ? 0 : completedLessons / totalLessons;

  String get progressPercentage => '${(progress * 100).round()}%';

  String get lessonQuizMeta => '$totalLessons Lessons • $quizCount Quizzes';
}

enum LearnTopicStatus { completed, inProgress, locked }

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

class LearnLessonModel {
  final String title;
  final String chapterLabel;
  final String subjectLabel;
  final String description;
  final double progress;
  final String currentTime;
  final String totalTime;
  final String notes;
  final List<LearnResourceModel> resources;

  const LearnLessonModel({
    required this.title,
    required this.chapterLabel,
    required this.subjectLabel,
    required this.description,
    required this.progress,
    required this.currentTime,
    required this.totalTime,
    required this.notes,
    required this.resources,
  });
}

class LearnResourceModel {
  final String title;
  final String meta;
  final IconData icon;
  final Color accent;
  final Color iconBackground;

  const LearnResourceModel({
    required this.title,
    required this.meta,
    required this.icon,
    required this.accent,
    required this.iconBackground,
  });
}
