import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../chapter/views/learn_subject_views.dart';
import '../controller/learn_attendance_controller.dart';

class LearnAttendanceViews extends StatefulWidget {
  const LearnAttendanceViews({super.key});

  @override
  State<LearnAttendanceViews> createState() => _LearnAttendanceViewsState();
}

class _LearnAttendanceViewsState extends State<LearnAttendanceViews> {
  late final LearnAttendanceController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(LearnAttendanceController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        child: Column(
          children: [
            const LearnTopBar(title: 'Attendance'),
            Expanded(
              child: Obx(() {
                if (_controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_controller.errorMessage.value.isNotEmpty) {
                  return _AttendanceStateCard(
                    message: _controller.errorMessage.value,
                    onRetry: _controller.fetchAttendance,
                  );
                }

                return RefreshIndicator(
                  onRefresh: _controller.fetchAttendance,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                    children: [
                      _AttendanceCalendarCard(controller: _controller),
                      const SizedBox(height: 18),
                      _OverallAttendanceCard(
                        summary: _controller.summary.value,
                      ),
                      const SizedBox(height: 18),
                      _SelectedDayCard(day: _controller.selectedAttendanceDay),
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

class _AttendanceCalendarCard extends StatelessWidget {
  const _AttendanceCalendarCard({required this.controller});

  final LearnAttendanceController controller;

  @override
  Widget build(BuildContext context) {
    final visibleMonth = controller.visibleMonth.value;
    final monthLabel = _formatMonthYear(visibleMonth);
    final days = controller.days;
    final leadingOffset = days.isEmpty ? 0 : days.first.date.weekday - 1;
    final cells = <AttendanceDayModel?>[
      ...List<AttendanceDayModel?>.filled(leadingOffset, null),
      ...days,
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFC8C7F1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  monthLabel,
                  style: const TextStyle(
                    color: Color(0xFF1D2231),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _CalendarArrowButton(
                icon: Icons.chevron_left_rounded,
                onTap: () => controller.changeMonth(-1),
              ),
              const SizedBox(width: 8),
              _CalendarArrowButton(
                icon: Icons.chevron_right_rounded,
                onTap: () => controller.changeMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              _WeekDayLabel(label: 'Mon'),
              _WeekDayLabel(label: 'Tue'),
              _WeekDayLabel(label: 'Wed'),
              _WeekDayLabel(label: 'Thu'),
              _WeekDayLabel(label: 'Fri'),
              _WeekDayLabel(label: 'Sat'),
              _WeekDayLabel(label: 'Sun'),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cells.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 10,
              crossAxisSpacing: 8,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, index) {
              final day = cells[index];
              if (day == null) {
                return const SizedBox.shrink();
              }
              return Obx(
                () => _AttendanceDayCell(
                  day: day,
                  isSelected: DateUtils.isSameDay(
                    day.date,
                    controller.selectedDate.value,
                  ),
                  onTap: () => controller.selectDate(day.date),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          const _AttendanceStatusLegend(),
        ],
      ),
    );
  }
}

class _AttendanceDayCell extends StatelessWidget {
  const _AttendanceDayCell({
    required this.day,
    required this.isSelected,
    required this.onTap,
  });

  final AttendanceDayModel day;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(day.status);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.24),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.date.day}',
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarArrowButton extends StatelessWidget {
  const _CalendarArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(icon, color: const Color(0xFF4C5164), size: 28),
      ),
    );
  }
}

class _WeekDayLabel extends StatelessWidget {
  const _WeekDayLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF7B8092),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OverallAttendanceCard extends StatelessWidget {
  const _OverallAttendanceCard({required this.summary});

  final AttendanceSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    final progress = (summary.percentage / 100).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFC8C7F1)),
      ),
      child: Column(
        children: [
          const Text(
            'Overall Attendance',
            style: TextStyle(
              color: Color(0xFF1D2231),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${summary.total} working days, ${summary.holidays} holidays',
            style: const TextStyle(
              color: Color(0xFF7B8092),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 130,
            height: 130,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    backgroundColor: const Color(0xFFE6E8EF),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF16A34A),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${summary.percentage.toStringAsFixed(2)}%',
                      style: const TextStyle(
                        color: Color(0xFF16A34A),
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'This month',
                      style: TextStyle(
                        color: Color(0xFF4C5164),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _AttendanceLegend(
                  count: '${summary.present}',
                  label: 'Present',
                  color: _statusColor(AttendanceStatus.present),
                ),
              ),
              const _VerticalDivider(),
              Expanded(
                child: _AttendanceLegend(
                  count: '${summary.absent}',
                  label: 'Absent',
                  color: _statusColor(AttendanceStatus.absent),
                ),
              ),
              const _VerticalDivider(),
              Expanded(
                child: _AttendanceLegend(
                  count: '${summary.notAttend}',
                  label: 'Not Attend',
                  color: _statusColor(AttendanceStatus.notAttend),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectedDayCard extends StatelessWidget {
  const _SelectedDayCard({required this.day});

  final AttendanceDayModel? day;

  @override
  Widget build(BuildContext context) {
    final currentDay = day;
    if (currentDay == null) {
      return const SizedBox.shrink();
    }

    final color = _statusColor(currentDay.status);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC8C7F1)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_statusIcon(currentDay.status), color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatFullDate(currentDay.date),
                  style: const TextStyle(
                    color: Color(0xFF1D2231),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  currentDay.note.isEmpty
                      ? currentDay.status.label
                      : '${currentDay.status.label} - ${currentDay.note}',
                  style: const TextStyle(
                    color: Color(0xFF4C5164),
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

class _AttendanceStatusLegend extends StatelessWidget {
  const _AttendanceStatusLegend();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 14,
      runSpacing: 8,
      children: [
        _StatusLegendItem(status: AttendanceStatus.present),
        _StatusLegendItem(status: AttendanceStatus.absent),
        _StatusLegendItem(status: AttendanceStatus.notAttend),
        _StatusLegendItem(status: AttendanceStatus.holiday),
      ],
    );
  }
}

class _StatusLegendItem extends StatelessWidget {
  const _StatusLegendItem({required this.status});

  final AttendanceStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          status.label,
          style: const TextStyle(
            color: Color(0xFF4C5164),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AttendanceLegend extends StatelessWidget {
  const _AttendanceLegend({
    required this.count,
    required this.label,
    required this.color,
  });

  final String count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF7B8092),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: const Color(0xFFD7DAE4));
  }
}

class _AttendanceStateCard extends StatelessWidget {
  const _AttendanceStateCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFC8C7F1)),
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
              const SizedBox(height: 14),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ],
    );
  }
}

Color _statusColor(AttendanceStatus status) {
  switch (status) {
    case AttendanceStatus.present:
      return const Color(0xFF16A34A);
    case AttendanceStatus.absent:
      return const Color(0xFFE11D48);
    case AttendanceStatus.notAttend:
      return const Color(0xFF64748B);
    case AttendanceStatus.holiday:
      return const Color(0xFF334155);
  }
}

IconData _statusIcon(AttendanceStatus status) {
  switch (status) {
    case AttendanceStatus.present:
      return Icons.check_circle_outline_rounded;
    case AttendanceStatus.absent:
      return Icons.cancel_outlined;
    case AttendanceStatus.notAttend:
      return Icons.radio_button_unchecked_rounded;
    case AttendanceStatus.holiday:
      return Icons.weekend_outlined;
  }
}

String _formatMonthYear(DateTime date) {
  return '${_monthNames[date.month - 1]} ${date.year}';
}

String _formatFullDate(DateTime date) {
  return '${date.day} ${_monthNames[date.month - 1]} ${date.year}';
}

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
