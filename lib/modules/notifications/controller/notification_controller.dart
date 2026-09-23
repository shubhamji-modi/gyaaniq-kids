import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/appcolors.dart';
import '../../../routes/app_routes.dart';
import '../notification_data.dart';

class NotificationController extends GetxController {
  static const int _pageSize = 20;

  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;

  int _page = 1;
  bool _hasMore = true;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    isLoading.value = true;
    errorMessage.value = '';
    _page = 1;
    _hasMore = true;

    final response = await NotificationRepository.fetchNotifications(
      page: _page,
      limit: _pageSize,
    );

    isLoading.value = false;

    if (!response.success) {
      notifications.clear();
      errorMessage.value = response.message;
      return;
    }

    final items = response.data ?? const <NotificationModel>[];
    notifications.assignAll(items);
    _hasMore = items.length >= _pageSize;
  }

  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !_hasMore) return;

    isLoadingMore.value = true;
    final response = await NotificationRepository.fetchNotifications(
      page: _page + 1,
      limit: _pageSize,
    );
    isLoadingMore.value = false;

    if (!response.success) return;

    final items = response.data ?? const <NotificationModel>[];
    if (items.isEmpty) {
      _hasMore = false;
      return;
    }

    _page += 1;
    _hasMore = items.length >= _pageSize;
    final existingIds = notifications.map((n) => n.id).toSet();
    notifications.addAll(items.where((n) => !existingIds.contains(n.id)));
  }

  /// Id of a push the user tapped before the app was ready to show it.
  ///
  /// A push tapped while the app is killed reaches us from
  /// `getInitialMessage()` during startup, i.e. while the splash screen is
  /// still up and about to `Get.offAllNamed(...)`. Opening the detail there
  /// either drew it over the splash or got wiped out by the navigation — which
  /// is why it used to land on a different screen every time. So the id is
  /// parked here and only opened once the app has actually reached the
  /// dashboard.
  static String? _pendingNotificationId;

  /// True once the app is past splash/auth and safe to navigate from.
  static bool _isAppReady = false;

  /// Entry point for a tapped push, whatever the app state was.
  static void handlePushTap(String id) {
    if (id.trim().isEmpty) return;
    _pendingNotificationId = id.trim();
    if (_isAppReady) {
      unawaited(_consumePending());
    }
  }

  /// Called by the dashboard once it is on screen — every route into the app
  /// passes through it, so this is the one place that knows navigation is safe.
  static void markAppReady() {
    _isAppReady = true;
    unawaited(_consumePending());
  }

  /// Dropped on logout so a stale push can't reopen for the next user.
  static void reset() {
    _isAppReady = false;
    _pendingNotificationId = null;
  }

  static Future<void> _consumePending() async {
    final id = _pendingNotificationId;
    if (id == null) return;
    _pendingNotificationId = null;

    // The detail always opens on top of the Notifications screen, never on
    // whatever tab happened to be showing.
    if (Get.currentRoute != AppRoutes.notifications) {
      unawaited(Get.toNamed(AppRoutes.notifications));
      // Let the push transition settle before stacking the dialog on it.
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
    await openDetail(id);
  }

  /// Opens a notification by id (used both from the list and from a push
  /// tap). Shows a centered dialog with the full title/body, or an error if
  /// the admin has since deleted it (404).
  static Future<void> openDetail(String id) async {
    final response = await NotificationRepository.fetchNotificationDetail(id);

    if (!response.success || response.data == null) {
      Get.snackbar(
        'Notification',
        response.message.isEmpty
            ? 'This notification is no longer available'
            : response.message,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final context = Get.context;
    if (context == null) return;
    final item = response.data!;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.white,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 40,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          // A message can run to 1000 characters: the card grows only to 80%
          // of the screen and the body scrolls past that.
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: item.tagColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item.tagLabel,
                            style: TextStyle(
                              color: item.tagColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          item.time,
                          style: const TextStyle(
                            color: AppColors.textMuted6,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: AppColors.textPrimaryDeep,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.message,
                      style: const TextStyle(
                        color: AppColors.textMuted2,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
