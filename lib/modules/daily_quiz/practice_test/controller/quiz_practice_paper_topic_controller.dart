import 'package:get/get.dart';

import '../../controller/question_answer_show_controller.dart';
import '../../views/question_answer_show_views.dart';
import 'quiz_practice_paper_subject_controller.dart';

class QuizPracticePaperTopicController extends GetxController {
  late final QuestionAnswerShowController quizController;

  @override
  void onInit() {
    super.onInit();
    quizController = Get.isRegistered<QuestionAnswerShowController>()
        ? Get.find<QuestionAnswerShowController>()
        : Get.put(QuestionAnswerShowController());
  }

  void startPractice({
    required PracticeQuizSubjectData subject,
    required PracticeQuizTopicData topic,
  }) {
    quizController.resetQuiz();
    Get.to(
      () => const QuestionAnswerShowViews(),
      arguments: {
        'subjectTitle': subject.title,
        'topicTitle': topic.title,
        'reviewMode': false,
      },
    );
  }
}
