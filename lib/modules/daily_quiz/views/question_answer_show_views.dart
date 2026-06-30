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
      backgroundColor: const Color(0xFFF7F8FC),
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
                            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isReview)
                            Row(
                              children: [
                                Expanded(
                                  child: _QuizActionButton(
                                    label: 'Questions',
                                    icon: Icons.apps_rounded,
                                    onTap: () {
                                      Get.bottomSheet<void>(
                                        _QuestionNavigatorSheet(
                                          controller: controller,
                                        ),
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        barrierColor: Colors.black.withValues(
                                          alpha: 0.55,
                                        ),
                                      );
                                    },
                                    foregroundColor: const Color(0xFF0865B7),
                                    backgroundColor: const Color(0xFFE9F4FF),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _QuizActionButton(
                                    label: controller.isSubmittingQuiz.value
                                        ? 'Submitting...'
                                        : 'Submit',
                                    icon: Icons.check_circle_outline_rounded,
                                    onTap:
                                        controller.totalQuestions > 0 &&
                                            !controller.isReviewMode.value &&
                                            !controller.isSubmittingQuiz.value
                                        ? () async {
                                            final shouldSubmit =
                                                await Get.dialog<bool>(
                                                  _SubmitQuizDialog(
                                                    totalQuestions: controller
                                                        .totalQuestions,
                                                    attemptedQuestions:
                                                        controller
                                                            .answeredCount,
                                                  ),
                                                  barrierDismissible: true,
                                                );

                                            if (shouldSubmit == true) {
                                              await controller.submitQuiz();
                                            }
                                          }
                                        : null,
                                    foregroundColor: Colors.white,
                                    backgroundColor: const Color(0xFF0865B7),
                                    disabledBackgroundColor: const Color(
                                      0xFFC9CCDE,
                                    ),
                                    showLoader:
                                        controller.isSubmittingQuiz.value,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (!isReview) ...[
                              const Text(
                                'Quiz Progress',
                                style: TextStyle(
                                  color: Color(0xFF4D4D60),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Text(
                                    'Question $questionNumber of ${controller.totalQuestions}',
                                    style: const TextStyle(
                                      color: Color(0xFF1E2230),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE4E2FF),
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    child: Text(
                                      controller.progressLabel,
                                      style: const TextStyle(
                                        color: Color(0xFF4D4FE1),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  value: controller.answeredProgress,
                                  minHeight: 7,
                                  backgroundColor: const Color(0xFFE0E4EB),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF4D4FE1),
                                      ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFB046F6),
                                      Color(0xFF7B2DE3),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF8F40E9,
                                      ).withValues(alpha: 0.25),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  controller.isReviewMode.value
                                      ? 'Review Mode'
                                      : 'Time ${controller.formattedElapsedTime}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                22,
                                22,
                                22,
                                20,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: const Color(0xFFD1CEEF),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFDCE2F3,
                                    ).withValues(alpha: 0.55),
                                    blurRadius: 24,
                                    offset: const Offset(0, 14),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4D4FE1),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                                  Transform.translate(
                                    offset: const Offset(20, -40),
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 18),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Q. $questionNumber ${question.question}',
                                            style: const TextStyle(
                                              color: Color(0xFF202436),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              height: 1.8,
                                            ),
                                          ),
                                          const SizedBox(height: 15),
                                          Wrap(
                                            spacing: 10,
                                            runSpacing: 10,
                                            children: question.tags
                                                .map(
                                                  (tag) => Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 11,
                                                          vertical: 7,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFF0F1F5,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            24,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      tag,
                                                      style: const TextStyle(
                                                        color: Color(
                                                          0xFF505165,
                                                        ),
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 0),
                                ],
                              ),
                            ),
                            Transform.translate(
                              offset: const Offset(0, 20),
                              child: Column(
                                children: [
                                  ...List.generate(question.options.length, (
                                    index,
                                  ) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: _OptionTile(optionIndex: index),
                                    );
                                  }),
                                  if (controller.isReviewMode.value)
                                    _ExplanationSection(question: question),
                                ],
                              ),
                            ),
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

class _QuestionTopBar extends StatelessWidget {
  const _QuestionTopBar();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuestionAnswerShowController>();

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF123887),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
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

      Color borderColor = const Color(0xFFD1CEEF);
      Color fillColor = Colors.white;
      Color bubbleColor = const Color(0xFFE8EBF0);
      Color bubbleTextColor = const Color(0xFF202436);

      if (isSelected) {
        borderColor = const Color(0xFF4D4FE1);
        fillColor = const Color(0xFFE0DEFF);
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
        borderRadius: BorderRadius.circular(28),
        onTap: () => controller.selectAnswer(optionIndex),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2.5 : 1.4,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: bubbleColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  String.fromCharCode(65 + optionIndex),
                  style: TextStyle(
                    color: bubbleTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  question.options[optionIndex],
                  style: const TextStyle(
                    color: Color(0xFF202436),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
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
                      foregroundColor: const Color(0xFF697181),
                      backgroundColor: const Color(0xFFE8ECF2),
                      disabledBackgroundColor: const Color(0xFFE8ECF2),
                      disabledForegroundColor: const Color(0xFF9AA1AD),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuizActionButton(
                      label: controller.isCurrentQuestionMarked
                          ? 'Marked'
                          : 'Mark',
                      icon: controller.isCurrentQuestionMarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      onTap: controller.isReviewMode.value
                          ? null
                          : controller.toggleMarkCurrentQuestion,
                      foregroundColor: const Color(0xFFC45A12),
                      backgroundColor: Colors.white,
                      borderColor: const Color(0xFFF0C8B5),
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
                      foregroundColor: const Color(0xFF697181),
                      backgroundColor: const Color(0xFFE8ECF2),
                      disabledBackgroundColor: const Color(0xFFE8ECF2),
                      disabledForegroundColor: const Color(0xFF9AA1AD),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuizActionButton(
                      label: controller.hasNextQuestion
                          ? 'Save & Next'
                          : 'Save',
                      icon: controller.hasNextQuestion
                          ? Icons.arrow_forward_rounded
                          : Icons.done_rounded,
                      iconAfterLabel: true,
                      onTap: controller.isReviewMode.value
                          ? null
                          : controller.saveAndNextQuestion,
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF0865B7),
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
                  height: 35,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF1F6),
                    borderRadius: BorderRadius.circular(30),
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
    this.showLoader = false,
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
  final bool showLoader;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final effectiveForeground = isEnabled
        ? foregroundColor
        : (disabledForegroundColor ?? Colors.white);
    final effectiveBackground = isEnabled
        ? backgroundColor
        : (disabledBackgroundColor ?? const Color(0xFFC9CCDE));

    final iconWidget = showLoader
        ? SizedBox(
            width: 12,
            height: 5,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: effectiveForeground,
            ),
          )
        : Icon(icon, size: 15, color: effectiveForeground);

    final labelWidget = Flexible(
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: effectiveForeground,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          height: 35,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: effectiveBackground,
            borderRadius: BorderRadius.circular(30),
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
                      isAnswered && correctIndex != null && selected == correctIndex;

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
      // Review mode: color by correctness.
      // green = correct, red = wrong, gray = not visited/unanswered.
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

    final bool isFilled = isReview ? isAnswered : (isCurrent || isMarked || isAnswered);
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

class _CircleNavButton extends StatelessWidget {
  const _CircleNavButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: isEnabled ? const Color(0xFF5D63F0) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isEnabled
                ? const Color(0xFF5D63F0)
                : const Color(0xFFD1CEEF),
            width: 1.6,
          ),
        ),
        child: Icon(
          icon,
          color: isEnabled ? Colors.white : const Color(0xFF585C70),
          size: 22,
        ),
      ),
    );
  }
}
