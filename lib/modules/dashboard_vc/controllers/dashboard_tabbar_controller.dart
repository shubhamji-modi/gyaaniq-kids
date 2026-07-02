import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/data/user_profile_provider.dart';
import '../../../core/service/api_service.dart';
import '../../../core/service/session_manager.dart';
import '../../../core/theme/appcolors.dart';
import '../../learn/chapter/controller/learn_chapter_controller.dart';
import '../../menubar/download/views/menubar_download_views.dart';
import '../../learn/chapter/views/learn_chapter_views.dart';
import '../../learn/chapter/views/learn_subject_views.dart';
import '../../learn/attendance/controller/learn_attendance_controller.dart';
import '../../learn/attendance/views/learn_attendance_views.dart';
import '../../learn/doubt_solve/views/learn_doubt_solve_views.dart';
import '../../learn/e_book/views/learn_ebook_views.dart';
import '../../learn/homework/views/learn_homework_views.dart';
import '../../learn/notes/views/learn_notes_views.dart';
import '../../menubar/xp_and_streak/xp_and_streak_show_views.dart';
import '../../../core/values/constants.dart';
import '../../../routes/app_routes.dart';

class DashboardTabbarController extends GetxController {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final RxInt currentTabIndex = 0.obs;
  final RxBool isLoadingDashboardSummary = true.obs;
  final RxBool isLoadingLearnSubjects = true.obs;
  final RxString dashboardSummaryError = ''.obs;
  final RxString learnSubjectsError = ''.obs;
  final RxBool isLoadingMockTests = true.obs;
  final RxString mockTestsError = ''.obs;
  final RxBool isLoadingDailyQuizAnalytics = true.obs;
  final RxString dailyQuizAnalyticsError = ''.obs;
  final RxBool isLoadingLeaderboardSummary = true.obs;
  final RxString leaderboardSummaryError = ''.obs;
  final RxBool isLoadingWeakAreas = true.obs;
  final RxString weakAreasError = ''.obs;
  final RxBool isLoadingUserXp = true.obs;
  final RxString userXpError = ''.obs;
  final RxBool isLoadingLiveClasses = true.obs;
  final RxString liveClassesError = ''.obs;
  final RxBool isLoadingAttendanceSummary = true.obs;
  final RxString attendanceSummaryError = ''.obs;
  final RxList<SubjectCardData> learnSubjects = <SubjectCardData>[].obs;
  final RxList<MockTestCardData> mockTests = <MockTestCardData>[].obs;
  final RxList<DailyQuizAnalyticsDayData> dailyQuizAnalytics =
      <DailyQuizAnalyticsDayData>[].obs;
  final Rx<LeaderboardStripData> leaderboardSummary =
      const LeaderboardStripData().obs;
  final Rx<WeakAreasSummaryData> weakAreasSummary =
      const WeakAreasSummaryData().obs;
  final Rx<UserXpSummaryData> userXpSummary = const UserXpSummaryData().obs;
  final RxList<LiveClassScheduleData> liveClassSchedules =
      <LiveClassScheduleData>[].obs;
  final Rx<DashboardLessonSummary> lessonSummary =
      const DashboardLessonSummary().obs;
  final Rx<AttendanceSummaryModel> attendanceSummary =
      AttendanceSummaryModel.empty().obs;
  Timer? _liveClassClockTimer;
  bool _isLoggingOut = false;

  final String studentName = 'Sarah!';
  final String studentClassBoard = 'CLASS 10 • CBSE BOARD';
  final String appBuild = 'App Build: v1.0.2';
  bool _isReloadingHomeTabData = false;

  final List<DashboardNavItemData> navItems = const [
    DashboardNavItemData(label: 'Home', icon: Icons.home_rounded),
    DashboardNavItemData(label: 'Learn', icon: Icons.menu_book_rounded),
    DashboardNavItemData(label: 'Quiz', icon: Icons.quiz_outlined),
    DashboardNavItemData(label: 'Live', icon: Icons.ondemand_video_outlined),
    DashboardNavItemData(label: 'Profile', icon: Icons.person_outline_rounded),
  ];

  String get chaptersSubtitle {
    if (isLoadingDashboardSummary.value) {
      return 'Loading chapters...';
    }
    if (dashboardSummaryError.value.isNotEmpty) {
      return 'Tap to refresh chapter summary';
    }

    final remaining = lessonSummary.value.notStarted;
    if (remaining <= 0) {
      return 'All chapters reviewed';
    }
    return '$remaining Chapter${remaining == 1 ? '' : 's'} left to review';
  }

  List<StudyToolData> get studyTools => [
    StudyToolData(
      title: 'Chapters',
      subtitle: chaptersSubtitle,
      icon: Icons.import_contacts_rounded,
      accent: Color(0xFF4A4FD9),
      iconBackground: Color(0xFFE5E6FF),
    ),
    const StudyToolData(
      title: 'Notes',
      subtitle: 'View all shared class notes',
      icon: Icons.note_alt_outlined,
      accent: Color(0xFFFFA615),
      iconBackground: Color(0xFFFFE6B7),
    ),
    const StudyToolData(
      title: 'Homework',
      subtitle: 'Keep learning daily',
      icon: Icons.assignment_outlined,
      accent: Color(0xFF7E2AD9),
      iconBackground: Color(0xFFEAD7FF),
    ),
    // const StudyToolData(
    //   title: 'Doubt Solve',
    //   subtitle: 'Chat with AI or Teachers',
    //   icon: Icons.live_help_outlined,
    //   accent: Color(0xFFC91F1F),
    //   iconBackground: Color(0xFFFFDEDE),
    // ),
    const StudyToolData(
      title: 'E-Book',
      subtitle: 'Access digital textbook',
      icon: Icons.library_books_outlined,
      accent: Color(0xFF4A4FD9),
      iconBackground: Color(0xFFF0F1F5),
    ),
    StudyToolData(
      title: 'Attendance',
      subtitle: attendanceSubtitle,
      icon: Icons.calendar_month_outlined,
      accent: Color(0xFF6366F1),
      iconBackground: Color(0xFFE2E7FF),
    ),
  ];

