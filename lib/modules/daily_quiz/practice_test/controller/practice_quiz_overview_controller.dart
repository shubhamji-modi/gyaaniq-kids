import 'package:get/get.dart';

import '../../../../core/service/api_service.dart';
import '../../../learn/chapter/controller/learn_chapter_controller.dart';
import '../../controller/question_answer_show_controller.dart';
import '../../views/question_answer_show_views.dart';

class PracticeQuizOverviewController extends GetxController {
  PracticeQuizOverviewController({
    required this.subject,
    required this.chapter,
    this.returnToLessonOnResultBack = false,
  });

  final LearnSubjectModel subject;
  final LearnChapterModel chapter;
  final bool returnToLessonOnResultBack;

  final RxBool isLoading = true.obs;
  final RxBool isStartingQuiz = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<PracticeQuizSummary> quizzes = <PracticeQuizSummary>[].obs;

  late final QuestionAnswerShowController questionController;

  PracticeQuizSummary? get selectedQuiz =>
      quizzes.isNotEmpty ? quizzes.first : null;

  @override
  void onInit() {
    super.onInit();
    questionController = Get.isRegistered<QuestionAnswerShowController>()
        ? Get.find<QuestionAnswerShowController>()
        : Get.put(QuestionAnswerShowController());
    loadQuizzes();
  }

  Future<void> loadQuizzes() async {
    isLoading.value = true;
    errorMessage.value = '';

    final response = await ApiService.instance.post<dynamic>(
      endpoint: ApiService.FETCH_QUIZZES,
      showLoader: false,
      fromJson: (json) => json,
      data: {
        'classLevel': subject.classLevel,
        'subjectId': subject.id,
        'lessonId': chapter.id,
      },
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      quizzes.clear();
      errorMessage.value = response.message;
      isLoading.value = false;
      return;
    }

    final body = response.data as Map<String, dynamic>;
    final quizzesJson =
        ((body['data'] as Map<String, dynamic>?)?['quizzes'])
            as List<dynamic>? ??
        const [];

    quizzes.assignAll(
      quizzesJson.map(
        (item) => PracticeQuizSummary.fromApi(item as Map<String, dynamic>),
      ),
    );

    errorMessage.value = quizzes.isEmpty
        ? 'No quizzes available right now.'
        : '';
    isLoading.value = false;
  }

  Future<void> startQuiz() async {
    final quiz = selectedQuiz;
    if (quiz == null) {
      return;
    }

    isStartingQuiz.value = true;

    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.FETCH_SINGLE_QUIZZES.replaceFirst(':id', quiz.id),
      showLoader: false,
      fromJson: (json) => json,
    );

    isStartingQuiz.value = false;

    if (!response.success || response.data is! Map<String, dynamic>) {
      Get.snackbar(
        'Quiz Error',
        response.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final body = response.data as Map<String, dynamic>;
    final quizJson = (body['data'] as Map<String, dynamic>?) ?? const {};
    final questionList =
        (quizJson['questions'] as List<dynamic>? ?? const [])
            .map(
              (item) => QuizQuestion.fromApi(
                item as Map<String, dynamic>,
                subjectTitle: subject.title,
              ),
            )
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

    if (questionList.isEmpty) {
      Get.snackbar(
        'No Questions',
        'This quiz does not have any questions yet.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    questionController.loadQuiz(
      quizId: _safeText(quizJson['_id'], fallback: quiz.id),
      title: _safeText(quizJson['title'], fallback: quiz.title),
      subjectTitle: subject.title,
      lessonTitle: chapter.title,
      questions: questionList,
      timeLimitMinutes: (quizJson['timeLimitMinutes'] as num?)?.toInt() ?? 0,
      returnToLessonOnResultBack: returnToLessonOnResultBack,
    );

    Get.to(() => const QuestionAnswerShowViews());
  }
}

class PracticeQuizSummary {
  const PracticeQuizSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.classLevel,
    required this.teacherName,
    required this.timeLimitMinutes,
    required this.passingPercentage,
    required this.totalMarks,
    required this.questionCount,
  });

  final String id;
  final String title;
  final String description;
  final String classLevel;
  final String teacherName;
  final int timeLimitMinutes;
  final int passingPercentage;
  final int totalMarks;
  final int questionCount;

  factory PracticeQuizSummary.fromApi(Map<String, dynamic> json) {
    return PracticeQuizSummary(
      id: _safeText(json['_id']),
      title: _safeText(json['title'], fallback: 'Untitled Quiz'),
      description: _stripHtml(_safeText(json['description'])),
      classLevel: _safeText(json['classLevel']),
      teacherName: _safeText(
        (json['teacher'] as Map<String, dynamic>?)?['name'],
      ),
      timeLimitMinutes: (json['timeLimitMinutes'] as num?)?.toInt() ?? 0,
      passingPercentage: (json['passingPercentage'] as num?)?.toInt() ?? 0,
      totalMarks: (json['totalMarks'] as num?)?.toInt() ?? 0,
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
    );
  }

  String get timeLimitLabel =>
      timeLimitMinutes <= 0 ? 'No Limit' : '$timeLimitMinutes Mins';

  String get metaLabel => '$questionCount Questions · $timeLimitLabel';
}

String _safeText(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
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
