import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/appcolors.dart';
import '../../../core/widgets/math_html_text.dart';
import '../data/library_models.dart';
import '../data/library_repository.dart';
import 'library_widgets.dart';

/// Practice quiz of a Library lesson. No XP, not counted anywhere — the
/// server sends no answers until the attempt is submitted.
class LibraryQuizViews extends StatefulWidget {
  const LibraryQuizViews({
    super.key,
    required this.lessonId,
    this.lessonTitle = '',
  });

  final String lessonId;
  final String lessonTitle;

  @override
  State<LibraryQuizViews> createState() => _LibraryQuizViewsState();
}

class _LibraryQuizViewsState extends State<LibraryQuizViews> {
  LibraryQuiz? _quiz;
  bool _loading = true;
  String _error = '';
  bool _submitting = false;

  /// Question index → chosen option.
  final Map<int, int> _answers = {};
  LibraryQuizResult? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    final result = await LibraryRepository.fetchQuiz(widget.lessonId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.ok && result.data != null) {
        _quiz = result.data;
      } else {
        _error = result.displayMessage;
      }
    });
  }

  Future<void> _submit() async {
    final quiz = _quiz;
    if (quiz == null || _submitting) return;
    final unanswered = quiz.questions.length - _answers.length;
    if (unanswered > 0) {
      final ok = await Get.dialog<bool>(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Submit now?',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          content: Text(
            '$unanswered question${unanswered == 1 ? ' is' : 's are'} not '
            'answered yet and will count as wrong.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Keep going'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text(
                'Submit',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    setState(() => _submitting = true);
    final result = await LibraryRepository.submitQuiz(
      lessonId: widget.lessonId,
      answers: {for (final q in quiz.questions) q.index: _answers[q.index]},
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result.ok && result.data != null) {
      setState(() => _result = result.data);
    } else {
      showLibrarySnack(result.displayMessage, isError: true);
    }
  }

  void _retry() {
    setState(() {
      _answers.clear();
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final quiz = _quiz;
    return Scaffold(
      backgroundColor: LibraryPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            LibraryTopBar(
              title: widget.lessonTitle.isEmpty
                  ? 'Practice quiz'
                  : 'Quiz · ${widget.lessonTitle}',
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : quiz == null
                  ? LibraryMessageView(
                      icon: Icons.quiz_outlined,
                      title: 'Unable to open the quiz',
                      message: _error,
                      actionLabel: 'Retry',
                      onAction: _load,
                    )
                  : quiz.questions.isEmpty
                  ? const LibraryMessageView(
                      icon: Icons.quiz_outlined,
                      title: 'No questions yet',
                      message: 'This quiz has no questions right now.',
                    )
                  : _body(quiz),
            ),
            if (quiz != null && quiz.questions.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE7EAF4))),
                ),
                child: _result == null
                    ? LibraryPrimaryButton(
                        label:
                            'Submit (${_answers.length}/${quiz.questions.length} answered)',
                        expand: true,
                        busy: _submitting,
                        onPressed: _submit,
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: LibrarySecondaryButton(
                              label: 'Done',
                              expand: true,
                              onPressed: Get.back,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: LibraryPrimaryButton(
                              label: 'Try again',
                              icon: Icons.refresh_rounded,
                              expand: true,
                              onPressed: _retry,
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

  Widget _body(LibraryQuiz quiz) {
    final result = _result;
    final byIndex = {for (final r in result?.results ?? const []) r.index: r};
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (result != null)
          _ScoreCard(result: result)
        else
          _IntroCard(quiz: quiz),
        const SizedBox(height: 14),
        for (var i = 0; i < quiz.questions.length; i++)
          _QuestionCard(
            number: i + 1,
            question: quiz.questions[i],
            selected: result != null
                ? byIndex[quiz.questions[i].index]?.selectedIndex
                : _answers[quiz.questions[i].index],
            review: byIndex[quiz.questions[i].index],
            showReview: result != null,
            onSelect: result != null
                ? null
                : (option) => setState(
                    () => _answers[quiz.questions[i].index] = option,
                  ),
          ),
      ],
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.quiz});

  final LibraryQuiz quiz;

  @override
  Widget build(BuildContext context) {
    final last = quiz.lastAttempt;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LibraryPalette.purpleSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (quiz.description.isNotEmpty) ...[
            MathHtmlText(
              quiz.description,
              textStyle: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            '${quiz.questions.length} questions'
            '${quiz.totalMarks > 0 ? ' · ${_fmt(quiz.totalMarks)} marks' : ''}'
            ' · practice only, no XP',
            style: const TextStyle(
              color: LibraryPalette.purple,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (last != null) ...[
            const SizedBox(height: 6),
            Text(
              'Last time: ${last.correct}/${last.total} (${last.percentage.round()}%)',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.result});

  final LibraryQuizResult result;

  @override
  Widget build(BuildContext context) {
    final a = result.attempt;
    final good = a.percentage >= 60;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: good ? LibraryPalette.greenSoft : LibraryPalette.amberSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${a.percentage.round()}%',
              style: TextStyle(
                color: good ? LibraryPalette.green : LibraryPalette.amber,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  good ? 'Well done!' : 'Keep practising!',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${a.correct} of ${a.total} correct · '
                  'score ${_fmt(a.score)}/${_fmt(a.maxScore)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
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

String _fmt(double v) =>
    v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.number,
    required this.question,
    required this.selected,
    required this.review,
    required this.showReview,
    required this.onSelect,
  });

  final int number;
  final LibraryQuizQuestion question;
  final int? selected;
  final LibraryQuizResultItem? review;
  final bool showReview;
  final ValueChanged<int>? onSelect;

  @override
  Widget build(BuildContext context) {
    final correctIndex = review?.correctIndex;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: !showReview
              ? LibraryPalette.border
              : (review?.isCorrect ?? false)
              ? LibraryPalette.green.withValues(alpha: 0.5)
              : LibraryPalette.red.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Q$number',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              if (showReview)
                Text(
                  (review?.isCorrect ?? false)
                      ? 'Correct'
                      : selected == null
                      ? 'Not answered'
                      : 'Wrong',
                  style: TextStyle(
                    color: (review?.isCorrect ?? false)
                        ? LibraryPalette.green
                        : LibraryPalette.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          MathHtmlText(
            question.questionText,
            textStyle: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          for (var o = 0; o < question.options.length; o++)
            _OptionTile(
              letter: String.fromCharCode(65 + o),
              html: question.options[o],
              selected: selected == o,
              correct: showReview && correctIndex == o,
              wrong: showReview && selected == o && correctIndex != o,
              onTap: onSelect == null ? null : () => onSelect!(o),
            ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.letter,
    required this.html,
    required this.selected,
    required this.correct,
    required this.wrong,
    required this.onTap,
  });

  final String letter;
  final String html;
  final bool selected;
  final bool correct;
  final bool wrong;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color border;
    final Color bg;
    if (correct) {
      border = LibraryPalette.green;
      bg = LibraryPalette.greenSoft;
    } else if (wrong) {
      border = LibraryPalette.red;
      bg = LibraryPalette.redSoft;
    } else if (selected) {
      border = AppColors.primary;
      bg = AppColors.primaryPale;
    } else {
      border = LibraryPalette.border;
      bg = Colors.white;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: border,
                width: selected || correct ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected || correct
                        ? border
                        : LibraryPalette.greySoft,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    letter,
                    style: TextStyle(
                      color: selected || correct
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MathHtmlText(
                    html,
                    textStyle: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
                if (correct)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: LibraryPalette.green,
                    size: 20,
                  )
                else if (wrong)
                  const Icon(
                    Icons.cancel_rounded,
                    color: LibraryPalette.red,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