  String get attendanceSubtitle {
    if (isLoadingAttendanceSummary.value) {
      return 'Loading attendance...';
    }
    if (attendanceSummaryError.value.isNotEmpty) {
      return 'Tap to view attendance';
    }
    final summary = attendanceSummary.value;
    if (summary.total == 0) {
      return 'No attendance yet';
    }
    return '${summary.percentage.toStringAsFixed(2)}% this month';
  }

  final List<PreviousResultData> previousResults = const [
    PreviousResultData(
      title: 'Algebra Unit Test',
      meta: 'Oct 24 • 15 questions',
      scoreText: '85%',
      icon: Icons.edit_note_rounded,
      iconBackground: Color(0xFFFFE2E2),
      accent: Color(0xFFEF4444),
    ),
    PreviousResultData(
      title: 'Plant Cell Quiz',
      meta: 'Oct 22 • 10 questions',
      scoreText: '100%',
      icon: Icons.science_outlined,
      iconBackground: Color(0xFFF0DEFF),
      accent: Color(0xFF8B5CF6),
    ),
  ];

  final List<ProfileMenuData> profileMenuItems = const [
    ProfileMenuData(title: 'Leaderboard', icon: Icons.leaderboard_outlined),
    ProfileMenuData(title: 'My Course', icon: Icons.import_contacts_rounded),
    ProfileMenuData(title: 'Downloads', icon: Icons.download_outlined),
    ProfileMenuData(
      title: 'Terms of Service',
      icon: Icons.description_outlined,
    ),
    ProfileMenuData(
      title: 'Privacy Shield',
      icon: Icons.verified_user_outlined,
    ),
    ProfileMenuData(
      title: 'XP & Streak Settings',
      icon: Icons.local_fire_department_outlined,
      color: Color(0xFF4A4FD9),
    ),
    ProfileMenuData(
      title: 'Sign Out',
      icon: Icons.logout_rounded,
      color: Color(0xFFC81E1E),
    ),
    ProfileMenuData(
      title: 'Delete Account',
      icon: Icons.auto_delete_sharp,
      color: Color(0xFFC81E1E),
    ),
  ];

