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
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.errorMessage.value.isNotEmpty) {
                  return _LeaderboardState(
                    title: 'Unable to load leaderboard',
                    message: controller.errorMessage.value,
                    onRetry: controller.loadLeaderboard,
                  );
                }

                if (controller.top.isEmpty && controller.currentUser == null) {
                  return _LeaderboardState(
                    title: 'No leaderboard yet',
                    message: 'Your class leaderboard will appear here soon.',
                    onRetry: controller.loadLeaderboard,
                  );
                }

                final topThree = controller.topThree;
                final currentUser = controller.currentUser;

                return RefreshIndicator(
                  onRefresh: controller.loadLeaderboard,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 18, 14, 26),
                    child: Column(
                      children: [
                        if (topThree.isNotEmpty)
                          SizedBox(
                            height: 220,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: topThree.length > 1
                                      ? _TopRankCard(user: topThree[1])
                                      : const SizedBox.shrink(),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _TopRankCard(
                                    user: topThree.first,
                                    isCenter: true,
                                  ),
                                ),
                                Expanded(
                                  child: topThree.length > 2
                                      ? _TopRankCard(user: topThree[2])
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                        if (topThree.isNotEmpty) const SizedBox(height: 40),
                        if (currentUser != null) ...[
                          _CurrentUserCard(user: currentUser),
                          const SizedBox(height: 15),
                        ],
                        ...controller.rankings.map(
                          (user) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _RankingListTile(user: user),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardState extends StatelessWidget {
  const _LeaderboardState({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF202436),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF4B4D63),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4D4FE1),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
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
    final controller = Get.find<LeaderboardController>();

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
          InkWell(
            onTap: () => _openClassPrizesSheet(controller),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8A3D), Color(0xFFFF5A5F)],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5A5F).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.card_giftcard_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Prizes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

void _openClassPrizesSheet(LeaderboardController controller) {
  controller.loadClassPrizes();
  Get.bottomSheet<void>(
    _ClassPrizesSheet(controller: controller),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class _ClassPrizesSheet extends StatelessWidget {
  const _ClassPrizesSheet({required this.controller});

  final LeaderboardController controller;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.74;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1E4EA),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF8A3D), Color(0xFFFF5A5F)],
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Class Prizes',
                          style: TextStyle(
                            color: Color(0xFF1B1F2A),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Obx(
                          () => Text(
                            controller.prizesClassLevel.value.isEmpty
                                ? 'Top 5 prizes for your class'
                                : 'Top 5 prizes for Class ${controller.prizesClassLevel.value}',
                            style: const TextStyle(
                              color: Color(0xFF8A8F9C),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: Get.back,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F3F8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF5B6172),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Obx(() {
                  if (controller.isLoadingPrizes.value) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (controller.prizesError.value.isNotEmpty) {
                    return _PrizesStateMessage(
                      icon: Icons.error_outline_rounded,
                      message: controller.prizesError.value,
                      onRetry: controller.loadClassPrizes,
                    );
                  }
                  if (controller.classPrizes.isEmpty) {
                    return const _PrizesStateMessage(
                      icon: Icons.card_giftcard_rounded,
                      message: 'No prizes have been set for your class yet.',
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(top: 10, bottom: 6),
                    itemCount: controller.classPrizes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) =>
                        _ClassPrizeTile(prize: controller.classPrizes[index]),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassPrizeTile extends StatelessWidget {
  const _ClassPrizeTile({required this.prize});

  final ClassPrize prize;

  @override
  Widget build(BuildContext context) {
    final rankColor = _prizeRankColor(prize.rank);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            rankColor.withValues(alpha: 0.18),
            rankColor.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: rankColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rankColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: rankColor.withValues(alpha: 0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: prize.rank == 1
                ? const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 20,
                  )
                : Text(
                    '${prize.rank}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: rankColor.withValues(alpha: 0.30)),
            ),
            clipBehavior: Clip.antiAlias,
            child: prize.imageUrl != null
                ? Image.network(
                    prize.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _PrizePlaceholder(),
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                        ? child
                        : const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                  )
                : const _PrizePlaceholder(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prize.rank == 1
                      ? 'Top Prize'
                      : 'Rank #${prize.rank}',
                  style: TextStyle(
                    color: rankColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  prize.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1B1F2A),
                    fontSize: 15,
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

class _PrizePlaceholder extends StatelessWidget {
  const _PrizePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFEFF1F7),
      child: Icon(
        Icons.card_giftcard_rounded,
        color: Color(0xFFAAB0C0),
        size: 24,
      ),
    );
  }
}

class _PrizesStateMessage extends StatelessWidget {
  const _PrizesStateMessage({
    required this.icon,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFAAB0C0), size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF505165),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4D4FE1),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

Color _prizeRankColor(int rank) {
  switch (rank) {
    case 1:
      return const Color(0xFFFFB300); // gold
    case 2:
      return const Color(0xFF9AA7BD); // silver
    case 3:
      return const Color(0xFFCD7F32); // bronze
    default:
      return const Color(0xFF6C4DF6); // violet
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
          const Icon(Icons.star_rounded, color: Color(0xFFFFA81E), size: 20),
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
