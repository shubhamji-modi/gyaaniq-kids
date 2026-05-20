import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../learn/chapter/views/learn_subject_views.dart';
import '../controller/quiz_practice_paper_subject_controller.dart';
import 'quiz_practice_paper_topic_views.dart';

class QuizPracticePaperSubjectViews extends StatelessWidget {
  const QuizPracticePaperSubjectViews({super.key});

  @override
  Widget build(BuildContext context) {
    final subjects = QuizPracticePaperSubjectRepository.subjects;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        child: Column(
          children: [
            const LearnTopBar(title: 'Practice Quiz'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                children: [
                  const Text(
                    'Select Subject',
                    style: TextStyle(
                      color: Color(0xFF1D2231),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Choose your daily challenge. Each subject helps you level up!',
                    style: TextStyle(
                      color: Color(0xFF4D4F61),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...subjects.map(
                    (subject) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _PracticeSubjectCard(subject: subject),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PracticeSubjectCard extends StatelessWidget {
  const _PracticeSubjectCard({required this.subject});

  final PracticeQuizSubjectData subject;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.to(() => QuizPracticePaperTopicViews(subject: subject)),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE2E5F2)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD9DFF0).withValues(alpha: 0.75),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: subject.iconBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(subject.icon, color: subject.accent, size: 26),
            ),
            const SizedBox(height: 15),
            Text(
              subject.title,
              style: const TextStyle(
                color: Color(0xFF1D2231),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: subject.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                subject.quizSetLabel,
                style: TextStyle(
                  color: subject.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              subject.description,
              style: const TextStyle(
                color: Color(0xFF4D4F61),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