  void changeTab(int index) {
    currentTabIndex.value = index;
    if (index == 0) {
      reloadHomeTabData();
      return;
    }
    if (index == 3 &&
        liveClassSchedules.isEmpty &&
        !isLoadingLiveClasses.value) {
      loadLiveClasses();
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
    _liveClassClockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (currentTabIndex.value == 3 && liveClassSchedules.isNotEmpty) {
        liveClassSchedules.refresh();
      }
    });
  }

  @override
  void onClose() {
    _liveClassClockTimer?.cancel();
    super.onClose();
  }

  Future<void> loadDashboardData() async {
    await reloadHomeTabData();
  }

  Future<void> reloadHomeTabData() async {
    if (_isReloadingHomeTabData) {
      return;
    }

    _isReloadingHomeTabData = true;
    try {
      await _loadProgressSummary();
      await _loadLearnSubjects();
      await loadMockTests();
      await loadDailyQuizAnalytics();
      await loadLeaderboardSummary();
      await loadWeakAreas();
      await loadUserXp();
      await loadLiveClasses();
      await loadAttendanceSummary();
    } finally {
      _isReloadingHomeTabData = false;
    }
  }

  Future<void> loadAttendanceSummary() async {
    isLoadingAttendanceSummary.value = true;
    attendanceSummaryError.value = '';

    final now = DateTime.now();
    final month = _formatAttendanceMonth(now);
    final from = '$month-01';
    final to =
        '$month-${DateUtils.getDaysInMonth(now.year, now.month).toString().padLeft(2, '0')}';

    final responses = await Future.wait([
      LearnAttendanceRepository.fetchMonthlyAttendance(month),
      LearnAttendanceRepository.fetchAttendanceSummary(from: from, to: to),
    ]);

    final monthResponse = responses[0] as ApiResponse<List<AttendanceDayModel>>;
    final summaryResponse = responses[1] as ApiResponse<AttendanceSummaryModel>;

    isLoadingAttendanceSummary.value = false;

    if (summaryResponse.success) {
      attendanceSummary.value =
          summaryResponse.data ?? AttendanceSummaryModel.empty();
      return;
    }

    if (monthResponse.success) {
      attendanceSummary.value = AttendanceSummaryModel.fromDays(
        monthResponse.data ?? const <AttendanceDayModel>[],
      );
      return;
    }

    attendanceSummary.value = AttendanceSummaryModel.empty();
    attendanceSummaryError.value = summaryResponse.message.isNotEmpty
        ? summaryResponse.message
        : monthResponse.message;
  }

  Future<void> loadUserXp() async {
    isLoadingUserXp.value = true;
    userXpError.value = '';

    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.USER_XP,
      showLoader: false,
      fromJson: (json) => json,
    );

    isLoadingUserXp.value = false;

    if (!response.success || response.data is! Map<String, dynamic>) {
      userXpSummary.value = const UserXpSummaryData();
      userXpError.value = response.message;
      return;
    }

    final body = response.data as Map<String, dynamic>;
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    userXpSummary.value = UserXpSummaryData.fromApi(data);
  }

  Future<void> loadLeaderboardSummary() async {
    isLoadingLeaderboardSummary.value = true;
    leaderboardSummaryError.value = '';

    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.USER_LEADERBOARD,
      showLoader: false,
      fromJson: (json) => json,
      queryParameters: const {'topLimit': 3},
    );

    isLoadingLeaderboardSummary.value = false;

    if (!response.success || response.data is! Map<String, dynamic>) {
      leaderboardSummary.value = const LeaderboardStripData();
      leaderboardSummaryError.value = response.message;
      return;
    }

    final body = response.data as Map<String, dynamic>;
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    leaderboardSummary.value = LeaderboardStripData.fromApi(data);
  }

  Future<void> loadDailyQuizAnalytics() async {
    isLoadingDailyQuizAnalytics.value = true;
    dailyQuizAnalyticsError.value = '';

    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.DAILY_QUIZZS_HISTORY,
      showLoader: false,
      fromJson: (json) => json,
      queryParameters: const {'page': 1, 'limit': 50},
    );

    isLoadingDailyQuizAnalytics.value = false;

    if (!response.success || response.data is! Map<String, dynamic>) {
      dailyQuizAnalytics.assignAll(DailyQuizAnalyticsDayData.weekDefaults());
      dailyQuizAnalyticsError.value = response.message;
      return;
    }

    final body = response.data as Map<String, dynamic>;
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    final attemptsJson = data['attempts'] as List<dynamic>? ?? const [];
    final attempts = attemptsJson
        .whereType<Map<String, dynamic>>()
        .map(DailyQuizAttemptData.fromApi)
        .where((attempt) => attempt.date != null)
        .toList();

    dailyQuizAnalytics.assignAll(
      DailyQuizAnalyticsDayData.fromAttempts(attempts),
    );
  }

  Future<void> loadLiveClasses({String? phase}) async {
    isLoadingLiveClasses.value = true;
    liveClassesError.value = '';

    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.LIVE_CLASS,
      showLoader: false,
      fromJson: (json) => json,
      queryParameters: {
        if (phase != null && phase.trim().isNotEmpty) 'phase': phase,
        'page': 1,
        'limit': 20,
      },
    );

    isLoadingLiveClasses.value = false;

    if (!response.success || response.data is! Map<String, dynamic>) {
      liveClassSchedules.clear();
      liveClassesError.value = response.message;
      return;
    }

    final body = response.data as Map<String, dynamic>;
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    final itemsJson = data['liveClasses'] as List<dynamic>? ?? const [];
    final items =
        itemsJson
            .whereType<Map<String, dynamic>>()
            .map(LiveClassScheduleData.fromApi)
            .toList()
          ..sort((a, b) {
            final phaseCompare = a.phasePriority.compareTo(b.phasePriority);
            if (phaseCompare != 0) {
              return phaseCompare;
            }
            final aStart = a.startAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bStart = b.startAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return aStart.compareTo(bStart);
          });

    liveClassSchedules.assignAll(items);
  }

  Future<void> loadWeakAreas() async {
    isLoadingWeakAreas.value = true;
    weakAreasError.value = '';

    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.weakAreas,
      showLoader: false,
      fromJson: (json) => json,
    );

    isLoadingWeakAreas.value = false;

    if (!response.success || response.data is! Map<String, dynamic>) {
      weakAreasSummary.value = const WeakAreasSummaryData();
      weakAreasError.value = response.message;
      return;
    }

    final body = response.data as Map<String, dynamic>;
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    debugPrint('Improvement Areas API data: $data');
    weakAreasSummary.value = WeakAreasSummaryData.fromApi(data);
  }

  LiveClassScheduleData? get featuredLiveClass {
    for (final item in liveClassSchedules) {
      if (item.computedPhase == 'live') {
        return item;
      }
    }
    return liveClassSchedules.isEmpty ? null : liveClassSchedules.first;
  }

  Future<void> joinLiveClass(LiveClassScheduleData item) async {
    if (!item.canJoin) {
      Get.snackbar(
        'Live class',
        item.computedPhase == 'upcoming'
            ? 'Join button class start time par enable hoga.'
            : 'This live class has ended.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4A4FD9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    final meetUri = _meetUriFromLink(item.meetLink);
    if (meetUri == null) {
      Get.snackbar(
        'Live class',
        'Meet link valid nahi hai.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFC81E1E),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    try {
      var launched = await launchUrl(
        meetUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        launched = await launchUrl(meetUri, mode: LaunchMode.platformDefault);
      }
      if (!launched) {
        throw Exception('Unable to launch Meet link');
      }
    } catch (_) {
      Get.snackbar(
        'Live class',
        'Browser me Meet link open nahi ho pa raha hai.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFC81E1E),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  Future<void> loadMockTests() async {
    isLoadingMockTests.value = true;
    mockTestsError.value = '';

    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.USER_MOCK_TEST,
      showLoader: false,
      fromJson: (json) => json,
      queryParameters: const {'page': 1, 'limit': 10},
    );

    isLoadingMockTests.value = false;

    if (!response.success || response.data is! Map<String, dynamic>) {
      mockTests.clear();
      mockTestsError.value = response.message;
      return;
    }

    final body = response.data as Map<String, dynamic>;
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    final itemsJson = data['mockTests'] as List<dynamic>? ?? const [];
    final items =
        itemsJson
            .map(
              (item) => MockTestCardData.fromApi(item as Map<String, dynamic>),
            )
            .toList()
          ..sort((a, b) {
            final phaseCompare = a.phasePriority.compareTo(b.phasePriority);
            if (phaseCompare != 0) {
              return phaseCompare;
            }
            final aStart = a.startAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bStart = b.startAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return aStart.compareTo(bStart);
          });
    mockTests.assignAll(items);
  }

  Future<void> _loadProgressSummary() async {
    isLoadingDashboardSummary.value = true;
    dashboardSummaryError.value = '';

    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.DASHBOARD_PROGRESS_SUMMARY,
      showLoader: false,
      fromJson: (json) => json,
    );

    isLoadingDashboardSummary.value = false;

    if (!response.success || response.data is! Map<String, dynamic>) {
      dashboardSummaryError.value = response.message;
      return;
    }

    final body = response.data as Map<String, dynamic>;
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    final lessons = (data['lessons'] as Map<String, dynamic>?) ?? const {};
    final perSubjectJson = data['perSubject'] as List<dynamic>? ?? const [];

    lessonSummary.value = DashboardLessonSummary.fromApi(lessons);
    _perSubjectSummaryById
      ..clear()
      ..addEntries(
        perSubjectJson.map((entry) {
          final summary = SubjectProgressSummary.fromApi(
            entry as Map<String, dynamic>,
          );
          return MapEntry(summary.subjectId, summary);
        }),
      );
  }

  final Map<String, SubjectProgressSummary> _perSubjectSummaryById = {};

  Future<void> _loadLearnSubjects() async {
    isLoadingLearnSubjects.value = true;
    learnSubjectsError.value = '';

    final response = await LearnCatalogData.getUserSubjects();

    if (!response.success) {
      isLoadingLearnSubjects.value = false;
      learnSubjects.clear();
      learnSubjectsError.value = response.message;
      return;
    }

    final subjects = response.data ?? const <LearnSubjectModel>[];
    learnSubjects.assignAll(
      subjects.asMap().entries.map((entry) {
        final subject = entry.value;
        final summary = _perSubjectSummaryById[subject.id];
        return SubjectCardData.fromLearnSubject(
          subject,
          index: entry.key,
          summary: summary,
        );
      }),
    );

    isLoadingLearnSubjects.value = false;
  }

  void openLeaderboard() {
    Get.toNamed(AppRoutes.leaderboard);
  }

  void openLearnSubjects() {
    Get.to(() => const LearnSubjectViews());
  }

  void openLearnSubjectFromCard(SubjectCardData subject) {
    Get.to<bool>(() => LearnChapterViews(subject: subject.learnSubject))?.then((
      shouldReload,
    ) {
      if (shouldReload == true) {
        loadDashboardData();
      }
    });
  }

  void openStudyTool(StudyToolData tool) {
    if (tool.title == 'Chapters') {
      openLearnSubjects();
      return;
    }

    if (tool.title == 'Notes') {
      Get.to(() => const LearnNotesViews());
      return;
    }

    if (tool.title == 'Homework') {
      Get.to(() => const LearnHomeworkViews());
      return;
    }

    if (tool.title == 'Doubt Solve') {
      Get.to(() => const LearnDoubtSolveViews());
      return;
    }

    if (tool.title == 'E-Book') {
      Get.to(() => const LearnEbookViews());
      return;
    }

    if (tool.title == 'Attendance') {
      Get.to(() => const LearnAttendanceViews())?.then((_) {
        loadAttendanceSummary();
      });
      return;
    }
  }

  Future<void> handleProfileMenuTap(
    ProfileMenuData item,
    BuildContext context,
  ) async {
    if (item.title == 'Leaderboard') {
      openLeaderboard();
      return;
    }

    if (item.title == 'My Course') {
      openLearnSubjects();
      return;
    }

    if (item.title == 'Downloads') {
      Get.to(() => const MenubarDownloadViews());
      return;
    }

    if (item.title == 'XP & Streak Settings') {
      Get.to(() => const XpAndStreakShowViews());
      return;
    }

    if (item.title == 'Sign Out') {
      final shouldLogout = await Get.dialog<bool>(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Sign Out',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: const Text(
            'Are you sure you want to sign out from your account?',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A4FD9),
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (shouldLogout == true) {
        if (_isLoggingOut) {
          return;
        }
        _isLoggingOut = true;

        final response = await ApiService.instance.post<dynamic>(
          endpoint: ApiService.LOGOUT,
          fromJson: (json) => json,
        );

        if (!response.success) {
          Get.snackbar(
            'Error',
            response.message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFB42318),
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
          );
          return;
        }

        final preferences = await SharedPreferences.getInstance();
        await preferences.setBool(StorageKeys.profileSetupCompleted, false);
        await _storage.delete(key: StorageKeys.authToken);
        await SessionManager.instance.logout();
        if (context.mounted) {
          Provider.of<UserProfileProvider>(
            context,
            listen: false,
          ).clearProfile();
        }
        // Navigate to login once and clear navigation stack via SessionManager.
        SessionManager.instance.navigateToLoginIfNeeded();
        _isLoggingOut = false;
      }

      return;
    }

    if (item.title == 'Delete Account') {
      final shouldDelete = await Get.dialog<bool>(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Account',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: const Text('Are you sure you want to delete your account?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A4FD9),
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (shouldDelete == true) {
        final response = await ApiService.instance.delete<dynamic>(
          endpoint: ApiService.DELETE_ACCOUNT,
          fromJson: (json) => json,
        );

        if (!response.success) {
          Get.snackbar(
            'Error',
            response.message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFB42318),
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
          );
          return;
        }

        final preferences = await SharedPreferences.getInstance();
        await preferences.setBool(StorageKeys.profileSetupCompleted, false);
        await _storage.delete(key: StorageKeys.authToken);
        await SessionManager.instance.logout();
        if (context.mounted) {
          Provider.of<UserProfileProvider>(
            context,
            listen: false,
          ).clearProfile();
        }
        Get.offAllNamed(AppRoutes.login);
      }
    }
  }
}

