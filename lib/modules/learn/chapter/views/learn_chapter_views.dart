import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/data/subscription_access.dart';
import '../../../../core/service/learn_progress_refresh_service.dart';
import '../../../subscription/subscription_views.dart';
import '../../exercise/views/lesson_qa_search_views.dart';
import '../controller/learn_chapter_controller.dart';
import 'learn_subject_views.dart';
import 'learn_topic_views.dart';

class LearnChapterViews extends StatefulWidget {
  const LearnChapterViews({super.key, required this.subject});

  final LearnSubjectModel subject;

  @override
  State<LearnChapterViews> createState() => _LearnChapterViewsState();
}

class _LearnChapterViewsState extends State<LearnChapterViews> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<LearnChapterModel> _chapters = const [];
  // Whether the student has an active subscription. When false, only the first
  // [SubscriptionAccess.freeLessonLimit] lessons stay open; the rest are locked
  // behind a purchase prompt.
  bool _isSubscribed = false;
  late final Worker _refreshWorker;

  @override
  void initState() {
    super.initState();
    _refreshWorker = ever<int>(
      LearnProgressRefreshService.instance.refreshTick,
      (_) {
        if (mounted) {
          _loadLessons();
        }
      },
    );
    _loadLessons();
  }

  @override
  void dispose() {
    _refreshWorker.dispose();
    super.dispose();
  }

  Future<void> _loadLessons() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Fetch lessons and subscription status concurrently so the paywall gate is
    // known by the time the list renders (no lock flicker for subscribers).
    final lessonsFuture = LearnCatalogData.getUserLessons(
      subject: widget.subject,
    );
    final subscribedFuture = SubscriptionAccess.isSubscribed();

    final response = await lessonsFuture;
    final subscribed = await subscribedFuture;

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _chapters = response.data ?? const [];
      _errorMessage = response.success ? '' : response.message;
      _isSubscribed = subscribed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final description = widget.subject.description.isNotEmpty
        ? widget.subject.description
        : widget.subject.subtitle;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        child: Column(
          children: [
            LearnTopBar(
              title: 'Chapters',
              trailing: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => Get.to(
                  () => LessonQaSearchViews(
                    subjectId: widget.subject.id,
                    classLevel: widget.subject.classLevel,
                    scopeTitle: widget.subject.title,
                    accent: widget.subject.accent,
                  ),
                ),
                icon: Icon(
                  Icons.search_rounded,
                  color: widget.subject.accent,
                  size: 24,
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadLessons,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
                  children: [
                    Text(
                      'CURRENT SUBJECT',
                      style: TextStyle(
                        color: widget.subject.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.subject.title,
                      style: const TextStyle(
                        color: Color(0xFF1D2231),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Author ',
                            style: TextStyle(
                              color: widget.subject.accent,
                              fontSize: 13,
                              height: 1.6,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: description.isEmpty
                                ? ''
                                : description,
                            style: const TextStyle(
                              color: Color(0xFF373B4B),
                              fontSize: 13,
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_errorMessage.isNotEmpty)
                      _ChapterStateCard(
                        title: 'Unable to load chapters',
                        message: _errorMessage,
                        onRetry: _loadLessons,
                      )
                    else if (_chapters.isEmpty)
                      const _ChapterStateCard(
                        title: 'No chapters available',
                        message: 'This subject does not have any lesson yet.',
                      )
                    else
                      ..._chapters.asMap().entries.map((entry) {
                        final index = entry.key;
                        final chapter = entry.value;
                        // Free students keep the first N lessons; the rest are
                        // gated behind the purchase prompt.
                        final paywallLocked =
                            !_isSubscribed &&
                            index >= SubscriptionAccess.freeLessonLimit;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: _ChapterCard(
                            subject: widget.subject,
                            chapter: chapter,
                            onReload: _loadLessons,
                            paywallLocked: paywallLocked,
                            onUnlockTap: () =>
                                Get.to(() => const SubscriptionViews()),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.subject,
    required this.chapter,
    required this.onReload,
    this.paywallLocked = false,
    this.onUnlockTap,
  });

  final LearnSubjectModel subject;
  final LearnChapterModel chapter;
  final Future<void> Function() onReload;

  /// Client-side subscription gate: the lesson exists but the free user must
  /// subscribe to open it. Distinct from a server [LearnChapterStatus.locked].
  final bool paywallLocked;
  final VoidCallback? onUnlockTap;

  @override
  Widget build(BuildContext context) {
    final isCompleted = chapter.status == LearnChapterStatus.completed;
    final isInProgress = chapter.status == LearnChapterStatus.inProgress;
    final isNotStarted = chapter.status == LearnChapterStatus.notStarted;
    final isServerLocked = chapter.status == LearnChapterStatus.locked;
    // Both server-locked and paywall-locked lessons wear the dimmed "locked"
    // treatment; only their tap behaviour differs (buy vs. nothing).
    final isLocked = isServerLocked || paywallLocked;

    const completedColor = Color(0xFF12B76A);
    const inProgressColor = Color(0xFFF97316);
    const inProgressBackground = Color(0xFFFFF3D6);
    const notStartedColor = Color(0xFF8C8F9C);
    const notStartedBackground = Color(0xFFF1F3F8);

    return InkWell(
      onTap: paywallLocked
          ? onUnlockTap
          : isServerLocked
          ? null
          : () async {
              final shouldReload = await Get.to<bool>(
                () => LearnTopicViews(subject: subject, chapter: chapter),
              );
              if (shouldReload == true) {
                await onReload();
              }
            },
      borderRadius: BorderRadius.circular(28),
      child: Opacity(
        opacity: paywallLocked ? 0.7 : (isServerLocked ? 0.55 : 1),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isCompleted
                  ? completedColor
                  : isInProgress
                  ? inProgressColor
                  : const Color(0xFFD8DCE4),
              width: isInProgress ? 2.2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD7DCEF).withValues(alpha: 0.28),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: isLocked
                          ? const Color(0xFFF0F2F6)
                          : isCompleted
                          ? const Color(0xFFE6F8EF)
                          : isInProgress
                          ? inProgressBackground
                          : notStartedBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isLocked
                          ? Icons.lock_outline_rounded
                          : (isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.menu_book_rounded),
                      color: isLocked
                          ? const Color(0xFFA1A4B3)
                          : (isCompleted
                                ? completedColor
                                : isInProgress
                                ? inProgressColor
                                : notStartedColor),
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  if (paywallLocked)
                    const _PremiumBadge()
                  else
                    _ChapterBadge(chapter: chapter),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Lesson ${chapter.chapterNumber}',
                style: TextStyle(
                  color: isLocked
                      ? const Color(0xFF8A8D9B)
                      : const Color(0xFF3E4357),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                chapter.title,
                style: TextStyle(
                  color: isLocked
                      ? const Color(0xFF5B5F6F)
                      : const Color(0xFF1D2231),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                chapter.summary,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF4C4F5E),
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 15),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: chapter.progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE5E8EF),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted
                        ? completedColor
                        : (isInProgress
                              ? inProgressColor
                              : const Color(0xFFD8DCE4)),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      paywallLocked
                          ? 'Subscribe to unlock this lesson'
                          : isServerLocked
                          ? chapter.summary
                          : chapter.lessonQuizMeta,
                      style: TextStyle(
                        color: isLocked
                            ? const Color(0xFF707486)
                            : const Color(0xFF44485C),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (paywallLocked)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: inProgressColor,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Unlock',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isCompleted)
                    const Text(
                      'Review ->',
                      style: TextStyle(
                        color: completedColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else if (isInProgress)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: inProgressColor,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else if (isServerLocked)
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: Color(0xFFBCBED0),
                    )
                  else if (isNotStarted)
                    const Icon(
                      Icons.radio_button_unchecked_rounded,
                      color: notStartedColor,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChapterBadge extends StatelessWidget {
  const _ChapterBadge({required this.chapter});

  final LearnChapterModel chapter;

  @override
  Widget build(BuildContext context) {
    final isCompleted = chapter.status == LearnChapterStatus.completed;
    final isInProgress = chapter.status == LearnChapterStatus.inProgress;

    const completedColor = Color(0xFF12B76A);
    const inProgressColor = Color(0xFFF97316);
    const inProgressBackground = Color(0xFFFFF3D6);
    const notStartedColor = Color(0xFF8C8F9C);

    final background = isCompleted
        ? completedColor
        : isInProgress
        ? inProgressBackground
        : const Color(0xFFE7EAEE);

    final label = isCompleted
        ? 'Completed'
        : isInProgress
        ? 'In Progress'
        : chapter.status == LearnChapterStatus.notStarted
        ? 'Not Started'
        : 'Locked';

    final textColor = isCompleted
        ? Colors.white
        : isInProgress
        ? inProgressColor
        : notStartedColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Badge shown on lessons a free user must subscribe to open.
class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge();

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFF97316);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, color: accent, size: 13),
          SizedBox(width: 5),
          Text(
            'Premium',
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterStateCard extends StatelessWidget {
  const _ChapterStateCard({
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC8C7F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1D2231),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF4F5367),
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A4FD9),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
