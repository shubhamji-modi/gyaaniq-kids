import 'package:flutter/material.dart';

class PracticeQuizSubjectData {
  const PracticeQuizSubjectData({
    required this.title,
    required this.description,
    required this.quizSetLabel,
    required this.accent,
    required this.icon,
    required this.iconBackground,
    required this.topics,
  });

  final String title;
  final String description;
  final String quizSetLabel;
  final Color accent;
  final IconData icon;
  final Color iconBackground;
  final List<PracticeQuizTopicData> topics;
}

class PracticeQuizTopicData {
  const PracticeQuizTopicData({
    required this.title,
    required this.level,
    required this.progress,
    required this.progressLabel,
    required this.accent,
    required this.progressColor,
    required this.icon,
    required this.iconBackground,
    this.isLocked = false,
  });

  final String title;
  final String level;
  final double progress;
  final String progressLabel;
  final Color accent;
  final Color progressColor;
  final IconData icon;
  final Color iconBackground;
  final bool isLocked;
}

class QuizPracticePaperSubjectRepository {
  static const subjects = <PracticeQuizSubjectData>[
    PracticeQuizSubjectData(
      title: 'Mathematics',
      description: 'Algebra, Geometry & logic puzzles.',
      quizSetLabel: '4 Quiz Sets',
      accent: Color(0xFF4C50E6),
      icon: Icons.calculate_rounded,
      iconBackground: Color(0xFFE6E7FF),
      topics: [
        PracticeQuizTopicData(
          title: 'Algebraic Expressions',
          level: 'Medium',
          progress: 0.65,
          progressLabel: '65%',
          accent: Color(0xFF8A3DF0),
          progressColor: Color(0xFF5A5FEF),
          icon: Icons.calculate_rounded,
          iconBackground: Color(0xFFE8E7FF),
        ),
        PracticeQuizTopicData(
          title: 'Linear Equations',
          level: 'Hard',
          progress: 0.20,
          progressLabel: '20%',
          accent: Color(0xFF9A6200),
          progressColor: Color(0xFF5A5FEF),
          icon: Icons.bar_chart_rounded,
          iconBackground: Color(0xFFFFF0D8),
        ),
        PracticeQuizTopicData(
          title: 'Rational Numbers',
          level: 'Easy',
          progress: 0.95,
          progressLabel: '95%',
          accent: Color(0xFF4C50E6),
          progressColor: Color(0xFFFFA31A),
          icon: Icons.percent_rounded,
          iconBackground: Color(0xFFF0E2FF),
          isLocked: true,
        ),
      ],
    ),
    PracticeQuizSubjectData(
      title: 'Science',
      description: 'Biology, Physics & Chemistry basics.',
      quizSetLabel: '3 Quiz Sets',
      accent: Color(0xFFA46A00),
      icon: Icons.science_outlined,
      iconBackground: Color(0xFFFFF1E0),
      topics: [
        PracticeQuizTopicData(
          title: 'Cell Structure',
          level: 'Medium',
          progress: 0.55,
          progressLabel: '55%',
          accent: Color(0xFFA46A00),
          progressColor: Color(0xFF5A5FEF),
          icon: Icons.biotech_outlined,
          iconBackground: Color(0xFFFFF1E0),
        ),
        PracticeQuizTopicData(
          title: 'Force & Motion',
          level: 'Hard',
          progress: 0.30,
          progressLabel: '30%',
          accent: Color(0xFF9A6200),
          progressColor: Color(0xFF5A5FEF),
          icon: Icons.rocket_launch_outlined,
          iconBackground: Color(0xFFFFF1E0),
        ),
        PracticeQuizTopicData(
          title: 'Matter & Reactions',
          level: 'Easy',
          progress: 0.72,
          progressLabel: '72%',
          accent: Color(0xFF4C50E6),
          progressColor: Color(0xFFFFA31A),
          icon: Icons.science_rounded,
          iconBackground: Color(0xFFEFF0FF),
        ),
      ],
    ),
    PracticeQuizSubjectData(
      title: 'English',
      description: 'Grammar, Vocabulary & Reading.',
      quizSetLabel: '5 Quiz Sets',
      accent: Color(0xFF7C2DDE),
      icon: Icons.menu_book_rounded,
      iconBackground: Color(0xFFF1E7FF),
      topics: [
        PracticeQuizTopicData(
          title: 'Reading Comprehension',
          level: 'Medium',
          progress: 0.48,
          progressLabel: '48%',
          accent: Color(0xFF7C2DDE),
          progressColor: Color(0xFF5A5FEF),
          icon: Icons.chrome_reader_mode_outlined,
          iconBackground: Color(0xFFF1E7FF),
        ),
        PracticeQuizTopicData(
          title: 'Parts of Speech',
          level: 'Easy',
          progress: 0.80,
          progressLabel: '80%',
          accent: Color(0xFF4C50E6),
          progressColor: Color(0xFFFFA31A),
          icon: Icons.spellcheck_rounded,
          iconBackground: Color(0xFFE9EBFF),
        ),
        PracticeQuizTopicData(
          title: 'Vocabulary Builder',
          level: 'Hard',
          progress: 0.22,
          progressLabel: '22%',
          accent: Color(0xFF9A6200),
          progressColor: Color(0xFF5A5FEF),
          icon: Icons.translate_rounded,
          iconBackground: Color(0xFFFFF1E0),
        ),
      ],
    ),
    PracticeQuizSubjectData(
      title: 'Social Studies',
      description: 'History, Geography & Civics.',
      quizSetLabel: '2 Quiz Sets',
      accent: Color(0xFFC81E1E),
      icon: Icons.public_rounded,
      iconBackground: Color(0xFFFFE7E7),
      topics: [
        PracticeQuizTopicData(
          title: 'Ancient Civilizations',
          level: 'Medium',
          progress: 0.40,
          progressLabel: '40%',
          accent: Color(0xFFC81E1E),
          progressColor: Color(0xFF5A5FEF),
          icon: Icons.account_balance_outlined,
          iconBackground: Color(0xFFFFEAEA),
        ),
        PracticeQuizTopicData(
          title: 'Map Skills',
          level: 'Easy',
          progress: 0.76,
          progressLabel: '76%',
          accent: Color(0xFF4C50E6),
          progressColor: Color(0xFFFFA31A),
          icon: Icons.map_outlined,
          iconBackground: Color(0xFFE9EBFF),
        ),
      ],
    ),
  ];
}
