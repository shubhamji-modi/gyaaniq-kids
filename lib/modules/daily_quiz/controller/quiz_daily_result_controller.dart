import 'package:get/get.dart';

import '../../../core/models/xp_config_data.dart';
import '../../../core/service/api_service.dart';
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
    required this.rewardSource,
    this.feedback = const {},
    this.hasAnswerKey = true,
    int? xpEarned,
  }) : _initialXpEarned = xpEarned;

  final String attemptId;
  final int score;
  final int maxScore;
  final int totalQuestions;
  final int elapsedSeconds;
  final double percentage;
  final bool passed;
  final QuizRewardSource rewardSource;
  final Map<String, QuizAnswerFeedback> feedback;
  final bool hasAnswerKey;
  final int? _initialXpEarned;

  final RxnInt configuredXpEarned = RxnInt();
  final RxBool isLoadingXp = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (_initialXpEarned != null) {
      configuredXpEarned.value = _initialXpEarned;
    } else {
      loadConfiguredXp();
    }
  }

  double get accuracy => maxScore == 0 ? 0 : score / maxScore;

  int get xpEarned => configuredXpEarned.value ?? 0;

  String get rewardSourceLabel {
    switch (rewardSource) {
      case QuizRewardSource.dailyQuiz:
        return 'Daily quiz reward';
      case QuizRewardSource.practiceTest:
        return 'Practice test reward';
      case QuizRewardSource.mockTest:
        return 'Mock test reward';
    }
  }

  Future<void> loadConfiguredXp() async {
    if (isLoadingXp.value) {
      return;
    }

    isLoadingXp.value = true;
    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.USER_XP,
      showLoader: false,
      fromJson: (json) => json,
    );
    isLoadingXp.value = false;

    if (!response.success || response.data is! Map<String, dynamic>) {
      configuredXpEarned.value = 0;
      return;
    }

    final body = response.data as Map<String, dynamic>;
    final data = body['data'];
    final config = data is Map<String, dynamic> ? data['config'] : null;
    if (config is! Map<String, dynamic>) {
      configuredXpEarned.value = 0;
      return;
    }

    configuredXpEarned.value = XpConfigData.fromApi(
      config,
    ).quizXp(source: rewardSource, passed: passed);
  }

  String get scoreText => '$score/$maxScore';

  String get accuracyText =>
      '${percentage.toStringAsFixed(percentage.truncateToDouble() == percentage ? 0 : 2)}%';

  String get scoreLabel => 'FINAL SCORE';

  String get accuracyLabel => 'Percentage';

  String get passStatusLabel => passed ? 'Passed' : 'Needs Improvement';

  bool get canTryAgain => rewardSource == QuizRewardSource.practiceTest;

  String get resultSubtitle {
    if (passed) {
      return 'Fantastic effort! Your quiz attempt has been submitted successfully.';
    }

    if (canTryAgain) {
      return 'Your quiz attempt has been submitted. Review the answers and try again to improve.';
    }

    return 'Your quiz attempt has been submitted. Review the answers to see where you can improve.';
  }

  String get formattedElapsedTime {
    final minutes = (elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void tryAgain() {
    if (!canTryAgain) {
      return;
    }

    final questionController = Get.find<QuestionAnswerShowController>();
    questionController.resetQuiz();
    Get.back<void>();
    Get.back<void>();
  }

  void goHome() {
    _openDashboardHome();
  }

  void backToSubjects() {
    if (rewardSource != QuizRewardSource.practiceTest) {
      _openDashboardHome();
      return;
    }

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

  void _openDashboardHome() {
    if (Get.isRegistered<DashboardTabbarController>()) {
      Get.find<DashboardTabbarController>().changeTab(0);
    }
    Get.offAll(() => const DashboardTabbarViewsScreen());
    Future<void>.delayed(const Duration(milliseconds: 10), () {
      if (Get.isRegistered<DashboardTabbarController>()) {
        Get.find<DashboardTabbarController>().changeTab(0);
      }
    });
  }

  void reviewAnswers() {
    final questionController = Get.find<QuestionAnswerShowController>();
    Get.back<void>();
    questionController.openReviewMode();
  }
}
