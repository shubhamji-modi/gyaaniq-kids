import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../chapter/controller/learn_chapter_controller.dart';
import '../../chapter/views/learn_subject_views.dart';
import '../controller/learn_notes_controller.dart';
import 'learn_notes_discription_views.dart';

/// Shows the notes for ONE lesson with pagination. Fetches page 1 on open and
/// loads further pages lazily as the user scrolls, so `FETCH_NOTES_BY_LESSON`
/// is only called when the user actually needs more rows.
class LearnLessonNotesViews extends StatefulWidget {
  const LearnLessonNotesViews({
    super.key,
    required this.subject,
    required this.lessonId,
    required this.lessonTitle,
  });

  final LearnSubjectModel subject;
  final String lessonId;
  final String lessonTitle;

  @override
  State<LearnLessonNotesViews> createState() => _LearnLessonNotesViewsState();
}

class _LearnLessonNotesViewsState extends State<LearnLessonNotesViews> {
  static const int _pageSize = 10;

  final ScrollController _scrollController = ScrollController();
  final List<LearnNoteModel> _notes = [];

  bool _isLoading = true; // first page
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _page = 0;
  int _total = 0;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore || _isLoading) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      _loadNextPage();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final response = await LearnNotesRepository.fetchNotesByLesson(
      lessonId: widget.lessonId,
      fallbackSubject: widget.subject,
      fallbackLessonTitle: widget.lessonTitle,
      page: 1,
      limit: _pageSize,
    );
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (response.success && response.data != null) {
        final page = response.data!;
        _notes
          ..clear()
          ..addAll(page.notes);
        _page = page.page;
        _total = page.total;
        _hasMore = page.hasMore;
      } else {
        _notes.clear();
        _error = response.message;
        _hasMore = false;
      }
    });
  }

  Future<void> _loadNextPage() async {
    setState(() => _isLoadingMore = true);

    final response = await LearnNotesRepository.fetchNotesByLesson(
      lessonId: widget.lessonId,
      fallbackSubject: widget.subject,
      fallbackLessonTitle: widget.lessonTitle,
      page: _page + 1,
      limit: _pageSize,
    );
    if (!mounted) return;

    setState(() {
      _isLoadingMore = false;
      if (response.success && response.data != null) {
        final page = response.data!;
        _notes.addAll(page.notes);
        _page = page.page;
        _total = page.total;
        _hasMore = page.hasMore;
      } else {
        // Stop paginating on error; keep what we already have.
        _hasMore = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        child: Column(
          children: [
            LearnTopBar(title: widget.lessonTitle),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadFirstPage,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        children: const [
          SizedBox(height: 40),
          _LessonNotesStateView(
            icon: Icons.hourglass_empty_rounded,
            title: 'Loading notes...',
            message: 'Fetching notes for this lesson.',
          ),
        ],
      );
    }

    if (_error.isNotEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 40),
          _LessonNotesStateView(
            icon: Icons.error_outline_rounded,
            title: 'Unable to load notes',
            message: _error,
            actionLabel: 'Retry',
            onAction: _loadFirstPage,
          ),
        ],
      );
    }

    if (_notes.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 40),
          _LessonNotesStateView(
            icon: Icons.note_alt_outlined,
            title: 'No notes yet',
            message: 'No notes have been shared for this lesson.',
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      // notes + a header + a trailing loader/footer.
      itemCount: _notes.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '$_total ${_total == 1 ? 'note' : 'notes'} in this lesson',
              style: const TextStyle(
                color: Color(0xFF4A4E61),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }

        if (index == _notes.length + 1) {
          if (_isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF4A4FD9),
                    ),
                  ),
                ),
              ),
            );
          }
          if (!_hasMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  'No more notes',
                  style: TextStyle(
                    color: Color(0xFF9AA0B4),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }
          return const SizedBox(height: 8);
        }

        final note = _notes[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _LessonNoteCard(note: note),
        );
      },
    );
  }
}

class _LessonNoteCard extends StatelessWidget {
  const _LessonNoteCard({required this.note});

  final LearnNoteModel note;

  @override
  Widget build(BuildContext context) {
    final count = note.resourceCount;
    final hasPdf = note.documentResources.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFC8CBE2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: note.tagColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  note.tag,
                  style: const TextStyle(
                    color: Color(0xFF3E2A12),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              // Dynamic attachment count. Hidden entirely when there are no
              // files so the card never shows "0 Files".
              if (count > 0)
                Text(
                  '$count ${count == 1 ? 'File' : 'Files'}',
                  style: const TextStyle(
                    color: Color(0xFF4A4FD9),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            note.title,
            style: const TextStyle(
              color: Color(0xFF1D2231),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            note.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF474C60),
              fontSize: 13,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  Get.to(() => LearnNotesDiscriptionViews(note: note)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A4FD9),
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size.fromHeight(45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              icon: Icon(
                hasPdf
                    ? Icons.picture_as_pdf_outlined
                    : Icons.remove_red_eye_outlined,
                size: 19,
              ),
              label: const Text(
                'Read Now',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonNotesStateView extends StatelessWidget {
  const _LessonNotesStateView({
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      constraints: const BoxConstraints(minHeight: 240),
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