class DashboardNavItemData {
  final String label;
  final IconData icon;

  const DashboardNavItemData({required this.label, required this.icon});
}

class SubjectCardData {
  final LearnSubjectModel learnSubject;
  final String title;
  final String subjectId;
  final String progressLabel;
  final String progressText;
  final double progressValue;
  final Color accent;
  final IconData icon;
  final Color iconBackground;

  const SubjectCardData({
    required this.learnSubject,
    required this.title,
    required this.subjectId,
    required this.progressLabel,
    required this.progressText,
    required this.progressValue,
    required this.accent,
    required this.icon,
    required this.iconBackground,
  });

  factory SubjectCardData.fromLearnSubject(
    LearnSubjectModel subject, {
    required int index,
    SubjectProgressSummary? summary,
  }) {
    final palette = _subjectPalette(index);
    final lessonsTotal = summary?.lessonsTotal ?? 0;
    final lessonsCompleted = summary?.lessonsCompleted ?? 0;
    final progressValue = lessonsTotal == 0
        ? 0.0
        : (lessonsCompleted / lessonsTotal).clamp(0.0, 1.0).toDouble();
    final progressPercentage = (progressValue * 100).round();

    return SubjectCardData(
      learnSubject: subject,
      title: subject.title,
      subjectId: subject.id,
      progressLabel: '$progressPercentage%',
      progressText: '$lessonsCompleted/$lessonsTotal Lessons',
      progressValue: progressValue,
      accent: palette.accent,
      icon: palette.icon,
      iconBackground: palette.iconBackground,
    );
  }

