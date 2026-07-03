import '../../../../core/service/api_service.dart';

/// A single avatar from the admin-curated library.
class AvatarItem {
  const AvatarItem({required this.id, required this.name, required this.url});

  final String id;
  final String name;
  final String url;

  factory AvatarItem.fromApi(Map<String, dynamic> json) {
    final image = (json['image'] as Map<String, dynamic>?) ?? const {};
    return AvatarItem(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      url: image['url']?.toString() ?? '',
    );
  }
}

/// One page of avatars plus the server pagination metadata.
class AvatarPage {
  const AvatarPage({
    required this.avatars,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<AvatarItem> avatars;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;
}

class EditProfileAvatarRepository {
  /// Fetch a paginated page of the active avatar pool, with optional search.
  static Future<ApiResponse<AvatarPage>> fetchAvatars({
    String search = '',
    int page = 1,
    int limit = 24,
  }) async {
    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.FETCH_AVATARS,
      showLoader: false,
      fromJson: (json) => json,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return ApiResponse<AvatarPage>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    final body = response.data as Map<String, dynamic>;
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    final avatars = (data['avatars'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AvatarItem.fromApi)
        .where((avatar) => avatar.url.isNotEmpty)
        .toList();
    final pagination = (data['pagination'] as Map<String, dynamic>?) ?? const {};

    return ApiResponse<AvatarPage>(
      success: true,
      statusCode: response.statusCode,
      message: body['message']?.toString() ?? response.message,
      data: AvatarPage(
        avatars: avatars,
        page: (pagination['page'] as num?)?.toInt() ?? page,
        limit: (pagination['limit'] as num?)?.toInt() ?? limit,
        total: (pagination['total'] as num?)?.toInt() ?? avatars.length,
        totalPages: (pagination['totalPages'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  /// Select an avatar as the profile picture. Returns the new `profilePic` URL.
  static Future<ApiResponse<String>> selectAvatar(String avatarId) async {
    final response = await ApiService.instance.put<dynamic>(
      endpoint: ApiService.SELECT_AVATAR,
      showLoader: false,
      fromJson: (json) => json,
      data: {'avatarId': avatarId},
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return ApiResponse<String>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    final body = response.data as Map<String, dynamic>;
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};

    return ApiResponse<String>(
      success: true,
      statusCode: response.statusCode,
      message: body['message']?.toString() ?? response.message,
      data: data['profilePic']?.toString() ?? '',
    );
  }
}
