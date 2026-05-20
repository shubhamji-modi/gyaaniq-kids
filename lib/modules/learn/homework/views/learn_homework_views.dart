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
  LearnHomeworkStatus _selectedTab = LearnHomeworkStatus.pending;

  @override
  Widget build(BuildContext context) {
    final items = LearnHomeworkRepository.assignments
        .where((item) => item.status == _selectedTab)
        .toList();

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
                  _HomeworkTabs(
                    selectedTab: _selectedTab,
                    onChanged: (value) {
                      setState(() {
                        _selectedTab = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: item.status == LearnHomeworkStatus.pending
                          ? _PendingHomeworkCard(item: item)
                          : _CompletedHomeworkCard(item: item),
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

class _HomeworkTabs extends StatelessWidget {
  const _HomeworkTabs({
    required this.selectedTab,
    required this.onChanged,
  });

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
          Expanded(
            child: _TabButton(
              label: 'Pending',
              isSelected: selectedTab == LearnHomeworkStatus.pending,
              onTap: () => onChanged(LearnHomeworkStatus.pending),
            ),
          ),
          Expanded(
            child: _TabButton(
              label: 'Completed',
              isSelected: selectedTab == LearnHomeworkStatus.completed,
              onTap: () => onChanged(LearnHomeworkStatus.completed),
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
    final showDuration = item.id == 'quadratic_equations';

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
              onPressed: () =>
                  Get.to(() => LearnHomeworkSumbitViews(homework: item)),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF4A4FD9),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Submit Assignment',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.arrow_forward_rounded, size: 23),
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
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
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
                const Row(
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      color: Color(0xFF0AA84F),
                      size: 19,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Submitted',
                      style: TextStyle(
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
            onPressed: () {},
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
