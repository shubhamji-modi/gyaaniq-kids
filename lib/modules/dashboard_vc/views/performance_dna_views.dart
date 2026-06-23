import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/appcolors.dart';
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
            return const Center(child: CircularProgressIndicator());
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
