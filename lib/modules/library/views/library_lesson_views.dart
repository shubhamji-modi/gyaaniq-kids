import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/service/api_service.dart';
import '../../../core/service/app_route_observer.dart';
import '../../../core/theme/appcolors.dart';
import '../../../core/widgets/math_html_text.dart';
import '../../learn/exercise/views/lesson_qa_views.dart';
import '../controller/library_controller.dart';
import '../controller/library_lesson_controller.dart';
import '../data/library_models.dart';
import '../data/library_repository.dart';
import '../library_navigation.dart';
import 'library_quiz_views.dart';
import 'library_widgets.dart';

/// One Library lesson. Readable → Overview / Notes / Q&A / Quiz. Otherwise the
/// lesson's state for this student, with the one action that fits it.
class LibraryLessonViews extends StatefulWidget {
  const LibraryLessonViews({super.key, required this.lessonId});

  final String lessonId;

  @override
  State<LibraryLessonViews> createState() => _LibraryLessonViewsState();
}

class _LibraryLessonViewsState extends State<LibraryLessonViews>
    with RouteAware {
  late final String _tag;
  late final LibraryLessonController c;
  bool _subscribed = false;

  @override
  void initState() {
    super.initState();
    _tag = 'library_lesson_${widget.lessonId}_$hashCode';
    c = Get.put(LibraryLessonController(lessonId: widget.lessonId), tag: _tag);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (!_subscribed && route is PageRoute) {
      appRouteObserver.subscribe(this, route);
      _subscribed = true;
    }
  }

  @override
  void dispose() {
    if (_subscribed) appRouteObserver.unsubscribe(this);
    Get.delete<LibraryLessonController>(tag: _tag);
    super.dispose();
  }

  /// Back from an upload, the quiz, … — `myState` may have moved on.
  @override
  void didPopNext() {
    c.load(silent: true);
  }

  Future<void> _toggleFollow() async {
    final wasFollowing = c.lesson.value?.isFollowing ?? false;
    final result = await c.toggleFollow();
    if (result == null) return;
    showLibrarySnack(
      result.ok
          ? (result.message.isNotEmpty && result.message != 'Success'
                ? result.message
                : (wasFollowing
                      ? 'You will no longer get updates for this lesson.'
                      : "We'll notify you when it's ready."))
          : result.displayMessage,
      isError: !result.ok,
    );
  }

  bool get _uploadsAvailable {
    if (!Get.isRegistered<LibraryController>()) return true;
    return Get.find<LibraryController>().meta.value?.uploadsAvailable ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LibraryPalette.background,
      body: SafeArea(
        child: Obx(() {
          final lesson = c.lesson.value;
          if (c.isLoading.value && lesson == null) {
            return const Column(
              children: [
                LibraryTopBar(title: 'Lesson'),
                Expanded(child: Center(child: CircularProgressIndicator())),
              ],
            );
          }
          if (lesson == null) {
            final gone = c.errorStatus.value == 404;
            return Column(
              children: [
                const LibraryTopBar(title: 'Lesson'),
                Expanded(
                  child: LibraryMessageView(
                    icon: gone
                        ? Icons.menu_book_outlined
                        : Icons.cloud_off_rounded,
                    title: gone
                        ? 'This lesson is no longer available.'
                        : 'Unable to open this lesson',
                    message: gone ? '' : c.error.value,
                    actionLabel: gone ? 'Back' : 'Retry',
                    onAction: gone ? Get.back : c.load,
                  ),
                ),
              ],
            );
          }
          if (lesson.canRead) return _ReadableLesson(lesson: lesson);
          return Column(
            children: [
              LibraryTopBar(
                title: lesson.title.isEmpty ? 'Lesson' : lesson.title,
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => c.load(silent: true),
                  child: _LessonStatusView(
                    lesson: lesson,
                    followBusy: c.isFollowBusy.value,
                    uploadsAvailable: _uploadsAvailable,
                    onToggleFollow: _toggleFollow,
                    onUpload: () => LibraryNavigation.startUpload(
                      lesson.id,
                      openedFromLesson: true,
                    ),
                    onContinue: () {
                      final sid = lesson.mySessionId;
                      if (sid == null) {
                        LibraryNavigation.startUpload(
                          lesson.id,
                          openedFromLesson: true,
                        );
                      } else {
                        LibraryNavigation.openSession(
                          sid,
                          openedFromLesson: true,
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _LessonHeader extends StatelessWidget {
  const _LessonHeader({required this.lesson});

  final LibraryLesson lesson;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lesson.sourceLine,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          lesson.title.isEmpty ? 'Untitled' : lesson.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// Not readable yet: what is going on and what this student can do.
class _LessonStatusView extends StatelessWidget {
  const _LessonStatusView({
    required this.lesson,
    required this.followBusy,
    required this.uploadsAvailable,
    required this.onToggleFollow,
    required this.onUpload,
    required this.onContinue,
  });

  final LibraryLesson lesson;
  final bool followBusy;
  final bool uploadsAvailable;
  final VoidCallback onToggleFollow;
  final VoidCallback onUpload;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final state = lesson.myState;
    final style = LibraryStateStyle.of(state);
    final progress = lesson.progress;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
      children: [
        _LessonHeader(lesson: lesson),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: LibraryPalette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: style.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(style.icon, color: style.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      style.label,
                      style: TextStyle(
                        color: style.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              if (lesson.message.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  lesson.message,
                  style: TextStyle(
                    color: state == LibraryLessonState.rejected
                        ? LibraryPalette.red
                        : AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ],
              if (lesson.uploadOpensAt != null &&
                  lesson.uploadOpensAt!.isAfter(DateTime.now())) ...[
                const SizedBox(height: 8),
                Text(
                  'Uploads open for everyone on '
                  '${libraryDateLabel(lesson.uploadOpensAt!)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (progress != null) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    minHeight: 7,
                    value: progress.isWriting || progress.pagesTotal <= 0
                        ? null
                        : progress.fraction,
                    backgroundColor: LibraryPalette.greySoft,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  progress.isWriting
                      ? 'Writing overview, notes, Q&A and quiz…'
                      : 'Reading page ${(progress.pagesRead + 1).clamp(1, progress.pagesTotal < 1 ? 1 : progress.pagesTotal)} of ${progress.pagesTotal}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (lesson.followerCount > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.groups_2_outlined,
                      size: 17,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      lesson.followerCount == 1
                          ? '1 student wants this'
                          : '${lesson.followerCount} students want this',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
              ..._actions(),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _actions() {
    final state = lesson.myState;
    final out = <Widget>[];
    if (state == LibraryLessonState.youCanUpload) {
      out.add(
        uploadsAvailable
            ? LibraryPrimaryButton(
                label: 'Upload pages',
                icon: Icons.photo_camera_outlined,
                color: LibraryPalette.green,
                expand: true,
                onPressed: onUpload,
              )
            : const Text(
                'Uploads are paused right now. Please try again later.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
      );
    } else if (state == LibraryLessonState.yourUploadInProgress &&
        lesson.progress == null) {
      out.add(
        LibraryPrimaryButton(
          label: 'Continue upload',
          icon: Icons.arrow_forward_rounded,
          expand: true,
          onPressed: onContinue,
        ),
      );
    } else if (state == LibraryLessonState.yourUploadInProgress) {
      out.add(
        LibrarySecondaryButton(
          label: 'View upload',
          expand: true,
          onPressed: onContinue,
        ),
      );
    }
    if (state.offersFollow) {
      out.add(
        lesson.isFollowing
            ? LibrarySecondaryButton(
                label: lesson.isRequester
                    ? "Following — you'll be notified"
                    : 'Following · tap to stop',
                icon: Icons.notifications_active_rounded,
                color: LibraryPalette.green,
                expand: true,
                busy: followBusy,
                onPressed: lesson.isRequester ? null : onToggleFollow,
              )
            : LibraryPrimaryButton(
                label: 'Follow — notify me when ready',
                icon: Icons.notifications_none_rounded,
                expand: true,
                busy: followBusy,
                onPressed: onToggleFollow,
              ),
      );
    }
    if (out.isEmpty) return const [];
    return [
      const SizedBox(height: 16),
      for (var i = 0; i < out.length; i++) ...[
        if (i > 0) const SizedBox(height: 10),
        out[i],
      ],
    ];
  }
}

/// Readable lesson: tabs for each part that exists.
class _ReadableLesson extends StatelessWidget {
  const _ReadableLesson({required this.lesson});

  final LibraryLesson lesson;

  @override
  Widget build(BuildContext context) {
    final overview = lesson.overview;
    final notes = lesson.notes;
    final tabs = <({String label, Widget view})>[
      if ((overview != null && !overview.isEmpty) || lesson.hasOverview)
        (
          label: 'Overview',
          view: _HtmlTab(
            heading: overview?.title ?? '',
            html: overview?.content ?? '',
            emptyText: 'The overview is not ready yet.',
          ),
        ),
      if ((notes != null && !notes.isEmpty) || lesson.hasNotes)
        (
          label: 'Notes',
          view: _HtmlTab(
            heading: notes?.title ?? '',
            html: notes?.content ?? '',
            emptyText: 'Notes are not ready yet.',
          ),
        ),
      (label: 'Q&A', view: _QaTab(lesson: lesson)),
      (label: 'Quiz', view: _QuizTab(lesson: lesson)),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          LibraryTopBar(title: lesson.title.isEmpty ? 'Lesson' : lesson.title),
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${lesson.publication.name} · Ch ${lesson.chapterNumber}'
                  '${lesson.subject.name.isEmpty ? '' : ' · ${lesson.subject.name}'}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (lesson.myState == LibraryLessonState.yourUploadInReview)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: LibraryPalette.purpleSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 17,
                          color: LibraryPalette.purple,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Other students will see this after a quick review.',
                            style: TextStyle(
                              color: LibraryPalette.purple,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                TabBar(
                  isScrollable: tabs.length > 3,
                  tabAlignment: tabs.length > 3 ? TabAlignment.start : null,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textMuted,
                  indicatorColor: AppColors.primary,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                  tabs: [for (final t in tabs) Tab(text: t.label)],
                ),
              ],
            ),
          ),
          Expanded(child: TabBarView(children: [for (final t in tabs) t.view])),
        ],
      ),
    );
  }
}

class _HtmlTab extends StatelessWidget {
  const _HtmlTab({
    required this.heading,
    required this.html,
    required this.emptyText,
  });

  final String heading;
  final String html;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (html.trim().isEmpty && heading.trim().isEmpty) {
      return LibraryMessageView(
        icon: Icons.hourglass_empty_rounded,
        title: emptyText,
        message: '',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: LibraryPalette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (heading.trim().isNotEmpty) ...[
                MathHtmlText(
                  heading,
                  textStyle: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              MathHtmlText(
                html,
                textStyle: const TextStyle(
                  color: Color(0xFF43485A),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QaTab extends StatelessWidget {
  const _QaTab({required this.lesson});

  final LibraryLesson lesson;

  @override
  Widget build(BuildContext context) {
    final count = lesson.qaCount;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      children: [
        _LaunchCard(
          icon: Icons.question_answer_outlined,
          color: AppColors.primary,
          title: 'Questions & answers',
          subtitle: count > 0
              ? '$count question${count == 1 ? '' : 's'} from this lesson, '
                    'with answers'
              : 'Questions from this lesson, with answers',
          buttonLabel: 'Open Q&A',
          onPressed: () => Get.to(
            () => LessonQaViews(
              lessonId: lesson.id,
              lessonTitle: lesson.title,
              screenTitle: 'Questions & Answers',
              endpoint: ApiService.LIBRARY_LESSON_QA.replaceFirst(
                ':id',
                lesson.id,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuizTab extends StatefulWidget {
  const _QuizTab({required this.lesson});

  final LibraryLesson lesson;

  @override
  State<_QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends State<_QuizTab> with AutomaticKeepAliveClientMixin {
  List<LibraryQuizAttemptSummary> _attempts = const [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadAttempts();
  }

  Future<void> _loadAttempts() async {
    final result = await LibraryRepository.fetchAttempts(widget.lesson.id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.ok) _attempts = result.data ?? const [];
    });
  }

  Future<void> _start() async {
    await Get.to(
      () => LibraryQuizViews(
        lessonId: widget.lesson.id,
        lessonTitle: widget.lesson.title,
      ),
    );
    unawaited(_loadAttempts());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final count = widget.lesson.quizQuestionCount;
    final description = widget.lesson.quizDescription;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      children: [
        _LaunchCard(
          icon: Icons.quiz_outlined,
          color: LibraryPalette.purple,
          title: 'Practice quiz',
          subtitle: [
            if (description.isNotEmpty) description,
            if (count > 0) '$count questions',
            'Practice only — no XP, not counted in Weak Areas or leaderboards.',
          ].join('\n'),
          buttonLabel: _attempts.isEmpty ? 'Start quiz' : 'Try again',
          onPressed: _start,
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
          )
        else if (_attempts.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Text(
            'Your attempts',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          for (final a in _attempts)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: LibraryPalette.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      a.createdAt == null
                          ? 'Attempt'
                          : libraryDateLabel(a.createdAt!),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    '${a.correct}/${a.total} · ${a.percentage.round()}%',
                    style: TextStyle(
                      color: a.percentage >= 60
                          ? LibraryPalette.green
                          : LibraryPalette.amber,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _LaunchCard extends StatelessWidget {
  const _LaunchCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LibraryPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          LibraryPrimaryButton(
            label: buttonLabel,
            color: color,
            expand: true,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}