  /// Learning status derived from the subject's lesson progress.
  /// `paused` is reserved for when the API exposes a real activity signal.
  SubjectLearningStatus get learningStatus {
    if (progressValue >= 1.0) return SubjectLearningStatus.completed;
    if (progressValue > 0) return SubjectLearningStatus.active;
    return SubjectLearningStatus.notStarted;
  }
}

/// Drives the segmented progress bar colors on the Learning card.
enum SubjectLearningStatus { notStarted, active, paused, completed }

class DashboardLessonSummary {
  final int total;
  final int completed;
  final int inProgress;
  final int notStarted;
  final double completionRate;

  const DashboardLessonSummary({
    this.total = 0,
    this.completed = 0,
    this.inProgress = 0,
    this.notStarted = 0,
    this.completionRate = 0,
  });

  factory DashboardLessonSummary.fromApi(Map<String, dynamic> json) {
    return DashboardLessonSummary(
      total: (json['total'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      inProgress: (json['inProgress'] as num?)?.toInt() ?? 0,
      notStarted: (json['notStarted'] as num?)?.toInt() ?? 0,
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0,
    );
  }

  double get progressValue => (completionRate / 100).clamp(0, 1);

  String get progressLabel =>
      completionRate.truncateToDouble() == completionRate
      ? '${completionRate.toStringAsFixed(0)}%'
      : '${completionRate.toStringAsFixed(2)}%';

  String get activeLessonLabel =>
      '$total Active Lesson${total == 1 ? '' : 's'}';
}

class LeaderboardStripData {
  const LeaderboardStripData({
    this.myRank = 0,
    this.totalStudents = 0,
    this.topStudents = const [],
  });

  final int myRank;
  final int totalStudents;
  final List<LeaderboardStripStudent> topStudents;

  factory LeaderboardStripData.fromApi(Map<String, dynamic> json) {
    final topJson = json['top'] as List<dynamic>? ?? const [];
    return LeaderboardStripData(
      myRank: (json['myRank'] as num?)?.toInt() ?? 0,
      totalStudents: (json['totalStudents'] as num?)?.toInt() ?? 0,
      topStudents: topJson
          .whereType<Map<String, dynamic>>()
          .map(LeaderboardStripStudent.fromApi)
          .take(3)
          .toList(),
    );
  }

  String get rankText => myRank > 0 ? '#${_formatCompactNumber(myRank)}' : '--';

  int get remainingStudents {
    final remaining = totalStudents - topStudents.length;
    return remaining < 0 ? 0 : remaining;
  }

  String get remainingText => '+${_formatCompactNumber(remainingStudents)}';
}

class LeaderboardStripStudent {
  const LeaderboardStripStudent({
    required this.rank,
    required this.name,
    required this.initials,
    required this.color,
  });

  final int rank;
  final String name;
  final String initials;
  final Color color;

  factory LeaderboardStripStudent.fromApi(Map<String, dynamic> json) {
    final student = _safeMap(json['student']);
    final rank = (json['rank'] as num?)?.toInt() ?? 0;
    final name = _safeText(student['name'], fallback: 'Student');

    return LeaderboardStripStudent(
      rank: rank,
      name: name,
      initials: _initials(name),
      color: _leaderboardAvatarColor(rank),
    );
  }
}

class UserXpSummaryData {
  const UserXpSummaryData({
    this.xp = 0,
    this.streakCount = 0,
    this.lastIncrementedAt,
  });

  final int xp;
  final int streakCount;
  final DateTime? lastIncrementedAt;

  factory UserXpSummaryData.fromApi(Map<String, dynamic> json) {
    final streak = _safeMap(json['streak']);
    return UserXpSummaryData(
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      streakCount: (streak['count'] as num?)?.toInt() ?? 0,
      lastIncrementedAt: _parseApiDate(streak['lastIncrementedAt']),
    );
  }

  String get xpText => _formatCompactNumber(xp);

  String get streakText {
    final value = streakCount.toString().padLeft(2, '0');
    return '$value Days';
  }

  String get profileStreakText {
    return '$streakCount Day${streakCount == 1 ? '' : 's'}';
  }
}

class _SubjectPalette {
  final IconData icon;
  final Color accent;
  final Color iconBackground;

  const _SubjectPalette({
    required this.icon,
    required this.accent,
    required this.iconBackground,
  });
}

_SubjectPalette _subjectPalette(int index) {
  const palettes = [
    _SubjectPalette(
      icon: Icons.calculate_outlined,
      accent: Color(0xFF4A4FD9),
      iconBackground: Color(0xFFE9E8FF),
    ),
    _SubjectPalette(
      icon: Icons.science_outlined,
      accent: Color(0xFFA56A00),
      iconBackground: Color(0xFFFFEDCF),
    ),
    _SubjectPalette(
      icon: Icons.import_contacts_rounded,
      accent: Color(0xFF8A2CD5),
      iconBackground: Color(0xFFF0DEFF),
    ),
    _SubjectPalette(
      icon: Icons.public_rounded,
      accent: Color(0xFF575867),
      iconBackground: Color(0xFFE0E3E7),
    ),
  ];

  return palettes[index % palettes.length];
}

class StudyToolData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color iconBackground;

  const StudyToolData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.iconBackground,
  });
}

