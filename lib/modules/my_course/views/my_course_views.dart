import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'my_course_data.dart';
import 'my_course_subject_views.dart';

class MyCourseViews extends StatefulWidget {
  const MyCourseViews({super.key});

  @override
  State<MyCourseViews> createState() => _MyCourseViewsState();
}

class _MyCourseViewsState extends State<MyCourseViews> {
  final TextEditingController _searchController = TextEditingController();
  CourseFilter _selectedFilter = CourseFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courses = _filteredCourses();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FE),
      body: SafeArea(
        child: Column(
          children: [
            const _TopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                children: [
                  const Text(
                    'My Courses',
                    style: TextStyle(
                      color: Color(0xFF1D212B),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFD5D8F4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF8A8DA1),
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              hintText: 'Search your courses...',
                              hintStyle: TextStyle(
                                color: Color(0xFF8A8DA1),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: CourseFilter.values.map((filter) {
                        final selected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: InkWell(
                            onTap: () =>
                                setState(() => _selectedFilter = filter),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFF4C49E8)
                                    : const Color(0xFFF0F1F6),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _filterLabel(filter),
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF5A5D70),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...courses.map(
                    (course) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _CourseListCard(
                        course: course,
                        onTap: () async {
                          await Get.to(
                            () => MyCourseSubjectViews(course: course),
                          );
                          if (mounted) {
                            setState(() {});
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _AiRecapCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<MyCourseModel> _filteredCourses() {
    final query = _searchController.text.trim().toLowerCase();

    return MyCourseRepository.courses.where((course) {
      final matchesSearch =
          query.isEmpty ||
          course.title.toLowerCase().contains(query) ||
          course.subject.toLowerCase().contains(query) ||
          course.teacher.toLowerCase().contains(query);

      if (!matchesSearch) {
        return false;
      }

      switch (_selectedFilter) {
        case CourseFilter.all:
          return true;
        case CourseFilter.inProgress:
          return course.progress > 0 && course.progress < 1;
        case CourseFilter.completed:
          return course.progress >= 1;
        case CourseFilter.bookmarked:
          return course.isBookmarked;
      }
    }).toList();
  }

  String _filterLabel(CourseFilter filter) {
    switch (filter) {
      case CourseFilter.all:
        return 'All Courses';
      case CourseFilter.inProgress:
        return 'In Progress';
      case CourseFilter.completed:
        return 'Completed';
      case CourseFilter.bookmarked:
        return 'Marked';
    }
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE7EAF3))),
      ),
      child: const Row(
        children: [
          _BackButton(),
          Expanded(
            child: Text(
              'My Courses',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF10388F),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: 36),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: Get.back,
      borderRadius: BorderRadius.circular(24),
      child: const SizedBox(
        width: 20,
        height: 20,
        child: Icon(
          Icons.arrow_back_ios_sharp,
          color: Color(0xFF10388F),
          size: 22,
        ),
      ),
    );
  }
}

class _CourseListCard extends StatelessWidget {
  const _CourseListCard({required this.course, required this.onTap});

  final MyCourseModel course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progressText = '${(course.progress * 100).round()}% Complete';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFD6D8F3)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF65708C).withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: course.heroColors,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 18,
                      left: 18,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: course.accentColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          course.subject,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _HeroPatternPainter(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                    Center(
                      child: Icon(
                        course.heroIcon,
                        size: 74,
                        color: Colors.white.withValues(alpha: 0.90),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: const TextStyle(
                      color: Color(0xFF1D212B),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        color: Color(0xFF595D6F),
                        size: 17,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        course.teacher,
                        style: const TextStyle(
                          color: Color(0xFF595D6F),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Text(
                        progressText,
                        style: TextStyle(
                          color: course.accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${course.completedLessons}/${course.totalLessons} Lessons',
                        style: const TextStyle(
                          color: Color(0xFF727589),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: course.progress,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE9EBF2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        course.subject == 'English'
                            ? const Color(0xFF9A6500)
                            : course.accentColor,
                      ),
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

class _AiRecapCard extends StatelessWidget {
  const _AiRecapCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5D5CEB), Color(0xFF6A63F4), Color(0xFF5B5EF0)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'AI RECAP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Ready for your Math\nQuiz?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Based on your recent ‘Advanced Algebra’ progress, we recommend a 5-minute refresher on Quadratic Equations before you start today’s lesson.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.8,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF554CE8),
                  size: 17,
                ),
                SizedBox(width: 8),
                Text(
                  'Start AI Refresher',
                  style: TextStyle(
                    color: Color(0xFF554CE8),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
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

class _HeroPatternPainter extends CustomPainter {
  const _HeroPatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.32), 26, paint);
    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.38), 18, paint);
    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.54),
      Offset(size.width * 0.30, size.height * 0.25),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.62, size.height * 0.22),
      Offset(size.width * 0.86, size.height * 0.48),
      paint,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width * 0.63, size.height * 0.62),
        width: 58,
        height: 34,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.38, size.height * 0.68),
        width: 74,
        height: 24,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _HeroPatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
