import '../service/api_service.dart';

/// Lightweight, UI-only subscription gate for content screens (e.g. the
/// Chapters list). Reads `GET user/subscription` without spinning up the full
/// in-app-purchase controller.
///
/// This drives *display* only (which lessons look unlocked). Real access is
/// still enforced server-side — the client never grants entitlement on its own.
class SubscriptionAccess {
  /// How many lessons a non-subscribed student may open for free (the rest are
  /// shown locked with a purchase prompt).
  static const int freeLessonLimit = 3;

  /// Returns `true` when the student currently has an active (or grace-period)
  /// entitlement. Any failure — network error, missing data — resolves to
  /// `false` so content stays gated rather than accidentally unlocked.
  static Future<bool> isSubscribed() async {
    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.subscriptionEndpoint,
      showLoader: false,
      fromJson: (json) => json,
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return false;
    }

    final body = response.data as Map<String, dynamic>;
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      return false;
    }

    final subscription = data['subscription'];
    if (subscription is! Map<String, dynamic>) {
      return false;
    }

    final status = subscription['status']?.toString() ?? '';
    final isEntitled = subscription['isEntitled'] == true;
    return isEntitled || status == 'active' || status == 'in_grace_period';
  }
}
