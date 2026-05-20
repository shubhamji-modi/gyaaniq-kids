import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../../../core/data/user_profile_provider.dart';
import '../../../../core/theme/appcolors.dart';

import '../../menubar/edit profile/views/edit_profile_views.dart';
import '../../daily_quiz/views/start_quiz_views.dart';
import '../../daily_quiz/result/preview_result/views/preview_result_views.dart';
import '../../daily_quiz/practice_test/Views/quiz_practice_paper_subject_views.dart';
import '../../explore_classes/views/explore_classes_views.dart';
import '../controllers/dashboard_tabbar_controller.dart';

class DashboardTabbarViewsScreen extends StatelessWidget {
  const DashboardTabbarViewsScreen({super.key});

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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.avatarGradientStart,
                      AppColors.avatarGradientEnd,
                    ],
                  ),
                  border: Border.all(color: AppColors.avatarBorder, width: 2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.person_rounded,
                    color: AppColors.white,
                    size: 28,
                  ),
                ),
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
                Text(
                  controller.streakText,
                  style: const TextStyle(
                    color: AppColors.streakText,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.iconMuted,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return _DashboardScaffold(
      child: Column(
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
            'Master your goals with interactive quests.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          const _JourneyCard(),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(child: _DailyQuizMiniCard()),
              SizedBox(width: 14),
              Expanded(child: _AiTutorCard()),
            ],
          ),
          const SizedBox(height: 18),
          const _LeaderboardStripCard(),
          const SizedBox(height: 18),
          Row(
            children: const [
              Text(
                'Live Classes',
                style: TextStyle(
                  color: AppColors.textPrimaryNavy,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Spacer(),
              Text(
                '● LIVE NOW',
                style: TextStyle(
                  color: AppColors.live,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _LiveHeroCard(),
          const SizedBox(height: 18),
          const _SpokenEnglishCard(),
          const SizedBox(height: 18),
          InkWell(
            onTap: () => Get.to(() => const ExploreClassesViews()),
            borderRadius: BorderRadius.circular(24),
            child: const _ExploreClassesCard(),
          ),
        ],
      ),
    );
  }
}

class _LearnTab extends GetView<DashboardTabbarController> {
  const _LearnTab();

  @override
  Widget build(BuildContext context) {
    return _DashboardScaffold(
      child: Column(
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
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.subjects.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.90,
            ),
            itemBuilder: (context, index) {
              final subject = controller.subjects[index];
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
          _PreviousResultsCard(results: controller.previousResults),
          const SizedBox(height: 18),
          const _RecentBadgesCard(),
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
      child: Column(
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
          const _LiveFeaturedCard(),
          const SizedBox(height: 20),
          ...controller.liveClassSchedules.map(_LiveScheduleCard.new),
        ],
      ),
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
          Row(
            children: const [
              Expanded(
                child: _StatCard(
                  icon: Icons.auto_awesome,
                  iconColor: AppColors.purpleDark2,
                  title: '2,450',
                  subtitle: 'Total XP',
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department,
                  iconColor: AppColors.warningText,
                  title: '12 Days',
                  subtitle: 'Streak',
                ),
              ),
            ],
          ),
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
            const Text(
              '42 Active Chapters',
              style: TextStyle(
                color: AppColors.neutralText2,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 25),
            Row(
              children: const [
                Text(
                  'Overall Progress',
                  style: TextStyle(
                    color: AppColors.textMuted3,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                Text(
                  '68%',
                  style: TextStyle(
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
              child: const LinearProgressIndicator(
                value: 0.68,
                minHeight: 10,
                backgroundColor: AppColors.neutralSurface3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
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

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                SizedBox(height: 14),
                _AvatarStack(),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Global Rank: #1,240',
                style: TextStyle(
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
  }
}

class _LiveHeroCard extends StatelessWidget {
  const _LiveHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            height: 140,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.liveHeroStart, AppColors.liveHeroEnd],
              ),
            ),
            child: Stack(
              children: [
                const Positioned(
                  left: 18,
                  top: 16,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.live,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Text(
                        'LIVE',
                        style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
                const Center(
                  child: CircleAvatar(
                    radius: 64,
                    backgroundColor: AppColors.liveHeroCircle,
                    child: Icon(
                      Icons.public_rounded,
                      color: AppColors.liveHeroIcon,
                      size: 84,
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 14,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.black.withValues(alpha: 0),
                          AppColors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Integration & Calculus Mastery',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Dr. Aris Thorne • 1.2k watching',
                          style: TextStyle(
                            color: AppColors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_outlined,
                  color: AppColors.liveIconMuted,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Ends in 25 mins',
                  style: TextStyle(
                    color: AppColors.liveTextMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Join Class',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
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
    final value = double.parse(subject.progressLabel.replaceAll('%', '')) / 100;
    final controller = Get.find<DashboardTabbarController>();

    return InkWell(
      onTap: () => controller.openLearnSubjectFromCard(subject.title),
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
                      value: value,
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
              'Continue',
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
    return Container(
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
          const Text(
            'Mock Test',
            style: TextStyle(
              color: AppColors.textHeading,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Real exam simulation with timers.',
            style: TextStyle(
              color: AppColors.textSecondaryAlt,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.neutralSurface4,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.event_note_rounded,
                  color: AppColors.primaryBright,
                  size: 15,
                ),
                SizedBox(width: 8),
                Text(
                  'Next: Sunday, 10 AM',
                  style: TextStyle(
                    color: AppColors.neutralText4,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard();

  @override
  Widget build(BuildContext context) {
    const heights = [52.0, 72.0, 60.0, 96.0, 86.0, 108.0];
    const colors = [
      AppColors.primaryTint,
      AppColors.primaryTint2,
      AppColors.primaryTint3,
      AppColors.primaryTint4,
      AppColors.primaryTint5,
      AppColors.analyticsHighlight,
    ];
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'Test Analytics',
                style: TextStyle(
                  color: AppColors.textHeading,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Spacer(),
              // Icon(Icons.query_stats_rounded, color: Color(0xFF4A4FD9)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(heights.length, (index) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 48,
                      height: heights[index],
                      decoration: BoxDecoration(
                        color: colors[index],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      labels[index],
                      style: const TextStyle(
                        color: AppColors.analyticsLabel,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'Your accuracy increased by 12% this\nweek!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.neutralText3,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviousResultsCard extends StatelessWidget {
  const _PreviousResultsCard({required this.results});

  final List<PreviousResultData> results;

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
                'Previous Results',
                style: TextStyle(
                  color: AppColors.textHeading,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Get.to(() => const PreviewResultViews()),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...results.map(
            (result) => Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Row(
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
                          result.title,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          result.meta,
                          style: const TextStyle(
                            color: AppColors.resultMeta,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        result.scoreText,
                        style: const TextStyle(
                          color: AppColors.primaryScore,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'SCORE',
                        style: TextStyle(
                          color: AppColors.textMuted4,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
  const _LiveFeaturedCard();

  @override
  Widget build(BuildContext context) {
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.blueGrayLight, AppColors.grayBlue],
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
                      AppColors.black.withValues(alpha: 0.04),
                      AppColors.black.withValues(alpha: 0.42),
                    ],
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 28,
              top: 24,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primaryBright,
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  child: Text(
                    'Mathematics',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 28,
              right: 28,
              bottom: 28,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Algebra Foundations\nwith Dr. Sarah Miller',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  _LiveNowButton(),
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
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.neutralText7,
              size: 30,
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
              child: const Center(
                child: Icon(
                  Icons.person_rounded,
                  size: 50,
                  color: AppColors.profileIcon,
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
      onTap: () => controller.handleProfileMenuTap(item),
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

class _AvatarStack extends StatelessWidget {
  const _AvatarStack();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 34,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.avatarGray,
            ),
          ),
          Positioned(
            left: 20,
            child: CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.avatarPink,
            ),
          ),
          Positioned(
            left: 40,
            child: CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.avatarBrown,
            ),
          ),
          Positioned(
            left: 60,
            child: CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.avatarLight,
              child: Text(
                '+42',
                style: TextStyle(
                  color: AppColors.neutralText9,
                  fontSize: 12,
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
  const _LiveNowButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(26),
      ),
      child: const Row(
        children: [
          Text(
            'Join Now',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward_rounded, color: AppColors.white, size: 24),
        ],
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
