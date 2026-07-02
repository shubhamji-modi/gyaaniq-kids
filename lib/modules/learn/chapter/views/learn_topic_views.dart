import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/service/learn_progress_refresh_service.dart';
import '../../exercise/views/lesson_qa_views.dart';
import '../controller/learn_chapter_controller.dart';
import 'learn_lesson_player_views.dart';
import 'learn_subject_views.dart';

class LearnTopicViews extends StatefulWidget {
  const LearnTopicViews({
    super.key,
    required this.subject,
    required this.chapter,
  });

  final LearnSubjectModel subject;
  final LearnChapterModel chapter;

  @override
  State<LearnTopicViews> createState() => _LearnTopicViewsState();
}

class _LearnTopicViewsState extends State<LearnTopicViews> {
  String? _startingLessonId;
  bool _isLoadingProgress = true;
  final Map<String, LearnLessonProgress> _progressByLessonId = {};
  late final Worker _refreshWorker;

  @override
  void initState() {
    super.initState();
    _refreshWorker = ever<int>(
      LearnProgressRefreshService.instance.refreshTick,
      (_) {
        if (mounted) {
          _loadTopicProgress();
        }
      },
    );
    _loadTopicProgress();
  }

  @override
  void dispose() {
    _refreshWorker.dispose();
    super.dispose();
  }

  Future<void> _loadTopicProgress() async {
    setState(() {
      _isLoadingProgress = true;
    });

    final responses = await Future.wait(
      widget.chapter.topics.map(
        (topic) =>
            LearnCatalogData.getLessonProgress(lessonId: topic.lesson.id),
      ),
    );

    if (!mounted) {
      return;
    }

    final nextProgressByLessonId = <String, LearnLessonProgress>{};
    for (final response in responses) {
      final progress = response.data;
      if (response.success && progress != null) {
        nextProgressByLessonId[progress.lessonId] = progress;
      }
    }

    setState(() {
      _isLoadingProgress = false;
      _progressByLessonId
        ..clear()
        ..addAll(nextProgressByLessonId);
    });
  }

  LearnTopicStatus _resolvedStatus(LearnTopicModel topic) {
    return _progressByLessonId[topic.lesson.id]?.status ?? topic.status;
  }

  double _resolvedProgress(LearnTopicModel topic) {
    return _progressByLessonId[topic.lesson.id]?.progressValue ??
        topic.progress;
  }

  double _chapterProgress(List<LearnTopicModel> topics) {
    if (topics.isEmpty) {
      return 0;
    }

    final completedTopics = topics
        .where((topic) => _resolvedStatus(topic) == LearnTopicStatus.completed)
        .length;
    return completedTopics / topics.length;
  }

  Future<void> _openTopic(LearnTopicModel topic) async {
    if (_startingLessonId != null) {
      return;
    }

    final currentStatus = _resolvedStatus(topic);
    if (currentStatus == LearnTopicStatus.completed) {
      await Get.to<bool>(
        () => LearnLessonPlayerViews(
          subject: widget.subject,
          chapter: widget.chapter,
          topic: topic,
          isCompleted: true,
        ),
      );
      return;
    }

    setState(() {
      _startingLessonId = topic.lesson.id;
    });

    final response = await LearnCatalogData.markLessonStarted(
      lessonId: topic.lesson.id,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _startingLessonId = null;
    });

