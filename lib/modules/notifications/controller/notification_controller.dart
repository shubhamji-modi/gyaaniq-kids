import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/appcolors.dart';
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

  /// Opens a notification by id (used both from the list and from a push
  /// tap). Shows a bottom sheet with the full title/body, or an error if the
  /// admin has since deleted it (404).
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

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // A message can run to 1000 characters, which overflowed the sheet's
      // default height: it now grows to at most 80% of the screen and the body
      // scrolls past that.
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
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
        );
      },
    );
  }
}