class LiveClassScheduleData {
  final String id;
  final String timeText;
  final String timeRangeText;
  final String title;
  final String description;
  final String meetLink;
  final String classLevel;
  final String teacher;
  final String subject;
  final String phase;
  final bool isLiveNow;
  final DateTime? startAt;
  final DateTime? endAt;
  final Color subjectColor;
  final Color accent;

  const LiveClassScheduleData({
    required this.id,
    required this.timeText,
    required this.timeRangeText,
    required this.title,
    required this.description,
    required this.meetLink,
    required this.classLevel,
    required this.teacher,
    required this.subject,
    required this.phase,
    required this.isLiveNow,
    required this.startAt,
    required this.endAt,
    required this.subjectColor,
    required this.accent,
  });

  factory LiveClassScheduleData.fromApi(Map<String, dynamic> json) {
    final subjectJson = _safeMap(json['subject']);
    final teacherJson = _safeMap(json['teacher']);
    final isLiveNow = json['isLiveNow'] == true;
    final startAt =
        _parseApiDate(json['startAt']) ??
        (isLiveNow
            ? _todayTimeAsDate(json['startTime'])
            : _parseApiDate(json['nextOccurrenceAt']));
    final endAt =
        _parseApiDate(json['endAt']) ??
        _parseApiDate(json['currentSessionEndsAt']) ??
        (isLiveNow ? _todayTimeAsDate(json['endTime']) : null);
    final subject = _safeText(subjectJson['name'], fallback: 'Live Class');
    final palette = _liveClassPalette(subject);

    return LiveClassScheduleData(
      id: _safeText(json['_id']),
      timeText: _formatLiveDateBlock(startAt),
      timeRangeText: _formatLiveTimeRange(startAt, endAt),
      title: _safeText(json['title'], fallback: 'Live Class'),
      description: _safeText(json['description']),
      meetLink: _safeText(json['meetLink']),
      classLevel: _safeText(json['classLevel']),
      teacher: _safeText(teacherJson['name'], fallback: 'Teacher'),
      subject: subject,
      phase: isLiveNow
          ? 'live'
          : _safeText(json['phase'], fallback: 'upcoming').toLowerCase(),
      isLiveNow: isLiveNow,
      startAt: startAt,
      endAt: endAt,
      subjectColor: palette.subjectColor,
      accent: palette.accent,
    );
  }

  String get computedPhase {
    final start = startAt?.toUtc();
    final end = endAt?.toUtc();
    if (start == null || end == null) {
      return phase;
    }

    final now = DateTime.now().toUtc();
    if (now.isBefore(start)) {
      return 'upcoming';
    }
    if (now.isAfter(end)) {
      return 'past';
    }
    return 'live';
  }

  bool get canJoin => isLiveNow || phase == 'live' || computedPhase == 'live';

  int get phasePriority {
    final status = computedPhase;
    if (status == 'live') {
      return 0;
    }
    if (status == 'upcoming') {
      return 1;
    }
    return 2;
  }

  String get phaseLabel {
    final status = computedPhase;
    if (status == 'live') {
      return 'Live Now';
    }
    if (status == 'past') {
      return 'Ended';
    }
    return 'Upcoming';
  }

  String get joinButtonLabel => canJoin ? 'Join Now' : phaseLabel;
}

class PreviousResultData {
  final String title;
  final String meta;
  final String scoreText;
  final IconData icon;
  final Color iconBackground;
  final Color accent;

  const PreviousResultData({
    required this.title,
    required this.meta,
    required this.scoreText,
    required this.icon,
    required this.iconBackground,
    required this.accent,
  });
}

class MockTestCardData {
  const MockTestCardData({
    required this.id,
    required this.title,
    required this.classLevel,
    required this.startAt,
    required this.endAt,
    required this.totalMarks,
    required this.passingPercentage,
    required this.phase,
    required this.attemptStatus,
    required this.myAttemptId,
  });

  final String id;
  final String title;
  final String classLevel;
  final DateTime? startAt;
  final DateTime? endAt;
  final int totalMarks;
  final int passingPercentage;
  final String phase;
  final String attemptStatus;
  final String myAttemptId;

  factory MockTestCardData.fromApi(Map<String, dynamic> json) {
    return MockTestCardData(
      id: _safeText(json['_id']),
      title: _safeText(json['title'], fallback: 'Mock Test'),
      classLevel: _safeText(json['classLevel']),
      startAt: DateTime.tryParse(json['startAt']?.toString() ?? ''),
      endAt: DateTime.tryParse(json['endAt']?.toString() ?? ''),
      totalMarks: (json['totalMarks'] as num?)?.toInt() ?? 0,
      passingPercentage: (json['passingPercentage'] as num?)?.toInt() ?? 0,
      phase: _safeText(json['phase'], fallback: 'upcoming'),
      attemptStatus: _safeText(
        json['attemptStatus'],
        fallback: 'not_attempted',
      ),
      myAttemptId: _safeText(json['myAttemptId']),
    );
  }

  bool get canStart => phase == 'live' && attemptStatus == 'not_attempted';

  int get phasePriority {
    if (phase == 'live') {
      return 0;
    }
    if (phase == 'upcoming') {
      return 1;
    }
    return 2;
  }

  String get windowLabel {
    return 'Start: ${_formatMockDateTime(startAt)}\nEnd: ${_formatMockDateTime(endAt)}';
  }

  String get statusLabel {
    if (attemptStatus == 'attempted') {
      return 'Attempted';
    }
    if (attemptStatus == 'missed') {
      return 'Missed';
    }
    if (phase == 'live') {
      return 'Live Now';
    }
    if (phase == 'past') {
      return 'Ended';
    }
    return 'Upcoming';
  }
}

