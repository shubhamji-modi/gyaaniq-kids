import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../learn/chapter/views/learn_subject_views.dart';
import '../controller/quiz_practice_paper_subject_controller.dart';
import '../controller/quiz_practice_paper_topic_controller.dart';

class QuizPracticePaperTopicViews extends StatelessWidget {
  QuizPracticePaperTopicViews({
    super.key,
    required this.subject,
  });

  final PracticeQuizSubjectData subject;
  final QuizPracticePaperTopicController controller =
      Get.put(QuizPracticePaperTopicController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        child: Column(
          children: [
            const LearnTopBar(title: 'Practice Quiz'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                children: [
                  Text(
                    '${subject.title} Topics',
                    style: const TextStyle(
                      color: Color(0xFF1D2231),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Master each concept through interactive practice questions.',
                    style: TextStyle(
                      color: Color(0xFF4D4F61),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 22),
                  ...subject.topics.map(
                    (topic) => Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _PracticeTopicCard(
                        subject: subject,
                        topic: topic,
                        onPracticeNow: () => controller.startPractice(
                          subject: subject,
                          topic: topic,
                        ),
                      ),
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

class _PracticeTopicCard extends StatelessWidget {
  const _PracticeTopicCard({
    required this.subject,
    required this.topic,
    required this.onPracticeNow,
  });

  final PracticeQuizSubjectData subject;
  final PracticeQuizTopicData topic;
  final VoidCallback onPracticeNow;

  @override
  Widget build(BuildContext context) {
    final buttonBackground =
        topic.isLocked ? const Color(0xFFE2E5EA) : const Color(0xFF4A4FD9);
    final buttonForeground =
        topic.isLocked ? const Color(0xFF1D2231) : Colors.white;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E5F2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD9DFF0).withValues(alpha: 0.78),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: topic.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  topic.level,
                  style: TextStyle(
                    color: topic.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: topic.iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(topic.icon, color: subject.accent, size: 23),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            topic.title,
            style: const TextStyle(
              color: Color(0xFF1D2231),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Text(
                'Progress',
                style: TextStyle(
                  color: Color(0xFF4D4F61),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                topic.progressLabel,
                style: TextStyle(
                  color: topic.progressColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: topic.progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE3E6EC),
              valueColor: AlwaysStoppedAnimation<Color>(topic.progressColor),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPracticeNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonBackground,
                foregroundColor: buttonForeground,
                elevation: 0,
                minimumSize: const Size.fromHeight(45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              iconAlignment: IconAlignment.end,
              icon: Icon(
                topic.isLocked ? Icons.refresh_rounded : Icons.play_circle_outline_rounded,
                size: 21,
              ),
              label: const Text('Practice Now'),
            ),
          ),
        ],
      ),
    );
  }
}
