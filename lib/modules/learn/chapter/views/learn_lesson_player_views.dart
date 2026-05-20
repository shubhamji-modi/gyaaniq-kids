import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/learn_chapter_controller.dart';
import 'learn_subject_views.dart';

class LearnLessonPlayerViews extends StatefulWidget {
  const LearnLessonPlayerViews({super.key, required this.topic});

  final LearnTopicModel topic;

  @override
  State<LearnLessonPlayerViews> createState() => _LearnLessonPlayerViewsState();
}

class _LearnLessonPlayerViewsState extends State<LearnLessonPlayerViews> {
  bool _showVideo = true;

  @override
  Widget build(BuildContext context) {
    final lesson = widget.topic.lesson;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        child: Column(
          children: [
            const LearnTopBar(title: 'Lesson Player'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
                children: [
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1720),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFF263A2F),
                                  const Color(0xFF10151D),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _BoardSketchPainter(),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.68),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  value: lesson.progress,
                                  minHeight: 8,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.28,
                                  ),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF5E63F4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 29,
                                  ),
                                  const SizedBox(width: 16),
                                  const Icon(
                                    Icons.volume_up_outlined,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                  const SizedBox(width: 20),
                                  Text(
                                    '${lesson.currentTime} / ${lesson.totalTime}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.fullscreen_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      _PlayerTab(
                        label: 'Video',
                        isSelected: _showVideo,
                        onTap: () {
                          setState(() {
                            _showVideo = true;
                          });
                        },
                      ),
                      const SizedBox(width: 28),
                      _PlayerTab(
                        label: 'Notes',
                        isSelected: !_showVideo,
                        onTap: () {
                          setState(() {
                            _showVideo = false;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(height: 1.5, color: const Color(0xFFC9CBE3)),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _ChipTag(
                        label: lesson.subjectLabel,
                        background: const Color(0xFFDCD9FF),
                        foreground: const Color(0xFF1F238B),
                      ),
                      _ChipTag(
                        label: lesson.chapterLabel,
                        background: const Color(0xFFE7E8EE),
                        foreground: const Color(0xFF4C4F5E),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    lesson.title,
                    style: const TextStyle(
                      color: Color(0xFF1D2231),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _showVideo ? lesson.description : lesson.notes,
                    style: const TextStyle(
                      color: Color(0xFF4C4F5E),
                      fontSize: 14,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 34),
                  const Row(
                    children: [
                      Icon(
                        Icons.attach_file_rounded,
                        color: Color(0xFF4C4F5E),
                        size: 28,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'LESSON RESOURCES',
                        style: TextStyle(
                          color: Color(0xFF4C4F5E),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  ...lesson.resources.map(
                    (resource) => Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _LessonResourceCard(resource: resource),
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

class _BoardSketchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final framePaint = Paint()..color = const Color(0xFF7B5A34);
    canvas.drawRect(Rect.fromLTWH(0, 0, 14, size.height), framePaint);
    canvas.drawRect(Rect.fromLTWH(size.width - 14, 0, 14, size.height), framePaint);

    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.15),
      Offset(size.width * 0.85, size.height * 0.15),
      linePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.28, size.height * 0.22),
      42,
      linePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.58, size.height * 0.18, 120, 52),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.60, size.height * 0.55),
      Offset(size.width * 0.72, size.height * 0.32),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.72, size.height * 0.32),
      Offset(size.width * 0.80, size.height * 0.70),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.72, size.height * 0.32),
      Offset(size.width * 0.89, size.height * 0.32),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PlayerTab extends StatelessWidget {
  const _PlayerTab({
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
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF4A4FD9)
                  : const Color(0xFF7A7D8E),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 70,
            height: 5,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF4A4FD9)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipTag extends StatelessWidget {
  const _ChipTag({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _LessonResourceCard extends StatelessWidget {
  const _LessonResourceCard({required this.resource});

  final LearnResourceModel resource;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFC8C7F1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD8DDF0).withValues(alpha: 0.26),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: resource.iconBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(resource.icon, color: resource.accent, size: 30),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource.title,
                  style: const TextStyle(
                    color: Color(0xFF1D2231),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  resource.meta,
                  style: const TextStyle(
                    color: Color(0xFF4C4F5E),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Get.snackbar(
                'Download Started',
                '${resource.title} is being downloaded.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.white,
                colorText: const Color(0xFF1D2231),
                margin: const EdgeInsets.all(14),
              );
            },
            icon: const Icon(
              Icons.download_rounded,
              color: Color(0xFF4A4FD9),
              size: 25,
            ),
          ),
        ],
      ),
    );
  }
}
