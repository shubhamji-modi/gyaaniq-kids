import 'package:flutter/material.dart';

import '../../core/theme/appcolors.dart';

enum NotificationTag { personal, classUpdate, ranking, dailyQuiz }

extension NotificationTagLabel on NotificationTag {
  String get label {
    switch (this) {
      case NotificationTag.personal:
        return 'Personal';
      case NotificationTag.classUpdate:
        return 'Class';
      case NotificationTag.ranking:
        return 'Ranking';
      case NotificationTag.dailyQuiz:
        return 'Daily Quiz';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationTag.personal:
        return Icons.person_rounded;
      case NotificationTag.classUpdate:
        return Icons.groups_rounded;
      case NotificationTag.ranking:
        return Icons.emoji_events_rounded;
      case NotificationTag.dailyQuiz:
        return Icons.quiz_rounded;
    }
  }

  Color get color {
    switch (this) {
      case NotificationTag.personal:
        return AppColors.primary;
      case NotificationTag.classUpdate:
        return AppColors.purpleDark;
      case NotificationTag.ranking:
        return AppColors.streakIcon;
      case NotificationTag.dailyQuiz:
        return AppColors.success;
    }
  }
}

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.tag,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
  });

  final String id;
  final NotificationTag tag;
  final String title;
  final String message;
  final String time;
  final bool isRead;

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      tag: tag,
      title: title,
      message: message,
      time: time,
      isRead: isRead ?? this.isRead,
    );
  }
}

class NotificationRepository {
  static final List<NotificationModel> dummyNotifications = [
    NotificationModel(
      id: '1',
      tag: NotificationTag.dailyQuiz,
      title: "Today's quiz is live!",
      message: 'Attempt today\'s daily quiz and keep your streak going.',
      time: '5m ago',
      isRead: false,
    ),
    NotificationModel(
      id: '2',
      tag: NotificationTag.ranking,
      title: 'You moved up the leaderboard',
      message: 'You are now ranked #3 in your class. Keep it up!',
      time: '1h ago',
      isRead: false,
    ),
    NotificationModel(
      id: '3',
      tag: NotificationTag.classUpdate,
      title: 'New homework assigned',
      message: 'Maths homework on Algebra has been assigned to your class.',
      time: '2h ago',
      isRead: true,
    ),
    NotificationModel(
      id: '4',
      tag: NotificationTag.personal,
      title: 'Streak milestone reached',
      message: 'You have completed a 7-day streak. Great job!',
      time: 'Yesterday',
      isRead: true,
    ),
    NotificationModel(
      id: '5',
      tag: NotificationTag.classUpdate,
      title: 'Class schedule updated',
      message: 'Your Science class timing has been changed to 4:00 PM.',
      time: 'Yesterday',
      isRead: false,
    ),
    NotificationModel(
      id: '6',
      tag: NotificationTag.dailyQuiz,
      title: 'You missed yesterday\'s quiz',
      message: 'Don\'t worry, a new quiz is ready for you today.',
      time: '2 days ago',
      isRead: true,
    ),
    NotificationModel(
      id: '7',
      tag: NotificationTag.ranking,
      title: 'Weekly ranking published',
      message: 'Check out how you performed this week among your peers.',
      time: '3 days ago',
      isRead: true,
    ),
    NotificationModel(
      id: '8',
      tag: NotificationTag.personal,
      title: 'Profile updated',
      message: 'Your profile details were updated successfully.',
      time: '4 days ago',
      isRead: true,
    ),
  ];
}
