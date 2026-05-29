import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../learn/chapter/controller/learn_chapter_controller.dart';
import '../../../learn/chapter/views/learn_subject_views.dart';
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

    return InkWell(
      onTap: () => Get.to(() => QuizPracticePaperTopicViews(subject: subject)),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE2E5F2)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD9DFF0).withValues(alpha: 0.75),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: subject.iconBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(subject.icon, color: subject.accent, size: 26),
            ),
            const SizedBox(height: 15),
            Text(
              subject.title,
              style: const TextStyle(
                color: Color(0xFF1D2231),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: subject.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                subject.classLevel,
                style: TextStyle(
                  color: subject.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              description.isEmpty
                  ? 'No description available for this subject yet.'
                  : description,
              style: const TextStyle(
                color: Color(0xFF4D4F61),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
