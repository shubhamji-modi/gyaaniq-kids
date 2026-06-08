import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/service/api_service.dart';
import 'question_answer_show_controller.dart';
import '../views/question_answer_show_views.dart';

class StartQuizController extends GetxController {
  StartQuizController({this.mockTestId = ''});

  final String mockTestId;
  late final QuestionAnswerShowController quizController;

  bool get isMockTest => mockTestId.isNotEmpty;

  String get challengeLabel => isMockTest ? 'MOCK TEST' : 'DAILY CHALLENGE';
  final RxBool isLoading = true.obs;
  final RxBool isStartingQuiz = false.obs;
  final RxString errorMessage = ''.obs;
  final Rxn<DailyQuizData> dailyQuiz = Rxn<DailyQuizData>();

  String get title =>
      dailyQuiz.value?.title ?? (isMockTest ? 'Mock Test' : 'Daily Challenge');

  String get description {
    final quiz = dailyQuiz.value;
    if (quiz == null) {
      return isMockTest
          ? 'Real exam simulation with timers.'
          : 'Test your understanding and build confidence daily.';
    }
    return 'Class ${quiz.classLevel} ${isMockTest ? 'mock test' : 'daily quiz'} is ready. Score ${quiz.passingPercentage}% or more to pass.';
  }

  String get meta => dailyQuiz.value?.metaLabel ?? 'Loading quiz...';

  final List<QuizFeatureData> features = const [
    QuizFeatureData(
      icon: Icons.timer_outlined,
      title: 'Timed Sessions',
      description:
          'The clock starts as soon as you begin. Total time allocated is \n15 minutes.',
    ),
    QuizFeatureData(
      icon: Icons.workspace_premium_outlined,
      title: 'Win Badges',
      description:
          'Score above 80% to unlock the Algebra Ace badge for your profile.',
    ),
    QuizFeatureData(
      icon: Icons.calendar_today_outlined,
      title: 'Daily Challenge',
      description:
      'A new quiz is available every day. Complete it to improve your knowledge and consistency.',
    ),
  ];


  final List<String> instructions = const [
    'Read each question carefully before selecting your answer from the options provided.',
    'You can move between questions using the previous and next buttons at the bottom.',
    'Unanswered questions can be submitted and will receive 0 marks.',
  ];

  @override
  void onInit() {
    super.onInit();
    quizController = Get.isRegistered<QuestionAnswerShowController>()
        ? Get.find<QuestionAnswerShowController>()
        : Get.put(QuestionAnswerShowController());
    if (isMockTest) {
      fetchMockTest();
    } else {
      fetchDailyQuiz();
    }
  }

  Future<void> fetchMockTest() async {
    isLoading.value = true;
    errorMessage.value = '';

    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.FETCH_MOCK_TEST.replaceFirst(':id', mockTestId),
      showLoader: false,
      fromJson: (json) => json,
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      dailyQuiz.value = null;
      errorMessage.value = response.message;
      isLoading.value = false;
      return;
    }

    final body = response.data as Map<String, dynamic>;
    final quizJson = (body['data'] as Map<String, dynamic>?) ?? const {};
    final quiz = DailyQuizData.fromMockApi(quizJson);

