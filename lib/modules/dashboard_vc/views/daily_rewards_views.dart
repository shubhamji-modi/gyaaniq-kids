import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/appcolors.dart';
import '../controllers/dashboard_tabbar_controller.dart';

class DailyRewardsViews extends GetView<DashboardTabbarController> {
  const DailyRewardsViews({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
        ),
        title: const Text(
          'Daily Rewards',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Obx(() {
            final xp = controller.userXpSummary.value.xp;
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.purpleSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.purpleDark2,
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$xp XP',
                      style: const TextStyle(
                        color: AppColors.purpleDark2,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Obx(() {
          final xpSummary = controller.userXpSummary.value;
          final streakCount = xpSummary.streakCount;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _RewardHeroCard(
                streakCount: streakCount,
                dailyClaim: controller.dailyClaimXp.value,
                countdown: controller.dailyClaimCountdown.value,
                isClaiming: controller.isClaimingDailyXp.value,
                onClaim: controller.claimDailyXp,
              ),
              const SizedBox(height: 20),
              _StreakJourneyCard(streakCount: streakCount),
            ],
          );
        }),
      ),
    );
  }
}

class _RewardHeroCard extends StatelessWidget {
  const _RewardHeroCard({
    required this.streakCount,
    required this.dailyClaim,
    required this.countdown,
    required this.isClaiming,
    required this.onClaim,
  });

  final int streakCount;
  final DailyClaimXpData dailyClaim;
  final Duration countdown;
  final bool isClaiming;
  final VoidCallback onClaim;

  String get _countdownText {
    final hours = countdown.inHours.toString().padLeft(2, '0');
    final minutes = (countdown.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (countdown.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final canClaim = dailyClaim.claimable && !isClaiming;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C2BD9), Color(0xFF4A4FD9)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C2BD9).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _HeroPill(
                icon: Icons.local_fire_department_rounded,
                iconColor: const Color(0xFFFF8A3D),
                label:
                    'Active Streak: ${streakCount.toString().padLeft(2, '0')} Days',
              ),
              const Spacer(),
              const _HeroPill(
                icon: Icons.bolt_rounded,
                iconColor: Color(0xFFFFD54A),
                label: '2X BOOST',
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Center(
                  child: Icon(
                    Icons.diamond_rounded,
                    color: Color(0xFF3DB6E8),
                    size: 42,
                  ),
                ),
                Positioned(
                  top: -8,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF12B76A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      '+${dailyClaim.displayAmount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            dailyClaim.claimedToday
                ? 'COLLECTED TODAY'
                : dailyClaim.enabled
                ? 'READY TO COLLECT'
                : 'REWARDS PAUSED',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            dailyClaim.claimedToday
                ? '+${dailyClaim.displayAmount} XP Earned Today!'
                : dailyClaim.enabled
                ? '+${dailyClaim.displayAmount} XP Waiting for You!'
                : 'Come back later for XP rewards',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            dailyClaim.claimedToday && countdown > Duration.zero
                ? 'Next claim unlocks in $_countdownText'
                : 'Check-in daily to keep your streak alive and\nunlock the Day 7 Mystery Mega Chest!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canClaim ? onClaim : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF7C2BD9),
                disabledBackgroundColor: Colors.white70,
                disabledForegroundColor: const Color(0xFF7C2BD9),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              child: isClaiming
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF7C2BD9),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFB020),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dailyClaim.buttonLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
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

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakJourneyCard extends StatelessWidget {
  const _StreakJourneyCard({required this.streakCount});

  final int streakCount;

  static const _rewards = [10, 20, 25, 30, 40, 100];

  @override
  Widget build(BuildContext context) {
    final currentDay = (streakCount % 7 == 0 ? streakCount : streakCount) + 1;
    final activeDay = currentDay.clamp(1, 7);
    final claimed = (activeDay - 1).clamp(0, 7);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '7-Day Streak Journey',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.purpleDark2,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Step $activeDay of 7',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Keep learning daily to avoid streak freeze',
                      style: TextStyle(
                        color: AppColors.neutralText8,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.streakBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: AppColors.streakIcon,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${activeDay}d',
                      style: const TextStyle(
                        color: AppColors.streakText,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: List.generate(7, (index) {
              final day = index + 1;
              final isMega = day == 7;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: day == 7 ? 0 : 6),
                  child: _StreakDayTile(
                    day: day,
                    isClaimed: day <= claimed,
                    isActive: day == activeDay,
                    isMega: isMega,
                    xp: isMega ? 100 : _rewards[index],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: claimed / 7,
              minHeight: 6,
              backgroundColor: AppColors.neutralSurface3,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.purpleDark2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$claimed/7 Claimed',
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

class _StreakDayTile extends StatelessWidget {
  const _StreakDayTile({
    required this.day,
    required this.isClaimed,
    required this.isActive,
    required this.isMega,
    required this.xp,
  });

  final int day;
  final bool isClaimed;
  final bool isActive;
  final bool isMega;
  final int xp;

  @override
  Widget build(BuildContext context) {
    final Color circleColor = isMega
        ? const Color(0xFFFFB020)
        : isClaimed
        ? AppColors.success
        : isActive
        ? AppColors.purpleDark2
        : AppColors.neutralSurface3;

    final Color labelColor = isActive || isClaimed || isMega
        ? AppColors.textPrimary
        : AppColors.neutralText8;

    return Column(
      children: [
        Text(
          'Day $day',
          style: TextStyle(
            color: labelColor,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isClaimed || isActive || isMega
                ? circleColor
                : AppColors.neutralSurface3,
            shape: BoxShape.circle,
            border: isActive
                ? Border.all(color: AppColors.purpleSoft2, width: 3)
                : null,
          ),
          child: Center(
            child: isClaimed
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : isMega
                ? const Icon(
                    Icons.card_giftcard_rounded,
                    color: Colors.white,
                    size: 18,
                  )
                : Icon(
                    Icons.bolt_rounded,
                    color: isActive ? Colors.white : AppColors.neutralText9,
                    size: 18,
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '+$xp',
          style: TextStyle(
            color: isActive ? AppColors.purpleDark2 : AppColors.neutralText8,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
