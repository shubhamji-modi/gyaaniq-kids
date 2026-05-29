import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/user_profile_provider.dart';
import '../../../core/service/api_service.dart';
import '../../../core/service/session_manager.dart';
import '../../learn/chapter/controller/learn_chapter_controller.dart';
import '../../menubar/download/views/menubar_download_views.dart';
import '../../menubar/purchase_subscription/views/subscription_history_views.dart';
import '../../learn/chapter/views/learn_chapter_views.dart';
import '../../learn/chapter/views/learn_subject_views.dart';
import '../../learn/attendance/views/learn_attendance_views.dart';
import '../../learn/doubt_solve/views/learn_doubt_solve_views.dart';
import '../../learn/e_book/views/learn_ebook_views.dart';
import '../../learn/homework/views/learn_homework_views.dart';
import '../../learn/notes/views/learn_notes_views.dart';
import '../../my_course/views/my_course_views.dart';
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
  final RxList<SubjectCardData> learnSubjects = <SubjectCardData>[].obs;
  final RxList<MockTestCardData> mockTests = <MockTestCardData>[].obs;
  final Rx<DashboardLessonSummary> lessonSummary =
      const DashboardLessonSummary().obs;

  final String studentName = 'Sarah!';
  final String studentClassBoard = 'CLASS 10 • CBSE BOARD';
  final String streakText = '07 Days';
  final String appBuild = 'App Build: v1.0.2';

  final List<DashboardNavItemData> navItems = const [
    DashboardNavItemData(label: 'Home', icon: Icons.home_rounded),
    DashboardNavItemData(label: 'Learn', icon: Icons.menu_book_rounded),
    DashboardNavItemData(label: 'Quiz', icon: Icons.quiz_outlined),
    DashboardNavItemData(label: 'Live', icon: Icons.ondemand_video_outlined),
    DashboardNavItemData(label: 'Profile', icon: Icons.person_outline_rounded),
  ];

  final List<StudyToolData> studyTools = const [
    StudyToolData(
      title: 'Chapters',
      subtitle: '12 Chapters left to review',
      icon: Icons.import_contacts_rounded,
      accent: Color(0xFF4A4FD9),
      iconBackground: Color(0xFFE5E6FF),
    ),
    StudyToolData(
      title: 'Notes',
      subtitle: 'View all shared class notes',
      icon: Icons.note_alt_outlined,
      accent: Color(0xFFFFA615),
      iconBackground: Color(0xFFFFE6B7),
    ),
    StudyToolData(
      title: 'Homework',
      subtitle: '3 Tasks due today',
      icon: Icons.assignment_outlined,
      accent: Color(0xFF7E2AD9),
      iconBackground: Color(0xFFEAD7FF),
    ),
    StudyToolData(
      title: 'Doubt Solve',
      subtitle: 'Chat with AI or Teachers',
      icon: Icons.live_help_outlined,
      accent: Color(0xFFC91F1F),
      iconBackground: Color(0xFFFFDEDE),
    ),
    StudyToolData(
      title: 'E-Book',
      subtitle: 'Access digital textbook',
      icon: Icons.library_books_outlined,
      accent: Color(0xFF4A4FD9),
      iconBackground: Color(0xFFF0F1F5),
    ),
    StudyToolData(
      title: 'Attendance',
      subtitle: '95% average presence',
      icon: Icons.calendar_month_outlined,
      accent: Color(0xFF6366F1),
      iconBackground: Color(0xFFE2E7FF),
    ),
  ];

  final List<LiveClassScheduleData> liveClassSchedules = const [
    LiveClassScheduleData(
      timeText: '02:30\nPM',
      title: 'Photosynthesis & Plant Life',
      teacher: 'Mr. David Chen',
      subject: 'Science',
      subjectColor: Color(0xFFEED7FF),
      accent: Color(0xFF4A4FD9),
    ),
    LiveClassScheduleData(
      timeText: '04:00\nPM',
      title: 'The Industrial Revolution',
      teacher: 'Prof. Elena Rodriguez',
      subject: 'History',
      subjectColor: Color(0xFFFFDFBA),
      accent: Color(0xFF7B8197),
    ),
    LiveClassScheduleData(
      timeText: '05:15\nPM',
      title: 'Advanced Grammar Workshop',
      teacher: 'Ms. Julia Knight',
      subject: 'English',
      subjectColor: Color(0xFFDDDDFE),
      accent: Color(0xFF7B8197),
    ),
    LiveClassScheduleData(
      timeText: 'Tomorrow\n09:00 AM',
      title: 'Triangles & Trigonometry',
      teacher: 'Dr. Sarah Miller',
      subject: 'Geometry',
      subjectColor: Color(0xFFF1D9FF),
      accent: Color(0xFF7B8197),
    ),
  ];

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
      title: 'Subscription',
      icon: Icons.workspace_premium_outlined,
    ),
    ProfileMenuData(
      title: 'Terms of Service',
      icon: Icons.description_outlined,
    ),
    ProfileMenuData(
      title: 'Privacy Shield',
      icon: Icons.verified_user_outlined,
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
  }

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    await _loadProgressSummary();
    await _loadLearnSubjects();
    await loadMockTests();
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
      Get.to(() => const LearnAttendanceViews());
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
      Get.to(() => const MyCourseViews());
      return;
    }

    if (item.title == 'Downloads') {
      Get.to(() => const MenubarDownloadViews());
      return;
    }

    if (item.title == 'Subscription') {
      Get.to(() => const SubscriptionHistoryViews());
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
        Get.offAllNamed(AppRoutes.login);
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
}

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
  final String timeText;
  final String title;
  final String teacher;
  final String subject;
  final Color subjectColor;
  final Color accent;

  const LiveClassScheduleData({
    required this.timeText,
    required this.title,
    required this.teacher,
    required this.subject,
    required this.subjectColor,
    required this.accent,
  });
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
