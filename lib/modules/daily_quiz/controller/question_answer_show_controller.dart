import 'dart:async';

import 'package:get/get.dart';

import '../../../core/service/api_service.dart';
import '../../../core/models/question_explanation.dart';
import '../../../core/models/xp_config_data.dart';
import '../../../core/service/ad_service.dart';
import '../../../core/service/explanation_catalog_service.dart';

import '../../dashboard_vc/controllers/dashboard_tabbar_controller.dart';
import '../controller/quiz_daily_result_controller.dart';
import '../views/question_answer_show_views.dart';
import '../views/quiz_daily_result.dart';

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    required this.tags,
    this.order = 0,
    this.marks = 1,
    this.questionImageUrl = '',
    this.optionImageUrls = const [],
  });

  final String id;
  final String question;
  final List<String> options;
  final int? correctOptionIndex;
  final List<String> tags;
  final int order;
  final int marks;
  final String questionImageUrl;
  final List<String> optionImageUrls;

  factory QuizQuestion.fromApi(
    Map<String, dynamic> json, {
    required String subjectTitle,
  }) {
    final difficulty = _safeText(json['difficulty'], fallback: 'Question');
    final marks = (json['marks'] as num?)?.toInt() ?? 1;

    // Extract question image URL - try multiple field name variations
    String questionImageUrl = '';
    if (json['questionImage'] != null) {
      questionImageUrl = _extractImageUrl(json['questionImage']);
    } else if (json['image'] != null) {
      questionImageUrl = _extractImageUrl(json['image']);
    } else if (json['imageUrl'] != null) {
      questionImageUrl = _extractImageUrl(json['imageUrl']);
    } else if (json['media'] is List && (json['media'] as List).isNotEmpty) {
      final media = (json['media'] as List).first;
      if (media is Map<String, dynamic>) {
        questionImageUrl = _extractImageUrl(media);
      }
    }

    // Extract option data (can be strings or objects with image)
    final optionsJson = json['options'] as List<dynamic>? ?? const [];
    final optionImageUrls = <String>[];
    final optionTexts = <String>[];

    for (final option in optionsJson) {
      if (option is Map<String, dynamic>) {
        optionTexts.add(
          _stripHtml(
            _safeText(
              option['text'] ??
                  option['optionText'] ??
                  option['label'] ??
                  option['value'],
            ),
          ),
        );
        String optionImage = '';
        if (option['image'] != null) {
          optionImage = _extractImageUrl(option['image']);
        } else if (option['imageUrl'] != null) {
          optionImage = _extractImageUrl(option['imageUrl']);
        } else if (option['media'] != null) {
          optionImage = _extractImageUrl(option['media']);
        }
        optionImageUrls.add(optionImage);
      } else {
        optionTexts.add(_stripHtml(_safeText(option)));
        optionImageUrls.add('');
      }
    }

    return QuizQuestion(
      id: _safeText(json['_id']),
      question: _stripHtml(_safeText(json['questionText'])),
      options: optionTexts,
      correctOptionIndex: null,
      tags: [
        subjectTitle,
        difficulty.toUpperCase(),
        '$marks Mark${marks > 1 ? 's' : ''}',
      ],
      order: (json['order'] as num?)?.toInt() ?? 0,
      marks: marks,
      questionImageUrl: questionImageUrl,
      optionImageUrls: optionImageUrls,
    );
  }

  QuizQuestion copyWith({
    String? id,
    String? question,
    List<String>? options,
    int? correctOptionIndex,
    List<String>? tags,
    int? order,
    int? marks,
    String? questionImageUrl,
    List<String>? optionImageUrls,
  }) {
    return QuizQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? this.options,
      correctOptionIndex: correctOptionIndex ?? this.correctOptionIndex,
      tags: tags ?? this.tags,
      order: order ?? this.order,
      marks: marks ?? this.marks,
      questionImageUrl: questionImageUrl ?? this.questionImageUrl,
      optionImageUrls: optionImageUrls ?? this.optionImageUrls,
    );
  }
}

