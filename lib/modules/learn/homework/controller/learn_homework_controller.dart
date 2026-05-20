import 'package:flutter/material.dart';

class LearnHomeworkRepository {
  static const List<LearnHomeworkModel> assignments = [
    LearnHomeworkModel(
      id: 'quadratic_equations',
      subject: 'Mathematics',
      subjectLabel: 'MATHEMATICS',
      topic: 'Chapter 4',
      title: 'Quadratic Equations Practice',
      dueDate: 'Oct 24, 2023',
      duration: '45 mins',
      accent: Color(0xFF4A4FD9),
      icon: Icons.calculate_outlined,
      iconBackground: Color(0xFF6368F2),
      chipBackground: Color(0xFFE4E4FF),
      status: LearnHomeworkStatus.pending,
      submittedDate: 'Oct 23, 2023',
      scoreLabel: 'Score',
      scoreValue: '9/10',
      submissionState: 'Submitted',
      readTime: '5 min read',
      fileName: 'Quadratic_Solutions_A...',
      fileMeta: '1.2 MB • Uploaded just now',
      instructions:
          'Please upload your handwritten solutions or a compiled PDF. Ensure all calculation steps are clearly visible for partial credit. We accept high-quality scans or photos.',
    ),
    LearnHomeworkModel(
      id: 'chemical_bonding',
      subject: 'Science',
      subjectLabel: 'SCIENCE',
      topic: 'Chemistry',
      title: 'Chemical Bonding Lab Report',
      dueDate: 'Oct 26, 2023',
      duration: '35 mins',
      accent: Color(0xFFFFA31A),
      icon: Icons.science_outlined,
      iconBackground: Color(0xFFFFA31A),
      chipBackground: Color(0xFFFFF1DE),
      status: LearnHomeworkStatus.pending,
      submittedDate: 'Oct 21, 2023',
      scoreLabel: 'Grade',
      scoreValue: 'A-',
      submissionState: 'Submitted',
      readTime: '6 min read',
      fileName: 'Chemical_Bonding_Report...',
      fileMeta: '2.4 MB • Uploaded just now',
      instructions:
          'Attach your experiment observations, diagrams, and final conclusion. Make sure all steps are easy to read and the report is neatly labeled.',
    ),
    LearnHomeworkModel(
      id: 'renaissance_essay',
      subject: 'History',
      subjectLabel: 'HISTORY',
      topic: 'World History',
      title: 'The Renaissance Essay',
      dueDate: 'Oct 28, 2023',
      duration: '50 mins',
      accent: Color(0xFF9A43E7),
      icon: Icons.history_edu_outlined,
      iconBackground: Color(0xFF9A43E7),
      chipBackground: Color(0xFFF2E4FF),
      status: LearnHomeworkStatus.pending,
      submittedDate: 'Oct 19, 2023',
      scoreLabel: 'Status',
      scoreValue: 'Grading...',
      submissionState: 'Submitted',
      readTime: '7 min read',
      fileName: 'Renaissance_Essay_Draft...',
      fileMeta: '980 KB • Uploaded just now',
      instructions:
          'Write a short essay explaining the cultural importance of the Renaissance. Include at least two examples from art, science, or literature.',
    ),
    LearnHomeworkModel(
      id: 'cell_structure',
      subject: 'Science',
      subjectLabel: 'SCIENCE',
      topic: 'Biology',
      title: 'Cell Structure Diagram',
      dueDate: 'Oct 21, 2023',
      duration: '30 mins',
      accent: Color(0xFFA46A00),
      icon: Icons.biotech_outlined,
      iconBackground: Color(0xFFFFF1DE),
      chipBackground: Color(0xFFFFF1DE),
      status: LearnHomeworkStatus.completed,
      submittedDate: 'Oct 21, 2023',
      scoreLabel: 'Grade',
      scoreValue: 'A-',
      submissionState: 'Submitted',
      readTime: '4 min read',
      fileName: 'Cell_Structure_Submission...',
      fileMeta: '1.0 MB • Uploaded just now',
      instructions:
          'Label each organelle clearly and include a short note describing its function.',
    ),
    LearnHomeworkModel(
      id: 'ancient_civilizations',
      subject: 'History',
      subjectLabel: 'HISTORY',
      topic: 'Essay',
      title: 'Ancient Civilizations Essay',
      dueDate: 'Oct 19, 2023',
      duration: '40 mins',
      accent: Color(0xFF9A43E7),
      icon: Icons.menu_book_outlined,
      iconBackground: Color(0xFFF2E4FF),
      chipBackground: Color(0xFFF2E4FF),
      status: LearnHomeworkStatus.completed,
      submittedDate: 'Oct 19, 2023',
      scoreLabel: 'Status',
      scoreValue: 'Grading...',
      submissionState: 'Submitted',
      readTime: '6 min read',
      fileName: 'Ancient_Civilizations_Essay...',
      fileMeta: '1.7 MB • Uploaded just now',
      instructions:
          'Discuss key achievements of one ancient civilization and explain its historical impact.',
    ),
  ];
}

enum LearnHomeworkStatus { pending, completed }

class LearnHomeworkModel {
  final String id;
  final String subject;
  final String subjectLabel;
  final String topic;
  final String title;
  final String dueDate;
  final String duration;
  final Color accent;
  final IconData icon;
  final Color iconBackground;
  final Color chipBackground;
  final LearnHomeworkStatus status;
  final String submittedDate;
  final String scoreLabel;
  final String scoreValue;
  final String submissionState;
  final String readTime;
  final String fileName;
  final String fileMeta;
  final String instructions;

  const LearnHomeworkModel({
    required this.id,
    required this.subject,
    required this.subjectLabel,
    required this.topic,
    required this.title,
    required this.dueDate,
    required this.duration,
    required this.accent,
    required this.icon,
    required this.iconBackground,
    required this.chipBackground,
    required this.status,
    required this.submittedDate,
    required this.scoreLabel,
    required this.scoreValue,
    required this.submissionState,
    required this.readTime,
    required this.fileName,
    required this.fileMeta,
    required this.instructions,
  });
}
