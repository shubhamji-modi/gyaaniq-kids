import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';

import '../data/library_models.dart';
import '../data/library_photo_service.dart';
import '../data/library_repository.dart';
import 'library_controller.dart';

enum LocalPageStatus { queued, uploading, failed }

/// A photo on the device that is not (yet) a page of the session.
class LocalPageUpload {
  LocalPageUpload({required this.path, this.replacePageId})
    : localId = '${DateTime.now().microsecondsSinceEpoch}_${path.hashCode}';

  final String localId;
  final String path;

  /// Set when this photo replaces a page (retake) — it keeps that position.
  final String? replacePageId;

  LocalPageStatus status = LocalPageStatus.queued;
  double progress = 0;
  String error = '';
}

/// One upload session: adding / replacing / ordering pages, submitting, and
/// following the AI while it works.
class LibraryUploadController extends GetxController {
  LibraryUploadController({
    required this.sessionId,
    LibraryUploadSession? initial,
  }) : _initial = initial;

  final String sessionId;
  final LibraryUploadSession? _initial;

  static const Duration _pollEvery = Duration(seconds: 5);

  final Rxn<LibraryUploadSession> session = Rxn<LibraryUploadSession>();
  final RxBool isLoading = true.obs;
  final RxString loadError = ''.obs;
  final RxInt loadErrorStatus = 0.obs;

  final RxList<LocalPageUpload> localPages = <LocalPageUpload>[].obs;
  final RxBool isCapturing = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool isCancelling = false.obs;
  final RxSet<String> busyPageIds = <String>{}.obs;

  /// "Uploading 3 of 12" for the current batch.
  final RxInt batchTotal = 0.obs;
  final RxInt batchDone = 0.obs;

  /// Ticks every 30 s so the expiry countdown stays current.
  final Rx<DateTime> now = DateTime.now().obs;

  final Rx<LibraryRules> rules = const LibraryRules().obs;

  Timer? _pollTimer;
  Timer? _clockTimer;
  bool _queueRunning = false;

  LibrarySessionStatus get status =>
      session.value?.status ?? LibrarySessionStatus.unknown;

  bool get hasPendingUploads => localPages.any(
    (p) =>
        p.status == LocalPageStatus.queued ||
        p.status == LocalPageStatus.uploading,
  );

  bool get hasFailedUploads =>
      localPages.any((p) => p.status == LocalPageStatus.failed);

  /// Pages already in the session plus new ones still on their way.
  int get plannedPageCount =>
      (session.value?.pages.length ?? 0) +
      localPages.where((p) => p.replacePageId == null).length;

  int get remainingSlots =>
      (rules.value.maxPages - plannedPageCount).clamp(0, rules.value.maxPages);

  bool get canSubmit =>
      (session.value?.canSubmit ?? false) &&
      !hasPendingUploads &&
      !isSubmitting.value &&
      !isCancelling.value;

  Duration? get timeLeft {
    final expires = session.value?.expiresAt;
    if (expires == null) return null;
    return expires.difference(now.value);
  }

