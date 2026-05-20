import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../menubar/download/views/menubar_download_views.dart';
import '../../menubar/purchase_subscription/views/subscription_history_views.dart';
import '../../learn/chapter/controller/learn_chapter_controller.dart';
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

  final List<SubjectCardData> subjects = const [
    SubjectCardData(
      title: 'Math',
      progressLabel: '80%',
      accent: Color(0xFF4A4FD9),
      icon: Icons.calculate_outlined,
      iconBackground: Color(0xFFE9E8FF),
    ),
    SubjectCardData(
      title: 'Science',
      progressLabel: '25%',
      accent: Color(0xFFA56A00),
      icon: Icons.science_outlined,
      iconBackground: Color(0xFFFFEDCF),
    ),
    SubjectCardData(
      title: 'English',
      progressLabel: '100%',
      accent: Color(0xFF8A2CD5),
      icon: Icons.import_contacts_rounded,
      iconBackground: Color(0xFFF0DEFF),
    ),
    SubjectCardData(
      title: 'Social',
      progressLabel: '0%',
      accent: Color(0xFF575867),
      icon: Icons.public_rounded,
      iconBackground: Color(0xFFE0E3E7),
    ),
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

  void openLeaderboard() {
    Get.toNamed(AppRoutes.leaderboard);
  }

  void openLearnSubjects() {
    Get.to(() => const LearnSubjectViews());
  }

  void openLearnSubjectFromCard(String title) {
    final subjectMap = {
      'Math': 'mathematics',
      'Science': 'science',
      'English': 'english',
      'Social': 'social',
    };

    final subjectId = subjectMap[title];
    final subject = subjectId == null
        ? null
        : LearnCatalogData.subjectById(subjectId);

    if (subject == null) {
      openLearnSubjects();
      return;
    }

    Get.to(() => LearnChapterViews(subject: subject));
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

  Future<void> handleProfileMenuTap(ProfileMenuData item) async {
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
        final preferences = await SharedPreferences.getInstance();
        await preferences.setBool(StorageKeys.profileSetupCompleted, false);
        await _storage.delete(key: StorageKeys.authToken);
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
  final String title;
  final String progressLabel;
  final Color accent;
  final IconData icon;
  final Color iconBackground;

  const SubjectCardData({
    required this.title,
    required this.progressLabel,
    required this.accent,
    required this.icon,
    required this.iconBackground,
  });
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
