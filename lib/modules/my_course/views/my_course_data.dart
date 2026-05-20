import 'package:flutter/material.dart';

enum CourseFilter { all, inProgress, completed, bookmarked }

enum LessonProgressState { locked, available, inProgress, completed }

class MyCourseModel {
  const MyCourseModel({
    required this.id,
    required this.subject,
    required this.title,
    required this.teacher,
    required this.progress,
    required this.completedLessons,
    required this.totalLessons,
    required this.accentColor,
    required this.heroColors,
    required this.heroIcon,
    required this.modules,
    this.isBookmarked = false,
  });

  final String id;
  final String subject;
  final String title;
  final String teacher;
  final double progress;
  final int completedLessons;
  final int totalLessons;
  final Color accentColor;
  final List<Color> heroColors;
  final IconData heroIcon;
  final bool isBookmarked;
  final List<CourseModuleModel> modules;
}

class CourseModuleModel {
  const CourseModuleModel({
    required this.id,
    required this.index,
    required this.title,
    required this.description,
    required this.lessons,
    this.expandedByDefault = false,
  });

  final String id;
  final int index;
  final String title;
  final String description;
  final bool expandedByDefault;
  final List<CourseLessonModel> lessons;
}

class CourseLessonModel {
  const CourseLessonModel({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.overview,
    required this.points,
    this.notesTitle = 'THE GENERAL FORMULA',
    this.notesFormula = 'x² + bx + (b/2)² = (x + b/2)²',
    this.resourceName = 'Lesson_Summary.pdf',
    this.resourceSize = '2.4 MB Download',
  });

  final String id;
  final String title;
  final int durationMinutes;
  final String overview;
  final List<String> points;
  final String notesTitle;
  final String notesFormula;
  final String resourceName;
  final String resourceSize;
}

class MyCourseRepository {
  static final List<MyCourseModel> courses = [
    MyCourseModel(
      id: 'maths',
      subject: 'Maths',
      title: 'Advanced Algebra & Logic',
      teacher: 'Dr. Sarah Jenkins',
      progress: 0.75,
      completedLessons: 12,
      totalLessons: 16,
      accentColor: const Color(0xFF4C49E8),
      heroColors: const [
        Color(0xFF18081F),
        Color(0xFF572A75),
        Color(0xFF111526),
      ],
      heroIcon: Icons.functions_rounded,
      modules: [
        CourseModuleModel(
          id: 'maths_1',
          index: 1,
          title: 'Foundations of Logic',
          description: 'Build the base concepts needed for abstract reasoning.',
          lessons: [
            CourseLessonModel(
              id: 'maths_1_1',
              title: 'What is Logical Reasoning?',
              durationMinutes: 10,
              overview:
                  'Understand how logical patterns help solve algebraic problems.',
              points: const [
                'Identify assumptions and conclusions in a problem.',
                'Understand the role of logic in mathematical proofs.',
                'Recognize valid vs invalid reasoning patterns.',
              ],
            ),
            CourseLessonModel(
              id: 'maths_1_2',
              title: 'Statements and Conditions',
              durationMinutes: 14,
              overview:
                  'Learn how conditions and statements shape problem solving.',
              points: const [
                'Break complex statements into smaller conditions.',
                'Interpret if-then relationships in equations.',
                'Practice conditional reasoning through examples.',
              ],
            ),
          ],
        ),
        CourseModuleModel(
          id: 'maths_2',
          index: 2,
          title: 'Quadratic Equations',
          description:
              'Master forms, factorization, and completing the square.',
          expandedByDefault: true,
          lessons: [
            CourseLessonModel(
              id: 'maths_2_1',
              title: 'Introduction',
              durationMinutes: 12,
              overview:
                  'Start with the structure and real-world meaning of quadratic equations.',
              points: const [
                'Identify standard quadratic form.',
                'Understand how quadratics model curves and motion.',
                'Review basic solving strategies.',
              ],
            ),
            CourseLessonModel(
              id: 'maths_2_2',
              title: 'Factoring Methods',
              durationMinutes: 18,
              overview:
                  'Learn how to break a quadratic into simpler linear expressions.',
              points: const [
                'Recognize factorable patterns quickly.',
                'Use split-middle term strategies.',
                'Check solutions by substitution.',
              ],
            ),
            CourseLessonModel(
              id: 'maths_2_3',
              title: 'Completing the Square',
              durationMinutes: 25,
              overview:
                  'Transform a quadratic expression into a perfect square trinomial.',
              points: const [
                'Understand the purpose of completing the square in solving quadratics.',
                'Learn the step-by-step process: identify, divide, square, and add.',
                'Apply the method to find the vertex of a parabola.',
              ],
            ),
            CourseLessonModel(
              id: 'maths_2_4',
              title: 'The Quadratic Formula',
              durationMinutes: 22,
              overview:
                  'Use the quadratic formula when factoring is not straightforward.',
              points: const [
                'Identify values of a, b, and c.',
                'Use the discriminant to predict roots.',
                'Solve non-factorable quadratics confidently.',
              ],
            ),
          ],
        ),
        CourseModuleModel(
          id: 'maths_3',
          index: 3,
          title: 'Systems of Equations',
          description:
              'Solve multiple equations together with elimination and substitution.',
          lessons: [
            CourseLessonModel(
              id: 'maths_3_1',
              title: 'Linear Systems Basics',
              durationMinutes: 16,
              overview:
                  'Learn how solutions behave when two equations interact.',
              points: const [
                'Interpret solutions as points of intersection.',
                'Differentiate consistent and inconsistent systems.',
                'Set up systems from word problems.',
              ],
            ),
          ],
        ),
      ],
    ),
    MyCourseModel(
      id: 'science',
      subject: 'Science',
      title: 'Introduction to Biology',
      teacher: 'Prof. Michael Chen',
      progress: 0.30,
      completedLessons: 4,
      totalLessons: 12,
      accentColor: const Color(0xFFA33EF4),
      heroColors: const [
        Color(0xFF07262C),
        Color(0xFF0A5E67),
        Color(0xFF1A171B),
      ],
      heroIcon: Icons.science_rounded,
      modules: [
        CourseModuleModel(
          id: 'science_1',
          index: 1,
          title: 'Cell Structure',
          description: 'Understand the building blocks of life.',
          expandedByDefault: true,
          lessons: [
            CourseLessonModel(
              id: 'science_1_1',
              title: 'Introduction to Cells',
              durationMinutes: 11,
              overview:
                  'Discover why cells are considered the smallest unit of life.',
              points: const [
                'Identify the major parts of a cell.',
                'Compare simple cell types.',
                'Understand the cell theory basics.',
              ],
              notesTitle: 'CELL THEORY',
              notesFormula: 'All living organisms are made of cells.',
            ),
            CourseLessonModel(
              id: 'science_1_2',
              title: 'Organelles and Functions',
              durationMinutes: 17,
              overview: 'Study the role of nucleus, mitochondria, and more.',
              points: const [
                'Connect organelles with their functions.',
                'Differentiate plant and animal cells.',
                'Understand how cell structures support life.',
              ],
              notesTitle: 'ORGANELLE MAP',
              notesFormula:
                  'Nucleus + Cytoplasm + Membrane = Cell core structure',
            ),
          ],
        ),
      ],
    ),
    MyCourseModel(
      id: 'english',
      subject: 'English',
      title: 'Modern Literature & Poetry',
      teacher: 'Ms. Elena Rodriguez',
      progress: 0.90,
      completedLessons: 18,
      totalLessons: 20,
      accentColor: const Color(0xFFFFAC23),
      heroColors: const [
        Color(0xFF66808C),
        Color(0xFFCFB77D),
        Color(0xFF1F5662),
      ],
      heroIcon: Icons.menu_book_rounded,
      isBookmarked: true,
      modules: [
        CourseModuleModel(
          id: 'english_1',
          index: 1,
          title: 'Poetic Devices',
          description:
              'Identify rhythm, imagery, and metaphor in modern poetry.',
          expandedByDefault: true,
          lessons: [
            CourseLessonModel(
              id: 'english_1_1',
              title: 'Understanding Imagery',
              durationMinutes: 13,
              overview:
                  'See how poets create mental pictures using carefully chosen language.',
              points: const [
                'Find sensory language inside a poem.',
                'Connect imagery with mood and tone.',
                'Interpret symbolic details with context.',
              ],
              notesTitle: 'IMAGERY QUICK NOTE',
              notesFormula: 'Image + Emotion + Context = Strong interpretation',
            ),
          ],
        ),
      ],
    ),
  ];

