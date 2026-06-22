import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../../../core/data/user_profile_provider.dart';
import '../../../../core/service/api_service.dart';
import '../../../../core/service/learn_progress_refresh_service.dart';
import '../../../../core/theme/appcolors.dart';

import '../../menubar/edit profile/views/edit_profile_views.dart';
import '../../daily_quiz/views/start_quiz_views.dart';
import '../../daily_quiz/result/preview_result/controller/preview_result_controller.dart';
import '../../daily_quiz/result/preview_result/views/preview_result_views.dart';
import '../../daily_quiz/practice_test/Views/quiz_practice_paper_subject_views.dart';
import '../../explore_classes/views/explore_classes_views.dart';
import '../controllers/dashboard_tabbar_controller.dart';

class DashboardTabbarViewsScreen extends StatefulWidget {
  const DashboardTabbarViewsScreen({super.key});

  @override
  State<DashboardTabbarViewsScreen> createState() =>
      _DashboardTabbarViewsScreenState();
}

class _DashboardTabbarViewsScreenState
    extends State<DashboardTabbarViewsScreen> {
  bool _isFetchingProfile = false;
  bool _hasHandledLaunchArgs = false;
  late final Worker _refreshWorker;

  @override
  void initState() {
    super.initState();
    _refreshWorker = ever<int>(
      LearnProgressRefreshService.instance.refreshTick,
      (_) {
        if (!mounted) {
          return;
        }
        Get.put(DashboardTabbarController()).loadDashboardData();
        _fetchProfile();
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleLaunchArgs();
      _fetchProfile();
    });
  }

  @override
  void dispose() {
    _refreshWorker.dispose();
    super.dispose();
  }

  void _handleLaunchArgs() {
    if (_hasHandledLaunchArgs || !mounted) {
      return;
    }
    _hasHandledLaunchArgs = true;

    final controller = Get.put(DashboardTabbarController());
    final args = Get.arguments;
    if (args is! Map) {
      return;
    }

    final initialTab = args['initialTab'];
    if (initialTab is int) {
      controller.changeTab(initialTab);
    }

    if (args['forceReload'] == true) {
      controller.loadDashboardData();
      _fetchProfile();
    }

    final successMessage = args['successMessage']?.toString().trim() ?? '';
    if (successMessage.isNotEmpty) {
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        if (!mounted) {
          return;
        }
        Get.snackbar(
          'Success',
          successMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.white,
          colorText: const Color(0xFF1D2231),
          margin: const EdgeInsets.all(14),
        );
      });
    }
  }

  Future<void> _fetchProfile() async {
    if (_isFetchingProfile || !mounted) {
      return;
    }

    _isFetchingProfile = true;
    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.GET_PROFILE,
      showLoader: false,
      fromJson: (json) => json,
    );

    if (!mounted) {
      return;
    }

    _isFetchingProfile = false;

    if (!response.success || response.data is! Map<String, dynamic>) {
      return;
    }

    final body = response.data as Map<String, dynamic>;
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      return;
    }

    context.read<UserProfileProvider>().setProfile(UserProfile.fromApi(data));
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DashboardTabbarController());

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Obx(
        () => IndexedStack(
          index: controller.currentTabIndex.value,
          children: const [
            _HomeTab(),
            _LearnTab(),
            _QuizTab(),
            _LiveTab(),
            _ProfileTab(),
          ],
        ),
      ),
      bottomNavigationBar: const _BottomNavBar(),
    );
  }
}

