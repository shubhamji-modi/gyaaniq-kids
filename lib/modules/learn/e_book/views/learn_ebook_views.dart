import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../chapter/views/learn_subject_views.dart';
import '../../common/subject_visual.dart';
import '../controller/learn_ebook_controller.dart';
import 'learn_ebook_discription_views.dart';

class LearnEbookViews extends StatefulWidget {
  const LearnEbookViews({super.key});

  @override
  State<LearnEbookViews> createState() => _LearnEbookViewsState();
}

class _LearnEbookViewsState extends State<LearnEbookViews> {
  String _selectedFilter = 'All Subject';
  String _query = '';
  bool _isLoading = true;
  String _error = '';
  List<LearnEbookModel> _books = const [];

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final response = await LearnEbookRepository.fetchStudentEbooks();
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      if (response.success) {
        _books = response.data ?? const [];
      } else {
        _books = const [];
        _error = response.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filters = <String>{
      'All Subject',
      ..._books.map((book) => book.filter).where((filter) => filter.isNotEmpty),
    }.toList();
    if (!filters.contains(_selectedFilter)) {
      _selectedFilter = 'All Subject';
    }

    final books = _books.where((book) {
      final filterMatch =
          _selectedFilter == 'All Subject' || book.filter == _selectedFilter;
      final q = _query.trim().toLowerCase();
      final queryMatch =
          q.isEmpty ||
          book.subject.toLowerCase().contains(q) ||
          book.title.toLowerCase().contains(q);
      return filterMatch && queryMatch;
    }).toList();

    // Group the (filtered) books by subject so each subject shows once.
    final grouped = <String, List<LearnEbookModel>>{};
    for (final book in books) {
      grouped.putIfAbsent(book.subject, () => []).add(book);
    }
    final groups = grouped.entries.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        child: Column(
          children: [
            const LearnTopBar(title: 'E-Books'),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadBooks,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 28),
                  children: [
                    TextField(
                      onChanged: (value) {
                        setState(() {
                          _query = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search textbooks...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF7B8092),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF7B8092),
                          size: 25,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFC8C7F1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFC8C7F1),
                          ),
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
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: filters.map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedFilter = filter;
                                });
                              },
                              borderRadius: BorderRadius.circular(22),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF4A4FD9)
                                      : const Color(0xFFE6E8ED),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Row(
                                  children: [
                                    if (filter == 'All Subject') ...[
                                      Icon(
                                        Icons.tune_rounded,
                                        size: 15,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF4C5164),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Text(
                                      filter,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF4C5164),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (_isLoading)
                      const _EbookStateView(
                        icon: Icons.hourglass_empty_rounded,
                        title: 'Loading e-books...',
                        message: 'Please wait while e-books are fetched.',
                      )
                    else if (_error.isNotEmpty)
                      _EbookStateView(
                        icon: Icons.error_outline_rounded,
                        title: 'Unable to load e-books',
                        message: _error,
                        actionLabel: 'Retry',
                        onAction: _loadBooks,
                      )
                    else if (groups.isEmpty)
                      const _EbookStateView(
                        icon: Icons.library_books_outlined,
                        title: 'No e-books found',
                        message: 'No active e-books are available right now.',
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: groups.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.74,
                            ),
                        itemBuilder: (context, index) {
                          final entry = groups[index];
                          return _SubjectGroupCard(
                            subject: entry.key,
                            books: entry.value,
                          );
                        },
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

class _EbookStateView extends StatelessWidget {
  const _EbookStateView({
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
      constraints: const BoxConstraints(minHeight: 280),
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

/// One card per subject. All e-books of that subject live behind it; tapping
/// opens a bottom sheet listing them (they are never shown as separate cards).
class _SubjectGroupCard extends StatelessWidget {
  const _SubjectGroupCard({required this.subject, required this.books});

  final String subject;
  final List<LearnEbookModel> books;

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD5D8E6),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  subject,
                  style: const TextStyle(
                    color: Color(0xFF1D2231),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${books.length} ${books.length == 1 ? ' E-book Available' : ' E-books Available'}',
                  style: const TextStyle(
                    color: Color(0xFF72788D),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: books.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final book = books[index];
                      return _EbookSheetTile(
                        book: book,
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          Get.to(() => LearnEbookDiscriptionViews(book: book));
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final visual = subjectVisualFor(subject);
    final count = books.length;

    return InkWell(
      onTap: () => _openSheet(context),
      borderRadius: BorderRadius.circular(26),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: visual.softBackground,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: visual.color.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Subject icon tile (same style as the Learn "My Subjects" cards).
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: visual.color,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: visual.color.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(visual.icon, color: Colors.white, size: 24),
                ),
                const Spacer(),
                // Count badge, top-right.
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: visual.color,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              subject,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF1D2231),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$count E-Book${count == 1 ? '' : 's'} Available',
              style: const TextStyle(
                color: Color(0xFF6F7588),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openSheet(context),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: visual.color.withValues(alpha: 0.14),
                  foregroundColor: visual.color,
                  minimumSize: const Size.fromHeight(42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                label: const Text(
                  'View',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EbookSheetTile extends StatelessWidget {
  const _EbookSheetTile({required this.book, required this.onTap});

  final LearnEbookModel book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = book.resourceCount;
    final visual = subjectVisualFor(book.subject);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDDE0EE)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: visual.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(visual.icon, color: visual.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title.replaceAll('\n', ' '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1D2231),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '$count ${count == 1 ? 'file' : 'files'}',
                      style: const TextStyle(
                        color: Color(0xFF72788D),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFB4B8CC)),
          ],
        ),
      ),
    );
  }
}
