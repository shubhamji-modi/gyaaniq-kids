import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/service/api_service.dart';
import '../controller/preview_result_controller.dart';

class PreviewResultViews extends StatelessWidget {
  const PreviewResultViews({super.key, this.initialType});

  final ResultHistoryType? initialType;

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<PreviewResultController>()
        ? Get.find<PreviewResultController>()
        : Get.put(PreviewResultController());
    final initialType = this.initialType;
    if (initialType != null && controller.selectedType != initialType) {
      final index = PreviewResultController.typeTabs.indexWhere(
        (tab) => tab.type == initialType,
      );
      if (index >= 0) {
        Future.microtask(() => controller.changeTypeTab(index));
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 5),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE8ECF5))),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: Get.back,
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFF143B8E),
                      size: 25,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Preview Result',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF143B8E),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                return RefreshIndicator(
                  onRefresh: () => controller.loadResults(refresh: true),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                    children: [
                      _ResultTypeTabs(controller: controller),
                      const SizedBox(height: 12),
                      _ResultStatusTabs(controller: controller),
                      const SizedBox(height: 18),
                      if (controller.isLoading.value)
                        const Padding(
                          padding: EdgeInsets.only(top: 100),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (controller.errorMessage.value.isNotEmpty &&
                          controller.results.isEmpty)
                        _ResultStateCard(
                          title: 'Unable to load results',
                          message: controller.errorMessage.value,
                          onRetry: () => controller.loadResults(refresh: true),
                        )
                      else if (controller.results.isEmpty)
                        const _ResultStateCard(
                          title: 'No results found',
                          message:
                              'No progress is available for this filter yet.',
                        )
                      else ...[
                        ...controller.results.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: _ResultCard(item: item),
                          ),
                        ),
                        if (controller.hasMore) ...[
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              onPressed: controller.isLoadingMore.value
                                  ? null
                                  : controller.loadMore,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A4FD9),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: controller.isLoadingMore.value
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Load More',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultTypeTabs extends StatelessWidget {
  const _ResultTypeTabs({required this.controller});

  final PreviewResultController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final tab = PreviewResultController.typeTabs[index];
          final isSelected = controller.selectedTypeIndex.value == index;
          return GestureDetector(
            onTap: () => controller.changeTypeTab(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF4A4FD9)
                    : const Color(0xFFE6E7EB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tab.label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF4A4B5D),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, index) => const SizedBox(width: 10),
        itemCount: PreviewResultController.typeTabs.length,
      ),
    );
  }
}

class _ResultStatusTabs extends StatelessWidget {
  const _ResultStatusTabs({required this.controller});