class DailyQuizAttemptData {
  const DailyQuizAttemptData({
    required this.date,
    required this.totalScore,
    required this.maxScore,
    required this.percentage,
    required this.passed,
  });

  final DateTime? date;
  final int totalScore;
  final int maxScore;
  final double percentage;
  final bool passed;

  factory DailyQuizAttemptData.fromApi(Map<String, dynamic> json) {
    final dailyQuiz = _safeMap(json['dailyQuiz']);
    return DailyQuizAttemptData(
      date:
          _parseApiDate(json['date'] ?? dailyQuiz['date']) ??
          _parseApiDate(json['createdAt']),
      totalScore: (json['totalScore'] as num?)?.toInt() ?? 0,
      maxScore:
          (json['maxScore'] as num?)?.toInt() ??
          (dailyQuiz['totalMarks'] as num?)?.toInt() ??
          0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      passed: json['passed'] == true,
    );
  }
}

class DailyQuizAnalyticsDayData {
  const DailyQuizAnalyticsDayData({
    required this.label,
    required this.date,
    required this.attempt,
  });

  final String label;
  final DateTime date;
  final DailyQuizAttemptData? attempt;

  bool get isAttempted => attempt != null;

  bool get isComingSoon {
    if (isAttempted) {
      return false;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.isAfter(today);
  }

  double get percentage => attempt?.percentage.clamp(0, 100).toDouble() ?? 0;

  double get barValue => isAttempted ? (percentage / 100).clamp(0.08, 1.0) : 0;

  String get statusText {
    if (isAttempted) {
      return '${percentage.round()}%';
    }
    return isComingSoon ? 'Coming Soon' : 'Not Attempt';
  }

  String get scoreText {
    final data = attempt;
    if (data == null) {
      return '-';
    }
    return '${data.totalScore}/${data.maxScore}';
  }

  Color get accent {
    if (isComingSoon) {
      return const Color(0xFF4A4FD9);
    }
    if (!isAttempted) {
      return const Color(0xFF9AA3B2);
    }
    if (attempt!.passed) {
      return const Color(0xFF12B76A);
    }
    return const Color(0xFFF97316);
  }

  Color get barColor {
    if (isComingSoon) {
      return const Color(0xFFE2E7FF);
    }
    if (!isAttempted) {
      return const Color(0xFFE6EAF0);
    }
    if (percentage >= 80) {
      return AppColors.analyticsHighlight;
    }
    if (percentage >= 60) {
      return AppColors.primaryTint5;
    }
    if (percentage >= 40) {
      return AppColors.primaryTint3;
    }
    return AppColors.primaryTint;
  }

  static List<DailyQuizAnalyticsDayData> weekDefaults() {
    final weekStart = _currentWeekStart();
    return List.generate(6, (index) {
      return DailyQuizAnalyticsDayData(
        label: _weekdayLabels[index],
        date: weekStart.add(Duration(days: index)),
        attempt: null,
      );
    });
  }

  static List<DailyQuizAnalyticsDayData> fromAttempts(
    List<DailyQuizAttemptData> attempts,
  ) {
    final weekStart = _currentWeekStart();
    final attemptByDate = <DateTime, DailyQuizAttemptData>{};

    for (final attempt in attempts) {
      final date = attempt.date;
      if (date == null) {
        continue;
      }
      final local = date.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      if (day.isBefore(weekStart) ||
          day.isAfter(weekStart.add(const Duration(days: 5)))) {
        continue;
      }

      final existing = attemptByDate[day];
      if (existing == null || date.isAfter(existing.date ?? date)) {
        attemptByDate[day] = attempt;
      }
    }

    return List.generate(6, (index) {
      final date = weekStart.add(Duration(days: index));
      return DailyQuizAnalyticsDayData(
        label: _weekdayLabels[index],
        date: date,
        attempt: attemptByDate[date],
      );
    });
  }
}

class WeakAreasSummaryData {
  final int answered;
  final int correct;
  final int skipped;
  final List<WeakAreaSubjectData> subjects;

  const WeakAreasSummaryData({
    this.answered = 0,
    this.correct = 0,
    this.skipped = 0,
    this.subjects = const [],
  });

  factory WeakAreasSummaryData.fromApi(Map<String, dynamic> json) {
    final totals = _safeMap(json['totals']);
    final subjectsJson = json['subjects'] as List<dynamic>? ?? const [];

    return WeakAreasSummaryData(
      answered: (totals['answered'] as num?)?.toInt() ?? 0,
      correct: (totals['correct'] as num?)?.toInt() ?? 0,
      skipped: (totals['skipped'] as num?)?.toInt() ?? 0,
      subjects: subjectsJson
          .whereType<Map<String, dynamic>>()
          .map(WeakAreaSubjectData.fromApi)
          .toList(),
    );
  }

  bool get hasAttempts => answered > 0 || correct > 0 || skipped > 0;
}

class WeakAreaSubjectData {
  final String id;
  final String name;
  final double accuracy;
  final int answered;
  final int correct;
  final int skipped;
  final int unresolvedLessons;
  final List<WeakAreaLessonData> lessons;

  const WeakAreaSubjectData({
    required this.id,
    required this.name,
    required this.accuracy,
    required this.answered,
    required this.correct,
    required this.skipped,
    required this.unresolvedLessons,
    required this.lessons,
  });

  factory WeakAreaSubjectData.fromApi(Map<String, dynamic> json) {
    final subject = _safeMap(json['subject']);
    final lessonsJson = json['lessons'] as List<dynamic>? ?? const [];

    return WeakAreaSubjectData(
      id: _safeText(subject['_id']),
      name: _safeText(subject['name'], fallback: 'Subject'),
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
      answered: (json['answered'] as num?)?.toInt() ?? 0,
      correct: (json['correct'] as num?)?.toInt() ?? 0,
      skipped: (json['skipped'] as num?)?.toInt() ?? 0,
      unresolvedLessons: (json['unresolvedLessons'] as num?)?.toInt() ?? 0,
      lessons: lessonsJson
          .whereType<Map<String, dynamic>>()
          .map(WeakAreaLessonData.fromApi)
          .toList(),
    );
  }