    if (!response.success) {
      Get.snackbar(
        'Unable to start lesson',
        response.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFB42318),
        colorText: Colors.white,
        margin: const EdgeInsets.all(14),
      );
      return;
    }

    setState(() {
      _progressByLessonId[topic.lesson.id] = LearnLessonProgress(
        lessonId: topic.lesson.id,
        status: LearnTopicStatus.inProgress,
        startedAt: '',
        completedAt: '',
        lastAccessedAt: '',
      );
    });

    final shouldReload = await Get.to<bool>(
      () => LearnLessonPlayerViews(
        subject: widget.subject,
        chapter: widget.chapter,
        topic: topic,
        isCompleted: currentStatus == LearnTopicStatus.completed,
      ),
    );

    if (shouldReload == true && mounted) {
      await _loadTopicProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chapter = widget.chapter;
    final completedTopics = chapter.topics
        .where((topic) => _resolvedStatus(topic) == LearnTopicStatus.completed)
        .length;
    final chapterProgress = _chapterProgress(chapter.topics);
    final chapterProgressLabel = '${(chapterProgress * 100).round()}%';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        child: Column(
          children: [
            const LearnTopBar(title: 'Topic'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: const Color(0xFFC8C7F1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OVERALL PROGRESS',
                          style: TextStyle(
                            color: chapter.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '$chapterProgressLabel Completed',
                                style: const TextStyle(
                                  color: Color(0xFF1D2231),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFA61E),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                '${widget.subject.classLevel} ${widget.subject.title}',
                                style: TextStyle(
                                  color: Color(0xFF6E4500),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: _isLoadingProgress ? null : chapterProgress,
                            minHeight: 8,
                            backgroundColor: const Color(0xFFE4E7EE),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF4A4FD9),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "You're doing great! Keep going to unlock the final quiz.",
                          style: TextStyle(
                            color: Color(0xFF43485A),
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Topics in this Chapter',
                          style: TextStyle(
                            color: Color(0xFF1D2231),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '$completedTopics / ${chapter.topics.length} Lessons',
                        style: const TextStyle(
                          color: Color(0xFF4A4FD9),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ...chapter.topics.map(
                    (topic) => Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _TopicCard(
                        topic: topic,
                        accent: widget.subject.accent,
                        status: _resolvedStatus(topic),
                        progress: _resolvedProgress(topic),
                        isStarting: _startingLessonId == topic.lesson.id,
                        onTap: () => _openTopic(topic),
                        onExerciseTap: () => Get.to(
                          () => LessonQaViews(
                            lessonId: topic.lesson.id,
                            lessonTitle: topic.title,
                            accent: widget.subject.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.topic,
    required this.accent,
    required this.status,
    required this.progress,
    required this.isStarting,
    required this.onTap,
    required this.onExerciseTap,
  });

  final LearnTopicModel topic;
  final Color accent;
  final LearnTopicStatus status;
  final double progress;
  final bool isStarting;
  final VoidCallback onTap;
  final VoidCallback onExerciseTap;

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == LearnTopicStatus.completed;
    final isInProgress = status == LearnTopicStatus.inProgress;
    final isLocked = status == LearnTopicStatus.locked;

    const completedColor = Color(0xFF12B76A);
    const inProgressColor = Color(0xFFF97316);
    const inProgressBackground = Color(0xFFFFF3D6);
    const notStartedColor = Color(0xFF8C8F9C);

    return InkWell(
      onTap: isLocked || isStarting ? null : onTap,
      borderRadius: BorderRadius.circular(24),
      child: Opacity(
        opacity: isLocked ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isCompleted
                  ? completedColor
                  : isInProgress
                  ? inProgressColor
                  : const Color(0xFFD8DCE4),
              width: isInProgress ? 2.2 : 1,
            ),
            boxShadow: isInProgress
                ? [
                    BoxShadow(
                      color: inProgressColor.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      : const Color(0xFFF1F3F8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isLocked
                      ? Icons.lock_outline_rounded
                      : isCompleted
                      ? Icons.check_rounded
                      : isInProgress
                      ? Icons.play_arrow_rounded
                      : Icons.menu_book_rounded,
                  color: isLocked
                      ? const Color(0xFFA5A8B5)
                      : isCompleted
                      ? completedColor
                      : isInProgress
                      ? inProgressColor
                      : notStartedColor,
                  size: 23,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            topic.title,
                            style: TextStyle(
                              color: isLocked
                                  ? const Color(0xFF666A78)
                                  : const Color(0xFF1D2231),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          _topicStatusLabel(
                            status: status,
                            isStarting: isStarting,
                          ),
                          style: TextStyle(
                            color: isStarting
                                ? inProgressColor
                                : isCompleted
                                ? completedColor
                                : (isInProgress
                                      ? inProgressColor
                                      : notStartedColor),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (topic.hasVideo)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.videocam_outlined,
                              color: Color(0xFF8A8D9B),
                              size: 18,
                            ),
                          ),
                        if (topic.hasNotes)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.description_outlined,
                              color: Color(0xFF8A8D9B),
                              size: 18,
                            ),
                          ),
                        if (topic.hasWorksheet)
                          const Icon(
                            Icons.fact_check_outlined,
                            color: Color(0xFF8A8D9B),
                            size: 18,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: isStarting ? null : progress,
                        minHeight: 7,
                        backgroundColor: const Color(0xFFE4E7EE),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isLocked
                              ? const Color(0xFFD9DDE5)
                              : (isInProgress
                                    ? inProgressColor
                                    : isCompleted
                                    ? completedColor
                                    : const Color(0xFFD9DDE5)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ExerciseButton(accent: accent, onTap: onExerciseTap),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseButton extends StatelessWidget {
  const _ExerciseButton({required this.accent, required this.onTap});

  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_outlined, color: accent, size: 18),
              const SizedBox(width: 8),
              Text(
                'Exercise',
                style: TextStyle(
                  color: accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded, color: accent, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

String _topicStatusLabel({
  required LearnTopicStatus status,
  required bool isStarting,
}) {
  if (isStarting) {
    return 'Starting...';
  }

  switch (status) {
    case LearnTopicStatus.completed:
      return 'Completed';
    case LearnTopicStatus.inProgress:
      return 'In Progress';
    case LearnTopicStatus.notStarted:
      return 'Not Started';
    case LearnTopicStatus.locked:
      return 'Locked';
  }
}
