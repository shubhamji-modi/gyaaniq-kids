import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../chapter/views/learn_subject_views.dart';
import '../controller/learn_homework_controller.dart';
import 'learn_homework_sumbit_views.dart';

class LearnHomeworkViews extends StatefulWidget {
  const LearnHomeworkViews({super.key});

  @override
  State<LearnHomeworkViews> createState() => _LearnHomeworkViewsState();
}

class _LearnHomeworkViewsState extends State<LearnHomeworkViews> {
  late final LearnHomeworkController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(LearnHomeworkController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        child: Column(
          children: [
            const LearnTopBar(title: 'Homework'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 28),
                children: [
                  const Text(
                    'My Homework',
                    style: TextStyle(
                      color: Color(0xFF1D2231),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Stay on track with your study journey.',
                    style: TextStyle(
                      color: Color(0xFF4C5164),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Obx(
                    () => _HomeworkTabs(
                      selectedTab: _controller.selectedTab.value,
                      onChanged: _controller.changeTab,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Obx(() {
                    if (_controller.isLoading.value) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 44),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (_controller.errorMessage.value.isNotEmpty) {
                      return _HomeworkStateCard(
                        message: _controller.errorMessage.value,
                        onRetry: _controller.fetchHomework,
                      );
                    }

                    if (_controller.assignments.isEmpty) {
                      return _HomeworkStateCard(
                        message:
                            'No ${_controller.selectedTab.value.label.toLowerCase()} homework found.',
                        onRetry: _controller.fetchHomework,
                      );
                    }

                    return Column(
                      children: _controller.assignments
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child:
                                  item.status == LearnHomeworkStatus.pending ||
                                      item.status == LearnHomeworkStatus.overdue
                                  ? _PendingHomeworkCard(item: item)
                                  : _CompletedHomeworkCard(item: item),
                            ),
                          )
                          .toList(),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeworkTabs extends StatelessWidget {
  const _HomeworkTabs({required this.selectedTab, required this.onChanged});

  final LearnHomeworkStatus selectedTab;
  final ValueChanged<LearnHomeworkStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFE6E8ED),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          for (final status in LearnHomeworkStatus.values)
            Expanded(
              child: _TabButton(
                label: status.label,
                isSelected: selectedTab == status,
                onTap: () => onChanged(status),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFF4A4FD9)
                : const Color(0xFF4C5164),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PendingHomeworkCard extends StatelessWidget {
  const _PendingHomeworkCard({required this.item});

  final LearnHomeworkModel item;

  @override
  Widget build(BuildContext context) {
    final showDuration = item.duration.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFC8C7F1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD8DDF0).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: item.iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Color(0xFF1D2231),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${item.subject} • ${item.topic}',
                      style: const TextStyle(
                        color: Color(0xFF4C5164),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: Color(0xFF4C5164),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Due: ${item.dueDate}',
                  style: const TextStyle(
                    color: Color(0xFF4C5164),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (showDuration) ...[
                const Icon(
                  Icons.access_time_rounded,
                  color: Color(0xFF4C5164),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  item.duration,
                  style: const TextStyle(
                    color: Color(0xFF4C5164),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: item.canSubmit
                  ? () {
                      Get.to<bool>(
                        () => LearnHomeworkSumbitViews(homework: item),
                      )?.then((didSubmit) {
                        if (didSubmit == true &&
                            Get.isRegistered<LearnHomeworkController>()) {
                          Get.find<LearnHomeworkController>().fetchHomework();
                        }
                      });
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF4A4FD9),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.status == LearnHomeworkStatus.overdue
                        ? 'Submit Late'
                        : 'Submit Assignment',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.arrow_forward_rounded, size: 23),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedHomeworkCard extends StatelessWidget {
  const _CompletedHomeworkCard({required this.item});

  final LearnHomeworkModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFC8C7F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: item.chipBackground,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  item.subjectLabel,
                  style: TextStyle(
                    color: item.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Spacer(),
              const CircleAvatar(
                radius: 13,
                backgroundColor: Color(0xFFDFF8E8),
                child: Icon(
                  Icons.check_rounded,
                  color: Color(0xFF0AA84F),
                  size: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            item.title,
            style: const TextStyle(
              color: Color(0xFF1D2231),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _InfoBlock(
                        label: 'Date',
                        value: item.submittedDate,
                      ),
                    ),
                    Expanded(
                      child: _InfoBlock(
                        label: item.scoreLabel,
                        value: item.scoreValue,
                        valueColor: item.id == 'cell_structure'
                            ? const Color(0xFFA46A00)
                            : const Color(0xFF4A4FD9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.verified_outlined,
                      color: Color(0xFF0AA84F),
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.submissionState,
                      style: const TextStyle(
                        color: Color(0xFF0AA84F),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: () =>
                Get.to(() => LearnHomeworkSumbitViews(homework: item)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(45),
              side: const BorderSide(color: Color(0xFF4A4FD9), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: const Text(
              'View Feedback',
              style: TextStyle(
                color: Color(0xFF4A4FD9),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeworkStateCard extends StatelessWidget {
  const _HomeworkStateCard({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE1E4EC)),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF4C5164),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.label,
    required this.value,
    this.valueColor = const Color(0xFF1D2231),
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF4C5164),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
