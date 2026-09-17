import 'package:flutter/material.dart';

import '../../core/service/api_service.dart';
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
    required this.tagLabel,
    required this.tagColor,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
  });

  final String id;
  final NotificationTag tag;
  final String tagLabel;
  final Color tagColor;
  final String title;
  final String message;
  final String time;
  final bool isRead;

  factory NotificationModel.fromApi(Map<String, dynamic> json) {
    final tagJson = json['tag'] as Map<String, dynamic>?;
    final tagKey = tagJson?['key']?.toString();
    final type = json['type']?.toString();
    final tag = _tagFromApi(tagKey: tagKey, type: type);
    final sentAt = DateTime.tryParse(
      json['sentAt']?.toString() ?? '',
    )?.toLocal();

    return NotificationModel(
      id: json['_id']?.toString() ?? '',
      tag: tag,
      tagLabel: tagJson?['name']?.toString() ?? tag.label,
      tagColor: _colorFromHex(tagJson?['color']?.toString()) ?? tag.color,
      title: json['title']?.toString() ?? '',
      message: json['body']?.toString() ?? '',
      time: sentAt == null ? '' : _timeAgo(sentAt),
      isRead: true,
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      tag: tag,
      tagLabel: tagLabel,
      tagColor: tagColor,
      title: title,
      message: message,
      time: time,
      isRead: isRead ?? this.isRead,
    );
  }
}

class NotificationRepository {
  static Future<ApiResponse<List<NotificationModel>>> fetchNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.USER_NOTIFICATIONS,
      showLoader: false,
      queryParameters: {'page': page, 'limit': limit},
      fromJson: (json) => json,
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return ApiResponse<List<NotificationModel>>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    final body = response.data as Map<String, dynamic>;
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    final itemsJson = data['notifications'] as List<dynamic>? ?? const [];
    final items = itemsJson
        .whereType<Map<String, dynamic>>()
        .map(NotificationModel.fromApi)
        .toList();

    return ApiResponse<List<NotificationModel>>(
      success: true,
      data: items,
      message: body['message']?.toString() ?? 'Success',
      statusCode: response.statusCode,
    );
  }

  static Future<ApiResponse<NotificationModel>> fetchNotificationDetail(
    String id,
  ) async {
    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.USER_NOTIFICATION_DETAIL.replaceFirst(':id', id),
      showLoader: false,
      fromJson: (json) => json,
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return ApiResponse<NotificationModel>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    final body = response.data as Map<String, dynamic>;
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      return ApiResponse<NotificationModel>(
        success: false,
        message: 'This notification is no longer available',
        statusCode: response.statusCode,
      );
    }

    return ApiResponse<NotificationModel>(
      success: true,
      data: NotificationModel.fromApi(data),
      message: body['message']?.toString() ?? 'Success',
      statusCode: response.statusCode,
    );
  }
}

NotificationTag _tagFromApi({String? tagKey, String? type}) {
  switch (tagKey) {
    case 'daily-quiz':
      return NotificationTag.dailyQuiz;
    case 'ranking':
      return NotificationTag.ranking;
  }
  switch (type) {
    case 'private':
      return NotificationTag.personal;
    case 'class':
      return NotificationTag.classUpdate;
    default:
      return NotificationTag.personal;
  }
}

Color? _colorFromHex(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  final value = hex.replaceFirst('#', '');
  final parsed = int.tryParse(
    value.length == 6 ? 'FF$value' : value,
    radix: 16,
  );
  return parsed == null ? null : Color(parsed);
}

String _timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  return '${date.day}/${date.month}/${date.year}';
}
