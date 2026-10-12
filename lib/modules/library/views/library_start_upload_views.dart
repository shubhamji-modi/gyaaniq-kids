import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/appcolors.dart';
import '../controller/library_controller.dart';
import '../data/library_models.dart';
import '../data/library_repository.dart';
import '../library_navigation.dart';
import 'library_request_views.dart';
import 'library_widgets.dart';

/// "Add a chapter" — the whole give-a-chapter flow, as three questions.
///
///   1. Which book?     publication + subject
///   2. Which chapter?  number + name
///   3. Ready           what happens next, then one button
///
/// The student is never shown the words "request" or "upload session". Behind
/// the scenes `requestLesson` answers `200` (the chapter is already known) or
/// `201` (it is new), and this screen turns that into either *the camera opens
/// now* or *a teacher will check it first* — the same two endpoints as before,
/// just never asked about separately.
class LibraryStartUploadViews extends StatefulWidget {
  const LibraryStartUploadViews({super.key, this.initialTitle = ''});

  /// Carried over when the student searched for a chapter and did not find it.
  final String initialTitle;

  @override
  State<LibraryStartUploadViews> createState() =>
      _LibraryStartUploadViewsState();
}

class _LibraryStartUploadViewsState extends State<LibraryStartUploadViews> {
  static const int _stepCount = 3;

  final LibraryController c = Get.find<LibraryController>();
  final _chapterFormKey = GlobalKey<FormState>();

  late final TextEditingController _title = TextEditingController(
    text: widget.initialTitle,
  );
  final TextEditingController _chapter = TextEditingController();

  late List<LibraryRef> _publications;
  LibraryRef? _publication;
  LibraryRef? _subject;

  int _step = 0;
  bool _sending = false;
  Map<String, String> _serverErrors = const {};
  String _error = '';

  /// Set once the server has told us about this chapter, so step 3 can say
  /// what will actually happen when the student taps the button.
  LibraryLesson? _outcome;
  bool _outcomeIsNew = false;

  LibraryMeta get meta => c.meta.value!;
  LibraryRules get rules => meta.rules;

  @override
  void initState() {
    super.initState();
    _publications = [...meta.publications];
    _publication = c.publicationFilter.value;
    _subject =
        c.subjectFilter.value ??
        (meta.subjects.length == 1 ? meta.subjects.first : null);
  }

  @override
  void dispose() {
    _title.dispose();
    _chapter.dispose();
    super.dispose();
  }

  void _clearServerError(String field) {
    if (_serverErrors.containsKey(field) || _error.isNotEmpty) {
      setState(() {
        _serverErrors = Map.of(_serverErrors)..remove(field);
        _error = '';
      });
    }
  }

  // -------------------------------------------------------------------------
  // Moving between the three questions
  // -------------------------------------------------------------------------

