import 'package:get/get.dart';

import '../../../core/models/xp_config_data.dart';
import '../../../core/service/api_service.dart';
import '../../../routes/app_routes.dart';
import '../practice_test/Views/quiz_practice_paper_subject_views.dart';
import '../../dashboard_vc/controllers/dashboard_tabbar_controller.dart';
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
    this.returnToLessonOnBack = false,
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
  final bool returnToLessonOnBack;
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

    final questionController = QuestionAnswerShowController.instance;
    questionController.resetQuiz();
    Get.back<void>();
    Get.back<void>();
  }

  void goHome() {
    _returnToDashboard();
  }

  void backToSubjects() {
    if (returnToLessonOnBack) {
      _backToLessonPlayer();
      return;
    }

    if (rewardSource != QuizRewardSource.practiceTest) {
      _returnToDashboard();
      return;
    }

    _returnToDashboard();
    Get.to(() => const QuizPracticePaperSubjectViews());
  }

  /// Goes back to the dashboard the student came from, on the Home tab.
  ///
  /// This used to `Get.offAll(() => const DashboardTabbarViewsScreen())`,
  /// which built a *second* dashboard and threw the original route away. GetX
  /// deletes every controller registered under a route when that route is
  /// disposed, and the removed route is disposed a frame or two *after* the
  /// replacement screen has already been built — so the new dashboard ended up
  /// holding a DashboardTabbarController that was killed moments later. Its Rx
  /// values could no longer emit, which is exactly why the bottom tab bar
  /// stopped responding to taps after finishing a practice test.
  ///
  /// Popping back instead keeps the original dashboard, and its controller,
  /// alive and reactive.
  void _returnToDashboard() {
    // Every path into the app lands on the named dashboard route, so it is the
    // bottom of the stack.
    Get.until((route) => route.isFirst);

    if (Get.currentRoute != AppRoutes.dashboard) {
      // Should not happen, but never leave the student on a stray screen.
      Get.offAllNamed(AppRoutes.dashboard);
      return;
    }

    if (Get.isRegistered<DashboardTabbarController>()) {
      Get.find<DashboardTabbarController>().changeTab(0);
    }
  }

  void _backToLessonPlayer() {
    for (var index = 0; index < 3; index++) {
      if (Get.key.currentState?.canPop() ?? false) {
        Get.back<void>();
      }
    }
  }

  void reviewAnswers() {
    final questionController = QuestionAnswerShowController.instance;
    Get.back<void>();
    questionController.openReviewMode();
  }
}
