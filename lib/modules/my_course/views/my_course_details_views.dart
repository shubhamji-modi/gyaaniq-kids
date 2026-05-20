import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'my_course_data.dart';

class MyCourseDetailsViews extends StatefulWidget {
  const MyCourseDetailsViews({
    super.key,
    required this.course,
    required this.module,
    required this.lesson,
  });

  final MyCourseModel course;
  final CourseModuleModel module;
  final CourseLessonModel lesson;

  @override
  State<MyCourseDetailsViews> createState() => _MyCourseDetailsViewsState();
}

class _MyCourseDetailsViewsState extends State<MyCourseDetailsViews>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    MyCourseRepository.markLessonViewed(widget.course.id, widget.lesson.id);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = MyCourseRepository.isLessonCompleted(
      widget.course.id,
      widget.lesson.id,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        child: Column(
          children: [
            const _TopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 140),
                children: [
                  _VideoPreviewCard(
                    title: widget.lesson.title,
                    accentColor: widget.course.accentColor,
                  ),
                  const SizedBox(height: 18),
                  _LessonOverviewCard(lesson: widget.lesson),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD8A8),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.stars_rounded,
                          color: Color(0xFF3A2200),
                          size: 22,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EARN 50 XP',
                                style: TextStyle(
                                  color: Color(0xFF3A2200),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Complete this video to reach your daily goal!',
                                style: TextStyle(
                                  color: Color(0xFF3A2200),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFD0D4F0)),
                    ),
                    child: Column(
                      children: [
                        TabBar(
                          controller: _tabController,
                          labelColor: widget.course.accentColor,
                          unselectedLabelColor: const Color(0xFF4C4E63),
                          indicatorColor: widget.course.accentColor,
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          tabs: const [
                            Tab(text: 'Notes'),
                            Tab(text: 'Resources'),
                          ],
                        ),
                        SizedBox(
                          height: 430,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _NotesTab(lesson: widget.lesson),
                              _ResourcesTab(lesson: widget.lesson),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: isCompleted
                        ? null
                        : () {
                            setState(() {
                              MyCourseRepository.markLessonCompleted(
                                widget.course.id,
                                widget.lesson.id,
                              );
                            });
                            Get.snackbar(
                              'Lesson Completed',
                              '${widget.lesson.title} marked as complete.',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.white,
                              colorText: const Color(0xFF1A1D27),
                              margin: const EdgeInsets.all(12),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.course.accentColor,
                      disabledBackgroundColor: const Color(0xFFBFC5E8),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 20),
                    label: Text(
                      isCompleted ? 'Completed' : 'Mark as Complete',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      widget.course.accentColor,
                      widget.course.accentColor.withValues(alpha: 0.75),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        width: 36,
        height: 36,
        child: Icon(
          Icons.arrow_back_ios_sharp,
          color: Color(0xFF10388F),
          size: 22,
        ),
      ),
    );
  }
}

class _VideoPreviewCard extends StatelessWidget {
  const _VideoPreviewCard({required this.title, required this.accentColor});

  final String title;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 200,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF021A1E), Color(0xFF132B36), Color(0xFF04070A)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _LessonBackgroundPainter(
                  color: Colors.cyanAccent.withValues(alpha: 0.26),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.30),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 35,
                ),
              ),
            ),
            Positioned(
              left: 22,
              bottom: 15,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonOverviewCard extends StatelessWidget {
  const _LessonOverviewCard({required this.lesson});

  final CourseLessonModel lesson;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFD6D8F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lesson Overview',
            style: TextStyle(
              color: Color(0xFF4A4FD9),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            lesson.overview,
            style: const TextStyle(
              color: Color(0xFF484B5C),
              fontSize: 14,
              height: 1.65,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          ...lesson.points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _OverviewPoint(text: point),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewPoint extends StatelessWidget {
  const _OverviewPoint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.check_circle_outline_rounded,
            color: Color(0xFF4A4FD9),
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF1E212B),
              fontSize: 14,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _NotesTab extends StatelessWidget {
  const _NotesTab({required this.lesson});

  final CourseLessonModel lesson;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F1F5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.notesTitle,
                  style: const TextStyle(
                    color: Color(0xFF4750D6),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  lesson.notesFormula,
                  style: const TextStyle(
                    color: Color(0xFF1D212B),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Key Steps:',
            style: TextStyle(
              color: Color(0xFF4B4E60),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            lesson.points.map((point) => '• $point').join('\n\n'),
            style: const TextStyle(
              color: Color(0xFF1E212B),
              fontSize: 14,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourcesTab extends StatelessWidget {
  const _ResourcesTab({required this.lesson});

  final CourseLessonModel lesson;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 18),
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFD9DCEF))),
          ),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8DAFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: Color(0xFF4A4FD9),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.resourceName,
                      style: const TextStyle(
                        color: Color(0xFF4A4FD9),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lesson.resourceSize,
                      style: const TextStyle(
                        color: Color(0xFF4B4E60),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Spacer(flex: 3),
      ],
    );
  }
}

class _LessonBackgroundPainter extends CustomPainter {
  const _LessonBackgroundPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.35),
      Offset(size.width * 0.34, size.height * 0.20),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.48, size.height * 0.60),
      Offset(size.width * 0.78, size.height * 0.40),
      paint,
    );
    canvas.drawCircle(Offset(size.width * 0.24, size.height * 0.54), 22, paint);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width * 0.68, size.height * 0.56),
        width: 72,
        height: 34,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.56, size.height * 0.24),
        width: 84,
        height: 30,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _LessonBackgroundPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
