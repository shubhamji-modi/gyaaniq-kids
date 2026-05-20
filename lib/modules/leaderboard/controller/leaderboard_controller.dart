import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LeaderboardController extends GetxController {
  final List<LeaderboardUser> topThree = const [
    LeaderboardUser(
      rank: 2,
      name: 'Jordan Lee',
      xp: 12450,
      initials: 'JL',
      avatarGradient: [Color(0xFF71D7D4), Color(0xFF3A6EA8)],
      ringColor: Color(0xFFD6D0EF),
    ),
    LeaderboardUser(
      rank: 1,
      name: 'Maya Chen',
      xp: 15200,
      initials: 'MC',
      avatarGradient: [Color(0xFFFFD561), Color(0xFF9F4B11)],
      ringColor: Color(0xFFFFA81E),
      isChampion: true,
    ),
    LeaderboardUser(
      rank: 3,
      name: 'Leo Garcia',
      xp: 11900,
      initials: 'LG',
      avatarGradient: [Color(0xFF2A6BC6), Color(0xFF101C33)],
      ringColor: Color(0xFFFFB46A),
    ),
  ];

  final LeaderboardUser currentUser = const LeaderboardUser(
    rank: 14,
    name: 'Alex Johnson',
    xp: 8450,
    initials: 'AJ',
    avatarGradient: [Color(0xFFFFD0AE), Color(0xFFF08E54)],
    ringColor: Color(0xFFFFFFFF),
    subtitle: 'Ranked #14 this week',
  );

  final List<LeaderboardUser> rankings = const [
    LeaderboardUser(
      rank: 4,
      name: 'Sarah Williams',
      xp: 10200,
      initials: 'SW',
      avatarGradient: [Color(0xFFCBEAEC), Color(0xFF8AC6CB)],
      ringColor: Color(0xFFEAF4F5),
    ),
    LeaderboardUser(
      rank: 5,
      name: 'David Kim',
      xp: 9800,
      initials: 'DK',
      avatarGradient: [Color(0xFF7ED0FF), Color(0xFF1F4B72)],
      ringColor: Color(0xFFE8F4FB),
    ),
    LeaderboardUser(
      rank: 6,
      name: 'Elena Rodriguez',
      xp: 9450,
      initials: 'ER',
      avatarGradient: [Color(0xFFEAFBFF), Color(0xFF8AB9D5)],
      ringColor: Color(0xFFEAF4FB),
    ),
    LeaderboardUser(
      rank: 7,
      name: 'James Smith',
      xp: 8900,
      initials: 'JS',
      avatarGradient: [Color(0xFF1D2E48), Color(0xFF457EA6)],
      ringColor: Color(0xFFE8EEF7),
    ),
  ];

  String formatXp(int value) {
    final valueText = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < valueText.length; i++) {
      final reverseIndex = valueText.length - i;
      buffer.write(valueText[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }
    return '${buffer.toString()} XP';
  }
}

class LeaderboardUser {
  const LeaderboardUser({
    required this.rank,
    required this.name,
    required this.xp,
    required this.initials,
    required this.avatarGradient,
    required this.ringColor,
    this.subtitle,
    this.isChampion = false,
  });

  final int rank;
  final String name;
  final int xp;
  final String initials;
  final List<Color> avatarGradient;
  final Color ringColor;
  final String? subtitle;
  final bool isChampion;
}
