import 'package:get/get.dart';

import '../../modules/dashboard_vc/controllers/dashboard_tabbar_controller.dart';
import '../../modules/daily_quiz/controller/question_answer_show_controller.dart';
import '../../modules/fun_fact/controller/fun_fact_controller.dart';
import '../../modules/my_course/views/my_course_data.dart';
import 'app_features_service.dart';
import 'learn_progress_refresh_service.dart';

/// Brings the app back to a clean slate after the student changes class.
///
/// Almost everything on screen — learning progress, XP, accuracy, subjects,
/// fun facts, tests, quiz history — belongs to one class. None of it is
/// invalidated by the profile update itself, so without this the new class is
/// shown with the previous class's numbers until each cache happens to expire.
///
/// Caches are emptied before the refetch, so a slow network shows an empty or
/// zero state rather than stale data from the class the student just left.
class ClassChangeService {
  const ClassChangeService._();

  static Future<void> applyClassChange() async {
    // Sections are switched on per class, so the previous class's answer is
    // stale from here on. Awaited: the dashboard rebuilds right after.
    await AppFeaturesService.instance.refresh();

    // Subject-keyed and quiz-keyed session state first: these hold the old
    // class's content and would otherwise be replayed while the new data is
    // still in flight.
    if (Get.isRegistered<FunFactController>()) {
      await FunFactController.instance.clearCache();
    }
    if (Get.isRegistered<QuestionAnswerShowController>()) {
      QuestionAnswerShowController.instance.clearSession();
    }
    MyCourseRepository.resetProgress();

    // Lets any open Learn screen rebuild against the new class.
    LearnProgressRefreshService.instance.notifyRefresh();

    if (Get.isRegistered<DashboardTabbarController>()) {
      await Get.find<DashboardTabbarController>().resetForClassChange();
    }
  }
}