class QuestionAnswerShowController extends GetxController {
  /// Always returns a live instance.
  ///
  /// GetX's smart management can dispose this controller when the route that
  /// created it is popped, so a plain `Get.find` crashes when the quiz screen
  /// is rebuilt afterwards. Registering it permanently keeps quiz state alive
  /// for the whole session.
  static QuestionAnswerShowController get instance =>
      Get.isRegistered<QuestionAnswerShowController>()
      ? Get.find<QuestionAnswerShowController>()
      : Get.put(QuestionAnswerShowController(), permanent: true);

  final RxInt currentQuestionIndex = 0.obs;
  final RxList<int?> selectedAnswers = <int?>[].obs;
  final RxInt elapsedSeconds = 0.obs;
  final RxBool isReviewMode = false.obs;
  final RxBool isSubmittingQuiz = false.obs;
  final RxList<bool> visitedQuestions = <bool>[].obs;
  final RxList<bool> markedQuestions = <bool>[].obs;
  final RxString quizTitle = 'Practice Quiz'.obs;
  final RxString subjectTitle = ''.obs;
  final RxString lessonTitle = ''.obs;
  final RxInt timeLimitMinutes = 0.obs;
  final RxString currentQuizId = ''.obs;
  final RxBool isDailyQuiz = false.obs;
  final RxBool isMockTest = false.obs;
  final RxBool returnToLessonOnResultBack = false.obs;
  final RxMap<String, QuestionExplanationData> explanationByQuestionId =
      <String, QuestionExplanationData>{}.obs;
  final RxMap<String, bool> explanationLoadingByQuestionId =
      <String, bool>{}.obs;
  final RxMap<String, String> explanationErrorByQuestionId =
      <String, String>{}.obs;
  final RxMap<String, bool> explanationRegenerationAllowedByQuestionId =
      <String, bool>{}.obs;
  final RxMap<String, bool> explanationRegeneratingByQuestionId =
      <String, bool>{}.obs;

  List<QuizQuestion> questions = const [];

  /// The student's total XP as it stood when this quiz was loaded.
  ///
  /// The submit response does not reliably carry the XP the attempt earned,
  /// and re-computing it from the XP config on the client is wrong whenever
  /// the server applies its own rules (a repeat attempt that earns nothing,
  /// for instance). Diffing the real total against this baseline reports what
  /// was actually awarded. Null when the baseline could not be read.
  int? _xpBaselineTotal;

  @override
  void onInit() {
    super.onInit();
    questions = _demoQuestions;
    selectedAnswers.assignAll(List<int?>.filled(questions.length, null));
    visitedQuestions.assignAll(List<bool>.filled(questions.length, false));
    markedQuestions.assignAll(List<bool>.filled(questions.length, false));
    _markVisited(0);
    isReviewMode.value = Get.arguments?['reviewMode'] == true;
    unawaited(ExplanationCatalogService.instance.loadStyles());
  }

  int get totalQuestions => questions.length;

  int get answeredCount =>
      selectedAnswers.where((answer) => answer != null).length;

  int get markedCount => markedQuestions.where((isMarked) => isMarked).length;

  bool get isQuizCompleted => answeredCount == totalQuestions;

  double get answeredProgress =>
      totalQuestions == 0 ? 0 : answeredCount / totalQuestions;

  QuizQuestion get currentQuestion => questions[currentQuestionIndex.value];

  bool get hasAnswerKey =>
      questions.any((question) => question.correctOptionIndex != null);

  String get explanationType {
    if (isDailyQuiz.value) {
      return 'dailyQuiz';
    }
    if (isMockTest.value) {
      return 'mockTest';
    }
    return 'quiz';
  }

  bool get hasPreviousQuestion => currentQuestionIndex.value > 0;

  bool get hasNextQuestion => currentQuestionIndex.value < totalQuestions - 1;

  bool get currentQuestionHasAnswer =>
      selectedAnswers[currentQuestionIndex.value] != null;

  bool get isCurrentQuestionMarked =>
      markedQuestions.isNotEmpty && markedQuestions[currentQuestionIndex.value];

  String get progressLabel => '${(answeredProgress * 100).round()}% Done';

