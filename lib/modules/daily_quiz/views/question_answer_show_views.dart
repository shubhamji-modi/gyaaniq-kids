import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/question_answer_show_controller.dart';

class QuestionAnswerShowViews extends StatefulWidget {
  const QuestionAnswerShowViews({super.key});

  @override
  State<QuestionAnswerShowViews> createState() =>
      _QuestionAnswerShowViewsState();
}

class _QuestionAnswerShowViewsState extends State<QuestionAnswerShowViews> {
  late final QuestionAnswerShowController controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    controller = Get.find<QuestionAnswerShowController>();

    if (!controller.isReviewMode.value) {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        controller.incrementTimer();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FC),
      body: SafeArea(
        child: Column(
          children: [
            const _QuestionTopBar(),
            Expanded(
              child: Obx(() {
                final question = controller.currentQuestion;
                final questionNumber =
                    controller.currentQuestionIndex.value + 1;
                final isReview = controller.isReviewMode.value;

                return Column(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragEnd: (details) {
                          final velocity = details.primaryVelocity ?? 0;
                          if (velocity < -150) {
                            controller.nextQuestion();
                          } else if (velocity > 150) {
                            controller.previousQuestion();
                          }
                        },
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, animation) =>
                              SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.15, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                          child: SingleChildScrollView(
                            key: ValueKey<int>(
                              controller.currentQuestionIndex.value,
                            ),
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ---- Progress header (attempt mode) ----
                                if (!isReview) ...[
                                  const Text(
                                    'QUIZ PROGRESS',
                                    style: TextStyle(
                                      color: Color(0xFF9AA0B4),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            99,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: controller.answeredProgress,
                                            minHeight: 7,
                                            backgroundColor: const Color(
                                              0xFFE0E4EB,
                                            ),
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                  Color
                                                >(Color(0xFF4D4FE1)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Text(
                                        'Q.$questionNumber of ${controller.totalQuestions}',
                                        style: const TextStyle(
                                          color: Color(0xFF1E2230),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      _InfoPill(
                                        label: controller.progressLabel,
                                        background: const Color(0xFFE4E2FF),
                                        foreground: const Color(0xFF4D4FE1),
                                      ),
                                      const Spacer(),
                                      _InfoPill(
                                        label:
                                            'Time ${controller.formattedElapsedTime}',
                                        icon: Icons.timer_outlined,
                                        background: const Color(0xFFF3E8CE),
                                        foreground: const Color(0xFF98773A),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                ],
                                // ---- Review-mode banner ----
                                if (isReview) ...[
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: _InfoPill(
                                      label: 'Review Mode',
                                      icon: Icons.visibility_outlined,
                                      background: const Color(0xFFEDE7FF),
                                      foreground: const Color(0xFF6B39D6),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                // ---- Question card ----
                                _QuestionCard(
                                  questionNumber: questionNumber,
                                  question: question,
                                ),
                                const SizedBox(height: 18),
                                // ---- Options ----
                                ...List.generate(question.options.length, (
                                  index,
                                ) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: _OptionTile(optionIndex: index),
                                  );
                                }),
                                if (isReview)
                                  _ExplanationSection(question: question),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    isReview
                        ? _ReviewNavBar(controller: controller)
                        : _BottomActionBar(controller: controller),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Confirms then submits the quiz. Shared by the top-bar Submit button.
Future<void> _confirmAndSubmit(QuestionAnswerShowController controller) async {
  final shouldSubmit = await Get.dialog<bool>(
    _SubmitQuizDialog(
      totalQuestions: controller.totalQuestions,
      attemptedQuestions: controller.answeredCount,
    ),
    barrierDismissible: true,
  );
  if (shouldSubmit == true) {
    await controller.submitQuiz();
  }
}

class _QuestionTopBar extends StatelessWidget {
  const _QuestionTopBar();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuestionAnswerShowController>();

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 8, 12, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4E7F0))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF113A90),
              size: 20,
            ),
          ),
          Expanded(
            child: Obx(
              () => Text(
                controller.quizTitle.value.isEmpty
                    ? 'Quiz'
                    : controller.quizTitle.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF123887),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Obx(() {
            if (controller.isReviewMode.value) {
              return const SizedBox.shrink();
            }
            final submitting = controller.isSubmittingQuiz.value;
            final enabled = controller.totalQuestions > 0 && !submitting;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: enabled ? () => _confirmAndSubmit(controller) : null,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: enabled
                        ? const Color(0xFF4D4FE1)
                        : const Color(0xFFC9CCDE),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (submitting)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      const SizedBox(width: 6),
                      Text(
                        submitting ? 'Submitting' : 'Submit',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Small rounded status pill ("9% Done", "Time 00:01", "Review Mode").
class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: foreground, size: 15),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.questionNumber, required this.question});

  final int questionNumber;
  final QuizQuestion question;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E4F5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDCE2F3).withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: const Color(0xFF4D4FE1)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Q.$questionNumber ${question.question}',
                      style: const TextStyle(
                        color: Color(0xFF202436),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.6,
                      ),
                    ),
                    if (question.questionImageUrl.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          question.questionImageUrl,
                          fit: BoxFit.cover,
                          height: 180,
                          width: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 180,
                              color: const Color(0xFFF0F1F5),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF4A4FD9),
                                  ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 180,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F1F5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    if (question.tags.isNotEmpty) ...[
                      const SizedBox(height: 15),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: question.tags
                            .map((tag) => _QuestionTagChip(tag: tag))
                            .toList(),
                      ),
                    ],
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

/// Colours a question tag by its meaning: difficulty (easy/medium/hard),
/// marks, or a neutral chip for subject names.
class _QuestionTagChip extends StatelessWidget {
  const _QuestionTagChip({required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    final t = tag.trim().toLowerCase();
    Color background = const Color(0xFFEFF0F4);
    Color foreground = const Color(0xFF505165);

    if (t == 'easy') {
      background = const Color(0xFFE7F8EF);
      foreground = const Color(0xFF1E9E5A);
    } else if (t == 'medium' || t == 'moderate') {
      background = const Color(0xFFFFF1DC);
      foreground = const Color(0xFFC9820E);
    } else if (t == 'hard' || t == 'difficult') {
      background = const Color(0xFFFDE7E7);
      foreground = const Color(0xFFD64545);
    } else if (t.contains('mark')) {
      background = const Color(0xFFE6EEFF);
      foreground = const Color(0xFF2E6BE6);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        tag,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OptionTile extends GetView<QuestionAnswerShowController> {
  const _OptionTile({required this.optionIndex});

  final int optionIndex;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final question = controller.currentQuestion;
      final selectedIndex =
          controller.selectedAnswers[controller.currentQuestionIndex.value];
      final isSelected = selectedIndex == optionIndex;
      final isCorrect = question.correctOptionIndex == optionIndex;
      final showReviewColors =
          controller.isReviewMode.value && controller.hasAnswerKey;

      Color borderColor = const Color(0xFFE6E4F5);
      Color fillColor = Colors.white;
      Color bubbleColor = const Color(0xFFEAEFFF);
      Color bubbleTextColor = const Color(0xFF5B6472);

      if (isSelected) {
        borderColor = const Color(0xFF4D4FE1);
        fillColor = const Color(0xFFEEEDFF);
        bubbleColor = const Color(0xFF4D4FE1);
        bubbleTextColor = Colors.white;
      }

      if (showReviewColors && isCorrect) {
        borderColor = const Color(0xFF22A45D);
        fillColor = const Color(0xFFE7F8EF);
        bubbleColor = const Color(0xFF22A45D);
        bubbleTextColor = Colors.white;
      } else if (showReviewColors && isSelected && !isCorrect) {
        borderColor = const Color(0xFFE45656);
        fillColor = const Color(0xFFFDEAEA);
        bubbleColor = const Color(0xFFE45656);
        bubbleTextColor = Colors.white;
      }

      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => controller.selectAnswer(optionIndex),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2 : 1.3,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      String.fromCharCode(65 + optionIndex),
                      style: TextStyle(
                        color: bubbleTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      question.options[optionIndex],
                      style: const TextStyle(
                        color: Color(0xFF202436),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              if (optionIndex < question.optionImageUrls.length &&
                  question.optionImageUrls[optionIndex].isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    question.optionImageUrls[optionIndex],
                    fit: BoxFit.cover,
                    height: 140,
                    width: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F1F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F1F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}

class _ExplanationSection extends GetView<QuestionAnswerShowController> {
  const _ExplanationSection({required this.question});

  final QuizQuestion question;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final explanation = controller.explanationByQuestionId[question.id];
      final isLoading =
          controller.explanationLoadingByQuestionId[question.id] == true;
      final errorMessage =
          controller.explanationErrorByQuestionId[question.id] ?? '';

      return Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (explanation != null)
              _ExplanationCard(text: explanation.explanation)
            else if (isLoading)
              const _ExplanationLoadingCard()
            else if (errorMessage.isNotEmpty)
              _ExplanationErrorCard(message: errorMessage),
            if (explanation == null) ...[
              if (isLoading || errorMessage.isNotEmpty)
                const SizedBox(height: 14),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () => controller.fetchExplanation(question),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    disabledBackgroundColor: const Color(0xFFFFA184),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.lightbulb_outline_rounded, size: 21),
                  label: Text(
                    isLoading ? 'Preparing explanation...' : 'View Explanation',
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD3E6FF), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: Color(0xFF1565C0),
                size: 22,
              ),
              SizedBox(width: 10),
              Text(
                'EXPLANATION',
                style: TextStyle(
                  color: Color(0xFF1565C0),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF5A5D6B),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExplanationLoadingCard extends StatelessWidget {
  const _ExplanationLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD3E6FF), width: 1.4),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Preparing explanation...',
              style: TextStyle(
                color: Color(0xFF1565C0),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExplanationErrorCard extends StatelessWidget {
  const _ExplanationErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB8AC)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFB42318),
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.controller});

  final QuestionAnswerShowController controller;

  void _openNavigator() {
    Get.bottomSheet<void>(
      _QuestionNavigatorSheet(controller: controller),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4E7F0))),
      ),
      child: SafeArea(
        top: false,
        child: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _QuizActionButton(
                      label: 'Clear',
                      icon: Icons.delete_outline_rounded,
                      onTap:
                          controller.currentQuestionHasAnswer &&
                              !controller.isReviewMode.value
                          ? controller.clearCurrentAnswer
                          : null,
                      foregroundColor: const Color(0xFF5B5F72),
                      backgroundColor: const Color(0xFFEDECFB),
                      disabledBackgroundColor: const Color(0xFFEDECFB),
                      disabledForegroundColor: const Color(0xFFA7ABBC),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuizActionButton(
                      label: 'Question',
                      icon: Icons.grid_view_rounded,
                      onTap: _openNavigator,
                      foregroundColor: const Color(0xFF6B7183),
                      backgroundColor: Colors.white,
                      borderColor: const Color(0xFFD9DCEA),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuizActionButton(
                      label: 'Skip',
                      icon: Icons.keyboard_double_arrow_right_rounded,
                      onTap:
                          controller.hasNextQuestion &&
                              !controller.isReviewMode.value
                          ? controller.skipCurrentQuestion
                          : null,
                      foregroundColor: const Color(0xFF5B5F72),
                      backgroundColor: const Color(0xFFEDECFB),
                      disabledBackgroundColor: const Color(0xFFEDECFB),
                      disabledForegroundColor: const Color(0xFFA7ABBC),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuizActionButton(
                      label: controller.hasNextQuestion ? 'Next' : 'Save',
                      icon: controller.hasNextQuestion
                          ? Icons.arrow_forward_rounded
                          : Icons.done_rounded,
                      iconAfterLabel: true,
                      onTap: controller.isReviewMode.value
                          ? null
                          : controller.saveAndNextQuestion,
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF4D4FE1),
                      disabledBackgroundColor: const Color(0xFFC9CCDE),
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

/// Review-mode bottom bar: lets the user step through questions directly with
/// Previous / Next, plus a tappable counter that opens the question grid.
class _ReviewNavBar extends StatelessWidget {
  const _ReviewNavBar({required this.controller});

  final QuestionAnswerShowController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4E7F0))),
      ),
      child: SafeArea(
        top: false,
        child: Obx(() {
          final canPrev = controller.hasPreviousQuestion;
          final canNext = controller.hasNextQuestion;
          return Row(
            children: [
              Expanded(
                child: _QuizActionButton(
                  label: 'Previous',
                  icon: Icons.arrow_back_rounded,
                  onTap: canPrev ? controller.previousQuestion : null,
                  foregroundColor: const Color(0xFF0865B7),
                  backgroundColor: const Color(0xFFE9F4FF),
                  disabledBackgroundColor: const Color(0xFFEFF1F5),
                  disabledForegroundColor: const Color(0xFFB0B5C0),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () => Get.bottomSheet<void>(
                  _QuestionNavigatorSheet(controller: controller),
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  barrierColor: Colors.black.withValues(alpha: 0.55),
                ),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF1F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.grid_view_rounded,
                        size: 15,
                        color: Color(0xFF4D4D60),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        '${controller.currentQuestionIndex.value + 1}/${controller.totalQuestions}',
                        style: const TextStyle(
                          color: Color(0xFF1E2230),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuizActionButton(
                  label: 'Next',
                  icon: Icons.arrow_forward_rounded,
                  iconAfterLabel: true,
                  onTap: canNext ? controller.nextQuestion : null,
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF0865B7),
                  disabledBackgroundColor: const Color(0xFFC9CCDE),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _QuizActionButton extends StatelessWidget {
  const _QuizActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.foregroundColor,
    required this.backgroundColor,
    this.disabledForegroundColor,
    this.disabledBackgroundColor,
    this.borderColor,
    this.iconAfterLabel = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color? disabledForegroundColor;
  final Color? disabledBackgroundColor;
  final Color? borderColor;
  final bool iconAfterLabel;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final effectiveForeground = isEnabled
        ? foregroundColor
        : (disabledForegroundColor ?? Colors.white);
    final effectiveBackground = isEnabled
        ? backgroundColor
        : (disabledBackgroundColor ?? const Color(0xFFC9CCDE));

    final iconWidget = Icon(icon, size: 18, color: effectiveForeground);

    final labelWidget = Flexible(
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: effectiveForeground,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: effectiveBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEnabled
                  ? (borderColor ?? effectiveBackground)
                  : Colors.transparent,
              width: borderColor == null ? 1 : 1.6,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: iconAfterLabel
                ? [labelWidget, const SizedBox(width: 10), iconWidget]
                : [iconWidget, const SizedBox(width: 10), labelWidget],
          ),
        ),
      ),
    );
  }
}

class _QuestionNavigatorSheet extends StatelessWidget {
  const _QuestionNavigatorSheet({required this.controller});

  final QuestionAnswerShowController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1E4EA),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Question Navigator',
                style: TextStyle(
                  color: Color(0xFF1D2433),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(controller.totalQuestions, (index) {
                  final isCurrent =
                      index == controller.currentQuestionIndex.value;
                  final isReview = controller.isReviewMode.value;
                  final selected = controller.selectedAnswers[index];
                  final isAnswered = selected != null;
                  final isMarked = controller.markedQuestions[index];
                  final isVisited = controller.visitedQuestions[index];
                  final correctIndex =
                      controller.questions[index].correctOptionIndex;
                  final isCorrect =
                      isAnswered &&
                      correctIndex != null &&
                      selected == correctIndex;

                  return _QuestionNumberButton(
                    number: index + 1,
                    isCurrent: isCurrent,
                    isReview: isReview,
                    isAnswered: isAnswered,
                    isCorrect: isCorrect,
                    isMarked: isMarked,
                    isVisited: isVisited,
                    onTap: () {
                      controller.goToQuestion(index);
                      Get.back<void>();
                    },
                  );
                }),
              ),
              const SizedBox(height: 28),
              if (controller.isReviewMode.value)
                const Wrap(
                  spacing: 22,
                  runSpacing: 12,
                  children: [
                    _NavigatorLegendDot(
                      label: 'Correct',
                      color: Color(0xFF0B8A3A),
                    ),
                    _NavigatorLegendDot(
                      label: 'Wrong',
                      color: Color(0xFFD92D20),
                    ),
                    _NavigatorLegendDot(
                      label: 'Not Visited',
                      color: Color(0xFFE9EDF3),
                    ),
                  ],
                )
              else
                const Wrap(
                  spacing: 22,
                  runSpacing: 12,
                  children: [
                    _NavigatorLegendDot(
                      label: 'Answered',
                      color: Color(0xFF0B8A3A),
                    ),
                    _NavigatorLegendDot(
                      label: 'Not Visited',
                      color: Color(0xFFE9EDF3),
                    ),
                    _NavigatorLegendDot(
                      label: 'Marked',
                      color: Color(0xFFC45A12),
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

class _QuestionNumberButton extends StatelessWidget {
  const _QuestionNumberButton({
    required this.number,
    required this.isCurrent,
    required this.isReview,
    required this.isAnswered,
    required this.isCorrect,
    required this.isMarked,
    required this.isVisited,
    required this.onTap,
  });

  final int number;
  final bool isCurrent;
  final bool isReview;
  final bool isAnswered;
  final bool isCorrect;
  final bool isMarked;
  final bool isVisited;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor;
    if (isReview) {
      backgroundColor = !isAnswered
          ? const Color(0xFFE9EDF3)
          : isCorrect
          ? const Color(0xFF0B8A3A)
          : const Color(0xFFD92D20);
    } else {
      backgroundColor = isCurrent
          ? const Color(0xFF0865B7)
          : isMarked
          ? const Color(0xFFC45A12)
          : isAnswered
          ? const Color(0xFF0B8A3A)
          : const Color(0xFFE9EDF3);
    }

    final bool isFilled = isReview
        ? isAnswered
        : (isCurrent || isMarked || isAnswered);
    final textColor = isFilled ? Colors.white : const Color(0xFF667085);

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 45,
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: isCurrent
                ? const Color(0xFF0865B7)
                : (isVisited ? backgroundColor : const Color(0xFFE1E5EC)),
            width: isCurrent ? 2.0 : 1.5,
          ),
        ),
        child: Text(
          '$number',
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _NavigatorLegendDot extends StatelessWidget {
  const _NavigatorLegendDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF697181),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SubmitQuizDialog extends StatelessWidget {
  const _SubmitQuizDialog({
    required this.totalQuestions,
    required this.attemptedQuestions,
  });

  final int totalQuestions;
  final int attemptedQuestions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 430),
        padding: const EdgeInsets.fromLTRB(26, 28, 26, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 32,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Submit Quiz?',
              style: TextStyle(
                color: Color(0xFF111421),
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Are you sure you want to submit your quiz? You cannot change your answers after submission.',
              style: TextStyle(
                color: Color(0xFF777D8D),
                fontSize: 18,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _SubmitQuizStatCard(
                    label: 'Total Questions',
                    value: '$totalQuestions',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _SubmitQuizStatCard(
                    label: 'Attempted',
                    value: '$attemptedQuestions',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFA4A4A4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Get.back(result: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F73D1),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: const Color(
                        0xFF1F73D1,
                      ).withValues(alpha: 0.28),
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmitQuizStatCard extends StatelessWidget {
  const _SubmitQuizStatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E4EA), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF717787),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0865B7),
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
