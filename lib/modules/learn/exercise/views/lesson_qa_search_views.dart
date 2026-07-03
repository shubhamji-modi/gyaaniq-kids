import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/lesson_qa_controller.dart';
import '../controller/lesson_qa_search_controller.dart';
import 'lesson_qa_views.dart';

/// Q&A search screen. Reused for both entry points:
/// - Exercise search (pass [lessonId]) — restricted to one lesson.
/// - Chapter search (pass [subjectId] + [classLevel]) — subject-wide, grouped
///   by lesson with a deep-link into each lesson's exercise.
class LessonQaSearchViews extends StatefulWidget {
  const LessonQaSearchViews({
    super.key,
    this.lessonId,
    this.subjectId,
    this.classLevel,
    this.scopeTitle = '',
    this.accent = const Color(0xFF4A4FD9),
  });

  final String? lessonId;
  final String? subjectId;
  final String? classLevel;
  final String scopeTitle;
  final Color accent;

  @override
  State<LessonQaSearchViews> createState() => _LessonQaSearchViewsState();
}

class _LessonQaSearchViewsState extends State<LessonQaSearchViews> {
  late final LessonQaSearchController controller;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  late final String _tag;

  @override
  void initState() {
    super.initState();
    _tag =
        'lesson_qa_search_${widget.lessonId ?? widget.subjectId ?? 'global'}';
    controller = Get.put(
      LessonQaSearchController(
        lessonId: widget.lessonId,
        subjectId: widget.subjectId,
        classLevel: widget.classLevel,
      ),
      tag: _tag,
    );
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 260) {
      controller.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _textController.dispose();
    Get.delete<LessonQaSearchController>(tag: _tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hint = widget.scopeTitle.isEmpty
        ? 'Search questions & answers'
        : 'Search in ${widget.scopeTitle}';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        child: Column(
          children: [
            _SearchBar(
              controller: _textController,
              hint: hint,
              accent: widget.accent,
              onChanged: controller.onQueryInput,
              onClear: () {
                _textController.clear();
                controller.clearQuery();
              },
            ),
            Expanded(
              child: Obx(() {
                if (!controller.hasSearched.value) {
                  return const _SearchHint(
                    icon: Icons.search_rounded,
                    title: 'Search Q&A',
                    message:
                        'Type at least 2 characters to search across questions and answers.',
                  );
                }

                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.errorMessage.value.isNotEmpty &&
                    controller.rows.isEmpty) {
                  return _SearchHint(
                    icon: Icons.error_outline_rounded,
                    title: 'Search failed',
                    message: controller.errorMessage.value,
                    onRetry: controller.retry,
                  );
                }

                if (controller.rows.isEmpty) {
                  return _SearchHint(
                    icon: Icons.search_off_rounded,
                    title: 'No results',
                    message:
                        'No questions or answers matched "${controller.query.value.trim()}".',
                  );
                }

                final groups = controller.groupedRows;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),
                  itemCount: groups.length + 1,
                  itemBuilder: (context, index) {
                    if (index == groups.length) {
                      return _SearchFooter(
                        isLoadingMore: controller.isLoadingMore.value,
                        hasMore: controller.hasMore,
                        total: controller.total.value,
                        accent: widget.accent,
                      );
                    }
                    return _SearchGroup(
                      group: groups[index],
                      controller: controller,
                      accent: widget.accent,
                      showHeader: !controller.isSingleLesson,
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.hint,
    required this.accent,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final Color accent;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 14, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE7EAF4))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF103383),
              size: 20,
            ),
          ),
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE1E4EE)),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onChanged: onChanged,
                      cursorColor: accent,
                      style: const TextStyle(
                        color: Color(0xFF1D2231),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: hint,
                        hintStyle: const TextStyle(
                          color: Color(0xFF9AA0B0),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, _) {
                      if (value.text.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return GestureDetector(
                        onTap: onClear,
                        child: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF9AA0B0),
                          size: 19,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchGroup extends StatelessWidget {
  const _SearchGroup({
    required this.group,
    required this.controller,
    required this.accent,
    required this.showHeader,
  });

  final LessonQaSearchGroup group;
  final LessonQaSearchController controller;
  final Color accent;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader && group.lessonTitle.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 8, 2, 10),
            child: Row(
              children: [
                Icon(Icons.menu_book_rounded, color: accent, size: 17),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.lessonTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1D2231),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (group.lessonId.isNotEmpty)
                  GestureDetector(
                    onTap: () => Get.to(
                      () => LessonQaViews(
                        lessonId: group.lessonId,
                        lessonTitle: group.lessonTitle,
                        accent: accent,
                      ),
                    ),
                    child: Text(
                      'See all',
                      style: TextStyle(
                        color: accent,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        ...group.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SearchResultCard(
              item: item,
              controller: controller,
              accent: accent,
            ),
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.item,
    required this.controller,
    required this.accent,
  });

  final LessonQaItem item;
  final LessonQaSearchController controller;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final expanded = controller.isExpanded(item.id);
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: expanded ? accent : const Color(0xFFE1E4EE),
            width: expanded ? 1.5 : 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => controller.toggleExpanded(item.id),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        item.isPdf
                            ? Icons.menu_book_rounded
                            : Icons.person_outline_rounded,
                        color: item.isPdf
                            ? const Color(0xFF5A3FE0)
                            : const Color(0xFF17935F),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.question,
                          maxLines: expanded ? null : 2,
                          overflow: expanded ? null : TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF1D2231),
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 160),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: expanded ? accent : const Color(0xFF9AA0B0),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.answer.isEmpty
                        ? 'Answer will be available soon.'
                        : item.answer,
                    maxLines: expanded ? null : 2,
                    overflow: expanded ? null : TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF5C6070),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _SearchFooter extends StatelessWidget {
  const _SearchFooter({
    required this.isLoadingMore,
    required this.hasMore,
    required this.total,
    required this.accent,
  });

  final bool isLoadingMore;
  final bool hasMore;
  final int total;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.6, color: accent),
          ),
        ),
      );
    }

    if (!hasMore && total > 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 4),
        child: Center(
          child: Text(
            '$total result${total == 1 ? '' : 's'}',
            style: const TextStyle(
              color: Color(0xFF9AA0B0),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return const SizedBox(height: 4);
  }
}

class _SearchHint extends StatelessWidget {
  const _SearchHint({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(30, 80, 30, 30),
      children: [
        Icon(icon, color: const Color(0xFF9AA0B0), size: 52),
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
        if (onRetry != null) ...[
          const SizedBox(height: 20),
          Center(
            child: OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4A4FD9),
                side: const BorderSide(color: Color(0xFF4A4FD9)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
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
      ],
    );
  }
}