  static final Map<String, Set<String>> _viewedLessons = {};
  static final Map<String, Set<String>> _completedLessons = {};
  static final Map<String, String> _lastViewedLesson = {};

  static Set<String> _setFor(Map<String, Set<String>> map, String courseId) {
    return map.putIfAbsent(courseId, () => <String>{});
  }

  static void markLessonViewed(String courseId, String lessonId) {
    _setFor(_viewedLessons, courseId).add(lessonId);
    _lastViewedLesson[courseId] = lessonId;
  }

  static void markLessonCompleted(String courseId, String lessonId) {
    markLessonViewed(courseId, lessonId);
    _setFor(_completedLessons, courseId).add(lessonId);
  }

  static bool isLessonViewed(String courseId, String lessonId) {
    return _viewedLessons[courseId]?.contains(lessonId) ?? false;
  }

  static bool isLessonCompleted(String courseId, String lessonId) {
    return _completedLessons[courseId]?.contains(lessonId) ?? false;
  }

  static String? lastViewedLesson(String courseId) {
    return _lastViewedLesson[courseId];
  }

  static LessonProgressState lessonState(
    MyCourseModel course,
    CourseModuleModel module,
    CourseLessonModel lesson,
  ) {
    if (isLessonCompleted(course.id, lesson.id)) {
      return LessonProgressState.completed;
    }

    final CourseLessonModel? firstUnlocked = nextAccessibleLesson(course);
    if (firstUnlocked != null && firstUnlocked.id == lesson.id) {
      return isLessonViewed(course.id, lesson.id)
          ? LessonProgressState.inProgress
          : LessonProgressState.available;
    }

    return LessonProgressState.locked;
  }

  static CourseLessonModel? nextAccessibleLesson(MyCourseModel course) {
    for (final module in course.modules) {
      for (final lesson in module.lessons) {
        if (!isLessonCompleted(course.id, lesson.id)) {
          return lesson;
        }
      }
    }
    return null;
  }

  static bool showResume(MyCourseModel course, CourseLessonModel lesson) {
    return lastViewedLesson(course.id) == lesson.id &&
        isLessonViewed(course.id, lesson.id) &&
        !isLessonCompleted(course.id, lesson.id);
  }
}
