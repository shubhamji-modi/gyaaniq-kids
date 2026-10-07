import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/appcolors.dart';
import '../controller/library_upload_controller.dart';
import '../data/library_models.dart';
import '../library_navigation.dart';
import 'library_widgets.dart';

/// Photographing a lesson's pages, submitting them, and following the AI
/// until the lesson is created (or some pages need a retake).
class LibraryUploadViews extends StatefulWidget {
  const LibraryUploadViews({
    super.key,
    required this.sessionId,
    this.initial,
    this.openedFromLesson = false,
  });

  final String sessionId;
  final LibraryUploadSession? initial;
  final bool openedFromLesson;

  @override
  State<LibraryUploadViews> createState() => _LibraryUploadViewsState();
}

class _LibraryUploadViewsState extends State<LibraryUploadViews> {
  late final String _tag;
  late final LibraryUploadController c;

  @override
  void initState() {
    super.initState();
    _tag = 'library_upload_${widget.sessionId}_$hashCode';
    c = Get.put(
      LibraryUploadController(
        sessionId: widget.sessionId,
        initial: widget.initial,
      ),
      tag: _tag,
    );
  }

  @override
  void dispose() {
    Get.delete<LibraryUploadController>(tag: _tag);
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _addPages({required bool fromGallery}) async {
    final message = await c.addPages(fromGallery: fromGallery);
    if (message != null) showLibrarySnack(message, isError: true);
  }

  Future<void> _retake(LibrarySessionPage page) async {
    final fromGallery = await _askSource(
      title: 'Retake page ${_numberOf(page)}',
    );
    if (fromGallery == null) return;
    final message = await c.retakePage(page, fromGallery: fromGallery);
    if (message != null) showLibrarySnack(message, isError: true);
  }

  int _numberOf(LibrarySessionPage page) {
    final pages = c.session.value?.pages ?? const [];
    final i = pages.indexWhere((p) => p.id == page.id);
    return i < 0 ? page.position : i + 1;
  }

  Future<bool?> _askSource({required String title}) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.document_scanner_outlined,
                color: AppColors.primary,
              ),
              title: const Text(
                'Scan with camera',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Best quality — recommended'),
              onTap: () => Navigator.of(context).pop(false),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.primary,
              ),
              title: const Text(
                'Choose from photos',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              onTap: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePage(LibrarySessionPage page) async {
    final ok = await _confirm(
      title: 'Remove page ${_numberOf(page)}?',
      message: 'You can add it again later.',
      confirm: 'Remove',
      destructive: true,
    );
    if (ok != true) return;
    final message = await c.deletePage(page);
    if (message != null) showLibrarySnack(message, isError: true);
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    final message = await c.reorder(oldIndex, newIndex);
    if (message != null) showLibrarySnack(message, isError: true);
  }

  Future<void> _submit() async {
    if (c.hasFailedUploads) {
      final ok = await _confirm(
        title: 'Some photos were not added',
        message:
            'Photos marked "Not added" will be left out. Submit the pages '
            'that were added?',
        confirm: 'Submit',
      );
      if (ok != true) return;
    }
    final message = await c.submit();
    if (message != null) showLibrarySnack(message, isError: true);
  }

  Future<void> _cancel() async {
    final ok = await _confirm(
      title: 'Cancel this upload?',
      message:
          'The photos will be removed and other students will be able to '
          'upload this lesson.',
      confirm: 'Cancel upload',
      cancel: 'Keep it',
      destructive: true,
    );
    if (ok != true) return;
    final message = await c.cancelUpload();
    if (message != null) {
      showLibrarySnack(message, isError: true);
      return;
    }
    Get.back();
    showLibrarySnack('Upload cancelled.');
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirm,
    String cancel = 'Cancel',
    bool destructive = false,
  }) {
    return Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancel),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              confirm,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: destructive ? LibraryPalette.red : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openLesson() {
    final lessonId = c.session.value?.lesson.id ?? '';
    if (widget.openedFromLesson || lessonId.isEmpty) {
      Get.back();
      return;
    }
    Get.off(
      () => LibraryNavigation.lessonPage(lessonId),
      preventDuplicates: false,
    );
  }

