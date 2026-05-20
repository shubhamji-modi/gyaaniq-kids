import 'package:get/get.dart';

import 'question_answer_show_controller.dart';

class QuizDailyResultController extends GetxController {
  QuizDailyResultController({
    required this.score,
    required this.totalQuestions,
    required this.elapsedSeconds,
  });

  final int score;
  final int totalQuestions;
  final int elapsedSeconds;

  double get accuracy => totalQuestions == 0 ? 0 : score / totalQuestions;

  int get xpEarned => score * 25;

  String get scoreText => '$score/$totalQuestions';

  String get accuracyText => '${(accuracy * 100).round()}%';

  String get formattedElapsedTime {
    final minutes = (elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void tryAgain() {
    final questionController = Get.find<QuestionAnswerShowController>();
    questionController.resetQuiz();
    Get.back<void>();
    Get.back<void>();
  }

  void goHome() {
    Get.until((route) => route.isFirst);
  }

  void reviewAnswers() {
    final questionController = Get.find<QuestionAnswerShowController>();
    Get.back<void>();
    questionController.openReviewMode();
  }
}
