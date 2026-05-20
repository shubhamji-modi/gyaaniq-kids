import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/leaderboard_controller.dart';

class LeaderboardViews extends StatelessWidget {
  const LeaderboardViews({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<LeaderboardController>()
        ? Get.find<LeaderboardController>()
        : Get.put(LeaderboardController());

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Column(
          children: [
            const _LeaderboardHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 26),
                child: Column(
                  children: [
                    SizedBox(
                      height: 220,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: _TopRankCard(user: controller.topThree[0])),
                          Expanded(
                            flex: 2,
                            child: _TopRankCard(
                              user: controller.topThree[1],
                              isCenter: true,
                            ),
                          ),
                          Expanded(child: _TopRankCard(user: controller.topThree[2])),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    _CurrentUserCard(user: controller.currentUser),
                    const SizedBox(height: 15),
                    ...controller.rankings.map(
                      (user) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _RankingListTile(user: user),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardHeader extends StatelessWidget {
  const _LeaderboardHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4E7F0))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF123887),
              size: 22,
            ),
          ),
          const Expanded(
            child: Text(
              'Leaderboard',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF123887),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _TopRankCard extends GetView<LeaderboardController> {
  const _TopRankCard({required this.user, this.isCenter = false});

  final LeaderboardUser user;
  final bool isCenter;

  @override
  Widget build(BuildContext context) {
    final avatarSize = isCenter ? 110.0 : 70.0;
    final badgeSize = isCenter ? 40.0 : 30.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            _AvatarBubble(
              initials: user.initials,
              size: avatarSize,
              ringColor: user.ringColor,
              gradient: user.avatarGradient,
              fontSize: isCenter ? 40 : 22,
            ),
            Positioned(
              top: isCenter ? -16 : -12,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color: user.rank == 2
                      ? const Color(0xFFDDE6F6)
                      : const Color(0xFFFFA81E),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFCBD4ED).withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: user.isChampion
                      ? const Icon(
                          Icons.workspace_premium_rounded,
                          color: Color(0xFF654000),
                          size: 25,
                        )
                      : Text(
                          '${user.rank}',
                          style: const TextStyle(
                            color: Color(0xFF202436),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          user.name,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF202436),
            fontSize: isCenter ? 19 : 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCenter ? 12 : 0,
            vertical: isCenter ? 5 : 0,
          ),
          decoration: isCenter
              ? BoxDecoration(
                  color: const Color(0xFFF0D5FF),
                  borderRadius: BorderRadius.circular(24),
                )
              : null,
          child: Text(
            controller.formatXp(user.xp),
            style: TextStyle(
              color: const Color(0xFF4D4FE1),
              fontSize: isCenter ? 14 : 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _CurrentUserCard extends GetView<LeaderboardController> {
  const _CurrentUserCard({required this.user});

  final LeaderboardUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4E51E3), Color(0xFF646AF7)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C62EE).withValues(alpha: 0.30),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          _AvatarBubble(
            initials: user.initials,
            size: 40,
            ringColor: Colors.white,
            gradient: user.avatarGradient,
            fontSize: 15,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 0),
                Text(
                  user.subtitle ?? '',
                  style: const TextStyle(
                    color: Color(0xFFE4E4FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            controller.formatXp(user.xp).replaceFirst(' XP', ' XP'),
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingListTile extends GetView<LeaderboardController> {
  const _RankingListTile({required this.user});

  final LeaderboardUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDFE4EE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCBD4ED).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${user.rank}',
              style: const TextStyle(
                color: Color(0xFF4B4D63),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 14),
          _AvatarBubble(
            initials: user.initials,
            size: 45,
            ringColor: const Color(0xFFF1F4F8),
            gradient: user.avatarGradient,
            fontSize: 17,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              user.name,
              style: const TextStyle(
                color: Color(0xFF202436),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            controller.formatXp(user.xp).replaceAll(' XP', ''),
            style: const TextStyle(
              color: Color(0xFF4D4FE1),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.star_rounded,
            color: Color(0xFFFFA81E),
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _AvatarBubble extends StatelessWidget {
  const _AvatarBubble({
    required this.initials,
    required this.size,
    required this.ringColor,
    required this.gradient,
    required this.fontSize,
  });

  final String initials;
  final double size;
  final Color ringColor;
  final List<Color> gradient;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ringColor,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCBD4ED).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
