import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../learn/chapter/controller/learn_chapter_controller.dart';
import '../../../learn/chapter/views/learn_subject_views.dart';
import '../../../learn/common/subject_visual.dart';
import 'quiz_practice_paper_topic_views.dart';

class QuizPracticePaperSubjectViews extends StatefulWidget {
  const QuizPracticePaperSubjectViews({super.key});

  @override
  State<QuizPracticePaperSubjectViews> createState() =>
      _QuizPracticePaperSubjectViewsState();
}

class _QuizPracticePaperSubjectViewsState
    extends State<QuizPracticePaperSubjectViews> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<LearnSubjectModel> _subjects = const [];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final response = await LearnCatalogData.getUserSubjects();

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _subjects = response.data ?? const [];
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
                onRefresh: _loadSubjects,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  children: [
                    const Text(
                      'Select Subject',
                      style: TextStyle(
                        color: Color(0xFF1D2231),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Choose your daily challenge. Each subject helps you level up!',
                      style: TextStyle(
                        color: Color(0xFF4D4F61),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_errorMessage.isNotEmpty)
                      _PracticeStateCard(
                        title: 'Unable to load subjects',
                        message: _errorMessage,
                        onRetry: _loadSubjects,
                      )
                    else if (_subjects.isEmpty)
                      const _PracticeStateCard(
                        title: 'No subjects available',
                        message:
                            'Your class subjects are not available right now.',
                      )
                    else
                      ..._subjects.map(
                        (subject) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _PracticeSubjectCard(subject: subject),
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

class _PracticeStateCard extends StatelessWidget {
  const _PracticeStateCard({
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

class _PracticeSubjectCard extends StatelessWidget {
  const _PracticeSubjectCard({required this.subject});

  final LearnSubjectModel subject;

  @override
  Widget build(BuildContext context) {
    final description = subject.description.isNotEmpty
        ? subject.description
        : subject.subtitle;
    // Name-based icon + colour so each subject is themed consistently across
    // the app (fixes the previous mismatched index-based icons/colours).
    final visual = subjectVisualFor(subject.title);

    return InkWell(
      onTap: () => Get.to(() => QuizPracticePaperTopicViews(subject: subject)),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: visual.softBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: visual.color.withValues(alpha: 0.18)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject icon tile.
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: visual.color,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: visual.color.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(visual.icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          subject.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF1D2231),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (subject.classLevel.trim().isNotEmpty &&
                          subject.classLevel.trim() != '-') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: visual.color.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            subject.classLevel.toUpperCase(),
                            style: TextStyle(
                              color: visual.color,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description.isEmpty
                        ? 'No description available yet.'
                        : description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6B7183),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
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
