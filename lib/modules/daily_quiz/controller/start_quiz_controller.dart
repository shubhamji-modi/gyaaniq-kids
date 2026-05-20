import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'question_answer_show_controller.dart';

class StartQuizController extends GetxController {
  late final QuestionAnswerShowController quizController;

  final String challengeLabel = 'DAILY CHALLENGE';
  final String title = 'Daily Challenge';
  final String description =
      'Test your understanding and build confidence daily.';
  final String meta = '10 Questions • 15 Mins';

  final List<QuizFeatureData> features = const [
    QuizFeatureData(
      icon: Icons.timer_outlined,
      title: 'Timed Sessions',
      description:
          'The clock starts as soon as you begin. Total time allocated is \n15 minutes.',
    ),
    QuizFeatureData(
      icon: Icons.auto_awesome_outlined,
      title: 'AI Assistance',
      description:
          'Need a nudge? Use the guide button for hints, but it may cost a few points!',
    ),
    QuizFeatureData(
      icon: Icons.workspace_premium_outlined,
      title: 'Win Badges',
      description:
          'Score above 80% to unlock the Algebra Ace badge for your profile.',
    ),
  ];

  final List<String> instructions = const [
    'Read each question carefully before selecting your answer from the options provided.',
    'You can move between questions using the previous and next buttons at the bottom.',
    'Submit will stay disabled until all 10 questions are answered.',
  ];

  @override
  void onInit() {
    super.onInit();
    quizController = Get.isRegistered<QuestionAnswerShowController>()
        ? Get.find<QuestionAnswerShowController>()
        : Get.put(QuestionAnswerShowController());
  }

  void startQuiz() {
    quizController.resetQuiz();
    quizController.startQuiz();
  }
}

class QuizFeatureData {
  const QuizFeatureData({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
