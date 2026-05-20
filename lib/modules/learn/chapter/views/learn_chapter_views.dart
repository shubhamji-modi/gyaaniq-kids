import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/learn_chapter_controller.dart';
import 'learn_subject_views.dart';
import 'learn_topic_views.dart';

class LearnChapterViews extends StatelessWidget {
  const LearnChapterViews({super.key, required this.subject});

  final LearnSubjectModel subject;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        child: Column(
          children: [
            const LearnTopBar(title: 'Chapters'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
                children: [
                  Text(
                    'CURRENT SUBJECT',
                    style: TextStyle(
                      color: subject.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subject.title,
                    style: const TextStyle(
                      color: Color(0xFF1D2231),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subject.chapters.firstWhereOrNull(
                          (chapter) =>
                              chapter.status == LearnChapterStatus.inProgress,
                        )?.summary ??
                        subject.subtitle,
                    style: const TextStyle(
                      color: Color(0xFF373B4B),
                      fontSize: 13,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...subject.chapters.map(
                    (chapter) => Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _ChapterCard(subject: subject, chapter: chapter),
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

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({required this.subject, required this.chapter});

  final LearnSubjectModel subject;
  final LearnChapterModel chapter;

  @override
  Widget build(BuildContext context) {
    final isCompleted = chapter.status == LearnChapterStatus.completed;
    final isInProgress = chapter.status == LearnChapterStatus.inProgress;
    final isLocked = chapter.status == LearnChapterStatus.locked;

    return InkWell(
      onTap: isLocked
          ? null
          : () => Get.to(
                () => LearnTopicViews(subject: subject, chapter: chapter),
              ),
      borderRadius: BorderRadius.circular(28),
      child: Opacity(
        opacity: isLocked ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isInProgress
                  ? const Color(0xFF4A4FD9)
                  : const Color(0xFFC8C7F1),
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
                          : (isInProgress
                              ? const Color(0xFFDCD9FF)
                              : const Color(0xFFFFE8C8)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isLocked
                          ? Icons.lock_outline_rounded
                          : (isCompleted
                              ? Icons.check_circle_rounded
                              : Icons.more_horiz_rounded),
                      color: isLocked
                          ? const Color(0xFFA1A4B3)
                          : (isCompleted
                              ? const Color(0xFFA46A00)
                              : const Color(0xFF4A4FD9)),
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  _ChapterBadge(chapter: chapter),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Chapter ${chapter.chapterNumber}',
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
              const SizedBox(height: 15),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: chapter.progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE5E8EF),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted
                        ? const Color(0xFFA46A00)
                        : (isInProgress
                            ? const Color(0xFF4A4FD9)
                            : const Color(0xFFD8DCE4)),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isLocked ? chapter.summary : chapter.lessonQuizMeta,
                      style: TextStyle(
                        color: isLocked
                            ? const Color(0xFF707486)
                            : const Color(0xFF44485C),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (isCompleted)
                    const Text(
                      'Review ->',
                      style: TextStyle(
                        color: Color(0xFF4A4FD9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (isInProgress)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A4FD9),
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
                    ),
                  if (isLocked)
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: Color(0xFFBCBED0),
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

    final background = isCompleted
        ? const Color(0xFFFFA61E)
        : isInProgress
            ? const Color(0xFF6368F2)
            : const Color(0xFFE7EAEE);

    final label = isCompleted
        ? 'Completed'
        : isInProgress
            ? '${chapter.progressPercentage} Progress'
            : 'Locked';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isCompleted || isInProgress
              ? Colors.white
              : const Color(0xFF8A8D9B),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

extension IterableX<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