  final PreviewResultController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final tab = PreviewResultController.tabs[index];
          final isSelected = controller.selectedTabIndex.value == index;
          return GestureDetector(
            onTap: () => controller.changeTab(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF4A4FD9)
                    : const Color(0xFFE6E7EB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tab.label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF4A4B5D),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, index) => const SizedBox(width: 14),
        itemCount: PreviewResultController.tabs.length,
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.item});

  final QuizSubmitResultItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => Get.bottomSheet(
        _FeedbackBottomSheet(item: item),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFC9CAE8), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFCBD4ED).withValues(alpha: 0.20),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: item.iconBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: item.accent, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.lessonTitle,
                        style: const TextStyle(
                          color: Color(0xFF1F2430),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${item.meta} • ${item.lessonLabel}',
                        style: const TextStyle(
                          color: Color(0xFF4E5263),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _StatusBadge(item: item),
              ],
            ),
            const SizedBox(height: 15),
            const Divider(color: Color(0xFFE7EAF3), thickness: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Score',
                        style: TextStyle(
                          color: Color(0xFF7A7E8E),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.scoreText} • ${item.percentageText}',
                        style: const TextStyle(
                          color: Color(0xFF2E3345),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Last Activity',
                        style: TextStyle(
                          color: Color(0xFF7A7E8E),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          color: Color(0xFF2E3345),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Container(
                //   padding: const EdgeInsets.symmetric(
                //     horizontal: 14,
                //     vertical: 10,
                //   ),
                //   decoration: BoxDecoration(
                //     color: item.accent.withValues(alpha: 0.10),
                //     borderRadius: BorderRadius.circular(30),
                //   ),
                //   child: Text(
                //     item.lessonLabel,
                //     style: TextStyle(
                //       color: item.accent,
                //       fontSize: 12,
                //       fontWeight: FontWeight.w800,
                //     ),
                //   ),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackBottomSheet extends StatelessWidget {
  const _FeedbackBottomSheet({required this.item});

  final QuizSubmitResultItem item;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PreviewResultController>();

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: FutureBuilder<ApiResponse<QuizAttemptFeedback>>(
            future: controller.loadFeedback(item),
            builder: (context, snapshot) {
              final response = snapshot.data;

              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              if (response == null ||
                  !response.success ||
                  response.data == null) {
                return _FeedbackState(
                  title: 'Unable to load feedback',
                  message: response?.message ?? 'Please try again.',
                );
              }

              final feedback = response.data!;
              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD3D7E4),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          feedback.title,
                          style: const TextStyle(
                            color: Color(0xFF1F2430),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: Get.back,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFD9DDF1)),
                    ),
                    child: Row(
                      children: [
                        _FeedbackSummaryTile(
                          label: 'Score',
                          value: feedback.scoreText,
                        ),
                        _FeedbackSummaryTile(
                          label: 'Percentage',
                          value: feedback.percentageText,
                        ),
                        _FeedbackSummaryTile(
                          label: 'Result',
                          value: feedback.passed ? 'Passed' : 'Failed',
                          color: feedback.passed
                              ? const Color(0xFF22A45D)
                              : const Color(0xFFE45656),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Question Feedback',
                    style: TextStyle(
                      color: Color(0xFF1F2430),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (feedback.answers.isEmpty)
                    const _FeedbackState(
                      title: 'No feedback available',
                      message:
                          'No answer feedback was returned for this attempt.',
                    )
                  else
                    ...feedback.answers.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AnswerFeedbackCard(
                          index: entry.key,
                          answer: entry.value,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _FeedbackSummaryTile extends StatelessWidget {
  const _FeedbackSummaryTile({
    required this.label,
    required this.value,
    this.color = const Color(0xFF4A4FD9),
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7A7E8E),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerFeedbackCard extends StatelessWidget {
  const _AnswerFeedbackCard({required this.index, required this.answer});

  final int index;
  final QuizAttemptAnswerFeedback answer;

  @override
  Widget build(BuildContext context) {
    final accent = answer.isCorrect
        ? const Color(0xFF22A45D)
        : const Color(0xFFE45656);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(color: accent, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  answer.isCorrect ? 'Correct' : 'Incorrect',
                  style: TextStyle(
                    color: accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${answer.marksAwarded}/${answer.marks}',
                style: const TextStyle(
                  color: Color(0xFF1F2430),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (answer.questionText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Q. ${index + 1} ${answer.questionText}',
              style: const TextStyle(
                color: Color(0xFF1F2430),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ],
          if (answer.options.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...answer.options.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _FeedbackOptionTile(
                  optionIndex: entry.key,
                  optionText: entry.value,
                  answer: answer,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AnswerMeta(
                  label: 'Selected',
                  value: answer.selectedLabel,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AnswerMeta(
                  label: 'Correct',
                  value: answer.correctLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeedbackOptionTile extends StatelessWidget {
  const _FeedbackOptionTile({
    required this.optionIndex,
    required this.optionText,
    required this.answer,
  });

  final int optionIndex;
  final String optionText;
  final QuizAttemptAnswerFeedback answer;

  @override
  Widget build(BuildContext context) {
    final isSelected = answer.selectedIndex == optionIndex;
    final isCorrect = answer.correctIndex == optionIndex;
    final borderColor = isCorrect
        ? const Color(0xFF22A45D)
        : isSelected
        ? const Color(0xFFE45656)
        : const Color(0xFFE1E5F0);
    final fillColor = isCorrect
        ? const Color(0xFFE7F8EF)
        : isSelected
        ? const Color(0xFFFDEAEA)
        : const Color(0xFFF5F6FA);
    final bubbleColor = isCorrect
        ? const Color(0xFF22A45D)
        : isSelected
        ? const Color(0xFFE45656)
        : const Color(0xFFE4E7EF);

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bubbleColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              String.fromCharCode(65 + optionIndex),
              style: TextStyle(
                color: isCorrect || isSelected
                    ? Colors.white
                    : const Color(0xFF1F2430),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              optionText,
              style: const TextStyle(
                color: Color(0xFF1F2430),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
          if (isCorrect)
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF22A45D),
              size: 18,
            )
          else if (isSelected)
            const Icon(
              Icons.cancel_rounded,
              color: Color(0xFFE45656),
              size: 18,
            ),
        ],
      ),
    );
  }
}

class _AnswerMeta extends StatelessWidget {
  const _AnswerMeta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7A7E8E),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1F2430),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackState extends StatelessWidget {
  const _FeedbackState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF1F2430),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF4E5263),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.item});

  final QuizSubmitResultItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: item.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        item.passed ? 'Passed' : 'Failed',
        style: TextStyle(
          color: item.accent,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ResultStateCard extends StatelessWidget {
  const _ResultStateCard({
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC9CAE8)),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1F2430),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF4E5263),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.5,
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
              ),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
