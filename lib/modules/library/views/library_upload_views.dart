import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/appcolors.dart';
import '../controller/library_upload_controller.dart';
import '../data/library_models.dart';
import '../library_navigation.dart';
import 'library_widgets.dart';

/// Photographing a chapter's pages, sending them, and following the AI until
/// the lesson is created (or some pages need a new photo).
///
/// The screen reads as three steps — take the photos, send them, wait — and
/// never shows a student more than the one they are on.
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
      title: 'New photo for page ${_numberOf(page)}',
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
                'Use the camera',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Best for reading the page'),
              onTap: () => Navigator.of(context).pop(false),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.primary,
              ),
              title: const Text(
                'Pick a photo I already took',
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
      message: 'You can take it again later.',
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
        title: 'Some photos did not go through',
        message:
            'The ones marked "Did not go through" will be left out. '
            'Send the rest?',
        confirm: 'Send them',
      );
      if (ok != true) return;
    }
    final message = await c.submit();
    if (message != null) showLibrarySnack(message, isError: true);
  }

  Future<void> _cancel() async {
    final ok = await _confirm(
      title: 'Stop and delete your photos?',
      message:
          'Your photos will be deleted and someone else in your class can '
          'do this chapter.',
      confirm: 'Yes, stop',
      cancel: 'Keep going',
      destructive: true,
    );
    if (ok != true) return;
    final message = await c.cancelUpload();
    if (message != null) {
      showLibrarySnack(message, isError: true);
      return;
    }
    Get.back();
    showLibrarySnack('Stopped. Your photos were deleted.');
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
                  ? 'Photograph the pages'
                  : 'Ch ${lesson.chapterNumber} · ${lesson.title}';
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
                    title: "We couldn't open this",
                    message: c.loadError.value,
                    actionLabel: c.loadErrorStatus.value == 404
                        ? 'Go back'
                        : 'Try again',
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
                      title: 'Done — your lesson is ready!',
                      message:
                          'You can read it right now. Your class will see it '
                          'once a teacher checks it.',
                      primaryLabel: 'Read it',
                      onPrimary: _openLesson,
                    );
                  case LibrarySessionStatus.failed:
                    return _EndView(
                      icon: Icons.error_outline_rounded,
                      color: LibraryPalette.red,
                      title: "We couldn't make the lesson",
                      message:
                          '${session.endReason ?? 'Something went wrong while reading your photos.'}'
                          '\n\nDon\'t worry — this did not use up a turn. You '
                          'can try again.',
                      primaryLabel: 'Try again',
                      onPrimary: _uploadAgain,
                      secondaryLabel: 'Go back',
                      onSecondary: _openLesson,
                    );
                  case LibrarySessionStatus.expired:
                    return _EndView(
                      icon: Icons.timer_off_outlined,
                      color: LibraryPalette.grey,
                      title: 'Time ran out',
                      message:
                          session.endReason ??
                          'The photos were not sent in time. If the chapter '
                              'still needs photos, you can start again.',
                      primaryLabel: 'Go back',
                      onPrimary: _openLesson,
                    );
                  case LibrarySessionStatus.cancelled:
                  case LibrarySessionStatus.rejected:
                  case LibrarySessionStatus.unknown:
                    return _EndView(
                      icon: Icons.do_not_disturb_on_outlined,
                      color: LibraryPalette.grey,
                      title: session.status == LibrarySessionStatus.rejected
                          ? 'These photos were not accepted'
                          : 'This has ended',
                      message:
                          session.endReason ??
                          'If the chapter still needs photos, you can start '
                              'again from the chapter.',
                      primaryLabel: 'Go back',
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

  // -- Step 1 / 2: taking photos and sending them ------------------------------

  Widget _editor(LibraryUploadSession session) {
    final retake = session.status == LibrarySessionStatus.needsRetake;
    // Nothing photographed yet: show how it works instead of an empty list.
    if (!retake && session.pages.isEmpty && c.localPages.isEmpty) {
      return _StartView(
        maxPages: c.rules.value.maxPages,
        busy: c.isCapturing.value,
        onScan: () => _addPages(fromGallery: false),
        onGallery: () => _addPages(fromGallery: true),
        onCancel: c.isCancelling.value ? null : _cancel,
      );
    }

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
        _StepHeader(
          step: retake ? 3 : 1,
          total: 3,
          label: retake ? 'Take the photos again' : 'Take a photo of each page',
        ),
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
                        _TimeLeftNote(timeLeft: c.timeLeft),
                      _UploadProgressStrip(controller: c),
                      if (session.pages.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 14, bottom: 6),
                          child: Text(
                            canReorder
                                ? 'Your pages (${session.pages.length}) · hold and drag to put them in order'
                                : 'Your pages (${session.pages.length})',
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
                      const SizedBox(height: 14),
                      const _PhotoTipsCard(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        _BottomBar(
          left: LibrarySecondaryButton(
            label: 'Stop',
            color: LibraryPalette.red,
            busy: c.isCancelling.value,
            onPressed: c.isSubmitting.value ? null : _cancel,
          ),
          right: LibraryPrimaryButton(
            label: retake
                ? 'Send again'
                : 'Send ${session.pages.length} photo'
                      '${session.pages.length == 1 ? '' : 's'}',
            icon: Icons.auto_awesome_rounded,
            busy: c.isSubmitting.value,
            onPressed: c.canSubmit ? _submit : null,
          ),
        ),
      ],
    );
  }
}

