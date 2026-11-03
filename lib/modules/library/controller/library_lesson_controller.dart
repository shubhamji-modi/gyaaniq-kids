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

  /// The "Was this helpful?" vote being sent, or `null`.
  final RxnString pendingVote = RxnString();

  /// Set once a vote is on record (or the server says this student can't
  /// rate), so a stale re-fetch can never bring the prompt back.
  final RxBool _feedbackClosed = false.obs;

  static const int _voteAttempts = 3;

  Timer? _pollTimer;

  bool get showFeedbackPrompt {
    final value = lesson.value;
    return !_feedbackClosed.value &&
        value != null &&
        value.canRead &&
        (value.feedback?.shouldPrompt ?? false);
  }

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

  /// `POST /lessons/:id/feedback` with [vote] (`up` / `down`).
  ///
  /// A vote is permanent: a network failure retries the *same* choice, and a
  /// `409` carrying the saved vote is taken as final. A `409` without one means
  /// the server has no record of this student opening the lesson, so the
  /// detail is re-read (which records it) and the same choice sent once more.
  Future<LibraryResult<String?>?> rate(String vote) async {
    if (pendingVote.value != null || _feedbackClosed.value) return null;
    pendingVote.value = vote;

    var result = await _sendVote(vote);
    if (result.statusCode == 409 && _savedVoteFrom(result) == null) {
      await load(silent: true);
      result = await _sendVote(vote);
    }
    pendingVote.value = null;

    final saved = result.ok
        ? (result.data ?? vote)
        : result.statusCode == 409
        ? _savedVoteFrom(result)
        : null;
    if (saved != null) {
      _closeFeedback(saved);
    } else if (const {403, 404, 400}.contains(result.statusCode)) {
      // Not eligible — asking again would only fail again.
      _feedbackClosed.value = true;
    }
    return result;
  }

  Future<LibraryResult<String?>> _sendVote(String vote) async {
    var result = await LibraryRepository.rateLesson(
      lessonId: lessonId,
      vote: vote,
    );
    for (var i = 1; i < _voteAttempts && result.isNetworkError; i++) {
      await Future<void>.delayed(Duration(seconds: i));
      result = await LibraryRepository.rateLesson(
        lessonId: lessonId,
        vote: vote,
      );
    }
    return result;
  }

  void _closeFeedback(String vote) {
    _feedbackClosed.value = true;
    final current = lesson.value;
    if (current != null) lesson.value = current.withVote(vote);
  }

  /// Saved vote from a `409` "already rated" — `error.vote` or
  /// `error.feedback.vote`.
  static String? _savedVoteFrom(LibraryResult<dynamic> result) {
    final err = result.errorMap;
    final nested = err['feedback'];
    return LibraryFeedback.parseVote(err['vote']) ??
        (nested is Map ? LibraryFeedback.parseVote(nested['vote']) : null);
  }
}
