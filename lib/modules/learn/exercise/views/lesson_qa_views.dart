import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../chapter/views/learn_subject_views.dart';
import '../controller/lesson_qa_controller.dart';
import 'lesson_qa_search_views.dart';

/// Exercise screen: renders a lesson's Q&A pairs as a horizontal "book" slider —
/// one question per page. Swipe left/right to move between questions; tap a page
/// to reveal its answer. Questions arrive sequentially from the server with
/// pagination, and the next page is prefetched as the student swipes.
class LessonQaViews extends StatefulWidget {
  const LessonQaViews({
    super.key,
    required this.lessonId,
    this.lessonTitle = '',
    this.accent = const Color(0xFF4A4FD9),
  });

  final String lessonId;
  final String lessonTitle;
  final Color accent;

  @override
  State<LessonQaViews> createState() => _LessonQaViewsState();
}

class _LessonQaViewsState extends State<LessonQaViews> {
  late final LessonQaController controller;
  final PageController _pageController = PageController();
  late final String _tag;

  @override
  void initState() {
    super.initState();
    _tag = 'lesson_qa_${widget.lessonId}';
    controller = Get.put(
      LessonQaController(
        lessonId: widget.lessonId,
        lessonTitle: widget.lessonTitle,
      ),
      tag: _tag,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    Get.delete<LessonQaController>(tag: _tag);
    super.dispose();
  }

  void _goToPage(int index) {
    if (index < 0 || index >= controller.rows.length) {
      return;
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        child: Column(
          children: [
            LearnTopBar(
              title: 'Exercise',
              trailing: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => Get.to(
                  () => LessonQaSearchViews(
                    lessonId: widget.lessonId,
                    scopeTitle: controller.resolvedLessonTitle.value.isEmpty
                        ? widget.lessonTitle
                        : controller.resolvedLessonTitle.value,
                    accent: widget.accent,
                  ),
                ),
                icon: Icon(
                  Icons.search_rounded,
                  color: widget.accent,
                  size: 24,
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.errorMessage.value.isNotEmpty &&
                    controller.rows.isEmpty) {
                  return _ExerciseMessage(
                    icon: Icons.error_outline_rounded,
                    title: 'Unable to load exercise',
                    message: controller.errorMessage.value,
                    onRetry: controller.refreshQa,
                  );
                }

                if (controller.rows.isEmpty) {
                  return _ExerciseMessage(
                    icon: Icons.menu_book_outlined,
                    title: 'No exercise yet',
                    message:
                        'Questions for this lesson will appear here once they are added.',
                    onRetry: controller.refreshQa,
                  );
                }

                final title = controller.resolvedLessonTitle.value.isEmpty
                    ? widget.lessonTitle
                    : controller.resolvedLessonTitle.value;

                return Column(
                  children: [
                    _BookHeader(title: title, accent: widget.accent),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: controller.setCurrentPage,
                        itemCount: controller.rows.length,
                        itemBuilder: (context, index) {
                          return _QaPage(
                            controller: controller,
                            item: controller.rows[index],
                            accent: widget.accent,
                          );
                        },
                      ),
                    ),
                    _BookNavBar(
                      controller: controller,
                      accent: widget.accent,
                      onPrev: () =>
                          _goToPage(controller.currentPage.value - 1),
                      onNext: () =>
                          _goToPage(controller.currentPage.value + 1),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookHeader extends StatelessWidget {
  const _BookHeader({required this.title, required this.accent});

  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EXERCISE',
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title.isEmpty ? 'Lesson Q&A' : title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF1D2231),
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single "page" of the book — one question with a tap-to-reveal answer.
class _QaPage extends StatelessWidget {
  const _QaPage({
    required this.controller,
    required this.item,
    required this.accent,
  });

  final LessonQaController controller;
  final LessonQaItem item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE1E4EE)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1D2231).withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${item.sequence}',
                      style: TextStyle(
                        color: accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Question ${item.sequence}',
                    style: const TextStyle(
                      color: Color(0xFF6B7080),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: item.isPdf
                          ? const Color(0xFFEDEBFF)
                          : const Color(0xFFE3F6EC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      item.sourceLabel,
                      style: TextStyle(
                        color: item.isPdf
                            ? const Color(0xFF5A3FE0)
                            : const Color(0xFF17935F),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.question,
                      style: const TextStyle(
                        color: Color(0xFF1D2231),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Divider(height: 1, color: Color(0xFFEDEFF4)),
                    const SizedBox(height: 18),
                    Obx(() {
                      final revealed = controller.isRevealed(item.id);
                      if (!revealed) {
                        return _RevealButton(
                          accent: accent,
                          onTap: () => controller.toggleRevealed(item.id),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ANSWER',
                            style: TextStyle(
                              color: accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.answer.isEmpty
                                ? 'Answer will be available soon.'
                                : item.answer,
                            style: const TextStyle(
                              color: Color(0xFF43485A),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: () => controller.toggleRevealed(item.id),
                            child: Text(
                              'Hide answer',
                              style: TextStyle(
                                color: accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevealButton extends StatelessWidget {
  const _RevealButton({required this.accent, required this.onTap});

  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.visibility_outlined, color: accent, size: 19),
              const SizedBox(width: 8),
              Text(
                'Show Answer',
                style: TextStyle(
                  color: accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom bar: prev / next chevrons, page counter, and a slim progress bar so
/// the slider reads like flipping through a book.
class _BookNavBar extends StatelessWidget {
  const _BookNavBar({
    required this.controller,
    required this.accent,
    required this.onPrev,
    required this.onNext,
  });

  final LessonQaController controller;
  final Color accent;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loaded = controller.rows.length;
      final total = controller.totalCount.value > 0
          ? controller.totalCount.value
          : loaded;
      final current = controller.currentPage.value;
      final canPrev = current > 0;
      final canNext = current < loaded - 1;
      final progress = total == 0 ? 0.0 : (current + 1) / total;

      return Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE7EAF4))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: const Color(0xFFE4E7EE),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _NavArrow(
                  icon: Icons.arrow_back_rounded,
                  accent: accent,
                  enabled: canPrev,
                  onTap: onPrev,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      controller.isLoadingMore.value && !canNext
                          ? 'Loading…'
                          : 'Question ${current + 1} of $total',
                      style: const TextStyle(
                        color: Color(0xFF43485A),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                _NavArrow(
                  icon: Icons.arrow_forward_rounded,
                  accent: accent,
                  enabled: canNext,
                  onTap: onNext,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({
    required this.icon,
    required this.accent,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled
                ? accent.withValues(alpha: 0.10)
                : const Color(0xFFF0F2F6),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: enabled ? accent : const Color(0xFFB7BCC8),
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _ExerciseMessage extends StatelessWidget {
  const _ExerciseMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(30, 90, 30, 30),
      children: [
        Icon(icon, color: const Color(0xFF9AA0B0), size: 54),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF1D2231),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF6B7080),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4A4FD9),
              side: const BorderSide(color: Color(0xFF4A4FD9)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}
