import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/appcolors.dart';
import '../../learn/chapter/controller/learn_chapter_controller.dart';
import '../../daily_quiz/practice_test/Views/practice_quiz_overview.dart';
import '../controllers/dashboard_tabbar_controller.dart';

/// Screen palette. Kept local so this screen reads as one piece rather than
/// borrowing half a dozen unrelated tokens.
const Color _canvas = Color(0xFFF4F5FB);
const Color _ink = Color(0xFF151935);
const Color _inkSoft = Color(0xFF6B7192);
const Color _hairline = Color(0xFFEBEEF8);

/// The full "Improvement Areas" list: every subject the student is losing
/// marks in, worst first, with the weak lessons behind each one a tap away.
class PerformanceDnaViews extends StatelessWidget {
  const PerformanceDnaViews({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardTabbarController>();

    return Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _ImprovementTopBar(),
            Expanded(
              child: Obx(() {
                if (controller.isLoadingWeakAreas.value) {
                  return const _ImprovementSkeleton();
                }

                if (controller.weakAreasError.value.isNotEmpty) {
                  return _PerformanceState(
                    message: controller.weakAreasError.value,
                    actionLabel: 'Retry',
                    onPressed: () => controller.loadWeakAreas(force: true),
                  );
                }

                final summary = controller.weakAreasSummary.value;
                final subjects = summary.subjects;

                return RefreshIndicator(
                  color: AppColors.primaryBright,
                  onRefresh: () => controller.loadWeakAreas(force: true),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 30),
                    children: [
                      _MasteryHeroCard(summary: summary),
                      const SizedBox(height: 22),
                      if (subjects.isEmpty)
                        _PerformanceState(
                          message: summary.hasAttempts
                              ? 'Nothing to fix right now — every subject is above the mark. Keep it up!'
                              : 'Attempt a quiz or two and we will show you exactly what to practise.',
                          actionLabel: 'Refresh',
                          onPressed: () => controller.loadWeakAreas(force: true),
                        )
                      else ...[
                        _SectionLabel(count: subjects.length),
                        const SizedBox(height: 14),
                        for (var index = 0; index < subjects.length; index++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _SubjectMasteryCard(
                              subject: subjects[index],
                              isTopPriority: index == 0,
                            ),
                          ),
                      ],
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImprovementTopBar extends StatelessWidget {
  const _ImprovementTopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 18, 14),
      child: Row(
        children: [
          Material(
            color: AppColors.white,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: Get.back,
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _ink,
                  size: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Improvement Areas',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Where your marks are leaking',
                  style: TextStyle(
                    color: _inkSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Overall mastery, as one ring plus the three totals behind it.
class _MasteryHeroCard extends StatelessWidget {
  const _MasteryHeroCard({required this.summary});

  final WeakAreasSummaryData summary;

  @override
  Widget build(BuildContext context) {
    final needsWork = summary.subjects.length;
    final headline = !summary.hasAttempts
        ? 'No attempts yet'
        : needsWork == 0
        ? 'Everything on track'
        : '$needsWork subject${needsWork == 1 ? '' : 's'} to fix';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4B3FD8), Color(0xFF6C5CE7), Color(0xFF9B6BF0)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4B3FD8).withValues(alpha: 0.28),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _MasteryRing(
                percent: summary.overallAccuracy,
                size: 84,
                stroke: 7,
                color: AppColors.white,
                trackColor: AppColors.white.withValues(alpha: 0.22),
                label: summary.overallAccuracyLabel,
                labelColor: AppColors.white,
                labelSize: 18,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Overall accuracy across everything you have attempted.',
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.80),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _HeroStat(value: '${summary.correct}', label: 'Correct'),
                _heroDivider,
                _HeroStat(value: '${summary.answered}', label: 'Attempted'),
                _heroDivider,
                _HeroStat(value: '${summary.skipped}', label: 'Skipped'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final Widget _heroDivider = Container(
  width: 1,
  height: 26,
  color: AppColors.white.withValues(alpha: 0.18),
);

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.78),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'SUBJECT MASTERY',
          style: TextStyle(
            color: _inkSoft,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _hairline),
          ),
          child: Text(
            '$count to fix',
            style: const TextStyle(
              color: _ink,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

/// One subject: its mastery ring, how the attempts split, and the weak
/// lessons hiding behind it (tap opens them).
class _SubjectMasteryCard extends StatelessWidget {
  const _SubjectMasteryCard({
    required this.subject,
    required this.isTopPriority,
  });

  final WeakAreaSubjectData subject;

  /// The worst subject gets a badge, so there is always one obvious next move.
  final bool isTopPriority;

  @override
  Widget build(BuildContext context) {
    final accent = _subjectAccent(subject.name);
    final mastery = subject.accuracy.clamp(0, 100).toDouble();
    final weakLessons = subject.lessons.length;

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => showWeakAreaLessonsBottomSheet(
          context,
          subject,
          dashboardController: Get.find<DashboardTabbarController>(),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _hairline),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9AA4C8).withValues(alpha: 0.13),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _MasteryRing(
                    percent: mastery,
                    size: 56,
                    stroke: 5,
                    color: accent,
                    trackColor: accent.withValues(alpha: 0.14),
                    label: subject.accuracyLabel,
                    labelColor: accent,
                    labelSize: 12,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                subject.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _ink,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            if (isTopPriority) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEDEF),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'START HERE',
                                  style: TextStyle(
                                    color: Color(0xFFD71920),
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${subject.correct}/${subject.answered} correct'
                          '${subject.skipped > 0 ? '  ·  ${subject.skipped} skipped' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _inkSoft,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: mastery / 100,
                  backgroundColor: const Color(0xFFF0F2F9),
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      weakLessons == 0
                          ? 'No specific lesson flagged yet'
                          : '$weakLessons weak lesson${weakLessons == 1 ? '' : 's'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _inkSoft,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Practice',
                          style: TextStyle(
                            color: accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: accent,
                          size: 18,
                        ),
                      ],
                    ),
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

/// A percentage drawn as a ring with the figure in the middle.
class _MasteryRing extends StatelessWidget {
  const _MasteryRing({
    required this.percent,
    required this.size,
    required this.stroke,
    required this.color,
    required this.trackColor,
    required this.label,
    required this.labelColor,
    required this.labelSize,
  });

  final double percent;
  final double size;
  final double stroke;
  final Color color;
  final Color trackColor;
  final String label;
  final Color labelColor;
  final double labelSize;

  @override
  Widget build(BuildContext context) {
    // A percentage straight off the API should never be able to break the
    // painter, so it is clamped (and NaN-guarded) before it gets there.
    final safePercent = percent.isNaN ? 0.0 : percent.clamp(0, 100).toDouble();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: safePercent / 100,
              strokeWidth: stroke,
              strokeCap: StrokeCap.round,
              backgroundColor: trackColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(stroke + 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: labelColor,
                  fontSize: labelSize,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImprovementSkeleton extends StatelessWidget {
  const _ImprovementSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 30),
      children: const [
        _PerformanceShimmerBox(height: 172, radius: 26),
        SizedBox(height: 24),
        Row(
          children: [
            _PerformanceShimmerBox(width: 128, height: 12, radius: 6),
            Spacer(),
            _PerformanceShimmerBox(width: 64, height: 22, radius: 11),
          ],
        ),
        SizedBox(height: 16),
        _ImprovementSkeletonCard(),
        SizedBox(height: 14),
        _ImprovementSkeletonCard(),
        SizedBox(height: 14),
        _ImprovementSkeletonCard(),
      ],
    );
  }
}

class _ImprovementSkeletonCard extends StatelessWidget {
  const _ImprovementSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _hairline),
      ),
      child: const Column(
        children: [
          Row(
            children: [
              _PerformanceShimmerBox(width: 56, height: 56, radius: 28),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PerformanceShimmerBox(
                      width: double.infinity,
                      height: 14,
                      radius: 7,
                    ),
                    SizedBox(height: 9),
                    _PerformanceShimmerBox(width: 124, height: 10, radius: 5),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 17),
          _PerformanceShimmerBox(
            width: double.infinity,
            height: 6,
            radius: 3,
          ),
          SizedBox(height: 16),
          Row(
            children: [
              _PerformanceShimmerBox(width: 104, height: 10, radius: 5),
              Spacer(),
              _PerformanceShimmerBox(width: 92, height: 32, radius: 16),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> showWeakAreaLessonsBottomSheet(
  BuildContext context,
  WeakAreaSubjectData subject, {
  DashboardTabbarController? dashboardController,
}) async {
  final learnSubject =
      _findLoadedLearnSubject(dashboardController, subject.id) ??
      await _fetchLearnSubject(subject.id) ??
      _fallbackLearnSubject(subject);
  final weakLessons = subject.lessons
      .where((lesson) => lesson.id.trim().isNotEmpty)
      .toList();
  final chapters = _weakLessonsAsChapters(weakLessons, learnSubject);

  if (!context.mounted) {
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFF8F6FF),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) {
      return SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE3F4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      learnSubject.title,
                      style: const TextStyle(
                        color: AppColors.textPrimaryNavy,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    subject.accuracyLabel,
                    style: const TextStyle(
                      color: AppColors.textMuted6,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            if (chapters.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No weak lessons available for this subject.',
                  style: TextStyle(
                    color: AppColors.textMuted6,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.62,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  itemCount: chapters.length,
                  itemBuilder: (c, i) {
                    final chapter = chapters[i];
                    final weakLesson = weakLessons[i];
                    return ListTile(
                      onTap: () {
                        Navigator.of(ctx).pop();
                        Get.to(
                          () => PracticeQuizOverviewViews(
                            subject: learnSubject,
                            chapter: chapter,
                            returnToLessonOnResultBack: true,
                          ),
                        );
                      },
                      contentPadding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tileColor: Colors.white,
                      title: Text(
                        chapter.title,
                        style: const TextStyle(
                          color: AppColors.textPrimaryNavy,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        chapter.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted6,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.play_arrow_rounded,
                            color: Color(0xFF4D4FE1),
                          ),
                          Text(
                            weakLesson.accuracyLabel,
                            style: const TextStyle(
                              color: AppColors.textMuted6,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                ),
              ),
          ],
        ),
      );
    },
  );
}

LearnSubjectModel? _findLoadedLearnSubject(
  DashboardTabbarController? controller,
  String subjectId,
) {
  if (controller == null) {
    return null;
  }
  for (final subjectCard in controller.learnSubjects) {
    if (subjectCard.learnSubject.id == subjectId) {
      return subjectCard.learnSubject;
    }
  }
  return null;
}

Future<LearnSubjectModel?> _fetchLearnSubject(String subjectId) async {
  final response = await LearnCatalogData.getUserSubjects();
  final subjects = response.data ?? const <LearnSubjectModel>[];
  for (final subject in subjects) {
    if (subject.id == subjectId) {
      return subject;
    }
  }
  return null;
}

LearnSubjectModel _fallbackLearnSubject(WeakAreaSubjectData subject) {
  final accent = _subjectAccent(subject.name);
  return LearnSubjectModel(
    id: subject.id,
    title: subject.name,
    subtitle: 'Weak lessons',
    icon: Icons.menu_book_rounded,
    accent: accent,
    iconBackground: accent.withValues(alpha: 0.12),
    chapters: const [],
    classLevel: '-',
    description: 'Weak lessons',
    completedLessons: 0,
    totalLessons: subject.lessons.length,
  );
}

List<LearnChapterModel> _weakLessonsAsChapters(
  List<WeakAreaLessonData> lessons,
  LearnSubjectModel learnSubject,
) {
  return lessons.asMap().entries.map((entry) {
    final index = entry.key;
    final lesson = entry.value;
    final order = lesson.order > 0 ? lesson.order : index + 1;
    final description = lesson.description.isEmpty
        ? 'Practice this weak lesson to improve your mastery.'
        : lesson.description;
    final learnLesson = LearnLessonModel(
      id: lesson.id,
      title: lesson.title,
      chapterLabel: 'LESSON $order',
      subjectLabel: learnSubject.title.toUpperCase(),
      description: description,
      progress: 0,
      currentTime: '00:00',
      totalTime: '00:00',
      notes: description,
      videoUrl: '',
      pdfUrl: '',
      content: '',
      resources: const [],
    );

    return LearnChapterModel(
      id: lesson.id,
      chapterNumber: order,
      title: lesson.title,
      status: LearnChapterStatus.inProgress,
      completedLessons: 0,
      totalLessons: 1,
      progressValue: 0,
      quizCount: 0,
      accent: learnSubject.accent,
      summary: description,
      topics: [
        LearnTopicModel(
          id: lesson.id,
          title: lesson.title,
          status: LearnTopicStatus.notStarted,
          progress: 0,
          hasVideo: false,
          hasNotes: description.isNotEmpty,
          hasWorksheet: false,
          lesson: learnLesson,
        ),
      ],
    );
  }).toList();
}
class _PerformanceShimmerBox extends StatefulWidget {
  const _PerformanceShimmerBox({
    this.width,
    required this.height,
    this.radius = 12,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<_PerformanceShimmerBox> createState() => _PerformanceShimmerBoxState();
}

class _PerformanceShimmerBoxState extends State<_PerformanceShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + (_controller.value * 2), 0),
              end: Alignment(0.2 + (_controller.value * 2), 0),
              colors: const [
                Color(0xFFE8EDF8),
                Color(0xFFF8FAFF),
                Color(0xFFE8EDF8),
              ],
            ),
          ),
        );
      },
    );
  }
}
class _PerformanceState extends StatelessWidget {
  const _PerformanceState({
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 60),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          TextButton(onPressed: onPressed, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

Color _subjectAccent(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('chem')) {
    return const Color(0xFF20C790);
  }
  if (lower.contains('stat') || lower.contains('math')) {
    return const Color(0xFF8FA2C7);
  }
  if (lower.contains('bio') || lower.contains('science')) {
    return const Color(0xFF28B7A2);
  }
  return const Color(0xFF7379FF);
}
