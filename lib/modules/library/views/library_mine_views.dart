import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/appcolors.dart';
import '../controller/library_controller.dart';
import '../data/library_models.dart';
import '../library_navigation.dart';
import 'library_widgets.dart';

/// The student's own lists, named the way a student would say them.
enum _Mine {
  asked('Asked for', Icons.pan_tool_alt_outlined),
  sent('Sent photos', Icons.photo_camera_outlined),
  waiting('Waiting for', Icons.notifications_none_rounded);

  const _Mine(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// "My chapters" — the three personal lists, one at a time.
///
/// This is deliberately off the front door: it only matters once a student has
/// already started something, so it never competes with the two main doors.
class LibraryMineViews extends StatefulWidget {
  const LibraryMineViews({super.key});

  @override
  State<LibraryMineViews> createState() => _LibraryMineViewsState();
}

class _LibraryMineViewsState extends State<LibraryMineViews> {
  late final LibraryController c = Get.find<LibraryController>();
  final _which = _Mine.asked.obs;

  @override
  void initState() {
    super.initState();
    _ensureLoaded(_which.value);
  }

  LibraryLessonList _listFor(_Mine which) {
    switch (which) {
      case _Mine.asked:
        return c.myRequests;
      case _Mine.sent:
        return c.myUploads;
      case _Mine.waiting:
        return c.following;
    }
  }

  void _ensureLoaded(_Mine which) {
    final list = _listFor(which);
    if (!list.loadedOnce && !list.isLoading.value) list.reload();
  }

  void _select(_Mine which) {
    _which.value = which;
    _ensureLoaded(which);
  }

  Future<void> _open(LibraryLesson lesson) async {
    await LibraryNavigation.openLesson(lesson.id);
    unawaited(c.refreshAfterReturn());
  }

  Future<void> _upload(LibraryLesson lesson) async {
    await LibraryNavigation.startUpload(lesson.id);
    unawaited(c.refreshAfterReturn());
  }

  Future<void> _continue(LibraryLesson lesson) async {
    final sid = lesson.mySessionId;
    if (sid == null) {
      await _upload(lesson);
      return;
    }
    await LibraryNavigation.openSession(sid);
    unawaited(c.refreshAfterReturn());
  }

  Future<void> _toggleFollow(LibraryLesson lesson) async {
    final result = await c.toggleFollow(lesson);
    showLibrarySnack(
      result.ok
          ? (lesson.isFollowing
                ? "We'll stop telling you about this one."
                : "Added. It's pending from admin — we'll tell you when it's "
                      'ready.')
          : result.displayMessage,
      isError: !result.ok,
    );
  }

  ({IconData icon, String title, String message}) _emptyFor(_Mine which) {
    switch (which) {
      case _Mine.asked:
        return (
          icon: Icons.pan_tool_alt_outlined,
          title: 'Nothing asked for yet',
          message:
              'Chapters you add from your book will show up here while a '
              'teacher checks them.',
        );
      case _Mine.sent:
        return (
          icon: Icons.photo_camera_outlined,
          title: 'No photos sent yet',
          message:
              'When you photograph a chapter for your class, it shows up '
              'here.',
        );
      case _Mine.waiting:
        return (
          icon: Icons.notifications_none_rounded,
          title: 'Not waiting for anything',
          message:
              "Tap \"Tell me when it's ready\" on a chapter that isn't "
              'ready, and it will show up here.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LibraryPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            const LibraryTopBar(title: 'My chapters'),
            Obx(
              () => Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  children: [
                    for (final option in _Mine.values) ...[
                      _MineTab(
                        option: option,
                        selected: option == _which.value,
                        onTap: () => _select(option),
                      ),
                      if (option != _Mine.values.last) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                final which = _which.value;
                final list = _listFor(which);
                final empty = _emptyFor(which);
                return Obx(() {
                  if ((list.isLoading.value || !list.loadedOnce) &&
                      list.items.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (list.error.value.isNotEmpty && list.items.isEmpty) {
                    return LibraryMessageView(
                      icon: Icons.cloud_off_rounded,
                      title: "We couldn't load this",
                      message: list.error.value,
                      actionLabel: 'Try again',
                      onAction: list.reload,
                    );
                  }
                  if (list.items.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () => list.reload(silent: true),
                      child: LibraryMessageView(
                        icon: empty.icon,
                        title: empty.title,
                        message: empty.message,
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () => list.reload(silent: true),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n.metrics.pixels >
                            n.metrics.maxScrollExtent - 300) {
                          list.loadMore();
                        }
                        return false;
                      },
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
                        itemCount:
                            list.items.length +
                            (list.isLoadingMore.value ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= list.items.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 18),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                ),
                              ),
                            );
                          }
                          final lesson = list.items[index];
                          return Obx(
                            () => LibraryLessonCard(
                              lesson: lesson,
                              uploadsAvailable:
                                  c.meta.value?.uploadsAvailable ?? true,
                              followBusy: c.busyIds.contains(lesson.id),
                              onOpen: () => _open(lesson),
                              onRead: () => _open(lesson),
                              onUpload: () => _upload(lesson),
                              onContinue: () => _continue(lesson),
                              onToggleFollow: () => _toggleFollow(lesson),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                });
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _MineTab extends StatelessWidget {
  const _MineTab({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _Mine option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.neutralSurface2,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(
                option.icon,
                size: 19,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