/// "Step 1 of 3 — Take a photo of each page". One line, always visible, so a
/// student always knows where they are in the job.
class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.step,
    required this.total,
    required this.label,
  });

  final int step;
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step $step of $total',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              for (var i = 1; i <= total; i++) ...[
                Expanded(
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: i <= step
                          ? AppColors.primary
                          : LibraryPalette.greySoft,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                if (i != total) const SizedBox(width: 6),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// What a student sees before the first photo: what the job is, in three
/// numbered lines, and one big button to begin.
/// Before the first photo. The student has just been told how this works on
/// the way in, so this screen does not explain it again — it opens the camera.
class _StartView extends StatelessWidget {
  const _StartView({
    required this.maxPages,
    required this.busy,
    required this.onScan,
    required this.onGallery,
    required this.onCancel,
  });

  final int maxPages;
  final bool busy;
  final VoidCallback onScan;
  final VoidCallback onGallery;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _StepHeader(
          step: 1,
          total: 3,
          label: 'Take a photo of each page',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 92,
                  height: 92,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: LibraryPalette.green.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_camera_rounded,
                    color: LibraryPalette.green,
                    size: 44,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Photograph every page',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'One photo per page, in order. Up to $maxPages pages.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
              LibraryPrimaryButton(
                label: 'Open the camera',
                icon: Icons.photo_camera_rounded,
                color: LibraryPalette.green,
                expand: true,
                busy: busy,
                onPressed: onScan,
              ),
              const SizedBox(height: 10),
              LibrarySecondaryButton(
                label: 'Pick photos I already took',
                icon: Icons.photo_library_outlined,
                expand: true,
                onPressed: busy ? null : onGallery,
              ),
              const SizedBox(height: 22),
              const _PhotoTipsCard(),
              if (onCancel != null) ...[
                const SizedBox(height: 14),
                Center(
                  child: TextButton(
                    onPressed: onCancel,
                    child: const Text(
                      'Not now',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// How to take a photo that we can actually read.
class _PhotoTipsCard extends StatelessWidget {
  const _PhotoTipsCard();

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
          const Text(
            'For a good photo',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const _Tip('Fit the whole page in the picture.'),
          const _Tip('Find bright light and keep your shadow off the page.'),
          const _Tip('Hold the phone still so the words are sharp.'),
          const _Tip('Tap a photo to check it — you can take it again.'),
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
      padding: const EdgeInsets.only(top: 4),
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

/// Only shown once there is something to lose — a countdown on an empty
/// screen just worries people.
class _TimeLeftNote extends StatelessWidget {
  const _TimeLeftNote({required this.timeLeft});

  final Duration? timeLeft;

  @override
  Widget build(BuildContext context) {
    final left = timeLeft;
    if (left == null) return const SizedBox.shrink();
    final urgent = left.isNegative;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LibraryPalette.amberSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.timer_outlined,
            size: 17,
            color: LibraryPalette.amber,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              urgent
                  ? 'Your time is almost up — send your photos now.'
                  : 'Send your photos within ${libraryDurationLabel(left)}.',
              style: const TextStyle(
                color: LibraryPalette.amber,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
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
                  done
                      ? 'All fixed — send them again'
                      : "Some photos aren't clear enough",
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (pages.isNotEmpty) ...[
            const SizedBox(height: 6),
            const Text(
              'Take these pages again:',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          for (final p in pages) ...[
            const SizedBox(height: 6),
            Text(
              'Page ${numberOf(p)}: ${p.reason ?? 'Please take this one again.'}',
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
                ? "Sending again is free — it doesn't use up a turn."
                : 'Do it within ${libraryDurationLabel(timeLeft!)}. '
                      "Sending again is free.",
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
          ? 'Getting your photos ready…'
          : 'Saving photo $current of $total';
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
                          'Changing this one…',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      else if (retake)
                        Text(
                          page.reason ?? 'Please take this one again.',
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
                              'Saved',
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
                      label: 'Take again',
                      icon: Icons.camera_alt_outlined,
                      color: LibraryPalette.amber,
                      onPressed: onRetake,
                    )
                  else
                    IconButton(
                      tooltip: 'Take this page again',
                      onPressed: replacing ? null : onRetake,
                      icon: const Icon(
                        Icons.camera_alt_outlined,
                        color: AppColors.textMuted,
                      ),
                    ),
                  if (canDelete)
                    IconButton(
                      tooltip: 'Remove this page',
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
                        ? 'Did not go through: ${item.error}'
                        : uploading
                        ? 'Saving… ${(item.progress * 100).round()}%'
                        : 'Waiting its turn…',
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
                tooltip: 'Try this one again',
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
          "That's the most we can take ($maxPages pages). "
          'Send them when you are ready.',
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
            label: 'Add the next page',
            icon: Icons.photo_camera_rounded,
            expand: true,
            busy: busy,
            onPressed: onScan,
          ),
          const SizedBox(height: 8),
          LibrarySecondaryButton(
            label: 'Pick photos I already took',
            icon: Icons.photo_library_outlined,
            expand: true,
            onPressed: busy ? null : onGallery,
          ),
          const SizedBox(height: 8),
          Text(
            'You can add $remaining more page${remaining == 1 ? '' : 's'}',
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

/// Step 3: the AI is reading the pages. Nothing for the student to do.
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
        ? 'Writing the notes, questions and quiz…'
        : total > 0
        ? 'Reading page ${(read + 1).clamp(1, total)} of $total'
        : 'Reading your pages…';

    return Column(
      children: [
        const _StepHeader(step: 3, total: 3, label: 'We are making the lesson'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 36, 24, 30),
            children: [
              Center(
                child: Container(
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
              ),
              const SizedBox(height: 20),
              const Text(
                'Thanks! We are reading your pages…',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
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
                  'Next we write the notes, questions and quiz.',
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
                        "You don't have to wait here. We'll tell you when it "
                        'is ready, or if a page needs a new photo.',
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
                child: LibrarySecondaryButton(
                  label: 'Do something else',
                  onPressed: Get.back,
                ),
              ),
            ],
          ),
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
                        label: 'Take again',
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
