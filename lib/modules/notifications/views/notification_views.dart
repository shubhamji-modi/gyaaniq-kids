import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/appcolors.dart';
import '../controller/notification_controller.dart';
import '../notification_data.dart';

class NotificationViews extends StatefulWidget {
  const NotificationViews({super.key});

  @override
  State<NotificationViews> createState() => _NotificationViewsState();
}

class _NotificationViewsState extends State<NotificationViews> {
  final NotificationController _controller = Get.put(NotificationController());
  final ScrollController _scrollController = ScrollController();
  NotificationTag? _selectedTag;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _controller.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<NotificationModel> _filtered(List<NotificationModel> notifications) {
    if (_selectedTag == null) return notifications;
    return notifications.where((n) => n.tag == _selectedTag).toList();
  }

  void _openNotification(NotificationModel item) {
    NotificationController.openDetail(item.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralSurface,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimaryDeep,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.textPrimaryDeep,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.headerBorder),
        ),
      ),
      body: Column(
        children: [
          _NotificationFilterBar(
            selectedTag: _selectedTag,
            onChanged: (tag) => setState(() => _selectedTag = tag),
          ),
          Expanded(
            child: Obx(() {
              if (_controller.isLoading.value &&
                  _controller.notifications.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = _filtered(_controller.notifications);
              if (items.isEmpty) {
                return const _EmptyNotifications();
              }
              return RefreshIndicator(
                onRefresh: _controller.fetchNotifications,
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: items.length + (_controller.isLoadingMore.value ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index >= items.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    final item = items[index];
                    return _NotificationCard(
                      item: item,
                      onTap: () => _openNotification(item),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _NotificationFilterBar extends StatelessWidget {
  const _NotificationFilterBar({
    required this.selectedTag,
    required this.onChanged,
  });

  final NotificationTag? selectedTag;
  final ValueChanged<NotificationTag?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'All',
              isSelected: selectedTag == null,
              onTap: () => onChanged(null),
            ),
            const SizedBox(width: 8),
            ...NotificationTag.values.map(
              (tag) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChip(
                  label: tag.label,
                  isSelected: selectedTag == tag,
                  onTap: () => onChanged(tag),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.neutralSurface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.lightBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});

  final NotificationModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isRead ? AppColors.white : AppColors.primaryPale,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isRead ? AppColors.lightBorder : AppColors.primarySoft,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: item.tagColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(item.tag.icon, color: item.tagColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            color: AppColors.textPrimaryDeep,
                            fontSize: 14,
                            fontWeight: item.isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6, top: 3),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: const TextStyle(
                      color: AppColors.textMuted2,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: item.tagColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item.tagLabel,
                          style: TextStyle(
                            color: item.tagColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_off_rounded,
            color: AppColors.textMuted6,
            size: 40,
          ),
          const SizedBox(height: 10),
          const Text(
            'No notifications here',
            style: TextStyle(
              color: AppColors.textMuted2,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
