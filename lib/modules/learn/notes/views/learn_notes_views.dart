import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../chapter/controller/learn_chapter_controller.dart';
import '../../chapter/views/learn_subject_views.dart';
import 'learn_lesson_notes_views.dart';

/// Notes home. Loads ONLY the subject list on open (no notes API here).
/// Lessons for a subject are fetched lazily the first time it is expanded,
/// and notes for a lesson are fetched only when that lesson is opened. This
/// keeps `FETCH_NOTES_BY_LESSON` to a single call per opened lesson instead of
/// firing once per lesson of every subject on screen load.
class LearnNotesViews extends StatefulWidget {
  const LearnNotesViews({super.key});

  @override
  State<LearnNotesViews> createState() => _LearnNotesViewsState();
}

class _LearnNotesViewsState extends State<LearnNotesViews> {
  bool _isLoading = true;
  String _error = '';
  String _query = '';
  List<LearnSubjectModel> _subjects = const [];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final response = await LearnCatalogData.getUserSubjects();
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      if (response.success) {
        _subjects = response.data ?? const [];
      } else {
        _subjects = const [];
        _error = response.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final subjects = q.isEmpty
        ? _subjects
        : _subjects
              .where((subject) => subject.title.toLowerCase().contains(q))
              .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        child: Column(
          children: [
            const LearnTopBar(title: 'Notes'),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadSubjects,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 18, 14, 24),
                  children: [
                    TextField(
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        hintText: 'Search subjects...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF72788D),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF7D8092),
                          size: 20,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFC7CBE1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFC7CBE1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF4A4FD9),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (_isLoading)
                      const _NotesStateView(
                        icon: Icons.hourglass_empty_rounded,
                        title: 'Loading subjects...',
                        message: 'Please wait while your subjects are fetched.',
                      )
                    else if (_error.isNotEmpty)
                      _NotesStateView(
                        icon: Icons.error_outline_rounded,
                        title: 'Unable to load subjects',
                        message: _error,
                        actionLabel: 'Retry',
                        onAction: _loadSubjects,
                      )
                    else if (subjects.isEmpty)
                      const _NotesStateView(
                        icon: Icons.menu_book_outlined,
                        title: 'No subjects found',
                        message: 'No subjects are available right now.',
                      )
                    else
                      ...subjects.map(
                        (subject) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _SubjectNotesTile(subject: subject),
                        ),
                      ),
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

/// Expandable subject tile. Lessons are fetched the first time it is opened.
class _SubjectNotesTile extends StatefulWidget {
  const _SubjectNotesTile({required this.subject});

  final LearnSubjectModel subject;

  @override
  State<_SubjectNotesTile> createState() => _SubjectNotesTileState();
}

class _SubjectNotesTileState extends State<_SubjectNotesTile> {
  bool _expanded = false;
  bool _isLoading = false;
  bool _loaded = false;
  String _error = '';
  List<_LessonEntry> _lessons = const [];

  Future<void> _loadLessons() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final response = await LearnCatalogData.getUserLessons(
      subject: widget.subject,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _loaded = true;
      if (response.success) {
        final entries = <_LessonEntry>[];
        for (final chapter in response.data ?? const <LearnChapterModel>[]) {
          for (final topic in chapter.topics) {
            entries.add(
              _LessonEntry(id: topic.lesson.id, title: topic.lesson.title),
            );
          }
        }
        _lessons = entries;
      } else {
        _lessons = const [];
        _error = response.message;
      }
    });
  }

  void _toggle() {
    final willExpand = !_expanded;
    setState(() => _expanded = willExpand);
    if (willExpand && !_loaded && !_isLoading) {
      _loadLessons();
    }
  }

  @override
  Widget build(BuildContext context) {
    final subject = widget.subject;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC8CBE2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: subject.iconBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(subject.icon, color: subject.accent, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject.title,
                          style: const TextStyle(
                            color: Color(0xFF1D2231),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Class ${subject.classLevel}',
                          style: const TextStyle(
                            color: Color(0xFF72788D),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF4A4FD9),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _buildLessons(subject),
            ),
        ],
      ),
    );
  }

  Widget _buildLessons(LearnSubjectModel subject) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A4FD9)),
            ),
          ),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _error,
              style: const TextStyle(
                color: Color(0xFF9A2F2F),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadLessons,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_lessons.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No lessons available for this subject.',
          style: TextStyle(
            color: Color(0xFF72788D),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Column(
      children: _lessons
          .map(
            (lesson) => InkWell(
              onTap: () => Get.to(
                () => LearnLessonNotesViews(
                  subject: subject,
                  lessonId: lesson.id,
                  lessonTitle: lesson.title,
                ),
              ),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 18,
                      color: Color(0xFF4A4FD9),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        lesson.title,
                        style: const TextStyle(
                          color: Color(0xFF2A2F42),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFB4B8CC),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _LessonEntry {
  const _LessonEntry({required this.id, required this.title});

  final String id;
  final String title;
}

class _NotesStateView extends StatelessWidget {
  const _NotesStateView({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 260),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E4EC)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF4A4FD9), size: 34),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1D2231),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6F7588),
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A4FD9),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
