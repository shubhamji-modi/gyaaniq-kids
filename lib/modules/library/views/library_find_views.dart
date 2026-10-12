import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/appcolors.dart';
import '../controller/library_controller.dart';
import '../data/library_models.dart';
import '../library_navigation.dart';
import 'library_start_upload_views.dart';
import 'library_widgets.dart';

/// "Find a chapter" — one job, one screen.
///
/// A search box, the results, and nothing else. The subject filter is the
/// only one left (students think in subjects, not publishers) and it reads as
/// a row of word buttons rather than a filter control. Everything the student
/// cannot act on is kept out.
class LibraryFindViews extends StatefulWidget {
  const LibraryFindViews({super.key});

  @override
  State<LibraryFindViews> createState() => _LibraryFindViewsState();
}

class _LibraryFindViewsState extends State<LibraryFindViews> {
  late final LibraryController c = Get.find<LibraryController>();
  late final TextEditingController _search = TextEditingController(
    text: c.search.value,
  );

  @override
  void initState() {
    super.initState();
    // Coming in fresh: show everything that is ready to read first.
    c.setStatusSilently(LibraryStatusFilter.all);
    if (!c.browse.loadedOnce) c.browse.reload();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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

  Future<void> _addInstead() async {
    await Get.to(
      () => LibraryStartUploadViews(initialTitle: _search.text.trim()),
    );
    unawaited(c.refreshAfterReturn());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LibraryPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            const LibraryTopBar(title: 'Find a chapter'),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: TextField(
                controller: _search,
                onChanged: c.onSearchChanged,
                textInputAction: TextInputAction.search,
                autofocus: true,
                style: const TextStyle(fontSize: 15.5),
                decoration: InputDecoration(
                  hintText: 'Chapter name or number',
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted6,
                    fontSize: 15,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, size: 23),
                  suffixIcon: Obx(
                    () => c.search.value.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () {
                              _search.clear();
                              c.onSearchChanged('');
                            },
                          ),
                  ),
                  filled: true,
                  fillColor: AppColors.neutralSurface2,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            _SubjectStrip(controller: c),
            Expanded(child: _results()),
          ],
        ),
      ),
    );
  }

  Widget _results() {
    final list = c.browse;
    return Obx(() {
      if (list.isLoading.value && list.items.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (list.error.value.isNotEmpty && list.items.isEmpty) {
        return LibraryMessageView(
          icon: Icons.cloud_off_rounded,
          title: "We couldn't load the chapters",
          message: list.error.value,
          actionLabel: 'Try again',
          onAction: list.reload,
        );
      }
      if (list.items.isEmpty) {
        return _NothingFound(
          searching: c.search.value.trim().isNotEmpty,
          onAdd: _addInstead,
        );
      }
      return RefreshIndicator(
        onRefresh: () => list.reload(silent: true),
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.pixels > n.metrics.maxScrollExtent - 300) {
              list.loadMore();
            }
            return false;
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
            itemCount: list.items.length + 1,
            itemBuilder: (context, index) {
              if (index >= list.items.length) {
                return Obx(
                  () => list.isLoadingMore.value
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          ),
                        )
                      : _AddHint(onAdd: _addInstead),
                );
              }
              final lesson = list.items[index];
              return Obx(
                () => LibraryLessonCard(
                  lesson: lesson,
                  uploadsAvailable: c.meta.value?.uploadsAvailable ?? true,
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
  }
}

/// Subjects as plain word buttons. No "Filter" label, no chip metaphor — just
/// "All · Maths · Science", which is how a student would ask for it.
class _SubjectStrip extends StatelessWidget {
  const _SubjectStrip({required this.controller});

  final LibraryController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final subjects = controller.meta.value?.subjects ?? const <LibraryRef>[];
      if (subjects.length < 2) return const SizedBox.shrink();
      final selected = controller.subjectFilter.value;
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.only(bottom: 12),
        child: SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _SubjectWord(
                label: 'All',
                selected: selected == null,
                onTap: () => controller.setSubject(null),
              ),
              for (final s in subjects)
                _SubjectWord(
                  label: s.name,
                  selected: selected?.id == s.id,
                  onTap: () => controller.setSubject(s),
                ),
            ],
          ),
        ),
      );
    });
  }
}

class _SubjectWord extends StatelessWidget {
  const _SubjectWord({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.neutralSurface2,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

/// Searched and found nothing: offer the only useful next move.
class _NothingFound extends StatelessWidget {
  const _NothingFound({required this.searching, required this.onAdd});

  final bool searching;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(28, 60, 28, 30),
      children: [
        const Icon(
          Icons.search_off_rounded,
          color: Color(0xFF9AA0B0),
          size: 56,
        ),
        const SizedBox(height: 16),
        Text(
          searching ? "That chapter isn't here yet" : 'No chapters yet',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'You can add it yourself — photograph the pages from your book and '
          'we will make the lesson for your class.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13.5,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 22),
        LibraryPrimaryButton(
          label: 'Add this chapter',
          icon: Icons.photo_camera_rounded,
          expand: true,
          color: LibraryPalette.green,
          onPressed: onAdd,
        ),
      ],
    );
  }
}

/// Bottom of a non-empty list: a soft reminder that adding is possible.
class _AddHint extends StatelessWidget {
  const _AddHint({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        color: LibraryPalette.greenSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              "Didn't find it? Add it from your book.",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 10),
          LibraryPrimaryButton(
            label: 'Add',
            color: LibraryPalette.green,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}