    dailyQuiz.value = quiz;
    errorMessage.value = quiz.questions.isEmpty
        ? 'This mock test does not have any questions yet.'
        : '';
    isLoading.value = false;
  }

  Future<void> fetchDailyQuiz() async {
    isLoading.value = true;
    errorMessage.value = '';

    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.DAILY_QUIZZS,
      showLoader: false,
      fromJson: (json) => json,
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      dailyQuiz.value = null;
      errorMessage.value = response.message;
      isLoading.value = false;
      return;
    }

    final body = response.data as Map<String, dynamic>;
    final quizJson = (body['data'] as Map<String, dynamic>?) ?? const {};
    final quiz = DailyQuizData.fromApi(quizJson);

    dailyQuiz.value = quiz;
    errorMessage.value = quiz.questions.isEmpty
        ? 'Today\'s quiz does not have any questions yet.'
        : '';
    isLoading.value = false;
  }

  void startQuiz() {
    final quiz = dailyQuiz.value;
    if (quiz == null || quiz.questions.isEmpty || isStartingQuiz.value) {
      return;
    }

    if (quiz.myAttemptId.isNotEmpty) {
      Get.snackbar(
        'Already Attempted',
        isMockTest
            ? 'You have already attempted this mock test.'
            : 'You have already attempted today\'s quiz.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isStartingQuiz.value = true;
    quizController.loadQuiz(
      quizId: quiz.id,
      title: quiz.title,
      subjectTitle: quiz.subjectSummary,
      lessonTitle: '',
      questions: quiz.questions,
      timeLimitMinutes: quiz.timeLimitMinutes,
      isDailyQuiz: !isMockTest,
      isMockTest: isMockTest,
    );
    isStartingQuiz.value = false;
    Get.to(() => const QuestionAnswerShowViews());
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

class DailyQuizData {
  const DailyQuizData({
    required this.id,
    required this.classLevel,
    required this.totalMarks,
    required this.timeLimitMinutes,
    required this.passingPercentage,
    required this.questions,
    required this.perSubjectCounts,
    required this.myAttemptId,
    this.titleOverride = '',
  });

  final String id;
  final String classLevel;
  final int totalMarks;
  final int timeLimitMinutes;
  final int passingPercentage;
  final List<QuizQuestion> questions;
  final List<DailyQuizSubjectCount> perSubjectCounts;
  final String myAttemptId;
  final String titleOverride;

  factory DailyQuizData.fromApi(Map<String, dynamic> json) {
    final subjectCounts =
        (json['perSubjectCounts'] as List<dynamic>? ?? const [])
            .map(
              (item) =>
                  DailyQuizSubjectCount.fromApi(item as Map<String, dynamic>),
            )
            .toList();

    final questions = (json['questions'] as List<dynamic>? ?? const []).map((
      item,
    ) {
      final questionJson = item as Map<String, dynamic>;
      final subjectTitle = _safeText(
        (questionJson['subject'] as Map<String, dynamic>?)?['name'],
        fallback: 'Daily Quiz',
      );
      return QuizQuestion.fromApi(questionJson, subjectTitle: subjectTitle);
    }).toList()..sort((a, b) => a.order.compareTo(b.order));

    return DailyQuizData(
      id: _safeText(json['_id']),
      classLevel: _safeText(json['classLevel'], fallback: '-'),
      totalMarks: (json['totalMarks'] as num?)?.toInt() ?? 0,
      timeLimitMinutes: (json['timeLimitMinutes'] as num?)?.toInt() ?? 0,
      passingPercentage: (json['passingPercentage'] as num?)?.toInt() ?? 0,
      questions: questions,
      perSubjectCounts: subjectCounts,
      myAttemptId: _safeText(json['myAttemptId']),
    );
  }

  factory DailyQuizData.fromMockApi(Map<String, dynamic> json) {
    final subjectCounts = (json['subjects'] as List<dynamic>? ?? const [])
        .map(
          (item) =>
              DailyQuizSubjectCount.fromMockApi(item as Map<String, dynamic>),
        )
        .toList();

    final questions = (json['questions'] as List<dynamic>? ?? const []).map((
      item,
    ) {
      final questionJson = item as Map<String, dynamic>;
      final subjectTitle = _safeText(
        (questionJson['subject'] as Map<String, dynamic>?)?['name'],
        fallback: 'Mock Test',
      );
      return QuizQuestion.fromApi(questionJson, subjectTitle: subjectTitle);
    }).toList()..sort((a, b) => a.order.compareTo(b.order));

    return DailyQuizData(
      id: _safeText(json['_id']),
      classLevel: _safeText(json['classLevel'], fallback: '-'),
      totalMarks: (json['totalMarks'] as num?)?.toInt() ?? 0,
      timeLimitMinutes: _mockDurationMinutes(json['startAt'], json['endAt']),
      passingPercentage: (json['passingPercentage'] as num?)?.toInt() ?? 0,
      questions: questions,
      perSubjectCounts: subjectCounts,
      myAttemptId: _safeText(json['myAttemptId']),
      titleOverride: _safeText(json['title'], fallback: 'Mock Test'),
    );
  }

  String get title => titleOverride.isEmpty ? 'Daily Quiz' : titleOverride;

  String get timeLimitLabel =>
      timeLimitMinutes <= 0 ? 'No Limit' : '$timeLimitMinutes Mins';

  String get metaLabel =>
      '${questions.length} Questions • $totalMarks Marks • $timeLimitLabel';

  String get subjectSummary {
    if (perSubjectCounts.isEmpty) {
      return 'Daily Quiz';
    }
    return perSubjectCounts.map((item) => item.subjectName).join(', ');
  }
}

class DailyQuizSubjectCount {
  const DailyQuizSubjectCount({
    required this.subjectName,
    required this.questionsCount,
  });

  final String subjectName;
  final int questionsCount;

  factory DailyQuizSubjectCount.fromApi(Map<String, dynamic> json) {
    return DailyQuizSubjectCount(
      subjectName: _safeText(
        (json['subject'] as Map<String, dynamic>?)?['name'],
        fallback: 'Subject',
      ),
      questionsCount: (json['questionsCount'] as num?)?.toInt() ?? 0,
    );
  }

  factory DailyQuizSubjectCount.fromMockApi(Map<String, dynamic> json) {
    return DailyQuizSubjectCount(
      subjectName: _safeText(
        (json['subject'] as Map<String, dynamic>?)?['name'],
        fallback: 'Subject',
      ),
      questionsCount:
          (json['generatedCount'] as num?)?.toInt() ??
          (json['requestedCount'] as num?)?.toInt() ??
          0,
    );
  }
}

String _safeText(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _mockDurationMinutes(dynamic startValue, dynamic endValue) {
  final start = DateTime.tryParse(startValue?.toString() ?? '');
  final end = DateTime.tryParse(endValue?.toString() ?? '');
  if (start == null || end == null || !end.isAfter(start)) {
    return 0;
  }
  return end.difference(start).inMinutes;
}
