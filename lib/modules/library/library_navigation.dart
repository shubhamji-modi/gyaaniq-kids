import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/service/app_features_service.dart';
import '../../core/utils/loading_dialog.dart';
import 'data/library_models.dart';
import 'data/library_repository.dart';
import 'views/library_lesson_views.dart';
import 'views/library_upload_views.dart';
import 'views/library_home_views.dart';
import 'views/library_widgets.dart';

/// Every way into a Library screen goes through here, so the screens never
/// need to know about each other.
class LibraryNavigation {
  const LibraryNavigation._();

  static Future<void> openLibrary() async {
    if (!AppFeaturesService.instance.isLibraryLessonsEnabled) return;
    await Get.to(() => const LibraryHomeViews());
  }

  static Widget lessonPage(String lessonId) =>
      LibraryLessonViews(lessonId: lessonId);

  /// Opens one lesson — from a row, a push (`linkType: libraryLesson`) or a
  /// request that turned out to exist already.
  static Future<void> openLesson(String lessonId) async {
    if (lessonId.trim().isEmpty) return;
    if (!AppFeaturesService.instance.isLibraryLessonsEnabled) return;
    await Get.to(
      () => LibraryLessonViews(lessonId: lessonId.trim()),
      preventDuplicates: false,
    );
  }

  /// [openedFromLesson] lets the upload screen simply go back to the lesson
  /// when it is done, instead of stacking a second copy of it.
  static Future<void> openSession(
    String sessionId, {
    LibraryUploadSession? initial,
    bool openedFromLesson = false,
  }) async {
    if (sessionId.trim().isEmpty) return;
    if (!AppFeaturesService.instance.isLibraryLessonsEnabled) return;
    await Get.to(
      () => LibraryUploadViews(
        sessionId: sessionId.trim(),
        initial: initial,
        openedFromLesson: openedFromLesson,
      ),
      preventDuplicates: false,
    );
  }

  /// `POST /lessons/:id/upload-session`, then the upload screen.
  ///
  /// `201` is a new session, `200` resumes this student's own. A `409` may
  /// point at another open upload of theirs (`error.sessionId`) — offered as
  /// "Open it". Everything else shows the server's message.
  ///
  /// With [replaceCurrent] the new upload screen takes the place of the
  /// current one (e.g. "Try again" on a failed upload).
  static Future<void> startUpload(
    String lessonId, {
    bool openedFromLesson = false,
    bool replaceCurrent = false,
  }) async {
    if (!AppFeaturesService.instance.isLibraryLessonsEnabled) return;
    LoadingDialog.show(message: 'Getting ready…');
    final result = await LibraryRepository.startUpload(lessonId);
    LoadingDialog.hide();

    if (result.ok && result.data != null) {
      final session = result.data!;
      if (replaceCurrent) {
        await Get.off(
          () => LibraryUploadViews(
            sessionId: session.id,
            initial: session,
            openedFromLesson: openedFromLesson,
          ),
          preventDuplicates: false,
        );
      } else {
        await openSession(
          session.id,
          initial: session,
          openedFromLesson: openedFromLesson,
        );
      }
      return;
    }

    final otherSession = result.errorMap['sessionId']?.toString() ?? '';
    if (result.statusCode == 409 && otherSession.isNotEmpty) {
      final open = await Get.dialog<bool>(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Another upload is open',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          content: Text(result.displayMessage),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Not now'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text(
                'Open it',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
      if (open == true) await openSession(otherSession);
      return;
    }

    showLibrarySnack(result.displayMessage, isError: true);
  }
}
