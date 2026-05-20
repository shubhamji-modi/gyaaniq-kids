import 'package:flutter/material.dart';

import '../../chapter/views/learn_subject_views.dart';

class LearnAttendanceViews extends StatefulWidget {
  const LearnAttendanceViews({super.key});

  @override
  State<LearnAttendanceViews> createState() => _LearnAttendanceViewsState();
}

class _LearnAttendanceViewsState extends State<LearnAttendanceViews> {
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime.now();

  void _changeMonth(int offset) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + offset);
      final daysInMonth = DateUtils.getDaysInMonth(
        _visibleMonth.year,
        _visibleMonth.month,
      );
      final safeDay = _selectedDate.day.clamp(1, daysInMonth);
      _selectedDate = DateTime(
        _visibleMonth.year,
        _visibleMonth.month,
        safeDay,
      );
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      if (date.year != _visibleMonth.year || date.month != _visibleMonth.month) {
        _visibleMonth = DateTime(date.year, date.month);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const subjects = [
      _SubjectAttendanceData(
        icon: Icons.functions_rounded,
        iconBackground: Color(0xFFE2E1FF),
        iconColor: Color(0xFF4A4FD9),
        title: 'Mathematics',
        subtitle: 'Missed: 1 Class',
        progress: 0.95,
        progressLabel: '95%',
        accent: Color(0xFF4A4FD9),
      ),
      _SubjectAttendanceData(
        icon: Icons.science_outlined,
        iconBackground: Color(0xFFFFF0DA),
        iconColor: Color(0xFFA46A00),
        title: 'Science',
        subtitle: 'Missed: 2 Classes',
        progress: 0.88,
        progressLabel: '88%',
        accent: Color(0xFFFFA31A),
      ),
      _SubjectAttendanceData(
        icon: Icons.history_edu_outlined,
        iconBackground: Color(0xFFEEDCFF),
        iconColor: Color(0xFF7D31E2),
        title: 'History',
        subtitle: 'Perfect Record',
        progress: 1,
        progressLabel: '100%',
        accent: Color(0xFF7D31E2),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        child: Column(
          children: [
            const LearnTopBar(title: 'Attendance'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                children: [
                  _AttendanceCalendarCard(
                    visibleMonth: _visibleMonth,
                    selectedDate: _selectedDate,
                    onPreviousMonth: () => _changeMonth(-1),
                    onNextMonth: () => _changeMonth(1),
                    onDateSelected: _selectDate,
                  ),
                  const SizedBox(height: 18),
                  const _OverallAttendanceCard(),
                  const SizedBox(height: 24),
                  const Text(
                    'Subject Breakdown',
                    style: TextStyle(
                      color: Color(0xFF1D2231),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...subjects.map(
                    (subject) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _SubjectAttendanceCard(subject: subject),
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

class _AttendanceCalendarCard extends StatelessWidget {
  const _AttendanceCalendarCard({
    required this.visibleMonth,
    required this.selectedDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onDateSelected,
  });

  final DateTime visibleMonth;
  final DateTime selectedDate;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final monthLabel = _formatMonthYear(visibleMonth);
    final days = _buildCalendarDays(visibleMonth, selectedDate);

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
                  style: TextStyle(
                    color: Color(0xFF1D2231),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _CalendarArrowButton(
                icon: Icons.chevron_left_rounded,
                onTap: onPreviousMonth,
              ),
              SizedBox(width: 8),
              _CalendarArrowButton(
                icon: Icons.chevron_right_rounded,
                onTap: onNextMonth,
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _WeekDayLabel(label: 'Mon'),
              _WeekDayLabel(label: 'Tue'),
              _WeekDayLabel(label: 'Wed'),
              _WeekDayLabel(label: 'Thu'),
              _WeekDayLabel(label: 'Fri'),
              _WeekDayLabel(label: 'Sat', color: Color(0xFFFFA31A)),
              _WeekDayLabel(label: 'Sun', color: Color(0xFFFFA31A)),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: days.map((day) {
              final isWeekend = day.date.weekday >= DateTime.saturday;
              return GestureDetector(
                onTap: () => onDateSelected(day.date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: 35,
                  height: 75,
                  decoration: BoxDecoration(
                    color: day.isSelected
                        ? Colors.white
                        : day.isCurrentMonth
                            ? const Color(0xFFF4F5F8)
                            : const Color(0xFFF7F8FC),
                    borderRadius: BorderRadius.circular(10),
                    border: day.isSelected
                        ? Border.all(color: const Color(0xFF4A4FD9), width: 2)
                        : null,
                    boxShadow: day.isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF4A4FD9).withValues(alpha: 0.14),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.date.day}',
                    style: TextStyle(
                      color: day.isCurrentMonth
                          ? isWeekend
                              ? const Color(0xFF1D2231)
                              : const Color(0xFF1D2231)
                          : const Color(0xFFC0C3CF),
                      fontSize: 16,
                      fontWeight: day.isSelected ? FontWeight.w800 : FontWeight.w700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _CalendarArrowButton extends StatelessWidget {
  const _CalendarArrowButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(
          icon,
          color: const Color(0xFF4C5164),
          size: 28,
        ),
      ),
    );
  }
}

class _CalendarDayData {
  const _CalendarDayData({
    required this.date,
    required this.isCurrentMonth,
    required this.isSelected,
  });

  final DateTime date;
  final bool isCurrentMonth;
  final bool isSelected;
}

String _formatMonthYear(DateTime date) {
  const monthNames = [
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

  return '${monthNames[date.month - 1]} ${date.year}';
}

List<_CalendarDayData> _buildCalendarDays(
  DateTime visibleMonth,
  DateTime selectedDate,
) {
  final firstDayOfMonth = DateTime(visibleMonth.year, visibleMonth.month, 1);
  final startOffset = firstDayOfMonth.weekday - DateTime.monday;
  final calendarStart = firstDayOfMonth.subtract(Duration(days: startOffset));
  final daysInMonth = DateUtils.getDaysInMonth(
    visibleMonth.year,
    visibleMonth.month,
  );
  final totalVisibleDays = startOffset + daysInMonth;
  final totalCells = ((totalVisibleDays + 6) ~/ 7) * 7;

  return List.generate(totalCells, (index) {
    final date = calendarStart.add(Duration(days: index));
    return _CalendarDayData(
      date: date,
      isCurrentMonth: date.month == visibleMonth.month,
      isSelected: DateUtils.isSameDay(date, selectedDate),
    );
  });
}

class _WeekDayLabel extends StatelessWidget {
  const _WeekDayLabel({
    required this.label,
    this.color = const Color(0xFF7B8092),
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 45,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OverallAttendanceCard extends StatelessWidget {
  const _OverallAttendanceCard();

  @override
  Widget build(BuildContext context) {
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
                    value: 0.90,
                    strokeWidth: 12,
                    backgroundColor: const Color(0xFFE6E8EF),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF4A4FD9),
                    ),
                  ),
                ),
                const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '90%',
                      style: TextStyle(
                        color: Color(0xFF4A4FD9),
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Excellent!',
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
          const Row(
            children: [
              Expanded(
                child: _AttendanceLegend(
                  count: '18',
                  label: 'Present',
                  color: Color(0xFF4A4FD9),
                ),
              ),
              _VerticalDivider(),
              Expanded(
                child: _AttendanceLegend(
                  count: '2',
                  label: 'Absent',
                  color: Color(0xFFC81E1E),
                ),
              ),
              _VerticalDivider(),
              Expanded(
                child: _AttendanceLegend(
                  count: '1',
                  label: 'Holiday',
                  color: Color(0xFFA46A00),
                ),
              ),
            ],
          ),
        ],
      ),
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
          style: const TextStyle(
            color: Color(0xFF7B8092),
            fontSize: 14,
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
    return Container(
      width: 1,
      height: 40,
      color: const Color(0xFFD7DAE4),
    );
  }
}

class _SubjectAttendanceCard extends StatelessWidget {
  const _SubjectAttendanceCard({required this.subject});

  final _SubjectAttendanceData subject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFC8C7F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: subject.iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(subject.icon, color: subject.iconColor, size: 24),
              ),
              const Spacer(),
              Text(
                subject.progressLabel,
                style: TextStyle(
                  color: subject.accent,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            subject.title,
            style: const TextStyle(
              color: Color(0xFF1D2231),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subject.subtitle,
            style: const TextStyle(
              color: Color(0xFF4C5164),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: subject.progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFD9DCE4),
              valueColor: AlwaysStoppedAnimation<Color>(subject.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectAttendanceData {
  const _SubjectAttendanceData({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.progressLabel,
    required this.accent,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final double progress;
  final String progressLabel;
  final Color accent;
}
