import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../learn/chapter/controller/learn_chapter_controller.dart';
import '../../../learn/chapter/views/learn_subject_views.dart';
import '../controller/quiz_practice_paper_topic_controller.dart';

class QuizPracticePaperTopicViews extends StatefulWidget {
  const QuizPracticePaperTopicViews({
    super.key,
    required this.subject,
  });

  final LearnSubjectModel subject;

  @override
  State<QuizPracticePaperTopicViews> createState() =>
      _QuizPracticePaperTopicViewsState();
}

class _QuizPracticePaperTopicViewsState
    extends State<QuizPracticePaperTopicViews> {
  late final QuizPracticePaperTopicController controller;
  bool _isLoading = true;
  String _errorMessage = '';
  List<LearnChapterModel> _lessons = const [];

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<QuizPracticePaperTopicController>()
        ? Get.find<QuizPracticePaperTopicController>()
        : Get.put(QuizPracticePaperTopicController());
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final response = await LearnCatalogData.getUserLessons(
      subject: widget.subject,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _lessons = response.data ?? const [];
      _errorMessage = response.success ? '' : response.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        child: Column(
          children: [
            const LearnTopBar(title: 'Practice Quiz'),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadLessons,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                  children: [
                    Text(
                      '${widget.subject.title} Lessons',
                      style: const TextStyle(
                        color: Color(0xFF1D2231),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Pick a lesson to start your practice quiz.',
                      style: TextStyle(
                        color: Color(0xFF4D4F61),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_errorMessage.isNotEmpty)
                      _PracticeLessonStateCard(
                        title: 'Unable to load lessons',
                        message: _errorMessage,
                        onRetry: _loadLessons,
                      )
                    else if (_lessons.isEmpty)
                      const _PracticeLessonStateCard(
                        title: 'No lessons available',
                        message:
                            'This subject does not have any lessons yet.',
                      )
                    else
                      ..._lessons.map(
                        (lesson) => Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: _PracticeLessonCard(
                            subject: widget.subject,
                            chapter: lesson,
                            onPracticeNow: () => controller.startPractice(
                              subject: widget.subject,
                              chapter: lesson,
                            ),
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

class _PracticeLessonStateCard extends StatelessWidget {
  const _PracticeLessonStateCard({
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E5F2)),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1D2231),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF4D4F61),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.6,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A4FD9),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

class _PracticeLessonCard extends StatelessWidget {
  const _PracticeLessonCard({
    required this.subject,
    required this.chapter,
    required this.onPracticeNow,
  });

  final LearnSubjectModel subject;
  final LearnChapterModel chapter;
  final VoidCallback onPracticeNow;

  @override
  Widget build(BuildContext context) {
    final lesson = chapter.topics.isNotEmpty ? chapter.topics.first.lesson : null;
    final hasVideo = lesson?.videoUrl.isNotEmpty == true;
    final hasPdf = lesson?.pdfUrl.isNotEmpty == true;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E5F2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD9DFF0).withValues(alpha: 0.78),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: subject.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'Lesson ${chapter.chapterNumber}',
                  style: TextStyle(
                    color: subject.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: subject.iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(subject.icon, color: subject.accent, size: 23),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            chapter.title,
            style: const TextStyle(
              color: Color(0xFF1D2231),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            chapter.summary.isEmpty
                ? 'Lesson description will be available soon.'
                : chapter.summary,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF4D4F61),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _LessonMetaChip(
                label: widgetLabel(subject.classLevel),
                background: subject.accent.withValues(alpha: 0.12),
                foreground: subject.accent,
              ),
              if (hasVideo)
                const _LessonMetaChip(
                  label: 'Video',
                  background: Color(0xFFE8ECFF),
                  foreground: Color(0xFF4A4FD9),
                ),
              if (hasPdf)
                const _LessonMetaChip(
                  label: 'PDF',
                  background: Color(0xFFFFE2DD),
                  foreground: Color(0xFFD6332B),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPracticeNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A4FD9),
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size.fromHeight(45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              iconAlignment: IconAlignment.end,
              icon: const Icon(
                Icons.play_circle_outline_rounded,
                size: 21,
              ),
              label: const Text('Practice Now'),
            ),
          ),
        ],
      ),
    );
  }

  String widgetLabel(String classLevel) => classLevel.trim().isEmpty
      ? 'Class'
      : classLevel;
}

class _LessonMetaChip extends StatelessWidget {
  const _LessonMetaChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
