import 'dart:async';

import 'package:get/get.dart';

import '../data/library_models.dart';
import '../data/library_repository.dart';
import 'library_controller.dart';

/// One Library lesson: its state for this student and, once readable, its
/// overview and notes.
class LibraryLessonController extends GetxController {
  LibraryLessonController({required this.lessonId});

  final String lessonId;

  static const Duration _pollEvery = Duration(seconds: 5);

  final Rxn<LibraryLesson> lesson = Rxn<LibraryLesson>();
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;
  final RxInt errorStatus = 0.obs;
  final RxBool isFollowBusy = false.obs;

  Timer? _pollTimer;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    super.onClose();
  }

  Future<void> load({bool silent = false}) async {
    if (!silent || lesson.value == null) {
      isLoading.value = true;
      error.value = '';
    }
    final result = await LibraryRepository.fetchLesson(lessonId);
    isLoading.value = false;

    if (result.ok && result.data != null) {
      error.value = '';
      errorStatus.value = 0;
      _apply(result.data!);
      return;
    }
    if (!silent || lesson.value == null || result.statusCode == 404) {
      errorStatus.value = result.statusCode;
      error.value = result.displayMessage;
      if (result.statusCode == 404) lesson.value = null;
    }
  }

  void _apply(LibraryLesson value) {
    lesson.value = value;
    // Keep the Library's lists in step with what this screen now knows.
    if (Get.isRegistered<LibraryController>()) {
      Get.find<LibraryController>().applyLesson(value);
    }
    // The uploader sees the AI's progress here while it works.
    final processing =
        value.progress != null &&
        value.myState == LibraryLessonState.yourUploadInProgress;
    if (processing) {
      _pollTimer ??= Timer.periodic(_pollEvery, (_) => load(silent: true));
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  Future<LibraryResult<LibraryLesson?>?> toggleFollow() async {
    final current = lesson.value;
    if (current == null || isFollowBusy.value) return null;
    isFollowBusy.value = true;
    final wantFollow = !current.isFollowing;
    final result = wantFollow
        ? await LibraryRepository.follow(lessonId)
        : await LibraryRepository.unfollow(lessonId);
    isFollowBusy.value = false;
    if (result.ok) {
      _apply(result.data ?? current.withFollowing(wantFollow));
    } else {
      await load(silent: true);
    }
    return result;
  }
}