  void _uploadAgain() {
    final lessonId = c.session.value?.lesson.id ?? '';
    if (lessonId.isEmpty) {
      Get.back();
      return;
    }
    LibraryNavigation.startUpload(
      lessonId,
      openedFromLesson: widget.openedFromLesson,
      replaceCurrent: true,
    );
  }

  void _preview(LibrarySessionPage page) {
    Get.dialog(
      _PagePreview(
        title: 'Page ${_numberOf(page)}',
        image: Image.network(page.url, fit: BoxFit.contain),
        reason: page.reason,
        canEdit: c.status.isEditable,
        onRetake: () {
          Get.back();
          _retake(page);
        },
        onDelete: c.status == LibrarySessionStatus.open
            ? () {
                Get.back();
                _deletePage(page);
              }
            : null,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LibraryPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            Obx(() {
              final lesson = c.session.value?.lesson;
              final title = lesson == null || lesson.title.isEmpty
                  ? 'Upload pages'
                  : 'Upload · Ch ${lesson.chapterNumber} ${lesson.title}';
              return LibraryTopBar(title: title);
            }),
            Expanded(
              child: Obx(() {
                final session = c.session.value;
                if (c.isLoading.value && session == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (session == null) {
                  return LibraryMessageView(
                    icon: Icons.cloud_off_rounded,
                    title: 'Unable to open this upload',
                    message: c.loadError.value,
                    actionLabel: c.loadErrorStatus.value == 404
                        ? 'Back'
                        : 'Retry',
                    onAction: c.loadErrorStatus.value == 404
                        ? Get.back
                        : c.load,
                  );
                }
                switch (session.status) {
                  case LibrarySessionStatus.open:
                  case LibrarySessionStatus.needsRetake:
                    return _editor(session);
                  case LibrarySessionStatus.submitted:
                    return _ProcessingView(session: session);
                  case LibrarySessionStatus.done:
                    return _EndView(
                      icon: Icons.celebration_rounded,
                      color: LibraryPalette.green,
                      title: 'Your lesson is ready!',
                      message:
                          'You can read it now. Other students will see it '
                          'after a quick review.',
                      primaryLabel: 'Open lesson',
                      onPrimary: _openLesson,
                    );
                  case LibrarySessionStatus.failed:
                    return _EndView(
                      icon: Icons.error_outline_rounded,
                      color: LibraryPalette.red,
                      title: "We couldn't create this lesson",
                      message:
                          '${session.endReason ?? 'Something went wrong while reading the pages.'}'
                          '\n\nThis upload was not counted — you can try again.',
                      primaryLabel: 'Try again',
                      onPrimary: _uploadAgain,
                      secondaryLabel: 'Back to lesson',
                      onSecondary: _openLesson,
                    );
                  case LibrarySessionStatus.expired:
                    return _EndView(
                      icon: Icons.timer_off_outlined,
                      color: LibraryPalette.grey,
                      title: 'This upload expired',
                      message:
                          session.endReason ??
                          'The pages were not submitted in time. If the '
                              'lesson still needs pages you can start again.',
                      primaryLabel: 'Back to lesson',
                      onPrimary: _openLesson,
                    );
                  case LibrarySessionStatus.cancelled:
                  case LibrarySessionStatus.rejected:
                  case LibrarySessionStatus.unknown:
                    return _EndView(
                      icon: Icons.do_not_disturb_on_outlined,
                      color: LibraryPalette.grey,
                      title: session.status == LibrarySessionStatus.rejected
                          ? 'This upload was not accepted'
                          : 'This upload has ended',
                      message:
                          session.endReason ??
                          'If the lesson still needs pages you can start a '
                              'new upload from the lesson.',
                      primaryLabel: 'Back to lesson',
                      onPrimary: _openLesson,
                    );
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editor(LibraryUploadSession session) {
    final retake = session.status == LibrarySessionStatus.needsRetake;
    final canReorder =
        session.status == LibrarySessionStatus.open && session.pages.length > 1;
    final retakePages = session.retakePages;
    // Read here, not in the lazy item builder, so Obx tracks them.
    final busyIds = c.busyPageIds.toSet();
    final replacingIds = c.localPages
        .map((l) => l.replacePageId)
        .whereType<String>()
        .toSet();

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (retake)
                        _RetakeBanner(
                          pages: retakePages,
                          numberOf: _numberOf,
                          timeLeft: c.timeLeft,
                        )
                      else
                        _GuideCard(
                          maxPages: c.rules.value.maxPages,
                          timeLeft: c.timeLeft,
                          hasPages: session.pages.isNotEmpty,
                        ),
                      _UploadProgressStrip(controller: c),
                      if (session.pages.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 14, bottom: 6),
                          child: Text(
                            canReorder
                                ? 'Pages (${session.pages.length}) · long-press and drag to reorder'
                                : 'Pages (${session.pages.length})',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverReorderableList(
                  itemCount: session.pages.length,
                  onReorder: canReorder ? _reorder : (_, _) {},
                  itemBuilder: (context, index) {
                    final page = session.pages[index];
                    final tile = _PageTile(
                      key: ValueKey(page.id),
                      number: index + 1,
                      page: page,
                      busy: busyIds.contains(page.id),
                      replacing: replacingIds.contains(page.id),
                      canDelete: session.status == LibrarySessionStatus.open,
                      onTap: () => _preview(page),
                      onRetake: () => _retake(page),
                      onDelete: () => _deletePage(page),
                    );
                    if (!canReorder) return tile;
                    return ReorderableDelayedDragStartListener(
                      key: ValueKey('drag_${page.id}'),
                      index: index,
                      child: tile,
                    );
                  },
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList.list(
                  children: [
                    for (final local in c.localPages)
                      _LocalPageTile(
                        key: ValueKey(local.localId),
                        item: local,
                        onRetry: () => c.retryLocal(local),
                        onRemove: () => c.removeLocal(local),
                      ),
                    if (!retake) ...[
                      const SizedBox(height: 6),
                      _AddPagesCard(
                        busy: c.isCapturing.value,
                        remaining: c.remainingSlots,
                        maxPages: c.rules.value.maxPages,
                        onScan: () => _addPages(fromGallery: false),
                        onGallery: () => _addPages(fromGallery: true),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        _BottomBar(
          left: LibrarySecondaryButton(
            label: 'Cancel',
            color: LibraryPalette.red,
            busy: c.isCancelling.value,
            onPressed: c.isSubmitting.value ? null : _cancel,
          ),
          right: LibraryPrimaryButton(
            label: retake ? 'Submit again' : 'Submit (${session.pages.length})',
            icon: Icons.auto_awesome_rounded,
            busy: c.isSubmitting.value,
            onPressed: c.canSubmit ? _submit : null,
          ),
        ),
      ],
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.maxPages,
    required this.timeLeft,
    required this.hasPages,
  });

  final int maxPages;
  final Duration? timeLeft;
  final bool hasPages;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LibraryPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pages 1–$maxPages, in order',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const _Tip('One page per photo — keep the whole page in the frame.'),
          const _Tip('Good light, no shadow, hold the phone steady.'),
          const _Tip('Tap a page to check it; retake any blurry one.'),
          if (hasPages && timeLeft != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 15,
                  color: LibraryPalette.amber,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    timeLeft!.isNegative
                        ? 'This upload is about to expire — submit now.'
                        : 'Expires in ${libraryDurationLabel(timeLeft!)} if not submitted',
                    style: const TextStyle(
                      color: LibraryPalette.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.check_circle_rounded,
              size: 14,
              color: LibraryPalette.green,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RetakeBanner extends StatelessWidget {
  const _RetakeBanner({
    required this.pages,
    required this.numberOf,
    required this.timeLeft,
  });

  final List<LibrarySessionPage> pages;
  final int Function(LibrarySessionPage) numberOf;
  final Duration? timeLeft;

  @override
  Widget build(BuildContext context) {
    final done = pages.isEmpty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: done ? LibraryPalette.greenSoft : LibraryPalette.amberSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                done ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                color: done ? LibraryPalette.green : LibraryPalette.amber,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  done ? 'All set — submit again' : 'Some pages need a retake',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          for (final p in pages) ...[
            const SizedBox(height: 6),
            Text(
              'Page ${numberOf(p)}: ${p.reason ?? 'Please take this page again.'}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            timeLeft == null || timeLeft!.isNegative
                ? 'Re-submitting is free — it does not use an upload.'
                : 'Retake within ${libraryDurationLabel(timeLeft!)}. '
                      'Re-submitting is free.',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadProgressStrip extends StatelessWidget {
  const _UploadProgressStrip({required this.controller});

  final LibraryUploadController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = controller;
      if (!c.hasPendingUploads && !c.isCapturing.value) {
        return const SizedBox.shrink();
      }
      final total = c.batchTotal.value;
      final current = (c.batchDone.value + 1).clamp(1, total < 1 ? 1 : total);
      final label = c.isCapturing.value && !c.hasPendingUploads
          ? 'Preparing photos…'
          : 'Uploading $current of $total';
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.primaryPale,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 5,
                value: total <= 0 ? null : c.batchDone.value / total,
                backgroundColor: Colors.white,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _PageTile extends StatelessWidget {
  const _PageTile({
    super.key,
    required this.number,
    required this.page,
    required this.busy,
    required this.replacing,
    required this.canDelete,
    required this.onTap,
    required this.onRetake,
    required this.onDelete,
  });

  final int number;
  final LibrarySessionPage page;
  final bool busy;
  final bool replacing;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onRetake;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final retake = page.needsRetake && !replacing;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: retake
                    ? LibraryPalette.amber.withValues(alpha: 0.7)
                    : LibraryPalette.border,
                width: retake ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                _Thumb(
                  child: Image.network(
                    page.url,
                    fit: BoxFit.cover,
                    cacheWidth: 180,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Page $number',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      if (replacing)
                        const Text(
                          'Replacing…',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      else if (retake)
                        Text(
                          page.reason ?? 'Please retake this page.',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: LibraryPalette.amber,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      else
                        const Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: LibraryPalette.green,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Added',
                              style: TextStyle(
                                color: LibraryPalette.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (busy)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else ...[
                  if (retake)
                    LibraryPrimaryButton(
                      label: 'Retake',
                      icon: Icons.camera_alt_outlined,
                      color: LibraryPalette.amber,
                      onPressed: onRetake,
                    )
                  else
                    IconButton(
                      tooltip: 'Retake',
                      onPressed: replacing ? null : onRetake,
                      icon: const Icon(
                        Icons.camera_alt_outlined,
                        color: AppColors.textMuted,
                      ),
                    ),
                  if (canDelete)
                    IconButton(
                      tooltip: 'Remove',
                      onPressed: replacing ? null : onDelete,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: LibraryPalette.red,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocalPageTile extends StatelessWidget {
  const _LocalPageTile({
    super.key,
    required this.item,
    required this.onRetry,
    required this.onRemove,
  });

  final LocalPageUpload item;
  final VoidCallback onRetry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final failed = item.status == LocalPageStatus.failed;
    final uploading = item.status == LocalPageStatus.uploading;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: failed
                ? LibraryPalette.red.withValues(alpha: 0.5)
                : LibraryPalette.border,
          ),
        ),
        child: Row(
          children: [
            _Thumb(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(item.path),
                    fit: BoxFit.cover,
                    cacheWidth: 180,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                  if (!failed)
                    Container(
                      color: Colors.black.withValues(alpha: 0.35),
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          color: Colors.white,
                          value: uploading && item.progress > 0
                              ? item.progress
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.replacePageId != null ? 'New photo' : 'New page',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    failed
                        ? 'Not added: ${item.error}'
                        : uploading
                        ? 'Uploading… ${(item.progress * 100).round()}%'
                        : 'Waiting…',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: failed ? LibraryPalette.red : AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (failed) ...[
              IconButton(
                tooltip: 'Try again',
                onPressed: onRetry,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.primary,
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                onPressed: onRemove,
                icon: const Icon(
                  Icons.close_rounded,
                  color: LibraryPalette.red,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 54,
        height: 72,
        color: LibraryPalette.greySoft,
        child: child,
      ),
    );
  }
}

class _AddPagesCard extends StatelessWidget {
  const _AddPagesCard({
    required this.busy,
    required this.remaining,
    required this.maxPages,
    required this.onScan,
    required this.onGallery,
  });

  final bool busy;
  final int remaining;
  final int maxPages;
  final VoidCallback onScan;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    if (remaining <= 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'You have added the maximum of $maxPages pages.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          LibraryPrimaryButton(
            label: 'Scan pages',
            icon: Icons.document_scanner_outlined,
            expand: true,
            busy: busy,
            onPressed: onScan,
          ),
          const SizedBox(height: 8),
          LibrarySecondaryButton(
            label: 'Choose from photos',
            icon: Icons.photo_library_outlined,
            expand: true,
            onPressed: busy ? null : onGallery,
          ),
          const SizedBox(height: 8),
          Text(
            '$remaining more page${remaining == 1 ? '' : 's'} allowed',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE7EAF4))),
      ),
      child: Row(
        children: [
          left,
          const SizedBox(width: 12),
          Expanded(child: right),
        ],
      ),
    );
  }
}

class _ProcessingView extends StatelessWidget {
  const _ProcessingView({required this.session});

  final LibraryUploadSession session;

  @override
  Widget build(BuildContext context) {
    final progress = session.progress;
    final writing = progress?.isWriting ?? false;
    final total = progress?.pagesTotal ?? session.pageCount;
    final read = progress?.pagesRead ?? 0;
    final label = writing
        ? 'Writing overview, notes, Q&A and quiz…'
        : total > 0
        ? 'Reading page ${(read + 1).clamp(1, total)} of $total'
        : 'Reading the pages…';

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      children: [
        Container(
          width: 84,
          height: 84,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primaryPale,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.primary,
            size: 40,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Creating your lesson…',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: writing || total <= 0 ? null : progress?.fraction ?? 0,
            backgroundColor: LibraryPalette.greySoft,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        if (!writing)
          const Text(
            'Then: overview · notes · Q&A · quiz',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
          ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: LibraryPalette.border),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                color: AppColors.primary,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "You can leave — we'll notify you when it's done or if a "
                  'page needs a retake.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: LibrarySecondaryButton(label: 'Leave', onPressed: Get.back),
        ),
      ],
    );
  }
}

class _EndView extends StatelessWidget {
  const _EndView({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 70, 28, 30),
      children: [
        Icon(icon, color: color, size: 64),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13.5,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 26),
        LibraryPrimaryButton(
          label: primaryLabel,
          expand: true,
          onPressed: onPrimary,
        ),
        if (secondaryLabel != null && onSecondary != null) ...[
          const SizedBox(height: 10),
          LibrarySecondaryButton(
            label: secondaryLabel!,
            expand: true,
            onPressed: onSecondary,
          ),
        ],
      ],
    );
  }
}

class _PagePreview extends StatelessWidget {
  const _PagePreview({
    required this.title,
    required this.image,
    required this.reason,
    required this.canEdit,
    required this.onRetake,
    required this.onDelete,
  });

  final String title;
  final Widget image;
  final String? reason;
  final bool canEdit;
  final VoidCallback onRetake;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: Get.back,
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: InteractiveViewer(
                maxScale: 5,
                child: Center(child: image),
              ),
            ),
            if (reason != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  reason!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFFD27A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (canEdit)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (onDelete != null) ...[
                      Expanded(
                        child: LibrarySecondaryButton(
                          label: 'Remove',
                          icon: Icons.delete_outline_rounded,
                          color: const Color(0xFFFF8A8A),
                          onPressed: onDelete,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: LibraryPrimaryButton(
                        label: 'Retake',
                        icon: Icons.camera_alt_outlined,
                        onPressed: onRetake,
                      ),
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