  String get accuracyLabel => _formatWeakAreaAccuracy(accuracy);

  String get correctAnswerLabel => '$correct/$answered correct';

  String get primaryLessonTitle => lessons.isEmpty ? name : lessons.first.title;

  String get primaryLessonMeta => lessons.isEmpty
      ? correctAnswerLabel
      : '${lessons.first.accuracyLabel} Accuracy';
}

class WeakAreaLessonData {
  final String id;
  final String title;
  final String description;
  final int order;
  final double accuracy;
  final int answered;
  final int correct;
  final int skipped;

  const WeakAreaLessonData({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    required this.accuracy,
    required this.answered,
    required this.correct,
    required this.skipped,
  });

  factory WeakAreaLessonData.fromApi(Map<String, dynamic> json) {
    final lesson = _safeMap(json['lesson']);

    return WeakAreaLessonData(
      id: _safeText(lesson['_id']),
      title: _safeText(lesson['title'], fallback: 'Lesson'),
      description: _safeText(lesson['description']),
      order: (lesson['order'] as num?)?.toInt() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
      answered: (json['answered'] as num?)?.toInt() ?? 0,
      correct: (json['correct'] as num?)?.toInt() ?? 0,
      skipped: (json['skipped'] as num?)?.toInt() ?? 0,
    );
  }

  String get accuracyLabel => _formatWeakAreaAccuracy(accuracy);
}

class ProfileMenuData {
  final String title;
  final IconData icon;
  final Color color;

  const ProfileMenuData({
    required this.title,
    required this.icon,
    this.color = const Color(0xFF4A4FD9),
  });
}

String _safeText(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _formatCompactNumber(int value) {
  final valueText = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < valueText.length; i++) {
    final reverseIndex = valueText.length - i;
    buffer.write(valueText[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

String _formatWeakAreaAccuracy(double value) {
  final rounded = value.truncateToDouble() == value
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$rounded%';
}

String _initials(String name) {
  final parts = name
      .split(RegExp(r'\s+'))
      .where((part) => part.trim().isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return 'ST';
  }
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}

Color _leaderboardAvatarColor(int rank) {
  switch (rank) {
    case 1:
      return AppColors.avatarGray;
    case 2:
      return AppColors.avatarPink;
    case 3:
      return AppColors.avatarBrown;
    default:
      return AppColors.avatarLight;
  }
}

Map<String, dynamic> _safeMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
}

DateTime? _parseApiDate(dynamic value) {
  return DateTime.tryParse(value?.toString() ?? '');
}

const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

DateTime _currentWeekStart() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return today.subtract(Duration(days: today.weekday - DateTime.monday));
}

DateTime? _todayTimeAsDate(dynamic value) {
  final text = _safeText(value);
  final parts = text.split(':');
  if (parts.length < 2) {
    return null;
  }
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) {
    return null;
  }
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, hour, minute);
}

String _formatMockDateTime(DateTime? date) {
  if (date == null) {
    return '-';
  }
  final local = date.toLocal();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '${months[local.month - 1]} ${local.day}, $hour:$minute $period';
}

String _formatLiveDateBlock(DateTime? date) {
  if (date == null) {
    return '--\n--';
  }
  final local = date.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dateOnly = DateTime(local.year, local.month, local.day);
  final dayText = dateOnly == today
      ? 'Today'
      : dateOnly == today.add(const Duration(days: 1))
      ? 'Tomorrow'
      : '${_monthName(local.month)} ${local.day}';
  return '$dayText\n${_formatClock(local)}';
}

String _formatLiveTimeRange(DateTime? startAt, DateTime? endAt) {
  if (startAt == null && endAt == null) {
    return '';
  }
  if (endAt == null) {
    return _formatClock(startAt!.toLocal());
  }
  if (startAt == null) {
    return _formatClock(endAt.toLocal());
  }
  return '${_formatClock(startAt.toLocal())} - ${_formatClock(endAt.toLocal())}';
}

String _formatClock(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

String _formatAttendanceMonth(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';
}

String _monthName(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[(month - 1).clamp(0, months.length - 1)];
}

Uri? _meetUriFromLink(String link) {
  final trimmed = link.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final normalized = trimmed.contains('://') ? trimmed : 'https://$trimmed';
  final uri = Uri.tryParse(normalized);
  if (uri == null || uri.host.trim().isEmpty) {
    return null;
  }
  return uri;
}

class _LiveClassPalette {
  const _LiveClassPalette({required this.subjectColor, required this.accent});

  final Color subjectColor;
  final Color accent;
}

_LiveClassPalette _liveClassPalette(String subject) {
  final key = subject.toLowerCase();
  if (key.contains('math')) {
    return const _LiveClassPalette(
      subjectColor: Color(0xFFE1DDFF),
      accent: Color(0xFF4A4FD9),
    );
  }
  if (key.contains('science')) {
    return const _LiveClassPalette(
      subjectColor: Color(0xFFDDF7EA),
      accent: Color(0xFF19945F),
    );
  }
  if (key.contains('english')) {
    return const _LiveClassPalette(
      subjectColor: Color(0xFFFFE6C7),
      accent: Color(0xFFB36500),
    );
  }
  if (key.contains('history') || key.contains('social')) {
    return const _LiveClassPalette(
      subjectColor: Color(0xFFFFDFBA),
      accent: Color(0xFF7B5B2B),
    );
  }
  return const _LiveClassPalette(
    subjectColor: Color(0xFFE6E8F2),
    accent: Color(0xFF4A4FD9),
  );
}