  @override
  void onInit() {
    super.onInit();
    _loadRules();
    if (_initial != null) {
      _apply(_initial);
      isLoading.value = false;
    }
    load(silent: _initial != null);
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      now.value = DateTime.now();
    });
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    _clockTimer?.cancel();
    for (final p in localPages) {
      _deleteQuietly(p.path);
    }
    unawaited(LibraryPhotoService.cleanUp());
    super.onClose();
  }

  void _loadRules() {
    if (Get.isRegistered<LibraryController>()) {
      final meta = Get.find<LibraryController>().meta.value;
      if (meta != null) {
        rules.value = meta.rules;
        return;
      }
    }
    LibraryRepository.fetchMeta().then((result) {
      if (result.ok && result.data != null) rules.value = result.data!.rules;
    });
  }

  void _apply(LibraryUploadSession value) {
    session.value = value;
    now.value = DateTime.now();
    _syncPolling();
  }

  /// Poll every 5 s only while the AI is working and this screen is open.
  void _syncPolling() {
    if (status == LibrarySessionStatus.submitted) {
      _pollTimer ??= Timer.periodic(_pollEvery, (_) => load(silent: true));
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      isLoading.value = true;
      loadError.value = '';
    }
    final result = await LibraryRepository.fetchSession(sessionId);
    isLoading.value = false;
    if (result.ok && result.data != null) {
      loadError.value = '';
      _apply(result.data!);
      return;
    }
    if (!silent || session.value == null) {
      loadErrorStatus.value = result.statusCode;
      loadError.value = result.statusCode == 404
          ? 'This upload is no longer available.'
          : result.displayMessage;
    }
  }

  // ---------------------------------------------------------------------------
  // Adding pages
  // ---------------------------------------------------------------------------

  /// Scans (or picks) new pages and uploads them one by one, in order.
  /// Returns a message to show when nothing could be added.
  Future<String?> addPages({required bool fromGallery}) async {
    if (!status.isEditable || isCapturing.value) return null;
    final slots = remainingSlots;
    if (slots <= 0) {
      return 'A lesson can have up to ${rules.value.maxPages} pages.';
    }
    isCapturing.value = true;
    try {
      final paths = fromGallery
          ? await LibraryPhotoService.pickFromGallery(maxPages: slots)
          : await LibraryPhotoService.scanPages(maxPages: slots);
      if (paths.isEmpty) return null;
      _enqueue(paths.take(slots).map((p) => LocalPageUpload(path: p)));
      return null;
    } on LibraryPhotoException catch (e) {
      return e.message;
    } finally {
      isCapturing.value = false;
    }
  }

  /// Replaces one page (retake) — the new photo keeps its position.
  Future<String?> retakePage(
    LibrarySessionPage page, {
    required bool fromGallery,
  }) async {
    if (!status.isEditable || isCapturing.value) return null;
    isCapturing.value = true;
    try {
      final paths = fromGallery
          ? await LibraryPhotoService.pickFromGallery(maxPages: 1)
          : await LibraryPhotoService.scanPages(maxPages: 1);
      if (paths.isEmpty) return null;
      _enqueue([LocalPageUpload(path: paths.first, replacePageId: page.id)]);
      return null;
    } on LibraryPhotoException catch (e) {
      return e.message;
    } finally {
      isCapturing.value = false;
    }
  }

  void _enqueue(Iterable<LocalPageUpload> items) {
    final list = items.toList();
    if (list.isEmpty) return;
    if (!_queueRunning) {
      batchTotal.value = 0;
      batchDone.value = 0;
    }
    batchTotal.value += list.length;
    localPages.addAll(list);
    unawaited(_runQueue());
  }

  void retryLocal(LocalPageUpload item) {
    if (item.status != LocalPageStatus.failed) return;
    item
      ..status = LocalPageStatus.queued
      ..error = ''
      ..progress = 0;
    if (!_queueRunning) {
      batchTotal.value = 1;
      batchDone.value = 0;
    } else {
      batchTotal.value += 1;
    }
    localPages.refresh();
    unawaited(_runQueue());
  }

  void removeLocal(LocalPageUpload item) {
    if (item.status == LocalPageStatus.uploading) return;
    localPages.remove(item);
    _deleteQuietly(item.path);
  }

  /// Uploads queued photos strictly one at a time so pages land in the order
  /// they were taken, and a bad photo fails on its own.
  Future<void> _runQueue() async {
    if (_queueRunning) return;
    _queueRunning = true;
    try {
      while (true) {
        final next = localPages.firstWhereOrNull(
          (p) => p.status == LocalPageStatus.queued,
        );
        if (next == null) break;
        if (!status.isEditable) {
          next
            ..status = LocalPageStatus.failed
            ..error = 'This upload can no longer take pages.';
          localPages.refresh();
          continue;
        }

        next
          ..status = LocalPageStatus.uploading
          ..progress = 0;
        localPages.refresh();

        final result = await LibraryRepository.addPage(
          sid: sessionId,
          filePath: next.path,
          replacePageId: next.replacePageId,
          onSendProgress: (sent, total) {
            if (total <= 0) return;
            next.progress = sent / total;
            localPages.refresh();
          },
        );

        if (result.ok && result.data != null) {
          localPages.remove(next);
          _deleteQuietly(next.path);
          batchDone.value += 1;
          _apply(result.data!);
          continue;
        }

        next
          ..status = LocalPageStatus.failed
          ..error = result.displayMessage;
        localPages.refresh();
        batchDone.value += 1;

        // Submitted / ended (409) or expired (410): nothing else will go in.
        if (result.statusCode == 409 || result.statusCode == 410) {
          for (final p in localPages) {
            if (p.status == LocalPageStatus.queued) {
              p
                ..status = LocalPageStatus.failed
                ..error = result.displayMessage;
            }
          }
          localPages.refresh();
          await load(silent: true);
          break;
        }
      }
    } finally {
      _queueRunning = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Editing pages
  // ---------------------------------------------------------------------------

  Future<String?> deletePage(LibrarySessionPage page) async {
    busyPageIds.add(page.id);
    final result = await LibraryRepository.removePage(
      sid: sessionId,
      pageId: page.id,
    );
    busyPageIds.remove(page.id);
    if (result.ok && result.data != null) {
      _apply(result.data!);
      return null;
    }
    if (result.statusCode == 409 || result.statusCode == 410) {
      await load(silent: true);
    }
    return result.displayMessage;
  }

  /// Moves a page and saves the new order; puts it back if the save fails.
  Future<String?> reorder(int oldIndex, int newIndex) async {
    final current = session.value;
    if (current == null || current.status != LibrarySessionStatus.open) {
      return null;
    }
    final pages = [...current.pages];
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex == newIndex) return null;
    final moved = pages.removeAt(oldIndex);
    pages.insert(newIndex, moved);

    session.value = LibraryUploadSession(
      id: current.id,
      status: current.status,
      rawStatus: current.rawStatus,
      expiresAt: current.expiresAt,
      lesson: current.lesson,
      pages: pages,
      pageCount: current.pageCount,
      retakeCount: current.retakeCount,
      canSubmit: current.canSubmit,
      progress: current.progress,
      endReason: current.endReason,
    );

    final result = await LibraryRepository.reorderPages(
      sid: sessionId,
      pageIds: pages.map((p) => p.id).toList(),
    );
    if (result.ok && result.data != null) {
      _apply(result.data!);
      return null;
    }
    session.value = current;
    await load(silent: true);
    return result.displayMessage;
  }

  // ---------------------------------------------------------------------------
  // Submit / cancel
  // ---------------------------------------------------------------------------

  /// First submit uses one of today's uploads; a retake re-submit is free.
  Future<String?> submit() async {
    if (!canSubmit) return null;
    isSubmitting.value = true;
    final result = await LibraryRepository.submit(sessionId);
    isSubmitting.value = false;
    if (result.ok) {
      if (result.data != null && result.data!.id.isNotEmpty) {
        _apply(result.data!);
      }
      await load(silent: true);
      return null;
    }
    await load(silent: true);
    return result.displayMessage;
  }

  /// Returns `null` on success, otherwise the message to show.
  Future<String?> cancelUpload() async {
    isCancelling.value = true;
    final result = await LibraryRepository.cancel(sessionId);
    isCancelling.value = false;
    if (result.ok) {
      _pollTimer?.cancel();
      return null;
    }
    await load(silent: true);
    return result.displayMessage;
  }

  /// Only removes the JPEGs [LibraryPhotoService.prepare] wrote — never a
  /// photo that belongs to the student.
  void _deleteQuietly(String path) {
    if (!path.split(Platform.pathSeparator).last.startsWith('library_page_')) {
      return;
    }
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
  }
}
