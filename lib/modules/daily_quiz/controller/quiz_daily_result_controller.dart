import 'package:get/get.dart';

import '../practice_test/Views/quiz_practice_paper_subject_views.dart';
import '../../dashboard_vc/controllers/dashboard_tabbar_controller.dart';
import '../../dashboard_vc/views/dashboard_tabbar_views_screen.dart';
import 'question_answer_show_controller.dart';

class QuizDailyResultController extends GetxController {
  QuizDailyResultController({
    required this.attemptId,
    required this.score,
    required this.maxScore,
    required this.totalQuestions,
    required this.elapsedSeconds,
    required this.percentage,
    required this.passed,
    this.feedback = const {},
    this.hasAnswerKey = true,
  });

  final String attemptId;
  final int score;
  final int maxScore;
  final int totalQuestions;
  final int elapsedSeconds;
  final double percentage;
  final bool passed;
  final Map<String, QuizAnswerFeedback> feedback;
  final bool hasAnswerKey;

  double get accuracy => maxScore == 0 ? 0 : score / maxScore;

  int get xpEarned => score * 25;

  String get scoreText => '$score/$maxScore';

  String get accuracyText => '${percentage.toStringAsFixed(percentage.truncateToDouble() == percentage ? 0 : 2)}%';

  String get scoreLabel => 'FINAL SCORE';

  String get accuracyLabel => 'Percentage';

  String get passStatusLabel => passed ? 'Passed' : 'Needs Improvement';

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

  void backToSubjects() {
    if (Get.isRegistered<DashboardTabbarController>()) {
      Get.find<DashboardTabbarController>().changeTab(0);
    }
    Get.offAll(() => const DashboardTabbarViewsScreen());
    Future<void>.delayed(const Duration(milliseconds: 10), () {
      if (Get.isRegistered<DashboardTabbarController>()) {
        Get.find<DashboardTabbarController>().changeTab(0);
      }
      Get.to(() => const QuizPracticePaperSubjectViews());
    });
  }

  void reviewAnswers() {
    final questionController = Get.find<QuestionAnswerShowController>();
    Get.back<void>();
    questionController.openReviewMode();
  }
}