  String get formattedElapsedTime {
    final minutes = (elapsedSeconds.value ~/ 60).toString().padLeft(2, '0');
    final seconds = (elapsedSeconds.value % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void startQuiz() {
    elapsedSeconds.value = 0;
    isReviewMode.value = false;
    Get.to(() => const QuestionAnswerShowViews());
  }

  void loadQuiz({
    required String quizId,
    required String title,
    required String subjectTitle,
    required String lessonTitle,
    required List<QuizQuestion> questions,
    int timeLimitMinutes = 0,
    bool isDailyQuiz = false,
    bool isMockTest = false,
    bool returnToLessonOnResultBack = false,
  }) {
    currentQuizId.value = quizId;
    quizTitle.value = title;
    this.subjectTitle.value = subjectTitle;
    this.lessonTitle.value = lessonTitle;
    this.timeLimitMinutes.value = timeLimitMinutes;
    this.isDailyQuiz.value = isDailyQuiz;
    this.isMockTest.value = isMockTest;
    this.returnToLessonOnResultBack.value = returnToLessonOnResultBack;
    this.questions = questions.isEmpty ? const [] : questions;
    explanationByQuestionId.clear();
    explanationLoadingByQuestionId.clear();
    explanationErrorByQuestionId.clear();
    explanationRegenerationAllowedByQuestionId.clear();
    resetQuiz();

    // Fire-and-forget: taken now so submitting costs no extra round trip.
    _xpBaselineTotal = null;
    unawaited(_captureXpBaseline());
  }

  Future<void> _captureXpBaseline() async {
    _xpBaselineTotal = await _fetchTotalXp();
  }

  /// The student's lifetime XP as the server currently reports it.
  Future<int?> _fetchTotalXp() async {
    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.USER_XP,
      showLoader: false,
      fromJson: (json) => json,
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return null;
    }

    final data = (response.data as Map<String, dynamic>)['data'];
    if (data is! Map<String, dynamic>) {
      return null;
    }
    return (data['xp'] as num?)?.toInt();
  }

  void selectAnswer(int optionIndex) {
    if (isReviewMode.value) {
      return;
    }

    _markVisited(currentQuestionIndex.value);
    selectedAnswers[currentQuestionIndex.value] = optionIndex;
    selectedAnswers.refresh();
  }

  void goToQuestion(int index) {
    if (index < 0 || index >= totalQuestions) {
      return;
    }
    _markVisited(index);
    currentQuestionIndex.value = index;
  }

  void nextQuestion() {
    if (hasNextQuestion) {
      goToQuestion(currentQuestionIndex.value + 1);
    }
  }

  void previousQuestion() {
    if (hasPreviousQuestion) {
      goToQuestion(currentQuestionIndex.value - 1);
    }
  }

  void clearCurrentAnswer() {
    if (isReviewMode.value || totalQuestions == 0) {
      return;
    }
    _markVisited(currentQuestionIndex.value);
    selectedAnswers[currentQuestionIndex.value] = null;
    selectedAnswers.refresh();
  }

  void toggleMarkCurrentQuestion() {
    if (isReviewMode.value || totalQuestions == 0) {
      return;
    }
    _markVisited(currentQuestionIndex.value);
    markedQuestions[currentQuestionIndex.value] =
        !markedQuestions[currentQuestionIndex.value];
    markedQuestions.refresh();
  }

  void skipCurrentQuestion() {
    if (isReviewMode.value || totalQuestions == 0) {
      return;
    }
    _markVisited(currentQuestionIndex.value);
    if (hasNextQuestion) {
      nextQuestion();
    }
  }

  void saveAndNextQuestion() {
    if (isReviewMode.value || totalQuestions == 0) {
      return;
    }
    _markVisited(currentQuestionIndex.value);
    if (hasNextQuestion) {
      nextQuestion();
    }
  }

  void incrementTimer() {
    if (!isReviewMode.value) {
      elapsedSeconds.value++;
    }
  }

  int get score {
    var total = 0;
    for (var i = 0; i < questions.length; i++) {
      if (selectedAnswers[i] == questions[i].correctOptionIndex) {
        total += questions[i].marks;
      }
    }
    return total;
  }

  int get maxScore =>
      questions.fold<int>(0, (sum, question) => sum + question.marks);

  Future<void> submitQuiz() async {
    if (totalQuestions == 0 || isReviewMode.value || isSubmittingQuiz.value) {
      return;
    }

    if (!isDailyQuiz.value &&
        !isMockTest.value &&
        currentQuizId.value.isEmpty) {
      Get.snackbar(
        'Quiz Error',
        'Quiz information is missing. Please start again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isSubmittingQuiz.value = true;

    final response = await ApiService.instance.post<dynamic>(
      endpoint: isDailyQuiz.value
          ? ApiService.DAILY_QUIZZS_ATTEMPT
          : isMockTest.value
          ? ApiService.SUBMIT_MOCK_TEST.replaceFirst(':id', currentQuizId.value)
          : ApiService.SUBMIT_PRACTICE_QUIZZES.replaceFirst(
              ':id',
              currentQuizId.value,
            ),
      showLoader: false,
      fromJson: (json) => json,
      data: {
        'answers': List.generate(
          questions.length,
          (index) => {
            'questionId': questions[index].id,
            'selectedIndex': selectedAnswers[index],
          },
        ),
      },
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      isSubmittingQuiz.value = false;
      Get.snackbar(
        'Submit Failed',
        response.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final body = response.data as Map<String, dynamic>;
    final attemptJson = (body['data'] as Map<String, dynamic>?) ?? const {};
    final answerFeedbackJson =
        (attemptJson['answers'] as List<dynamic>? ?? const []);

    final feedbackByQuestionId = {
      for (final item in answerFeedbackJson)
        _safeText((item as Map<String, dynamic>)['questionId']):
            QuizAnswerFeedback.fromApi(item),
    };

    questions = questions.map((question) {
      final feedback = feedbackByQuestionId[question.id];
      if (feedback == null) {
        return question;
      }
      return question.copyWith(correctOptionIndex: feedback.correctIndex);
    }).toList();

    final xpEarned = await _resolveXpEarned(attemptJson, body);

    Get.put(
      QuizDailyResultController(
        attemptId: _safeText(attemptJson['attemptId']),
        score: (attemptJson['totalScore'] as num?)?.toInt() ?? 0,
        maxScore: (attemptJson['maxScore'] as num?)?.toInt() ?? maxScore,
        totalQuestions: totalQuestions,
        elapsedSeconds: elapsedSeconds.value,
        percentage: (attemptJson['percentage'] as num?)?.toDouble() ?? 0,
        passed: attemptJson['passed'] == true,
        rewardSource: isDailyQuiz.value
            ? QuizRewardSource.dailyQuiz
            : isMockTest.value
            ? QuizRewardSource.mockTest
            : QuizRewardSource.practiceTest,
        xpEarned: xpEarned,
        hasAnswerKey: true,
        feedback: feedbackByQuestionId,
        returnToLessonOnBack: returnToLessonOnResultBack.value,
      ),
      tag: 'daily_quiz_result',
    );

    // The attempt has moved the student's XP and streak, and it has changed
    // which subjects they are weak in — the dashboard's TTL-cached copies of
    // both are now wrong. Forced from here, at the one moment the numbers
    // actually change, so every quiz type and every way back to the Home tab
    // shows the new figures: the tab's own reload asks without `force` and
    // would sit on the 3-minute cache, which a quiz easily finishes inside.
    if (Get.isRegistered<DashboardTabbarController>()) {
      final dashboardController = Get.find<DashboardTabbarController>();
      unawaited(dashboardController.loadUserXp(force: true));
      unawaited(dashboardController.loadWeakAreas(force: true));
    }

    await AdService.instance.showQuizResultAdIfEnabled();
    isSubmittingQuiz.value = false;

    Get.to(() => const QuizDailyResult());
  }

  /// XP this attempt actually earned.
  ///
  /// Preference order: an explicit amount from the submit response, then the
  /// real change in the student's total, and only then null — which lets the
  /// result screen fall back to the XP config. The config is the weakest
  /// signal because it describes what an attempt is *worth*, not what the
  /// server awarded: a repeat practice attempt that earns nothing would still
  /// be advertised as a full reward.
  Future<int?> _resolveXpEarned(
    Map<String, dynamic> attemptJson,
    Map<String, dynamic> body,
  ) async {
    final reported = _readXpEarned(attemptJson) ?? _readXpEarned(body);
    if (reported != null) {
      return reported;
    }

    final baseline = _xpBaselineTotal;
    if (baseline == null) {
      return null;
    }

    final total = await _fetchTotalXp();
    if (total == null) {
      return null;
    }

    final earned = total - baseline;
    return earned < 0 ? 0 : earned;
  }

  void openReviewMode() {
    isReviewMode.value = true;
    currentQuestionIndex.value = 0;
    Get.to(
      () => const QuestionAnswerShowViews(),
      arguments: {'reviewMode': true},
    );
  }

  Future<void> fetchExplanation(
    QuizQuestion question, {
    bool force = false,
  }) async {
    if (!isReviewMode.value || question.id.isEmpty) {
      return;
    }

    if ((!force && explanationByQuestionId.containsKey(question.id)) ||
        explanationLoadingByQuestionId[question.id] == true) {
      return;
    }

    explanationErrorByQuestionId.remove(question.id);
    explanationLoadingByQuestionId[question.id] = true;

    final endpoint = ApiService.GET_QUESTION_EXPLANATION
        .replaceFirst(':type', explanationType)
        .replaceFirst(':questionId', question.id);

    final response = await ApiService.instance.get<dynamic>(
      endpoint: endpoint,
      showLoader: false,
      fromJson: (json) => json,
      requestTimeout: const Duration(seconds: 90),
    );

    explanationLoadingByQuestionId.remove(question.id);

    if (!response.success || response.data is! Map<String, dynamic>) {
      explanationErrorByQuestionId[question.id] = _explanationError(
        response.statusCode,
        response.message,
      );
      return;
    }

    final body = response.data as Map<String, dynamic>;
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      explanationErrorByQuestionId[question.id] =
          body['message']?.toString() ?? 'Unable to load explanation.';
      return;
    }

    final explanation = QuestionExplanationData.fromApi(data);
    if (explanation.explanation.isEmpty) {
      explanationErrorByQuestionId[question.id] =
          'Explanation is not available for this question.';
      return;
    }

    explanationByQuestionId[question.id] = explanation;
    explanationRegenerationAllowedByQuestionId[question.id] = true;
  }

  Future<void> seeAnotherExplanation(QuizQuestion question) async {
    final current = explanationByQuestionId[question.id];
    if (current == null ||
        current.explanationId.isEmpty ||
        explanationLoadingByQuestionId[question.id] == true) {
      return;
    }

    explanationErrorByQuestionId.remove(question.id);
    explanationLoadingByQuestionId[question.id] = true;
    final endpoint = ApiService.GET_ANOTHER_QUESTION_EXPLANATION
        .replaceFirst(':type', explanationType)
        .replaceFirst(':questionId', question.id);
    final response = await ApiService.instance.get<dynamic>(
      endpoint: endpoint,
      queryParameters: {'after': current.explanationId},
      showLoader: false,
      fromJson: (json) => json,
      requestTimeout: const Duration(seconds: 90),
    );
    explanationLoadingByQuestionId.remove(question.id);
    if (response.statusCode == 404) {
      explanationByQuestionId.remove(question.id);
      await fetchExplanation(question, force: true);
      return;
    }
    final data = _explanationData(response);
    if (data == null) {
      explanationErrorByQuestionId[question.id] = _explanationError(
        response.statusCode,
        response.message,
      );
      return;
    }
    explanationByQuestionId[question.id] = data;
  }

  Future<void> regenerateExplanation(
    QuizQuestion question,
    String style,
  ) async {
    if (style.isEmpty || explanationLoadingByQuestionId[question.id] == true) {
      return;
    }
    explanationErrorByQuestionId.remove(question.id);
    explanationLoadingByQuestionId[question.id] = true;
    explanationRegeneratingByQuestionId[question.id] = true;
    final endpoint = ApiService.REGENERATE_QUESTION_EXPLANATION
        .replaceFirst(':type', explanationType)
        .replaceFirst(':questionId', question.id);
    final response = await ApiService.instance.post<dynamic>(
      endpoint: endpoint,
      data: {'style': style},
      showLoader: false,
      fromJson: (json) => json,
      requestTimeout: const Duration(seconds: 90),
    );
    explanationLoadingByQuestionId.remove(question.id);
    explanationRegeneratingByQuestionId.remove(question.id);
    if (response.statusCode == 403) {
      explanationRegenerationAllowedByQuestionId[question.id] = false;
    }
    final data = _explanationData(response);
    if (data == null) {
      explanationErrorByQuestionId[question.id] = _explanationError(
        response.statusCode,
        response.message,
      );
      return;
    }
    explanationByQuestionId[question.id] = data;
  }

  void closeExplanation(QuizQuestion question) {
    explanationByQuestionId.remove(question.id);
    explanationErrorByQuestionId.remove(question.id);
    explanationRegenerationAllowedByQuestionId.remove(question.id);
    explanationRegeneratingByQuestionId.remove(question.id);
  }

  /// Drops the loaded quiz entirely, not just the answers.
  ///
  /// This controller is permanent, so a class change would otherwise leave the
  /// previous class's questions, title and quiz id sitting in memory ready to
  /// be shown again.
  void clearSession() {
    questions = const [];
    currentQuizId.value = '';
    quizTitle.value = 'Practice Quiz';
    subjectTitle.value = '';
    lessonTitle.value = '';
    timeLimitMinutes.value = 0;
    isDailyQuiz.value = false;
    isMockTest.value = false;
    returnToLessonOnResultBack.value = false;
    explanationByQuestionId.clear();
    explanationLoadingByQuestionId.clear();
    explanationErrorByQuestionId.clear();
    explanationRegenerationAllowedByQuestionId.clear();
    explanationRegeneratingByQuestionId.clear();
    resetQuiz();
  }

  void resetQuiz() {
    currentQuestionIndex.value = 0;
    elapsedSeconds.value = 0;
    isReviewMode.value = false;
    selectedAnswers.assignAll(List<int?>.filled(questions.length, null));
    visitedQuestions.assignAll(List<bool>.filled(questions.length, false));
    markedQuestions.assignAll(List<bool>.filled(questions.length, false));
    _markVisited(0);
  }

  void _markVisited(int index) {
    if (index < 0 || index >= visitedQuestions.length) {
      return;
    }
    if (visitedQuestions[index]) {
      return;
    }
    visitedQuestions[index] = true;
    visitedQuestions.refresh();
  }
}

QuestionExplanationData? _explanationData(ApiResponse<dynamic> response) {
  if (!response.success || response.data is! Map<String, dynamic>) return null;
  final data = (response.data as Map<String, dynamic>)['data'];
  if (data is! Map<String, dynamic>) return null;
  final explanation = QuestionExplanationData.fromApi(data);
  return explanation.explanation.isEmpty ? null : explanation;
}

String _explanationError(int statusCode, String message) {
  return switch (statusCode) {
    400 => 'We could not load this explanation. Please try again.',
    404 => 'This question is no longer available.',
    422 => "We can't explain this question yet.",
    503 ||
    504 => "Explanations aren't available right now. Please try again later.",
    _ => message.isEmpty ? 'Unable to load explanation.' : message,
  };
}

class QuizAnswerFeedback {
  const QuizAnswerFeedback({
    required this.questionId,
    required this.selectedIndex,
    required this.correctIndex,
    required this.isCorrect,
    required this.marks,
    required this.marksAwarded,
  });

  final String questionId;
  final int? selectedIndex;
  final int correctIndex;
  final bool isCorrect;
  final int marks;
  final int marksAwarded;

  factory QuizAnswerFeedback.fromApi(Map<String, dynamic> json) {
    return QuizAnswerFeedback(
      questionId: _safeText(json['questionId']),
      selectedIndex: (json['selectedIndex'] as num?)?.toInt(),
      correctIndex: (json['correctIndex'] as num?)?.toInt() ?? 0,
      isCorrect: json['isCorrect'] == true,
      marks: (json['marks'] as num?)?.toInt() ?? 0,
      marksAwarded: (json['marksAwarded'] as num?)?.toInt() ?? 0,
    );
  }
}

const List<QuizQuestion> _demoQuestions = [
  QuizQuestion(
    id: '1',
    question: 'What is the value of 8 x 7?',
    options: ['54', '56', '64', '58'],
    correctOptionIndex: 1,
    tags: ['Math', 'Multiplication', 'Speed Drill'],
    marks: 1,
  ),
  QuizQuestion(
    id: '2',
    question: 'Which planet is known as the Red Planet?',
    options: ['Venus', 'Mars', 'Jupiter', 'Mercury'],
    correctOptionIndex: 1,
    tags: ['Science', 'Space', 'Planets'],
    marks: 1,
  ),
  QuizQuestion(
    id: '3',
    question: 'What is the synonym of "rapid"?',
    options: ['Slow', 'Quick', 'Silent', 'Large'],
    correctOptionIndex: 1,
    tags: ['English', 'Vocabulary', 'Words'],
    marks: 1,
  ),
  QuizQuestion(
    id: '4',
    question: 'Who wrote the Indian National Anthem?',
    options: [
      'Rabindranath Tagore',
      'Bankim Chandra Chattopadhyay',
      'Sarojini Naidu',
      'Subhas Chandra Bose',
    ],
    correctOptionIndex: 0,
    tags: ['GK', 'India', 'History'],
    marks: 1,
  ),
  QuizQuestion(
    id: '5',
    question:
        'If a cell has a higher concentration of solutes than the surrounding environment, what direction will water typically move?',
    options: [
      'Water will move into the cell.',
      'Water will move out of the cell.',
      'Water will remain stationary.',
      'Solutes will move, not water.',
    ],
    correctOptionIndex: 0,
    tags: ['Biology', 'Cellular Processes', 'Osmosis'],
    marks: 1,
  ),
  QuizQuestion(
    id: '6',
    question:
        'Which gas do plants absorb from the atmosphere during photosynthesis?',
    options: ['Oxygen', 'Nitrogen', 'Carbon dioxide', 'Hydrogen'],
    correctOptionIndex: 2,
    tags: ['Science', 'Plants', 'Photosynthesis'],
    marks: 1,
  ),
  QuizQuestion(
    id: '7',
    question: 'What is 25% of 200?',
    options: ['25', '40', '50', '75'],
    correctOptionIndex: 2,
    tags: ['Math', 'Percentages', 'Practice'],
    marks: 1,
  ),
  QuizQuestion(
    id: '8',
    question: 'Which part of speech is the word "beautiful"?',
    options: ['Verb', 'Adjective', 'Noun', 'Pronoun'],
    correctOptionIndex: 1,
    tags: ['English', 'Grammar', 'Adjectives'],
    marks: 1,
  ),
  QuizQuestion(
    id: '9',
    question: 'The Battle of Plassey took place in which year?',
    options: ['1757', '1857', '1947', '1764'],
    correctOptionIndex: 0,
    tags: ['History', 'India', 'Battle'],
    marks: 1,
  ),
  QuizQuestion(
    id: '10',
    question: 'Which number is a prime number?',
    options: ['21', '27', '29', '35'],
    correctOptionIndex: 2,
    tags: ['Math', 'Prime Numbers', 'Concept'],
    marks: 1,
  ),
];

String _safeText(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _extractImageUrl(dynamic imageData) {
  if (imageData is String) {
    return imageData.trim();
  }
  if (imageData is Map<String, dynamic>) {
    // Try common image URL field names
    if (imageData['url'] is String) {
      return (imageData['url'] as String).trim();
    }
    if (imageData['imageUrl'] is String) {
      return (imageData['imageUrl'] as String).trim();
    }
    if (imageData['link'] is String) {
      return (imageData['link'] as String).trim();
    }
    if (imageData['src'] is String) {
      return (imageData['src'] as String).trim();
    }
  }
  return '';
}

/// Reads the XP an attempt earned, if the payload states it.
///
/// A bare `xp` number is deliberately not accepted: across these endpoints it
/// is the student's new lifetime total, and reading it as the reward showed
/// results like "+1250 XP Gained". Only a nested `xp` object is read, and only
/// for its explicitly-named earned field.
int? _readXpEarned(Map<String, dynamic> json) {
  const keys = ['xpEarned', 'earnedXp', 'xpAwarded', 'awardedXp', 'xpGained'];

  for (final key in keys) {
    final value = json[key];
    if (value is num) {
      return value.toInt();
    }
  }

  final nested = json['xp'];
  if (nested is Map<String, dynamic>) {
    return _readXpEarned(nested);
  }
  return null;
}

String _stripHtml(String value) {
  return value
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