class _BottomNavBar extends GetView<DashboardTabbarController> {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryShadow.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Obx(
          () => Row(
            children: List.generate(controller.navItems.length, (index) {
              final item = controller.navItems[index];
              final isSelected = controller.currentTabIndex.value == index;

              return Expanded(
                child: InkWell(
                  onTap: () => controller.changeTab(index),
                  borderRadius: BorderRadius.circular(24),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryBright
                          : AppColors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          color: isSelected
                              ? AppColors.white
                              : AppColors.navUnselected,
                          size: 22,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.white
                                : AppColors.navUnselected,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _DashboardScaffold extends StatelessWidget {
  const _DashboardScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const _DashboardHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHeader extends GetView<DashboardTabbarController> {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<UserProfileProvider>(context).profile;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.headerBorder)),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _ProfileAvatar(
                imageUrl: profile?.profilePic ?? '',
                size: 40,
                iconSize: 28,
                borderWidth: 2,
              ),
              const Positioned(
                right: -1,
                bottom: -1,
                child: CircleAvatar(
                  radius: 9,
                  backgroundColor: AppColors.white,
                  child: CircleAvatar(
                    radius: 7,
                    backgroundColor: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, ${profile?.name ?? 'Student'}👋',
                  style: const TextStyle(
                    color: AppColors.textPrimaryDeep,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'CLASS ${profile?.userClass ?? '-'} • ${profile?.educationBoard ?? '-'} BOARD',
                  style: const TextStyle(
                    color: AppColors.textMuted2,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.streakBackground,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.chipBorder),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_fire_department_outlined,
                  color: AppColors.streakIcon,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Obx(
                  () => Text(
                    controller.userXpSummary.value.streakText,
                    style: const TextStyle(
                      color: AppColors.streakText,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // const SizedBox(width: 12),
          // const Icon(
          //   Icons.notifications_none_rounded,
          //   color: AppColors.iconMuted,
          //   size: 20,
          // ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.imageUrl,
    required this.size,
    required this.iconSize,
    required this.borderWidth,
    this.backgroundColor,
  });

  final String imageUrl;
  final double size;
  final double iconSize;
  final double borderWidth;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.trim().isNotEmpty;
    final trimmedImage = imageUrl.trim();
    final isNetworkImage = trimmedImage.startsWith('http');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasImage
            ? null
            : const LinearGradient(
                colors: [
                  AppColors.avatarGradientStart,
                  AppColors.avatarGradientEnd,
                ],
              ),
        color: hasImage ? backgroundColor ?? AppColors.white : null,
        border: Border.all(color: AppColors.avatarBorder, width: borderWidth),
      ),
      child: ClipOval(
        child: hasImage
            ? isNetworkImage
                  ? Image.network(
                      trimmedImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _FallbackAvatarIcon(iconSize: iconSize),
                    )
                  : Image.file(
                      File(trimmedImage),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _FallbackAvatarIcon(iconSize: iconSize),
                    )
            : _FallbackAvatarIcon(iconSize: iconSize),
      ),
    );
  }
}

class _FallbackAvatarIcon extends StatelessWidget {
  const _FallbackAvatarIcon({required this.iconSize});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(Icons.person_rounded, color: AppColors.white, size: iconSize),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardTabbarController>();

    return _DashboardScaffold(
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Learning Journey',
              style: TextStyle(
                color: AppColors.textBlue,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Master your goals with interactive question.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            if (controller.dashboardSummaryError.value.isNotEmpty)
              _DashboardInlineState(
                message: controller.dashboardSummaryError.value,
                onRetry: controller.loadDashboardData,
              )
            else ...[
              const _JourneyCard(),
              const SizedBox(height: 18),
            ],
            const Row(
              children: [
                Expanded(child: _DailyQuizMiniCard()),
                SizedBox(width: 14),
                Expanded(child: _AiTutorCard()),
              ],
            ),
            const SizedBox(height: 18),
            const _LeaderboardStripCard(),
            const _HomeLiveClassesSection(),
            const SizedBox(height: 18),
            const _SpokenEnglishCard(),
            // const SizedBox(height: 18),
            // InkWell(
            //   onTap: () => Get.to(() => const ExploreClassesViews()),
            //   borderRadius: BorderRadius.circular(24),
            //   // child: const _ExploreClassesCard(),
            // ),
          ],
        ),
      ),
    );
  }
}

class _LearnTab extends GetView<DashboardTabbarController> {
  const _LearnTab();

  @override
  Widget build(BuildContext context) {
    return _DashboardScaffold(
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ChallengeBanner(),
            const SizedBox(height: 24),
            const Text(
              'My Subjects',
              style: TextStyle(
                color: AppColors.textHeadingAlt,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            if (controller.isLoadingLearnSubjects.value)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (controller.learnSubjectsError.value.isNotEmpty)
              _DashboardInlineState(
                message: controller.learnSubjectsError.value,
                onRetry: controller.loadDashboardData,
              )
            else if (controller.learnSubjects.isEmpty)
              const _DashboardInlineState(
                message: 'No subjects available right now.',
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.learnSubjects.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.90,
                ),
                itemBuilder: (context, index) {
                  final subject = controller.learnSubjects[index];
                  return _SubjectCard(subject: subject);
                },
              ),
            const SizedBox(height: 28),
            const Text(
              'Study Tools',
              style: TextStyle(
                color: AppColors.textHeadingAlt,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            ...controller.studyTools.map(_StudyToolCard.new),
          ],
        ),
      ),
    );
  }
}

class _QuizTab extends GetView<DashboardTabbarController> {
  const _QuizTab();

  @override
  Widget build(BuildContext context) {
    return _DashboardScaffold(
      child: Column(
        children: [
          const _QuizChallengeCard(),
          const SizedBox(height: 18),
          const _QuizPracticeCard(),
          const SizedBox(height: 18),
          const _MockTestCard(),
          const SizedBox(height: 18),
          const _AnalyticsCard(),
          const SizedBox(height: 18),
          const _PreviousResultsCard(),
          // const SizedBox(height: 18),
          // const _RecentBadgesCard(),
        ],
      ),
    );
  }
}

class _LiveTab extends GetView<DashboardTabbarController> {
  const _LiveTab();

  @override
  Widget build(BuildContext context) {
    return _DashboardScaffold(
      child: Obx(() {
        if (controller.isLoadingLiveClasses.value) {
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (controller.liveClassesError.value.isNotEmpty) {
          return _DashboardInlineState(
            message: controller.liveClassesError.value,
            onRetry: controller.loadLiveClasses,
          );
        }

        if (controller.liveClassSchedules.isEmpty) {
          return _DashboardInlineState(
            message: 'No live classes available right now.',
            onRetry: controller.loadLiveClasses,
          );
        }

        final featuredClass = controller.featuredLiveClass;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Live Class',
              style: TextStyle(
                color: AppColors.textHeadingAlt,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            if (featuredClass != null) ...[
              _LiveFeaturedCard(item: featuredClass),
              const SizedBox(height: 20),
            ],
            ...controller.liveClassSchedules.map(_LiveScheduleCard.new),
          ],
        );
      }),
    );
  }
}

class _ProfileTab extends GetView<DashboardTabbarController> {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return _DashboardScaffold(
      child: Column(
        children: [
          const SizedBox(height: 18),
          const _ProfileAvatarSection(),
          const SizedBox(height: 18),
          Obx(() {
            final xpSummary = controller.userXpSummary.value;
            return Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.auto_awesome,
                    iconColor: AppColors.purpleDark2,
                    title: xpSummary.xpText,
                    subtitle: 'Total XP',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatCard(
                    icon: Icons.local_fire_department,
                    iconColor: AppColors.warningText,
                    title: xpSummary.profileStreakText,
                    subtitle: 'Streak',
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardShadow.withValues(alpha: 0.32),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: controller.profileMenuItems
                  .map((item) => _ProfileMenuTile(item: item))
                  .toList(),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            controller.appBuild,
            style: const TextStyle(
              color: AppColors.textMuted8,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardTabbarController>();

    return Obx(() {
      final summary = controller.lessonSummary.value;

      return InkWell(
        onTap: () => controller.changeTab(1),
        borderRadius: BorderRadius.circular(26),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.import_contacts_rounded,
                  color: AppColors.primary,
                  size: 25,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Learning',
                style: TextStyle(
                  color: AppColors.textPrimaryAlt,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                summary.activeLessonLabel,
                style: const TextStyle(
                  color: AppColors.neutralText2,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  const Text(
                    'Overall Progress',
                    style: TextStyle(
                      color: AppColors.textMuted3,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    summary.progressLabel,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: summary.progressValue,
                  minHeight: 10,
                  backgroundColor: AppColors.neutralSurface3,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _DailyQuizMiniCard extends StatelessWidget {
  const _DailyQuizMiniCard();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.to(() => const StartQuizViews()),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'BONUS +50 XP',
                  style: TextStyle(
                    color: AppColors.textBlueDark,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 58,
              left: 0,
              child: Text(
                'Daily\nQuiz',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Start Now',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -8,
              right: -6,
              child: Icon(
                Icons.quiz_outlined,
                size: 62,
                color: AppColors.white.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiTutorCard extends StatelessWidget {
  const _AiTutorCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration().copyWith(
        color: AppColors.neutralSurface,
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: AppColors.purpleSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.purple,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'AI Tutor',
            style: TextStyle(
              color: AppColors.neutralText,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Ask any doubt\ninstant solutions.',
            style: TextStyle(
              color: AppColors.textMuted7,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.neutralSurface2,
              border: Border.all(color: AppColors.softBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.textMuted7,
                  size: 14,
                ),
                SizedBox(width: 6),
                Text(
                  'Locked',
                  style: TextStyle(
                    color: AppColors.textMuted7,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardStripCard extends StatelessWidget {
  const _LeaderboardStripCard();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardTabbarController>();

    return Obx(() {
      final summary = controller.leaderboardSummary.value;

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        color: AppColors.warning2,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Leaderboard',
                        style: TextStyle(
                          color: AppColors.textPrimaryNavy,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _AvatarStack(summary: summary),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  controller.isLoadingLeaderboardSummary.value
                      ? 'Global Rank: ...'
                      : 'Global Rank: ${summary.rankText}',
                  style: const TextStyle(
                    color: AppColors.textMuted6,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 22),
                InkWell(
                  onTap: controller.openLeaderboard,
                  borderRadius: BorderRadius.circular(26),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDeeper,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: const Text(
                      'View Ranking',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _HomeLiveClassesSection extends GetView<DashboardTabbarController> {
  const _HomeLiveClassesSection();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final featuredClass = controller.featuredLiveClass;
      if (controller.isLoadingLiveClasses.value ||
          controller.liveClassesError.value.isNotEmpty ||
          featuredClass == null ||
          featuredClass.computedPhase != 'live') {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 18),
          const Text(
            'Live Classes',
            style: TextStyle(
              color: AppColors.textPrimaryNavy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          _LiveFeaturedCard(item: featuredClass),
        ],
      );
    });
  }
}

class _SpokenEnglishCard extends StatelessWidget {
  const _SpokenEnglishCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration().copyWith(
        color: AppColors.neutralSurface,
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: AppColors.purpleSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.purple,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Spoken English',
            style: TextStyle(
              color: AppColors.neutralText,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Practice with AI Tutor',
            style: TextStyle(
              color: AppColors.textMuted7,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.neutralSurface2,
              border: Border.all(color: AppColors.softBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.textMuted7,
                  size: 14,
                ),
                SizedBox(width: 6),
                Text(
                  'Locked',
                  style: TextStyle(
                    color: AppColors.textMuted7,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreClassesCard extends StatelessWidget {
  const _ExploreClassesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: AppColors.purpleSoft2,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.travel_explore,
              color: AppColors.purpleDark,
              size: 25,
            ),
          ),
          const SizedBox(width: 18),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explore Classes',
                  style: TextStyle(
                    color: AppColors.textPrimaryAlt,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Explore your learning path.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textMuted4,
            size: 28,
          ),
        ],
      ),
    );
  }
}

class _ChallengeBanner extends StatelessWidget {
  const _ChallengeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // padding: const EdgeInsets.all(24),
      // decoration: BoxDecoration(
      //   color: const Color(0xFF2E3236),
      //   borderRadius: BorderRadius.circular(30),
      // ),
      // child: const Column(
      //   crossAxisAlignment: CrossAxisAlignment.start,
      //   children: [
      //     DecoratedBox(
      //       decoration: BoxDecoration(
      //         color: Color(0xFF5A5FEF),
      //         borderRadius: BorderRadius.all(Radius.circular(18)),
      //       ),
      //       child: Padding(
      //         padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      //         child: Text(
      //           'Daily Challenge',
      //           style: TextStyle(
      //             color: Colors.white,
      //             fontSize: 12,
      //             fontWeight: FontWeight.w700,
      //           ),
      //         ),
      //       ),
      //     ),
      //     SizedBox(height: 13),
      //     Text(
      //       'Mastering Trigonometry',
      //       style: TextStyle(
      //         color: Colors.white,
      //         fontSize: 18,
      //         fontWeight: FontWeight.w800,
      //       ),
      //     ),
      //     SizedBox(height: 12),
      //     Text(
      //       'Solve today\'s featured problems to earn double XP\nand unlock the "Math Wizard" badge.',
      //       style: TextStyle(
      //         color: Color(0xFFE4E7ED),
      //         fontSize: 13,
      //         fontWeight: FontWeight.w500,
      //         height: 1.65,
      //       ),
      //     ),
      //     SizedBox(height: 16),
      //     _BannerButton(text: 'Start Challenge'),
      //   ],
      // ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject});

  final SubjectCardData subject;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardTabbarController>();

    return InkWell(
      onTap: () => controller.openLearnSubjectFromCard(subject),
      borderRadius: BorderRadius.circular(26),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: subject.iconBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(subject.icon, color: subject.accent, size: 25),
            ),
            const Spacer(),
            Text(
              subject.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: subject.progressValue,
                      minHeight: 8,
                      backgroundColor: AppColors.neutralSurface5,
                      valueColor: AlwaysStoppedAnimation<Color>(subject.accent),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  subject.progressLabel,
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.92),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              subject.progressText,
              style: TextStyle(
                color: subject.accent,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardInlineState extends StatelessWidget {
  const _DashboardInlineState({required this.message, this.onRetry});

  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.resultMeta,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onRetry,
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StudyToolCard extends StatelessWidget {
  const _StudyToolCard(this.tool);

  final StudyToolData tool;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardTabbarController>();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => controller.openStudyTool(tool),
        borderRadius: BorderRadius.circular(26),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: tool.iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(tool.icon, color: tool.accent, size: 28),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tool.subtitle,
                      style: const TextStyle(
                        color: AppColors.neutralText5,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.neutralText6,
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizChallengeCard extends StatelessWidget {
  const _QuizChallengeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.26),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            bottom: 8,
            child: Icon(
              Icons.quiz_outlined,
              size: 102,
              color: AppColors.white.withValues(alpha: 0.14),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⚡ DAILY CHALLENGE',
                style: TextStyle(
                  color: AppColors.primaryPale,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Daily Quiz',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'Test your knowledge with 5 quick \nquestions andearn a 2x XP multiplier!',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.55,
                ),
              ),
              SizedBox(height: 22),
              _BannerButton(
                text: 'Start Challenge',
                inverted: true,
                onTap: () => Get.to(() => const StartQuizViews()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuizPracticeCard extends StatelessWidget {
  const _QuizPracticeCard();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.to(() => const QuizPracticePaperSubjectViews()),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.purpleSoft2,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: AppColors.purpleDark,
                    size: 25,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.streakBorder,
                  size: 28,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Practice Quiz',
              style: TextStyle(
                color: AppColors.textHeading,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Chapter-wise focused practice\nsessions.',
              style: TextStyle(
                color: AppColors.textSecondaryAlt,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: const [
                  _Tag(label: 'Mathematics'),
                  SizedBox(width: 10),
                  _Tag(label: 'Science'),
                  SizedBox(width: 10),
                  _Tag(label: 'Social'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockTestCard extends StatelessWidget {
  const _MockTestCard();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final dashboardController = Get.find<DashboardTabbarController>();
      final mockTest = dashboardController.mockTests.isNotEmpty
          ? dashboardController.mockTests.first
          : null;

      return InkWell(
        onTap: mockTest == null
            ? null
            : () {
                if (!mockTest.canStart) {
                  Get.snackbar(
                    'Mock Test',
                    mockTest.attemptStatus == 'attempted'
                        ? 'You have already attempted this mock test.'
                        : 'Mock test is ${mockTest.statusLabel.toLowerCase()}.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  return;
                }
                Get.to(() => StartQuizViews(mockTestId: mockTest.id));
              },
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.alarm_rounded,
                  color: AppColors.warningTextDark,
                  size: 25,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                mockTest?.title ?? 'Mock Test',
                style: const TextStyle(
                  color: AppColors.textHeading,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                dashboardController.isLoadingMockTests.value
                    ? 'Loading mock tests...'
                    : (dashboardController.mockTestsError.value.isNotEmpty
                          ? dashboardController.mockTestsError.value
                          : 'Real exam simulation with timers.'),
                style: const TextStyle(
                  color: AppColors.textSecondaryAlt,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.neutralSurface4,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.event_note_rounded,
                      color: AppColors.primaryBright,
                      size: 15,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        mockTest?.windowLabel ?? 'No mock test available',
                        style: const TextStyle(
                          color: AppColors.neutralText4,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (mockTest != null) ...[
                const SizedBox(height: 10),
                _Tag(label: mockTest.statusLabel),
              ],
            ],
          ),
        ),
      );
    });
  }
}

class _AnalyticsCard extends GetView<DashboardTabbarController> {
  const _AnalyticsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Daily Quiz Analytics',
                style: TextStyle(
                  color: AppColors.textHeading,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  onPressed: controller.loadDailyQuizAnalytics,
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Obx(() {
            if (controller.isLoadingDailyQuizAnalytics.value) {
              return const SizedBox(
                height: 150,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (controller.dailyQuizAnalyticsError.value.isNotEmpty) {
              return _DashboardInlineState(
                message: controller.dailyQuizAnalyticsError.value,
                onRetry: controller.loadDailyQuizAnalytics,
              );
            }

            final days = controller.dailyQuizAnalytics.isEmpty
                ? DailyQuizAnalyticsDayData.weekDefaults()
                : controller.dailyQuizAnalytics.toList();
            final attemptedCount = days.where((day) => day.isAttempted).length;
            final average = attemptedCount == 0
                ? 0
                : (days
                              .where((day) => day.isAttempted)
                              .fold<double>(
                                0,
                                (sum, day) => sum + day.percentage,
                              ) /
                          attemptedCount)
                      .round();

            return Column(
              children: [
                SizedBox(
                  height: 144,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: days
                        .map(
                          (day) =>
                              Expanded(child: _DailyQuizAnalyticsBar(day: day)),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  attemptedCount == 0
                      ? 'No daily quiz attempted this week.'
                      : '$attemptedCount/6 attempted • Average $average%',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.neutralText3,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _DailyQuizAnalyticsBar extends StatelessWidget {
  const _DailyQuizAnalyticsBar({required this.day});

  final DailyQuizAnalyticsDayData day;

  @override
  Widget build(BuildContext context) {
    const maxBarHeight = 72.0;
    final barHeight = day.isAttempted ? maxBarHeight * day.barValue : 18.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: 30,
            child: Center(
              child: Text(
                day.statusText,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: day.accent,
                  fontSize: day.isAttempted ? 11 : 8.5,
                  fontWeight: FontWeight.w800,
                  height: 1.12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            width: 34,
            height: barHeight,
            decoration: BoxDecoration(
              color: day.barColor,
              borderRadius: BorderRadius.circular(9),
              border: day.isAttempted
                  ? null
                  : Border.all(color: const Color(0xFFD4DAE4)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            day.label,
            style: const TextStyle(
              color: AppColors.analyticsLabel,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            day.scoreText,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.resultMeta,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviousResultsCard extends StatefulWidget {
  const _PreviousResultsCard();

  @override
  State<_PreviousResultsCard> createState() => _PreviousResultsCardState();
}

class _PreviousResultsCardState extends State<_PreviousResultsCard> {
  bool _isLoading = true;
  String _dailyErrorMessage = '';
  String _practiceErrorMessage = '';
  String _mockErrorMessage = '';
  List<QuizSubmitResultItem> _dailyResults = const [];
  List<QuizSubmitResultItem> _practiceResults = const [];
  List<QuizSubmitResultItem> _mockResults = const [];

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() {
      _isLoading = true;
      _dailyErrorMessage = '';
      _practiceErrorMessage = '';
      _mockErrorMessage = '';
    });

    final responses = await Future.wait([
      QuizSubmitResultRepository.fetchResults(
        type: ResultHistoryType.daily,
        limit: 2,
      ),
      QuizSubmitResultRepository.fetchResults(
        type: ResultHistoryType.practice,
        limit: 2,
      ),
      QuizSubmitResultRepository.fetchResults(
        type: ResultHistoryType.mock,
        limit: 2,
      ),
    ]);

    if (!mounted) {
      return;
    }

    final dailyResponse = responses[0];
    final practiceResponse = responses[1];
    final mockResponse = responses[2];

    setState(() {
      _isLoading = false;
      _dailyResults = dailyResponse.data?.results ?? const [];
      _practiceResults = practiceResponse.data?.results ?? const [];
      _mockResults = mockResponse.data?.results ?? const [];
      _dailyErrorMessage = dailyResponse.success ? '' : dailyResponse.message;
      _practiceErrorMessage = practiceResponse.success
          ? ''
          : practiceResponse.message;
      _mockErrorMessage = mockResponse.success ? '' : mockResponse.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Quiz History',
                style: TextStyle(
                  color: AppColors.textHeading,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _DashboardResultSection(
              title: 'Daily Quiz',
              emptyMessage: 'No daily quiz result yet.',
              errorMessage: _dailyErrorMessage,
              results: _dailyResults,
              backgroundColor: AppColors.primaryPale,
              borderColor: AppColors.primaryTint,
              onRetry: _loadResults,
              onViewAll: () => Get.to(
                () => const PreviewResultViews(
                  initialType: ResultHistoryType.daily,
                ),
              ),
            ),
            const SizedBox(height: 18),
            _DashboardResultSection(
              title: 'Practice Test',
              emptyMessage: 'No practice test result yet.',
              errorMessage: _practiceErrorMessage,
              results: _practiceResults,
              backgroundColor: AppColors.neutralSurface2,
              borderColor: AppColors.softBorder,
              onRetry: _loadResults,
              onViewAll: () => Get.to(
                () => const PreviewResultViews(
                  initialType: ResultHistoryType.practice,
                ),
              ),
            ),
            const SizedBox(height: 18),
            _DashboardResultSection(
              title: 'Mock Test',
              emptyMessage: 'No mock test result yet.',
              errorMessage: _mockErrorMessage,
              results: _mockResults,
              backgroundColor: const Color(0xFFFFF6E8),
              borderColor: const Color(0xFFFFE0AE),
              onRetry: _loadResults,
              onViewAll: () => Get.to(
                () => const PreviewResultViews(
                  initialType: ResultHistoryType.mock,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DashboardResultSection extends StatelessWidget {
  const _DashboardResultSection({
    required this.title,
    required this.emptyMessage,
    required this.errorMessage,
    required this.results,
    required this.backgroundColor,
    required this.borderColor,
    required this.onRetry,
    required this.onViewAll,
  });

  final String title;
  final String emptyMessage;
  final String errorMessage;
  final List<QuizSubmitResultItem> results;
  final Color backgroundColor;
  final Color borderColor;
  final Future<void> Function() onRetry;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onViewAll,
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (errorMessage.isNotEmpty)
            _PreviousResultState(message: errorMessage, onRetry: onRetry)
          else if (results.isEmpty)
            _PreviousResultState(message: emptyMessage)
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: List.generate(results.length, (index) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        child: _DashboardResultRow(result: results[index]),
                      ),
                      if (index != results.length - 1)
                        const Divider(
                          height: 1,
                          thickness: 1,
                          indent: 58,
                          color: Color(0xFFE4E7F2),
                        ),
                    ],
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _DashboardResultRow extends StatelessWidget {
  const _DashboardResultRow({required this.result});

  final QuizSubmitResultItem result;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: result.iconBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(result.icon, color: result.accent, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.quizTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${result.scoreText} • ${result.percentageText} • ${result.dateLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.resultMeta,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: result.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            result.passed ? 'Passed' : 'Failed',
            style: TextStyle(
              color: result.accent,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviousResultState extends StatelessWidget {
  const _PreviousResultState({required this.message, this.onRetry});

  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.resultMeta,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onRetry,
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecentBadgesCard extends StatelessWidget {
  const _RecentBadgesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.softBorder2,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Recent Badges',
            style: TextStyle(
              color: AppColors.textHeading,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BadgeItem(
                label: 'Quiz Master',
                color: AppColors.badgeGold,
                icon: Icons.workspace_premium_rounded,
              ),
              _BadgeItem(
                label: 'Fastest Finisher',
                color: AppColors.primary,
                icon: Icons.speed_rounded,
              ),
              _BadgeItem(
                label: '7 Day Streak',
                color: AppColors.badgeLocked,
                icon: Icons.lock_outline_rounded,
                textColor: AppColors.badgeLockedText,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveFeaturedCard extends StatelessWidget {
  const _LiveFeaturedCard({required this.item});

  final LiveClassScheduleData item;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardTabbarController>();
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.softBorder2),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/live_backImage.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.black.withValues(alpha: 0.02),
                      AppColors.black.withValues(alpha: 0.34),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 28,
              top: 24,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.primaryBright,
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  child: Text(
                    item.subject,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 28,
              right: 28,
              bottom: 28,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.title}\nwith ${item.teacher}',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _LiveNowButton(
                    text: item.joinButtonLabel,
                    enabled: item.canJoin,
                    onTap: item.canJoin
                        ? () => controller.joinLiveClass(item)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveScheduleCard extends StatelessWidget {
  const _LiveScheduleCard(this.item);

  final LiveClassScheduleData item;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardTabbarController>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: _cardDecoration(borderRadius: 28),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Text(
                item.timeText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: item.accent,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
            ),
            Container(
              width: 1,
              height: 110,
              color: AppColors.divider,
              margin: const EdgeInsets.symmetric(horizontal: 18),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: item.subjectColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      item.subject,
                      style: const TextStyle(
                        color: AppColors.purpleLabel,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: AppColors.textPrimaryAlt,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.teacher,
                    style: const TextStyle(
                      color: AppColors.neutralText5,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (item.timeRangeText.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.timeRangeText,
                      style: const TextStyle(
                        color: AppColors.textMuted8,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            _LiveNowButton(
              text: item.joinButtonLabel,
              enabled: item.canJoin,
              onTap: item.canJoin ? () => controller.joinLiveClass(item) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatarSection extends StatelessWidget {
  const _ProfileAvatarSection();

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<UserProfileProvider>(context).profile;
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryBright, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBright.withValues(alpha: 0.15),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
                gradient: const LinearGradient(
                  colors: [AppColors.profileRing, AppColors.profileRing2],
                ),
              ),
              child: Center(
                child: _ProfileAvatar(
                  imageUrl: profile?.profilePic ?? '',
                  size: 82,
                  iconSize: 50,
                  borderWidth: 0,
                  backgroundColor: AppColors.transparent,
                ),
              ),
            ),
            Positioned(
              right: -2,
              bottom: 10,
              child: GestureDetector(
                onTap: () => Get.to(() => const EditProfileViews()),
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.warning3,
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: AppColors.warningTextDark,
                    size: 17,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          profile?.name ?? 'Student',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                'CLASS ${profile?.userClass ?? '-'}',
                style: const TextStyle(
                  color: AppColors.primaryBright,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '•',
                style: TextStyle(
                  color: AppColors.neutralDot,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.boardBackground,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                '${profile?.educationBoard ?? '-'} BOARD',
                style: const TextStyle(
                  color: AppColors.boardText,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 34),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.neutralText8,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({required this.item});

  final ProfileMenuData item;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardTabbarController>();

    return InkWell(
      onTap: () {
        if (item.title == 'Terms of Service') {
          Get.to(
            () => const _ProfilePolicyScreen(
              title: 'Terms of Service',
              sections: _termsOfServiceSections,
            ),
          );
          return;
        }

        if (item.title == 'Privacy Shield') {
          Get.to(
            () => const _ProfilePolicyScreen(
              title: 'Privacy Shield',
              sections: _privacyShieldSections,
            ),
          );
          return;
        }

        controller.handleProfileMenuTap(item, context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.profileMenuBorder),
          ),
        ),
        child: Row(
          children: [
            Icon(item.icon, color: item.color, size: 26),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  color: item.color == AppColors.destructive
                      ? AppColors.destructive
                      : AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: item.color == AppColors.destructive
                  ? AppColors.neutralText11
                  : AppColors.neutralText10,
              size: 30,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePolicyScreen extends StatelessWidget {
  const _ProfilePolicyScreen({required this.title, required this.sections});

  final String title;
  final List<_PolicySectionData> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(
                  bottom: BorderSide(color: AppColors.headerBorder),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: Get.back,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textBlueDark,
                      size: 22,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textBlueDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cardShadow.withValues(alpha: 0.20),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (
                          var index = 0;
                          index < sections.length;
                          index++
                        ) ...[
                          _PolicySection(section: sections[index]),
                          if (index != sections.length - 1)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 18),
                              child: Divider(
                                color: AppColors.profileMenuBorder,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.section});

  final _PolicySectionData section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                section.icon,
                color: AppColors.primaryBright,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                section.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          section.body,
          style: const TextStyle(
            color: AppColors.neutralText5,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

class _PolicySectionData {
  const _PolicySectionData({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;
}

const _termsOfServiceSections = [
  _PolicySectionData(
    title: 'Learning Account',
    body:
        'EduPath Learning is built for student learning, practice, live classes, homework, notes, e-books, attendance, XP and leaderboard features. Use your own account only, keep your login details private, and make sure profile details such as class, board and school information are accurate.',
    icon: Icons.person_outline_rounded,
  ),
  _PolicySectionData(
    title: 'Classroom Conduct',
    body:
        'Join live classes on time, use respectful language with teachers and classmates, and do not share Meet links, lesson content, homework answers or private class material outside the app. Misuse of chat, doubt solving, calls, uploads or downloads may lead to restricted access.',
    icon: Icons.school_outlined,
  ),
  _PolicySectionData(
    title: 'Study Content',
    body:
        'Videos, PDFs, notes, quizzes, mock tests, e-books and worksheets are provided for personal study. You may save available files for offline learning inside the app, but you should not copy, resell, publish or redistribute the material without permission.',
    icon: Icons.menu_book_outlined,
  ),
  _PolicySectionData(
    title: 'Progress And Results',
    body:
        'Quiz scores, mock test attempts, lesson progress, XP, streaks, attendance and leaderboard rankings are shown to help you improve. Results depend on submitted answers, attendance records and teacher/admin updates, so occasional corrections or sync delays may happen.',
    icon: Icons.query_stats_rounded,
  ),
  _PolicySectionData(
    title: 'Safe Use',
    body:
        'Keep the app updated, use a stable internet connection for tests and live classes, and report any incorrect content or technical issue to support. The app can update features, learning rules or access controls to keep the platform reliable and safe.',
    icon: Icons.verified_user_outlined,
  ),
];

const _privacyShieldSections = [
  _PolicySectionData(
    title: 'Information We Use',
    body:
        'The app may use your name, mobile/email login details, class, board, profile photo, selected subjects, lesson progress, quiz attempts, homework submissions, attendance, XP, streaks, downloads and live class participation to personalize your learning experience.',
    icon: Icons.badge_outlined,
  ),
  _PolicySectionData(
    title: 'Why It Is Needed',
    body:
        'Your data helps show the right subjects, unlock chapters, save progress, display marks, manage attendance, recommend practice, support teacher doubt solving, maintain downloads, and keep your account secure across app sessions.',
    icon: Icons.tune_rounded,
  ),
  _PolicySectionData(
    title: 'Student Safety',
    body:
        'Student information is used only for learning, support, classroom management and platform safety. We avoid asking for unnecessary personal details, and sensitive actions such as profile updates, sign out and account deletion stay under account control.',
    icon: Icons.shield_outlined,
  ),
  _PolicySectionData(
    title: 'Storage And Downloads',
    body:
        'Offline PDFs and learning files are saved on your device for study access. You can remove individual downloads or clear all downloads from the Downloads screen. Deleting downloads removes local files but does not erase your account progress.',
    icon: Icons.download_done_outlined,
  ),
  _PolicySectionData(
    title: 'Your Choices',
    body:
        'You can update profile details, sign out, clear downloads, or request account deletion from the profile area. If something looks wrong in your profile, attendance, progress or results, contact your school or app support for correction.',
    icon: Icons.settings_outlined,
  ),
];

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.summary});

  final LeaderboardStripData summary;

  @override
  Widget build(BuildContext context) {
    final students = summary.topStudents;
    final showRemaining = summary.remainingStudents > 0;
    final width = students.isEmpty
        ? 0.0
        : ((students.length - 1) * 20 + 34 + (showRemaining ? 20 : 0))
              .toDouble();

    return SizedBox(
      width: width,
      height: 34,
      child: Stack(
        children: [
          for (var index = 0; index < students.length; index++)
            Positioned(
              left: index * 20,
              child: CircleAvatar(
                radius: 17,
                backgroundColor: students[index].color,
                child: Text(
                  students[index].initials,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          if (showRemaining)
            Positioned(
              left: students.length * 20,
              child: CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.avatarLight,
                child: Text(
                  summary.remainingText,
                  style: const TextStyle(
                    color: AppColors.neutralText9,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  const _BadgeItem({
    required this.label,
    required this.color,
    required this.icon,
    this.textColor = AppColors.textDark,
  });

  final String label;
  final Color color;
  final IconData icon;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 34,
          backgroundColor: color,
          child: Icon(icon, color: AppColors.white, size: 25),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 84,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.profileMenuBorder,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BannerButton extends StatelessWidget {
  const _BannerButton({required this.text, this.inverted = false, this.onTap});

  final String text;
  final bool inverted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: inverted ? AppColors.white : AppColors.primary,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: inverted ? AppColors.primary : AppColors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _LiveNowButton extends StatelessWidget {
  const _LiveNowButton({required this.text, required this.enabled, this.onTap});

  final String text;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = enabled ? AppColors.white : AppColors.neutralText7;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : AppColors.neutralSurface3,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                color: foreground,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (enabled) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.white,
                size: 22,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration({double borderRadius = 26}) {
  return BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(color: AppColors.cardBorder),
    boxShadow: [
      BoxShadow(
        color: AppColors.cardShadow.withValues(alpha: 0.24),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
