import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../../../core/data/user_profile_provider.dart';

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
      backgroundColor: const Color(0xFFF6F8FD),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5561E9).withValues(alpha: 0.18),
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
                          ? const Color(0xFF5A5FEF)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF4B4B62),
                          size: 22,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF4B4B62),
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
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE0E5F2))),
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
                    colors: [Color(0xFF123F96), Color(0xFF081B42)],
                  ),
                  border: Border.all(color: const Color(0xFF0B4CC4), width: 2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const Positioned(
                right: -1,
                bottom: -1,
                child: CircleAvatar(
                  radius: 9,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 7,
                    backgroundColor: Color(0xFF22C55E),
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
                    color: Color(0xFF18233D),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'CLASS ${profile?.userClass ?? '-'} • ${profile?.educationBoard ?? '-'} BOARD',
                  style: const TextStyle(
                    color: Color(0xFF6E7B95),
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
              color: const Color(0xFFFFFBF1),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Color(0xFFF6D27D)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_fire_department_outlined,
                  color: Color(0xFFF59E0B),
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  controller.streakText,
                  style: const TextStyle(
                    color: Color(0xFFC46609),
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
            color: Color(0xFF515A70),
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
              color: Color(0xFF0F378C),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Master your goals with interactive quests.',
            style: TextStyle(
              color: Color(0xFF62708D),
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
                  color: Color(0xFF1A2540),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Spacer(),
              Text(
                '● LIVE NOW',
                style: TextStyle(
                  color: Color(0xFFEF4444),
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
              color: Color(0xFF1F2637),
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
              color: Color(0xFF1F2637),
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
              color: Color(0xFF1F2637),
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
                  iconColor: Color(0xFF7C2BD9),
                  title: '2,450',
                  subtitle: 'Total XP',
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department,
                  iconColor: Color(0xFF996300),
                  title: '12 Days',
                  subtitle: 'Streak',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFCBD4ED).withValues(alpha: 0.32),
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
              color: Color(0xFFB2B7C8),
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
                color: const Color(0xFFE1E0FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.import_contacts_rounded,
                color: Color(0xFF4A4FD9),
                size: 25,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Learning',
              style: TextStyle(
                color: Color(0xFF1C2233),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '42 Active Chapters',
              style: TextStyle(
                color: Color(0xFF2F3750),
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
                    color: Color(0xFF666D84),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                Text(
                  '68%',
                  style: TextStyle(
                    color: Color(0xFF4A4FD9),
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
                backgroundColor: Color(0xFFE7EAF1),
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A4FD9)),
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
          color: const Color(0xFF163B98),
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
                  color: const Color(0xFFFFC61B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'BONUS +50 XP',
                  style: TextStyle(
                    color: Color(0xFF062C7F),
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
                  color: Colors.white,
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
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Start Now',
                  style: TextStyle(
                    color: Colors.white,
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
                color: Colors.white.withValues(alpha: 0.12),
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
        color: const Color(0xFFF8F9FD),
        border: Border.all(color: const Color(0xFFE2E6F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFFA176F5),
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'AI Tutor',
            style: TextStyle(
              color: Color(0xFF30384A),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Ask any doubt\ninstant solutions.',
            style: TextStyle(
              color: Color(0xFF9AA4BA),
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
              color: const Color(0xFFF4F6FB),
              border: Border.all(color: const Color(0xFFD9DFEC)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFF9AA4BA),
                  size: 14,
                ),
                SizedBox(width: 6),
                Text(
                  'Locked',
                  style: TextStyle(
                    color: Color(0xFF9AA4BA),
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
                      color: Color(0xFFFFB200),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Leaderboard',
                      style: TextStyle(
                        color: Color(0xFF1B2436),
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
                  color: Color(0xFFA0A7BD),
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
                    color: const Color(0xFF143B98),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: const Text(
                    'View Ranking',
                    style: TextStyle(
                      color: Colors.white,
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
                colors: [Color(0xFF41210D), Color(0xFF17110D)],
              ),
            ),
            child: Stack(
              children: [
                const Positioned(
                  left: 18,
                  top: 16,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFFEF4444),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
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
                    backgroundColor: Color(0xFF195C76),
                    child: Icon(
                      Icons.public_rounded,
                      color: Color(0xFFE8BD77),
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
                          Colors.black.withValues(alpha: 0),
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Integration & Calculus Mastery',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Dr. Aris Thorne • 1.2k watching',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
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
                const Icon(Icons.schedule_outlined, color: Color(0xFF8B98B5)),
                const SizedBox(width: 10),
                const Text(
                  'Ends in 25 mins',
                  style: TextStyle(
                    color: Color(0xFF67748E),
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
                    color: const Color(0xFF163B98),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Join Class',
                    style: TextStyle(
                      color: Colors.white,
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
        color: const Color(0xFFF8F9FD),
        border: Border.all(color: const Color(0xFFE2E6F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFFA176F5),
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Spoken English',
            style: TextStyle(
              color: Color(0xFF30384A),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Practice with AI Tutor',
            style: TextStyle(
              color: Color(0xFF9AA4BA),
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
              color: const Color(0xFFF4F6FB),
              border: Border.all(color: const Color(0xFFD9DFEC)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFF9AA4BA),
                  size: 14,
                ),
                SizedBox(width: 6),
                Text(
                  'Locked',
                  style: TextStyle(
                    color: Color(0xFF9AA4BA),
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
              color: const Color(0xFFF0DEFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.travel_explore,
              color: Color(0xFF7E2AD9),
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
                    color: Color(0xFF1C2233),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Explore your learning path.',
                  style: TextStyle(
                    color: Color(0xFF4B4F61),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF747B8E),
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
                color: Color(0xFF1D2231),
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
                      backgroundColor: const Color(0xFFE4E7EE),
                      valueColor: AlwaysStoppedAnimation<Color>(subject.accent),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  subject.progressLabel,
                  style: TextStyle(
                    color: const Color(0xFF4B4F61).withValues(alpha: 0.92),
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
                        color: Color(0xFF1D2231),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tool.subtitle,
                      style: const TextStyle(
                        color: Color(0xFF4E5366),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF767D90),
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
        color: const Color(0xFF4A4FD9),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A4FD9).withValues(alpha: 0.26),
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
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⚡ DAILY CHALLENGE',
                style: TextStyle(
                  color: Color(0xFFE9E9FF),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Daily Quiz',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'Test your knowledge with 5 quick \nquestions andearn a 2x XP multiplier!',
                style: TextStyle(
                  color: Colors.white,
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
                    color: const Color(0xFFF0DEFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFF7E2AD9),
                    size: 25,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFFC4BCD7),
                  size: 28,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Practice Quiz',
              style: TextStyle(
                color: Color(0xFF1F2430),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Chapter-wise focused practice\nsessions.',
              style: TextStyle(
                color: Color(0xFF4B5161),
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
              color: const Color(0xFFFFE2BA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.alarm_rounded,
              color: Color(0xFF5E3B00),
              size: 25,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Mock Test',
            style: TextStyle(
              color: Color(0xFF1F2430),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Real exam simulation with timers.',
            style: TextStyle(
              color: Color(0xFF4B5161),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE3E7EE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.event_note_rounded,
                  color: Color(0xFF5A5FEF),
                  size: 15,
                ),
                SizedBox(width: 8),
                Text(
                  'Next: Sunday, 10 AM',
                  style: TextStyle(
                    color: Color(0xFF41485A),
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
      Color(0xFFD8D9FB),
      Color(0xFFB9BAEF),
      Color(0xFF8E8FE2),
      Color(0xFF676AE0),
      Color(0xFF4447D8),
      Color(0xFFFFAA18),
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
                  color: Color(0xFF1F2430),
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
                        color: Color(0xFF6E7488),
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
                color: Color(0xFF31384A),
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
                  color: Color(0xFF1F2430),
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
                    color: Color(0xFF4A4FD9),
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
                            color: Color(0xFF202534),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          result.meta,
                          style: const TextStyle(
                            color: Color(0xFF7A8093),
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
                          color: Color(0xFF3345FF),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'SCORE',
                        style: TextStyle(
                          color: Color(0xFF747B8E),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFFC8D0E6),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Recent Badges',
            style: TextStyle(
              color: Color(0xFF1F2430),
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
                color: Color(0xFFC98609),
                icon: Icons.workspace_premium_rounded,
              ),
              _BadgeItem(
                label: 'Fastest Finisher',
                color: Color(0xFF4A4FD9),
                icon: Icons.speed_rounded,
              ),
              _BadgeItem(
                label: '7 Day Streak',
                color: Color(0xFFD9DCE4),
                icon: Icons.lock_outline_rounded,
                textColor: Color(0xFF9BA1AF),
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
        border: Border.all(color: const Color(0xFFC8D0E6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCBD4ED).withValues(alpha: 0.24),
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
                  colors: [Color(0xFFDBEEF7), Color(0xFF8E9C96)],
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
                      Colors.black.withValues(alpha: 0.04),
                      Colors.black.withValues(alpha: 0.42),
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
                  color: Color(0xFF5A5FEF),
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  child: Text(
                    'Mathematics',
                    style: TextStyle(
                      color: Colors.white,
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
                        color: Colors.white,
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
              color: const Color(0xFFD5DAEA),
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
                        color: Color(0xFF3B136B),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Color(0xFF1C2233),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.teacher,
                    style: const TextStyle(
                      color: Color(0xFF555C70),
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
              color: Color(0xFF7B8197),
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
                border: Border.all(color: const Color(0xFF5A5FEF), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5A5FEF).withValues(alpha: 0.15),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
                gradient: const LinearGradient(
                  colors: [Color(0xFFF5F7FB), Color(0xFFE3E8F2)],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.person_rounded,
                  size: 50,
                  color: Color(0xFF1B3C97),
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
                    color: Color(0xFFFFB020),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Color(0xFF5E3B00),
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
            color: Color(0xFF1D2231),
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
                color: const Color(0xFFE8E6FF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                'CLASS ${profile?.userClass ?? '-'}',
                style: const TextStyle(
                  color: Color(0xFF5A5FEF),
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
                  color: Color(0xFFC1C4D3),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF6EEDC),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                '${profile?.educationBoard ?? '-'} BOARD',
                style: const TextStyle(
                  color: Color(0xFF946000),
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
              color: Color(0xFF1D2231),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF7A7C8C),
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
          border: Border(bottom: BorderSide(color: Color(0xFFF0F2F8))),
        ),
        child: Row(
          children: [
            Icon(item.icon, color: item.color, size: 26),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  color: item.color == const Color(0xFFC81E1E)
                      ? const Color(0xFFC81E1E)
                      : const Color(0xFF1D2231),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: item.color == const Color(0xFFC81E1E)
                  ? const Color(0xFFE4B1B1)
                  : const Color(0xFFC6CAD8),
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
            child: CircleAvatar(radius: 17, backgroundColor: Color(0xFFBCC4D9)),
          ),
          Positioned(
            left: 20,
            child: CircleAvatar(radius: 17, backgroundColor: Color(0xFFD8A9A9)),
          ),
          Positioned(
            left: 40,
            child: CircleAvatar(radius: 17, backgroundColor: Color(0xFF9F8A7B)),
          ),
          Positioned(
            left: 60,
            child: CircleAvatar(
              radius: 17,
              backgroundColor: Color(0xFFF0F3F8),
              child: Text(
                '+42',
                style: TextStyle(
                  color: Color(0xFF8190AD),
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
    this.textColor = const Color(0xFF202534),
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
          child: Icon(icon, color: Colors.white, size: 25),
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
        color: const Color(0xFFF0F2F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF4B4F61),
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
          color: inverted ? Colors.white : const Color(0xFF4A4FD9),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: inverted ? const Color(0xFF4A4FD9) : Colors.white,
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
        color: const Color(0xFF4A4FD9),
        borderRadius: BorderRadius.circular(26),
      ),
      child: const Row(
        children: [
          Text(
            'Join Now',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration({double borderRadius = 26}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(color: const Color(0xFFE3E8F4)),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFFCBD4ED).withValues(alpha: 0.24),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