  Future<void> _next() async {
    FocusScope.of(context).unfocus();
    if (_step == 0) {
      if (_publication == null || _subject == null) {
        setState(() {
          _error = _publication == null
              ? 'Pick your book first.'
              : 'Pick the subject.';
        });
        return;
      }
      setState(() {
        _error = '';
        _step = 1;
      });
      return;
    }
    if (_step == 1) {
      if (!(_chapterFormKey.currentState?.validate() ?? false)) return;
      // Ask the server about this chapter now, so step 3 can be honest about
      // what the button will do.
      await _lookUp();
    }
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_step == 0) {
      Get.back();
      return;
    }
    setState(() {
      _error = '';
      _outcome = null;
      _step--;
    });
  }

  /// `requestLesson` is both "does this chapter exist?" and "please add it".
  /// `200` means it was already known (no daily limit used), `201` that it is
  /// new and now waiting for a teacher.
  Future<void> _lookUp() async {
    setState(() {
      _sending = true;
      _error = '';
      _serverErrors = const {};
    });
    final result = await LibraryRepository.requestLesson(
      publicationId: _publication!.id,
      subjectId: _subject!.id,
      chapterNumber: int.parse(_chapter.text.trim()),
      title: _title.text,
    );
    if (!mounted) return;
    setState(() => _sending = false);

    if (result.ok) {
      unawaited(c.refreshAfterReturn());
      setState(() {
        _outcome = result.data;
        _outcomeIsNew = result.statusCode != 200;
        _step = 2;
      });
      return;
    }

    final fieldErrors = result.fieldErrors;
    setState(() {
      _serverErrors = fieldErrors;
      const onStepOne = {'publicationId', 'subjectId'};
      const onStepTwo = {'chapterNumber', 'title'};
      final unplaced = fieldErrors.keys.where(
        (k) => !onStepOne.contains(k) && !onStepTwo.contains(k),
      );
      _error = fieldErrors.isEmpty || unplaced.isNotEmpty
          ? result.displayMessage
          : '';
      if (fieldErrors.keys.any(onStepOne.contains)) _step = 0;
    });
  }

  // -------------------------------------------------------------------------
  // Pickers
  // -------------------------------------------------------------------------

  Future<void> _pickBook() async {
    final picked = await showLibraryPublicationPicker(
      context,
      known: _publications,
      selected: _publication,
      noteMax: rules.noteMax,
      onListed: (listed) {
        c.rememberPublication(listed);
        if (!_publications.contains(listed)) _publications.add(listed);
      },
    );
    if (picked == null) return;
    setState(() {
      _publication = picked;
      if (!_publications.contains(picked)) _publications.add(picked);
    });
    _clearServerError('publicationId');
  }

  Future<void> _pickSubject() async {
    final picked = await showModalBottomSheet<LibraryRef>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                'Which subject?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
            for (final s in meta.subjects)
              ListTile(
                title: Text(
                  s.name,
                  style: TextStyle(
                    fontWeight: s == _subject
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: s == _subject
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
                trailing: s == _subject
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(s),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    setState(() => _subject = picked);
    _clearServerError('subjectId');
  }

  // -------------------------------------------------------------------------
  // Finishing
  // -------------------------------------------------------------------------

  /// The chapter needs photos from this student right now.
  bool get _cameraNext {
    final lesson = _outcome;
    if (lesson == null) return false;
    return lesson.myState == LibraryLessonState.youCanUpload ||
        lesson.myState == LibraryLessonState.yourUploadInProgress;
  }

  Future<void> _finish() async {
    final lesson = _outcome;
    if (lesson == null) {
      Get.back();
      return;
    }
    switch (lesson.myState) {
      case LibraryLessonState.youCanUpload:
        // Straight into the camera flow — the student never saw the words
        // "request" or "session".
        await LibraryNavigation.startUpload(lesson.id, replaceCurrent: true);
      case LibraryLessonState.yourUploadInProgress:
        final sid = lesson.mySessionId;
        if (sid == null) {
          await LibraryNavigation.startUpload(lesson.id, replaceCurrent: true);
        } else {
          Get.back();
          await LibraryNavigation.openSession(sid);
        }
      case LibraryLessonState.available:
      case LibraryLessonState.yourUploadInReview:
        Get.back();
        await LibraryNavigation.openLesson(lesson.id);
      default:
        Get.back();
        showLibrarySnack(
          _outcomeIsNew
              ? "Sent! We'll tell you when you can add the photos."
              : "We'll tell you when this chapter is ready.",
        );
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: LibraryPalette.background,
        body: SafeArea(
          child: Column(
            children: [
              LibraryTopBar(title: 'Add a chapter', onBack: _back),
              LibraryStepBar(
                step: _step + 1,
                total: _stepCount,
                label: _stepLabel(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  children: [
                    if (_step == 0) ..._askBook(),
                    if (_step == 1) ..._askChapter(),
                    if (_step == 2) ..._ready(),
                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _ErrorBox(message: _error),
                    ],
                  ],
                ),
              ),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  String _stepLabel() {
    switch (_step) {
      case 0:
        return 'Which book is it from?';
      case 1:
        return 'Which chapter?';
      default:
        return _cameraNext ? 'Ready for your photos' : 'All done';
    }
  }

  // -- 1. Which book ----------------------------------------------------------

  List<Widget> _askBook() {
    return [
      const _BigQuestion(
        icon: Icons.menu_book_rounded,
        title: 'Which book is it from?',
        message: 'Look at the cover of your book.',
      ),
      const SizedBox(height: 24),
      _TapField(
        label: 'Book',
        value: _publication?.name,
        hint: 'Tap to choose',
        error: _serverErrors['publicationId'],
        onTap: _pickBook,
      ),
      const SizedBox(height: 16),
      _TapField(
        label: 'Subject',
        value: _subject?.name,
        hint: 'Tap to choose',
        error: _serverErrors['subjectId'],
        onTap: _pickSubject,
      ),
    ];
  }

  // -- 2. Which chapter -------------------------------------------------------

  List<Widget> _askChapter() {
    return [
      const _BigQuestion(
        icon: Icons.bookmark_border_rounded,
        title: 'Which chapter?',
        message: 'Copy the number and the name from your book.',
      ),
      const SizedBox(height: 24),
      Form(
        key: _chapterFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FieldLabel('Chapter number'),
            TextFormField(
              controller: _chapter,
              keyboardType: TextInputType.number,
              autofocus: _chapter.text.isEmpty,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              onChanged: (_) => _clearServerError('chapterNumber'),
              decoration: libraryInputDecoration(
                hint: '4',
                error: _serverErrors['chapterNumber'],
              ),
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null) return 'Type the chapter number.';
                if (n < 1 || n > rules.chapterMax) {
                  return 'It should be between 1 and ${rules.chapterMax}.';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            const _FieldLabel('Chapter name'),
            TextFormField(
              controller: _title,
              maxLength: rules.titleMax,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              onChanged: (_) => _clearServerError('title'),
              decoration: libraryInputDecoration(
                hint: 'Fractions',
                error: _serverErrors['title'],
              ),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return 'Type the chapter name.';
                if (t.length > rules.titleMax) {
                  return 'Keep it under ${rules.titleMax} letters.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    ];
  }

  // -- 3. What happens now ----------------------------------------------------

  List<Widget> _ready() {
    final camera = _cameraNext;
    final lesson = _outcome;
    final readable =
        lesson?.myState == LibraryLessonState.available ||
        lesson?.myState == LibraryLessonState.yourUploadInReview;

    if (readable) {
      return [
        const _BigQuestion(
          icon: Icons.auto_stories_rounded,
          title: 'Good news — it already exists!',
          message: 'Someone in your class has already added this chapter. '
              'You can read it right now.',
          color: LibraryPalette.green,
        ),
      ];
    }

    if (camera) {
      return [
        const _BigQuestion(
          icon: Icons.photo_camera_rounded,
          title: "You're all set",
          message: 'Now photograph the pages of this chapter from your book.',
          color: LibraryPalette.green,
        ),
        const SizedBox(height: 22),
        const _HowItWorks(),
      ];
    }

    return [
      _BigQuestion(
        icon: Icons.schedule_rounded,
        title: _outcomeIsNew ? 'Thanks — got it!' : 'Already on the way',
        message: _outcomeIsNew
            ? 'A teacher will check this chapter first. We will tell you as '
                  'soon as you can add the photos.'
            : 'Someone has already asked for this chapter. We will tell you '
                  'when it is ready.',
        color: LibraryPalette.amber,
      ),
    ];
  }

  // -- Footer -----------------------------------------------------------------

  Widget _footer() {
    final last = _step == _stepCount - 1;
    final lesson = _outcome;
    final readable =
        lesson?.myState == LibraryLessonState.available ||
        lesson?.myState == LibraryLessonState.yourUploadInReview;

    String label;
    IconData? icon;
    Color color = AppColors.primary;
    if (!last) {
      label = 'Next';
      icon = Icons.arrow_forward_rounded;
    } else if (readable) {
      label = 'Read it now';
      icon = Icons.chrome_reader_mode_outlined;
    } else if (_cameraNext) {
      label = 'Open the camera';
      icon = Icons.photo_camera_rounded;
      color = LibraryPalette.green;
    } else {
      label = 'Done';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE7EAF4))),
      ),
      child: Row(
        children: [
          if (_step > 0 && !last) ...[
            LibrarySecondaryButton(
              label: 'Back',
              onPressed: _sending ? null : _back,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: LibraryPrimaryButton(
              label: label,
              icon: icon,
              color: color,
              expand: true,
              busy: _sending,
              onPressed: last ? _finish : _next,
            ),
          ),
        ],
      ),
    );
  }
}

/// The three things that will happen to the student's photos.
class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LibraryPalette.border),
      ),
      child: const Column(
        children: [
          _HowLine(
            number: 1,
            text: 'Take one photo of every page, in order.',
          ),
          _HowLine(number: 2, text: 'Check them and tap Send.'),
          _HowLine(
            number: 3,
            text: 'We write the notes, questions and quiz for your class.',
            last: true,
          ),
        ],
      ),
    );
  }
}

class _HowLine extends StatelessWidget {
  const _HowLine({
    required this.number,
    required this.text,
    this.last = false,
  });

  final int number;
  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: LibraryPalette.green,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A step's single question, large enough to be the only thing read.
class _BigQuestion extends StatelessWidget {
  const _BigQuestion({
    required this.icon,
    required this.title,
    required this.message,
    this.color = AppColors.primary,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14.5,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// A big tappable row standing in for a dropdown — easier to hit than a
/// form field, and obviously tappable.
class _TapField extends StatelessWidget {
  const _TapField({
    required this.label,
    required this.value,
    required this.hint,
    required this.onTap,
    this.error,
  });

  final String label;
  final String? value;
  final String hint;
  final String? error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chosen = value != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: error != null
                      ? LibraryPalette.red
                      : chosen
                      ? AppColors.primary
                      : LibraryPalette.border,
                  width: chosen || error != null ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value ?? hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: chosen
                            ? AppColors.textPrimary
                            : AppColors.textMuted6,
                        fontSize: 16,
                        fontWeight: chosen ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted,
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              error!,
              style: const TextStyle(
                color: LibraryPalette.red,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LibraryPalette.redSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: LibraryPalette.red,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: LibraryPalette.red,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
