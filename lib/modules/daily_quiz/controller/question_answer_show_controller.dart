import '../../../core/service/api_service.dart';
import '../../../core/models/xp_config_data.dart';
import 'package:get/get.dart';

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
  });

  final String id;
  final String question;
  final List<String> options;
  final int? correctOptionIndex;
  final List<String> tags;
  final int order;
  final int marks;

  factory QuizQuestion.fromApi(
    Map<String, dynamic> json, {
    required String subjectTitle,
  }) {
    final difficulty = _safeText(json['difficulty'], fallback: 'Question');
    final marks = (json['marks'] as num?)?.toInt() ?? 1;

    return QuizQuestion(
      id: _safeText(json['_id']),
      question: _stripHtml(_safeText(json['questionText'])),
      options: (json['options'] as List<dynamic>? ?? const [])
          .map((option) => _stripHtml(_safeText(option)))
          .toList(),
      correctOptionIndex: null,
      tags: [
        subjectTitle,
        difficulty.toUpperCase(),
        '$marks Mark${marks > 1 ? 's' : ''}',
      ],
      order: (json['order'] as num?)?.toInt() ?? 0,
      marks: marks,
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
  }) {
    return QuizQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? this.options,
      correctOptionIndex: correctOptionIndex ?? this.correctOptionIndex,
      tags: tags ?? this.tags,
      order: order ?? this.order,
      marks: marks ?? this.marks,
    );
  }
}

class QuestionAnswerShowController extends GetxController {
  final RxInt currentQuestionIndex = 0.obs;
  final RxList<int?> selectedAnswers = <int?>[].obs;
  final RxInt elapsedSeconds = 0.obs;
  final RxBool isReviewMode = false.obs;
  final RxBool isSubmittingQuiz = false.obs;
  final RxString quizTitle = 'Practice Quiz'.obs;
  final RxString subjectTitle = ''.obs;
  final RxString lessonTitle = ''.obs;
  final RxInt timeLimitMinutes = 0.obs;
  final RxString currentQuizId = ''.obs;
  final RxBool isDailyQuiz = false.obs;
  final RxBool isMockTest = false.obs;

  List<QuizQuestion> questions = const [];

  @override
  void onInit() {
    super.onInit();
    questions = _demoQuestions;
    selectedAnswers.assignAll(List<int?>.filled(questions.length, null));
    isReviewMode.value = Get.arguments?['reviewMode'] == true;
  }

  int get totalQuestions => questions.length;

  int get answeredCount =>
      selectedAnswers.where((answer) => answer != null).length;

  bool get isQuizCompleted => answeredCount == totalQuestions;

  double get answeredProgress =>
      totalQuestions == 0 ? 0 : answeredCount / totalQuestions;

  QuizQuestion get currentQuestion => questions[currentQuestionIndex.value];

  bool get hasAnswerKey =>
      questions.any((question) => question.correctOptionIndex != null);

  bool get hasPreviousQuestion => currentQuestionIndex.value > 0;

  bool get hasNextQuestion => currentQuestionIndex.value < totalQuestions - 1;

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
  }) {
    currentQuizId.value = quizId;
    quizTitle.value = title;
    this.subjectTitle.value = subjectTitle;
    this.lessonTitle.value = lessonTitle;
    this.timeLimitMinutes.value = timeLimitMinutes;
    this.isDailyQuiz.value = isDailyQuiz;
    this.isMockTest.value = isMockTest;
    this.questions = questions.isEmpty ? const [] : questions;
    resetQuiz();
  }

  void selectAnswer(int optionIndex) {
    if (isReviewMode.value) {
      return;
    }

    selectedAnswers[currentQuestionIndex.value] = optionIndex;
    selectedAnswers.refresh();
  }

  void goToQuestion(int index) {
    if (index < 0 || index >= totalQuestions) {
      return;
    }
    currentQuestionIndex.value = index;
  }

  void nextQuestion() {
    if (hasNextQuestion) {
      currentQuestionIndex.value++;
    }
  }

  void previousQuestion() {
    if (hasPreviousQuestion) {
      currentQuestionIndex.value--;
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

    isSubmittingQuiz.value = false;

    if (!response.success || response.data is! Map<String, dynamic>) {
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
        xpEarned: _readXpEarned(attemptJson) ?? _readXpEarned(body),
        hasAnswerKey: true,
        feedback: feedbackByQuestionId,
      ),
      tag: 'daily_quiz_result',
    );

    Get.to(() => const QuizDailyResult());
  }

  void openReviewMode() {
    isReviewMode.value = true;
    currentQuestionIndex.value = 0;
    Get.to(
      () => const QuestionAnswerShowViews(),
      arguments: {'reviewMode': true},
    );
  }

  void resetQuiz() {
    currentQuestionIndex.value = 0;
    elapsedSeconds.value = 0;
    isReviewMode.value = false;
    selectedAnswers.assignAll(List<int?>.filled(questions.length, null));
  }
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

int? _readXpEarned(Map<String, dynamic> json) {
  const keys = ['xpEarned', 'earnedXp', 'xpAwarded', 'awardedXp', 'xp'];

  for (final key in keys) {
    final value = json[key];
    if (value is num) {
      return value.toInt();
    }
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
