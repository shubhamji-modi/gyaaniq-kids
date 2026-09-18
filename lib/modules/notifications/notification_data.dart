import 'package:flutter/material.dart';

import '../../core/service/api_service.dart';
import '../../core/theme/appcolors.dart';

/// A spread of palette colors assigned to unrecognized notification types,
/// keyed by type so a given type always gets the same color across rebuilds.
const List<Color> _fallbackTagColors = [
  AppColors.primary,
  AppColors.purpleDark,
  AppColors.streakIcon,
  AppColors.success,
  Color(0xFFE4572E),
  Color(0xFF1671D9),
];

Color _fallbackColorFor(String key) {
  if (key.isEmpty) return _fallbackTagColors.first;
  var hash = 0;
  for (final unit in key.codeUnits) {
    hash = (hash + unit) & 0x7fffffff;
  }
  return _fallbackTagColors[hash % _fallbackTagColors.length];
}

String _defaultLabelFor(String type) {
  switch (type) {
    case 'private':
      return 'Private';
    case 'class':
      return 'Class';
    case 'public':
      return 'Public';
    case 'ranking':
      return 'Ranking';
    case 'daily-quiz':
      return 'Daily Quiz';
    default:
      if (type.isEmpty) return 'General';
      return type
          .split(RegExp(r'[-_\s]+'))
          .where((w) => w.isNotEmpty)
          .map((w) => w[0].toUpperCase() + w.substring(1))
          .join(' ');
  }
}

IconData _defaultIconFor(String type) {
  switch (type) {
    case 'private':
      return Icons.person_rounded;
    case 'class':
      return Icons.groups_rounded;
    case 'public':
      return Icons.public_rounded;
    case 'ranking':
      return Icons.emoji_events_rounded;
    case 'daily-quiz':
      return Icons.quiz_rounded;
    default:
      return Icons.notifications_rounded;
  }
}

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.tagKey,
    required this.tagLabel,
    required this.tagColor,
    required this.tagIcon,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
  });

  final String id;

  /// Raw grouping key from the API (the tag's `key`, or the notification's
  /// `type` when no tag object is present). Filter chips are built from
  /// whatever distinct keys show up, so a new backend type needs no app
  /// update to appear as a filter.
  final String tagKey;
  final String tagLabel;
  final Color tagColor;
  final IconData tagIcon;
  final String title;
  final String message;
  final String time;
  final bool isRead;

  factory NotificationModel.fromApi(Map<String, dynamic> json) {
    final type = json['type']?.toString() ?? '';
    final tagKey = type.isNotEmpty ? type : 'general';
    final sentAt = DateTime.tryParse(
      json['sentAt']?.toString() ?? '',
    )?.toLocal();

    return NotificationModel(
      id: json['_id']?.toString() ?? '',
      tagKey: tagKey,
      tagLabel: _defaultLabelFor(tagKey),
      tagColor: _fallbackColorFor(tagKey),
      tagIcon: _defaultIconFor(tagKey),
      title: json['title']?.toString() ?? '',
      message: json['body']?.toString() ?? '',
      time: sentAt == null ? '' : _timeAgo(sentAt),
      isRead: true,
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      tagKey: tagKey,
      tagLabel: tagLabel,
      tagColor: tagColor,
      tagIcon: tagIcon,
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


String _timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  return '${date.day}/${date.month}/${date.year}';
}
