import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/appcolors.dart';
import '../../learn/chapter/controller/learn_chapter_controller.dart';
import '../../daily_quiz/practice_test/Views/practice_quiz_overview.dart';
import '../controllers/dashboard_tabbar_controller.dart';

class PerformanceDnaViews extends GetView<DashboardTabbarController> {
  const PerformanceDnaViews({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FC),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textBlueDark,
            size: 18,
          ),
          onPressed: Get.back,
        ),
        title: const Text(
          'Performance DNA',
          style: TextStyle(
            color: AppColors.textBlueDark,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Obx(() {
          final summary = controller.weakAreasSummary.value;

          if (controller.isLoadingWeakAreas.value) {
            return const _PerformanceDnaSkeleton();
          }

          if (controller.weakAreasError.value.isNotEmpty) {
            return _PerformanceState(
              message: controller.weakAreasError.value,
              actionLabel: 'Retry',
              onPressed: controller.loadWeakAreas,
            );
          }

          return RefreshIndicator(
            onRefresh: controller.loadWeakAreas,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 46, 10, 28),
              children: [
                _PerformanceSummaryStrip(summary: summary),
                const SizedBox(height: 16),
                const _SectionTitle(),
                const SizedBox(height: 14),
                if (summary.subjects.isEmpty)
                  _PerformanceState(
                    message: summary.hasAttempts
                        ? 'Great job, no weak areas right now!'
                        : 'Start attempting quizzes to see subject mastery.',
                    actionLabel: 'Refresh',
                    onPressed: controller.loadWeakAreas,
                  )
                else
                  _SubjectMasteryTimeline(subjects: summary.subjects),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _PerformanceSummaryStrip extends StatelessWidget {
  const _PerformanceSummaryStrip({required this.summary});

  final WeakAreasSummaryData summary;

  @override
  Widget build(BuildContext context) {
    final reviewCount = summary.subjects.length;

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 34),
      decoration: BoxDecoration(
        color: const Color(0xFF303341),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryMetric(
              value: '${summary.correct}',
              label: 'MASTERED',
              color: const Color(0xFF55E0AD),
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: AppColors.white.withValues(alpha: 0.10),
          ),
          Expanded(
            child: _SummaryMetric(
              value: '$reviewCount',
              label: 'REVIEW',
              color: const Color(0xFFFFD3DE),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 27,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 7,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(width: 4),
        Icon(Icons.hourglass_empty_rounded, size: 12, color: Color(0xFF6E7488)),
        SizedBox(width: 5),
        Text(
          'SUBJECT MASTERY',
          style: TextStyle(
            color: Color(0xFF6E7488),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _SubjectMasteryTimeline extends StatelessWidget {
  const _SubjectMasteryTimeline({required this.subjects});

  final List<WeakAreaSubjectData> subjects;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 12,
          top: 0,
          bottom: 0,
          child: Container(width: 1, color: const Color(0xFFDDE3F4)),
        ),
        Column(
          children: subjects.asMap().entries.map((entry) {
            return _SubjectMasteryRow(
              subject: entry.value,
              accent: _subjectAccent(entry.value.name),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SubjectMasteryRow extends StatelessWidget {
  const _SubjectMasteryRow({required this.subject, required this.accent});

  final WeakAreaSubjectData subject;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final mastery = subject.accuracy.clamp(0, 100).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: () => showWeakAreaLessonsBottomSheet(context, subject),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 25,
              alignment: Alignment.center,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryBright, width: 2),
                ),
                child: Center(
                  child: Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryBright,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 1),
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE9EDF6)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SubjectIcon(accent: accent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subject.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF161927),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  height: 1.06,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${subject.answered} Attempts',
                                style: const TextStyle(
                                  color: Color(0xFF6F7482),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE2E4),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            'RETRY',
                            style: TextStyle(
                              color: Color(0xFFD71920),
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Mastery Level',
                          style: TextStyle(
                            color: Color(0xFF4E5567),
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          subject.accuracyLabel,
                          style: const TextStyle(
                            color: Color(0xFFD71920),
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        value: mastery / 100,
                        backgroundColor: const Color(0xFFECEEF2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFD71920),
                        ),
                      ),
                    ),
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

class _PerformanceDnaSkeleton extends StatelessWidget {
  const _PerformanceDnaSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 46, 10, 28),
      children: const [
        _PerformanceShimmerBox(height: 80, radius: 14),
        SizedBox(height: 28),
        Row(
          children: [
            _PerformanceShimmerBox(width: 12, height: 12, radius: 6),
            SizedBox(width: 7),
            _PerformanceShimmerBox(width: 128, height: 12, radius: 6),
          ],
        ),
        SizedBox(height: 14),
        _SubjectMasterySkeletonCard(),
        SizedBox(height: 20),
        _SubjectMasterySkeletonCard(),
        SizedBox(height: 20),
        _SubjectMasterySkeletonCard(),
      ],
    );
  }
}

class _SubjectMasterySkeletonCard extends StatelessWidget {
  const _SubjectMasterySkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 25,
          child: Center(
            child: _PerformanceShimmerBox(width: 13, height: 13, radius: 7),
          ),
        ),
        const SizedBox(width: 1),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE9EDF6)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _PerformanceShimmerBox(width: 20, height: 20, radius: 4),
                    SizedBox(width: 10),
                    Expanded(
                      child: _PerformanceShimmerBox(height: 14, radius: 7),
                    ),
                    SizedBox(width: 24),
                    _PerformanceShimmerBox(width: 64, height: 24, radius: 14),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    _PerformanceShimmerBox(width: 86, height: 10, radius: 5),
                    Spacer(),
                    _PerformanceShimmerBox(width: 42, height: 16, radius: 8),
                  ],
                ),
                SizedBox(height: 8),
                _PerformanceShimmerBox(height: 4, radius: 4),
              ],
            ),
          ),
        ),
      ],
    );
  }
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

class _SubjectIcon extends StatelessWidget {
  const _SubjectIcon({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(Icons.menu_book_rounded, color: accent, size: 14),
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
