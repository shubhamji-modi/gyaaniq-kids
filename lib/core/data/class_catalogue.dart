import '../service/api_service.dart';

/// A single selectable class from the public class catalogue.
///
/// Backed by `GET /api/v1/classes/active` — the only unauthenticated endpoint.
/// The [className] string (e.g. `"5th"`) is exactly what downstream APIs expect
/// as `classLevel`; never rename or transform it on the client.
class ClassOption {
  const ClassOption({
    required this.id,
    required this.className,
    required this.displayOrder,
  });

  final String id;
  final String className;
  final int displayOrder;

  factory ClassOption.fromApi(Map<String, dynamic> json) {
    return ClassOption(
      id: json['id']?.toString() ?? '',
      className: json['className']?.toString() ?? '',
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

class ClassCatalogueRepository {
  /// Fetch the active classes, sorted by [ClassOption.displayOrder] ascending
  /// (5th → 10th). Public endpoint — no auth header is sent.
  ///
  /// On success returns the (possibly empty) list; an empty list means every
  /// class has been deactivated by the admin and the UI should show an
  /// "no classes available" message rather than an empty grid.
  static Future<ApiResponse<List<ClassOption>>> fetchActiveClasses() async {
    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.ACTIVE_CLASSES,
      includeAuth: false,
      showLoader: false,
      fromJson: (json) => json,
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return ApiResponse<List<ClassOption>>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    final body = response.data as Map<String, dynamic>;
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    final classes =
        (data['classes'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(ClassOption.fromApi)
            .where((option) => option.className.isNotEmpty)
            .toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return ApiResponse<List<ClassOption>>(
      success: true,
      statusCode: response.statusCode,
      message: body['message']?.toString() ?? response.message,
      data: classes,
    );
  }
}
