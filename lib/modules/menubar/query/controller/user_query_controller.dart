import '../../../../core/service/api_service.dart';

/// The three things a student can raise from the Profile tab's Query screen.
///
/// They are one and the same message, told apart only by this type — admins
/// read them together under Student Queries in the admin panel.
enum UserQueryType { suggestion, contact, request }

extension UserQueryTypeApi on UserQueryType {
  /// The value the API expects in the request body.
  String get apiValue {
    return switch (this) {
      UserQueryType.suggestion => 'suggestion',
      UserQueryType.contact => 'contact',
      UserQueryType.request => 'request',
    };
  }

  /// The heading the student sees for this option.
  String get label {
    return switch (this) {
      UserQueryType.suggestion => 'Suggestion',
      UserQueryType.contact => 'Contact Us',
      UserQueryType.request => 'Request',
    };
  }
}

/// Reads a type back from the API.
///
/// The server accepts and echoes several spellings — case, spaces, `-` and
/// `_` are all ignored — so `"Contact Us"` and `"contact_us"` map to the same
/// option as `"contact"`.
UserQueryType? userQueryTypeFromApi(String raw) {
  final normalized = raw.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
  return switch (normalized) {
    'suggestion' => UserQueryType.suggestion,
    'contact' || 'contactus' => UserQueryType.contact,
    'request' => UserQueryType.request,
    _ => null,
  };
}

/// One message the student has sent, as the server stores it.
class UserQueryItem {
  const UserQueryItem({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.resolvedAt,
  });

  final String id;
  final String type;
  final String typeLabel;
  final String message;

  /// `open` until an admin marks it `resolved`.
  final String status;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  bool get isResolved => status == 'resolved';

  /// The Query option this message was sent under, or null if the server
  /// introduces a type this build does not know about.
  UserQueryType? get option => userQueryTypeFromApi(type);

  /// What to show as the heading. Prefers the server's own label so a new
  /// type still reads correctly.
  String get displayLabel =>
      typeLabel.isNotEmpty ? typeLabel : (option?.label ?? 'Query');

  factory UserQueryItem.fromApi(Map<String, dynamic> json) {
    return UserQueryItem(
      id: json['_id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      typeLabel: json['typeLabel']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      status: json['status']?.toString() ?? 'open',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      resolvedAt: DateTime.tryParse(json['resolvedAt']?.toString() ?? ''),
    );
  }
}

/// One page of the student's own queries.
class UserQueryPage {
  const UserQueryPage({
    required this.queries,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  final List<UserQueryItem> queries;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  bool get hasMore => page < totalPages;
}

class UserQueryRepository {
  const UserQueryRepository._();

  /// Shortest and longest message the API accepts, counted after trimming.
  static const int minMessageLength = 3;
  static const int maxMessageLength = 1000;

  /// Cleans a typed message the way the server does before it measures it.
  ///
  /// Zero-width and other invisible characters are stripped (a message made
  /// only of those is rejected as empty), line breaks are kept, and runs of
  /// blank lines collapse to one. Running the same rules on the client means
  /// the character counter agrees with the server's verdict.
  static String normalizeMessage(String raw) {
    return raw
        .replaceAll(RegExp(r'[​-‍﻿⁠]'), '')
        .replaceAll('\r\n', '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  /// How long [raw] counts as against [maxMessageLength], for the counter
  /// under the text field.
  static int messageLength(String raw) => normalizeMessage(raw).visibleLength;

  /// The reason [message] cannot be sent, or null when it is fine.
  static String? validationError(String message, UserQueryType type) {
    final normalized = normalizeMessage(message);
    if (normalized.isEmpty) {
      return 'Please type your ${type.label.toLowerCase()} before submitting.';
    }
    if (normalized.visibleLength < minMessageLength) {
      return 'Please write at least $minMessageLength characters.';
    }
    if (normalized.visibleLength > maxMessageLength) {
      return 'Please keep your message under $maxMessageLength characters.';
    }
    return null;
  }

  /// Sends the student's message.
  ///
  /// Nothing about the student is sent: name, class, phone, email and app
  /// version are all read from the account server-side.
  ///
  /// Sending the same message twice within ten minutes is answered with a
  /// `200` and the query that was already saved, so a double tap is safe and
  /// still lands on the success screen.
  static Future<ApiResponse<UserQueryItem>> submit({
    required UserQueryType type,
    required String message,
  }) async {
    final response = await ApiService.instance.post<dynamic>(
      endpoint: ApiService.USER_QUERIES,
      showLoader: false,
      fromJson: (json) => json,
      data: {'type': type.apiValue, 'message': normalizeMessage(message)},
    );

    final body = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : const <String, dynamic>{};
    // The server writes its messages for the student — rate limits, daily
    // caps and validation all explain themselves — so they are passed through
    // rather than replaced with our own wording.
    final serverMessage = body['message']?.toString() ?? response.message;

    if (!response.success) {
      return ApiResponse<UserQueryItem>(
        success: false,
        message: serverMessage,
        statusCode: response.statusCode,
      );
    }

    final data = body['data'];
    return ApiResponse<UserQueryItem>(
      success: true,
      message: serverMessage,
      statusCode: response.statusCode,
      data: data is Map<String, dynamic> ? UserQueryItem.fromApi(data) : null,
    );
  }

  /// The student's own queries, newest first.
  static Future<ApiResponse<UserQueryPage>> fetchMyQueries({
    UserQueryType? type,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.USER_QUERIES,
      showLoader: false,
      fromJson: (json) => json,
      queryParameters: {
        if (type != null) 'type': type.apiValue,
        'page': page,
        'limit': limit.clamp(1, 50),
      },
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return ApiResponse<UserQueryPage>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    final body = response.data as Map<String, dynamic>;
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    final pagination = (data['pagination'] as Map<String, dynamic>?) ?? const {};
    final queries = (data['queries'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(UserQueryItem.fromApi)
        .toList();

    return ApiResponse<UserQueryPage>(
      success: true,
      message: body['message']?.toString() ?? response.message,
      statusCode: response.statusCode,
      data: UserQueryPage(
        queries: queries,
        total: (pagination['total'] as num?)?.toInt() ?? queries.length,
        page: (pagination['page'] as num?)?.toInt() ?? page,
        limit: (pagination['limit'] as num?)?.toInt() ?? limit,
        totalPages: (pagination['totalPages'] as num?)?.toInt() ?? 1,
      ),
    );
  }
}

extension on String {
  /// Length in code points rather than UTF-16 units, so a plain emoji counts
  /// as one character the way the API counts it — `length` would score 🌙 as
  /// two and reject messages the server accepts.
  int get visibleLength => runes.length;
}
