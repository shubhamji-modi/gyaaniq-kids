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

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF4D4FE1),
                                ),
                              ),
                            ),
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
                                children: List.generate(
                                  question.options.length,
                                  (index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: _OptionTile(optionIndex: index),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _BottomActionBar(controller: controller),
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

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.controller});

  final QuestionAnswerShowController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4E7F0))),
      ),
      child: SafeArea(
        top: false,
        child: Obx(
          () => Row(
            children: [
              _CircleNavButton(
                icon: Icons.chevron_left_rounded,
                onTap: controller.hasPreviousQuestion
                    ? controller.previousQuestion
                    : null,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed:
                        controller.totalQuestions > 0 &&
                            !controller.isReviewMode.value &&
                            !controller.isSubmittingQuiz.value
                        ? controller.submitQuiz
                        : null,
                    icon: controller.isSubmittingQuiz.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 20,
                          ),
                    label: Text(
                      controller.isReviewMode.value
                          ? 'Answers Reviewed'
                          : (controller.isSubmittingQuiz.value
                                ? 'Submitting...'
                                : 'Finish Quiz'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4D4FE1),
                      disabledBackgroundColor: const Color(0xFFC9CCDE),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              _CircleNavButton(
                icon: Icons.chevron_right_rounded,
                onTap: controller.hasNextQuestion
                    ? controller.nextQuestion
                    : null,
              ),
            ],
          ),
        ),
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
