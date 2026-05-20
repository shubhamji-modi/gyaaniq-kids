import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'my_course_data.dart';
import 'my_course_details_views.dart';

class MyCourseSubjectViews extends StatefulWidget {
  const MyCourseSubjectViews({super.key, required this.course});

  final MyCourseModel course;

  @override
  State<MyCourseSubjectViews> createState() => _MyCourseSubjectViewsState();
}

class _MyCourseSubjectViewsState extends State<MyCourseSubjectViews> {
  late final Set<String> _expandedModules;

  @override
  void initState() {
    super.initState();
    _expandedModules = widget.course.modules
        .where((module) => module.expandedByDefault)
        .map((module) => module.id)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        child: Column(
          children: [
            const _TopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                children: [
                  _CourseOverviewCard(course: widget.course),
                  const SizedBox(height: 22),
                  ...widget.course.modules.map(
                    (module) => Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _ModuleCard(
                        course: widget.course,
                        module: module,
                        expanded: _expandedModules.contains(module.id),
                        onToggle: () {
                          setState(() {
                            if (_expandedModules.contains(module.id)) {
                              _expandedModules.remove(module.id);
                            } else {
                              _expandedModules.add(module.id);
                            }
                          });
                        },
                        onLessonTap: (lesson) async {
                          final state = MyCourseRepository.lessonState(
                            widget.course,
                            module,
                            lesson,
                          );

                          if (state == LessonProgressState.locked) {
                            Get.snackbar(
                              'Lesson Locked',
                              'Pehle previous lesson complete karke is topic ko unlock karein.',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.white,
                              colorText: const Color(0xFF1A1D27),
                              margin: const EdgeInsets.all(12),
                            );
                            return;
                          }

                          MyCourseRepository.markLessonViewed(
                            widget.course.id,
                            lesson.id,
                          );

                          await Get.to(
                            () => MyCourseDetailsViews(
                              course: widget.course,
                              module: module,
                              lesson: lesson,
                            ),
                          );

                          if (mounted) {
                            setState(() {});
                          }
                        },
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

class _CourseOverviewCard extends StatelessWidget {
  const _CourseOverviewCard({required this.course});

  final MyCourseModel course;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFD7DAF6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF68769B).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _Badge(
                label: course.subject,
                color: course.subject == 'English'
                    ? const Color(0xFFFFB126)
                    : course.accentColor,
                textColor: Colors.white,
              ),
              _Badge(
                label: '${(course.progress * 100).round()}% Complete',
                color: const Color(0xFFF0F2FB),
                textColor: const Color(0xFF4B4E60),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            course.title,
            style: const TextStyle(
              color: Color(0xFF1A1D27),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${course.completedLessons}/${course.totalLessons} lessons • ${course.teacher}',
            style: const TextStyle(
              color: Color(0xFF737789),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            widgetText(course),
            style: const TextStyle(
              color: Color(0xFF4A4E60),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }

  String widgetText(MyCourseModel course) {
    if (course.id == 'science') {
      return 'Explore core biology concepts with structured lessons, visual explanations, and practice-based understanding.';
    }
    if (course.id == 'english') {
      return 'Read modern texts with confidence and learn how themes, tone, and imagery shape strong literary interpretation.';
    }
    return 'Master the complexities of quadratic functions, logarithmic logic, and abstract reasoning through interactive problem-solving.';
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.course,
    required this.module,
    required this.expanded,
    required this.onToggle,
    required this.onLessonTap,
  });

  final MyCourseModel course;
  final CourseModuleModel module;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<CourseLessonModel> onLessonTap;

  @override
  Widget build(BuildContext context) {
    final completedCount = module.lessons
        .where(
          (lesson) =>
              MyCourseRepository.isLessonCompleted(course.id, lesson.id),
        )
        .length;

    final borderColor = expanded ? course.accentColor : const Color(0xFFE1E4ED);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: borderColor, width: expanded ? 1.6 : 1),
        boxShadow: [
          BoxShadow(
            color: course.accentColor.withValues(alpha: expanded ? 0.10 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Row(
                children: [
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: completedCount == module.lessons.length
                          ? const Color(0xFFDCF7E5)
                          : course.accentColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${module.index}',
                      style: TextStyle(
                        color: completedCount == module.lessons.length
                            ? const Color(0xFF148340)
                            : course.accentColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          module.title,
                          style: const TextStyle(
                            color: Color(0xFF1A1D27),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '$completedCount/${module.lessons.length} Lessons • ${module.description}',
                          style: TextStyle(
                            color: expanded
                                ? course.accentColor
                                : const Color(0xFF7E8193),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: course.accentColor,
                    size: 30,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1, color: Color(0xFFE3E6F3)),
            ...module.lessons.map(
              (lesson) => _LessonTile(
                course: course,
                module: module,
                lesson: lesson,
                onTap: () => onLessonTap(lesson),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.course,
    required this.module,
    required this.lesson,
    required this.onTap,
  });

  final MyCourseModel course;
  final CourseModuleModel module;
  final CourseLessonModel lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final state = MyCourseRepository.lessonState(course, module, lesson);
    final isCurrent = state == LessonProgressState.inProgress;
    final isCompleted = state == LessonProgressState.completed;
    final isLocked = state == LessonProgressState.locked;
    final canResume = MyCourseRepository.showResume(course, lesson);

    final backgroundColor = isCurrent ? course.accentColor : Colors.transparent;

    final titleColor = isCurrent
        ? Colors.white
        : isLocked
        ? const Color(0xFF8C8FA0)
        : const Color(0xFF1A1D27);

    final subtitle = isCompleted
        ? '${lesson.durationMinutes} min • Completed'
        : isLocked
        ? '${lesson.durationMinutes} min • Locked'
        : canResume
        ? '${lesson.durationMinutes} min • Continue Learning'
        : '${lesson.durationMinutes} min • Start Lesson';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: EdgeInsets.fromLTRB(12, 12, 12, isCurrent ? 12 : 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 33,
              height: 33,
              decoration: BoxDecoration(
                color: _iconBackground(isCompleted, isLocked, isCurrent),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _iconData(isCompleted, isLocked, isCurrent),
                color: _iconColor(isCompleted, isLocked, isCurrent),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isCurrent
                          ? Colors.white.withValues(alpha: 0.92)
                          : const Color(0xFF828397),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (canResume)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Resume',
                  style: TextStyle(
                    color: course.accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _iconBackground(bool isCompleted, bool isLocked, bool isCurrent) {
    if (isCompleted) {
      return const Color(0xFFD8F9E2);
    }
    if (isLocked) {
      return const Color(0xFFF0F1F4);
    }
    if (isCurrent) {
      return Colors.white.withValues(alpha: 0.20);
    }
    return course.accentColor.withValues(alpha: 0.14);
  }

  Color _iconColor(bool isCompleted, bool isLocked, bool isCurrent) {
    if (isCompleted) {
      return const Color(0xFF168A43);
    }
    if (isLocked) {
      return const Color(0xFFB0B2BF);
    }
    if (isCurrent) {
      return Colors.white;
    }
    return course.accentColor;
  }

  IconData _iconData(bool isCompleted, bool isLocked, bool isCurrent) {
    if (isCompleted) {
      return Icons.check_circle;
    }
    if (isLocked) {
      return Icons.lock_outline_rounded;
    }
    if (isCurrent) {
      return Icons.play_circle_outline_rounded;
    }
    return Icons.play_arrow_rounded;
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
