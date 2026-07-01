import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../learn/chapter/controller/learn_chapter_controller.dart';
import '../controller/practice_quiz_overview_controller.dart';

class PracticeQuizOverviewViews extends StatelessWidget {
  const PracticeQuizOverviewViews({
    super.key,
    required this.subject,
    required this.chapter,
    this.returnToLessonOnResultBack = false,
  });

  final LearnSubjectModel subject;
  final LearnChapterModel chapter;
  final bool returnToLessonOnResultBack;

  @override
  Widget build(BuildContext context) {
    final sourceTag = returnToLessonOnResultBack ? 'lesson' : 'default';
    final controllerTag = '${subject.id}_${chapter.id}_$sourceTag';
    final controller =
        Get.isRegistered<PracticeQuizOverviewController>(tag: controllerTag)
        ? Get.find<PracticeQuizOverviewController>(tag: controllerTag)
        : Get.put(
            PracticeQuizOverviewController(
              subject: subject,
              chapter: chapter,
              returnToLessonOnResultBack: returnToLessonOnResultBack,
            ),
            tag: controllerTag,
          );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Column(
          children: [
            const _OverviewTopBar(),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.errorMessage.value.isNotEmpty &&
                    controller.quizzes.isEmpty) {
                  return _OverviewStateCard(
                    title: 'Unable to load quiz',
                    message: controller.errorMessage.value,
                    onRetry: controller.loadQuizzes,
                  );
                }

                final quiz = controller.selectedQuiz;
                if (quiz == null) {
                  return _OverviewStateCard(
                    title: 'No quiz available',
                    message: 'This lesson does not have a practice quiz yet.',
                    onRetry: controller.loadQuizzes,
                  );
                }

                return RefreshIndicator(
                  onRefresh: controller.loadQuizzes,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(12, 6, 14, 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF8A3D), Color(0xFFFF5A5F)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFFF5A5F,
                                ).withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Practice Quiz',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          quiz.title,
                          style: const TextStyle(
                            color: Color(0xFF4950DB),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          quiz.description.isEmpty
                              ? 'Quiz description is not available.'
                              : quiz.description,
                          style: const TextStyle(
                            color: Color(0xFF474B5F),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.quiz_rounded,
                                accent: const Color(0xFF2C6BFF),
                                title: '${quiz.questionCount}',
                                subtitle: 'Questions',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.timer_rounded,
                                accent: const Color(0xFF8B46F9),
                                title: quiz.timeLimitLabel,
                                subtitle: 'Time Limit',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.workspace_premium_rounded,
                                accent: const Color(0xFFFF7A00),
                                title: '${quiz.totalMarks}',
                                subtitle: 'Total Marks',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.verified_rounded,
                                accent: const Color(0xFF22A45D),
                                title: '${quiz.passingPercentage}%',
                                subtitle: 'Passing',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFD8E0F3,
                                ).withValues(alpha: 0.75),
                                blurRadius: 30,
                                offset: const Offset(0, 16),
                              ),
                            ],
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFFFFFF), Color(0xFFF5F6FF)],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Quiz Instructions',
                                style: TextStyle(
                                  color: Color(0xFF4950DB),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const _InstructionTile(
                                number: 1,
                                text:
                                    'Read each question carefully before selecting your answer from the options provided.',
                              ),
                              const SizedBox(height: 18),
                              const _InstructionTile(
                                number: 2,
                                text:
                                    'You can skip questions and return to them later using the navigation panel at the bottom.',
                              ),
                              const SizedBox(height: 18),
                              const _InstructionTile(
                                number: 3,
                                text:
                                    'Ensure you have a stable internet connection before clicking the Start Quiz button.',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            Obx(() {
              if (controller.isLoading.value ||
                  controller.selectedQuiz == null) {
                return const SizedBox.shrink();
              }
              return _StartQuizBottomBar(controller: controller);
            }),
          ],
        ),
      ),
    );
  }
}

/// Sticky bottom action bar that keeps the Start Quiz button reachable while
/// the overview content scrolls above it.
class _StartQuizBottomBar extends StatelessWidget {
  const _StartQuizBottomBar({required this.controller});

  final PracticeQuizOverviewController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8EBF4))),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 22,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Obx(() {
        final isStarting = controller.isStartingQuiz.value;
        return Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF7A5CFF), Color(0xFF4D4FE1)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4D4FE1).withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: isStarting ? null : controller.startQuiz,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isStarting)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      isStarting ? 'Loading Quiz...' : 'Start Quiz',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _OverviewTopBar extends StatelessWidget {
  const _OverviewTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 10),
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
          const Expanded(
            child: Text(
              'Quiz',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF123887),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _OverviewStateCard extends StatelessWidget {
  const _OverviewStateCard({
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFD5D8E8)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF1D2230),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF505165),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4D4FE1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6B6F80),
                    fontSize: 11,
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

class _InstructionTile extends StatelessWidget {
  const _InstructionTile({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFF4D4FE1),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF2E3345),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
