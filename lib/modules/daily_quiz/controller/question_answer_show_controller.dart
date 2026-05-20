import 'package:get/get.dart';

import '../controller/quiz_daily_result_controller.dart';
import '../views/question_answer_show_views.dart';
import '../views/quiz_daily_result.dart';

class QuizQuestion {
  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    required this.tags,
  });

  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final List<String> tags;
}

class QuestionAnswerShowController extends GetxController {
  final RxInt currentQuestionIndex = 0.obs;
  final RxList<int?> selectedAnswers = <int?>[].obs;
  final RxInt elapsedSeconds = 0.obs;
  final RxBool isReviewMode = false.obs;

  late final List<QuizQuestion> questions;

  @override
  void onInit() {
    super.onInit();
    questions = _demoQuestions;
    selectedAnswers.assignAll(List<int?>.filled(questions.length, null));
    isReviewMode.value = Get.arguments?['reviewMode'] == true;
  }

  int get totalQuestions => questions.length;

  int get answeredCount => selectedAnswers.where((answer) => answer != null).length;

  bool get isQuizCompleted => answeredCount == totalQuestions;

  double get answeredProgress =>
      totalQuestions == 0 ? 0 : answeredCount / totalQuestions;

  QuizQuestion get currentQuestion => questions[currentQuestionIndex.value];

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
        total++;
      }
    }
    return total;
  }

  void submitQuiz() {
    if (!isQuizCompleted || isReviewMode.value) {
      return;
    }

    Get.put(
      QuizDailyResultController(
        score: score,
        totalQuestions: totalQuestions,
        elapsedSeconds: elapsedSeconds.value,
      ),
      tag: 'daily_quiz_result',
    );

    Get.to(() => const QuizDailyResult());
  }

  void openReviewMode() {
    isReviewMode.value = true;
    currentQuestionIndex.value = 0;
    Get.to(() => const QuestionAnswerShowViews(), arguments: {'reviewMode': true});
  }

  void resetQuiz() {
    currentQuestionIndex.value = 0;
    elapsedSeconds.value = 0;
    isReviewMode.value = false;
    selectedAnswers.assignAll(List<int?>.filled(questions.length, null));
  }
}

const List<QuizQuestion> _demoQuestions = [
  QuizQuestion(
    question: 'What is the value of 8 x 7?',
    options: ['54', '56', '64', '58'],
    correctOptionIndex: 1,
    tags: ['Math', 'Multiplication', 'Speed Drill'],
  ),
  QuizQuestion(
    question: 'Which planet is known as the Red Planet?',
    options: ['Venus', 'Mars', 'Jupiter', 'Mercury'],
    correctOptionIndex: 1,
    tags: ['Science', 'Space', 'Planets'],
  ),
  QuizQuestion(
    question: 'What is the synonym of "rapid"?',
    options: ['Slow', 'Quick', 'Silent', 'Large'],
    correctOptionIndex: 1,
    tags: ['English', 'Vocabulary', 'Words'],
  ),
  QuizQuestion(
    question: 'Who wrote the Indian National Anthem?',
    options: [
      'Rabindranath Tagore',
      'Bankim Chandra Chattopadhyay',
      'Sarojini Naidu',
      'Subhas Chandra Bose',
    ],
    correctOptionIndex: 0,
    tags: ['GK', 'India', 'History'],
  ),
  QuizQuestion(
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
  ),
  QuizQuestion(
    question: 'Which gas do plants absorb from the atmosphere during photosynthesis?',
    options: ['Oxygen', 'Nitrogen', 'Carbon dioxide', 'Hydrogen'],
    correctOptionIndex: 2,
    tags: ['Science', 'Plants', 'Photosynthesis'],
  ),
  QuizQuestion(
    question: 'What is 25% of 200?',
    options: ['25', '40', '50', '75'],
    correctOptionIndex: 2,
    tags: ['Math', 'Percentages', 'Practice'],
  ),
  QuizQuestion(
    question: 'Which part of speech is the word "beautiful"?',
    options: ['Verb', 'Adjective', 'Noun', 'Pronoun'],
    correctOptionIndex: 1,
    tags: ['English', 'Grammar', 'Adjectives'],
  ),
  QuizQuestion(
    question: 'The Battle of Plassey took place in which year?',
    options: ['1757', '1857', '1947', '1764'],
    correctOptionIndex: 0,
    tags: ['History', 'India', 'Battle'],
  ),
  QuizQuestion(
    question: 'Which number is a prime number?',
    options: ['21', '27', '29', '35'],
    correctOptionIndex: 2,
    tags: ['Math', 'Prime Numbers', 'Concept'],
  ),
];
