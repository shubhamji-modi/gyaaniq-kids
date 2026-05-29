import 'package:get/get.dart';

import '../../../learn/chapter/controller/learn_chapter_controller.dart';
import '../Views/practice_quiz_overview.dart';

class QuizPracticePaperTopicController extends GetxController {
  void startPractice({
    required LearnSubjectModel subject,
    required LearnChapterModel chapter,
  }) {
    Get.to(
      () => PracticeQuizOverviewViews(subject: subject, chapter: chapter),
    );
  }
}
