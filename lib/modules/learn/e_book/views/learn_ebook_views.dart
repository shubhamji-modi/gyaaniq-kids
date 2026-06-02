import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../chapter/views/learn_subject_views.dart';
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
                    else if (books.isEmpty)
                      const _EbookStateView(
                        icon: Icons.library_books_outlined,
                        title: 'No e-books found',
                        message: 'No active e-books are available right now.',
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: books.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.56,
                            ),
                        itemBuilder: (context, index) {
                          return _EbookCard(book: books[index]);
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

class _EbookCard extends StatelessWidget {
  const _EbookCard({required this.book});

  final LearnEbookModel book;

  @override
  Widget build(BuildContext context) {
    final accentLight = Color.lerp(book.accent, Colors.white, 0.78)!;
    final accentSoft = Color.lerp(book.accent, Colors.white, 0.9)!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accentSoft, Colors.white],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC8C7F1)),
        boxShadow: [
          BoxShadow(
            color: book.accent.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [accentLight, Colors.white],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -18,
                    right: -6,
                    child: Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: book.accent.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -12,
                    bottom: -24,
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.9,
                      child: _EbookCoverArt(style: book.coverStyle),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Container(
                      height: 34,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.82),
                            Colors.white.withValues(alpha: 0.28),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            book.subject,
            style: TextStyle(
              color: book.accent,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF1D2231),
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  Get.to(() => LearnEbookDiscriptionViews(book: book)),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFFE4E7EC),
                foregroundColor: const Color(0xFF4A4FD9),
                minimumSize: const Size.fromHeight(40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: const Text(
                'Read Now',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EbookCoverArt extends StatelessWidget {
  const _EbookCoverArt({required this.style});

  final LearnEbookCoverStyle style;

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case LearnEbookCoverStyle.math:
        return CustomPaint(painter: _MathBookPainter());
      case LearnEbookCoverStyle.chemistry:
        return CustomPaint(painter: _ChemistryBookPainter());
      case LearnEbookCoverStyle.history:
        return CustomPaint(painter: _HistoryBookPainter());
      case LearnEbookCoverStyle.english:
        return CustomPaint(painter: _EnglishBookPainter());
      case LearnEbookCoverStyle.biology:
        return CustomPaint(painter: _BiologyBookPainter());
    }
  }
}

class _MathBookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF9A86A8), Color(0xFFD5C1E2)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final orange = Paint()..color = const Color(0xFFFF8E1B);
    final purple = Paint()
      ..color = const Color(0xFFBA85D8).withValues(alpha: 0.8);
    canvas.drawCircle(
      Offset(size.width * 0.14, size.height * 0.55),
      34,
      orange,
    );
    canvas.drawCircle(
      Offset(size.width * 0.76, size.height * 0.45),
      32,
      orange,
    );
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.66),
      18,
      purple,
    );

    final bookRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.24,
        size.height * 0.16,
        size.width * 0.48,
        size.height * 0.66,
      ),
      const Radius.circular(12),
    );
    canvas.drawRRect(bookRect, orange);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.275,
        size.height * 0.16,
        6,
        size.height * 0.66,
      ),
      Paint()..color = const Color(0xFFFFB14D),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChemistryBookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF6A418A), Color(0xFF191325)],
      ).createShader(Offset(size.width * 0.5, size.height * 0.48) & size);
    canvas.drawRect(Offset.zero & size, bg);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.16,
          size.height * 0.1,
          size.width * 0.68,
          size.height * 0.78,
        ),
        const Radius.circular(10),
      ),
      Paint()..color = const Color(0xFF11131B),
    );
    canvas.drawCircle(
      Offset(size.width * 0.56, size.height * 0.28),
      12,
      Paint()..color = const Color(0xFFF2A5FF),
    );
    final atom = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.57, size.height * 0.28),
        width: 70,
        height: 28,
      ),
      atom,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.57, size.height * 0.28),
        width: 30,
        height: 72,
      ),
      atom,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HistoryBookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF1B3C36), Color(0xFF071113)],
      ).createShader(Offset(size.width * 0.5, size.height * 0.45) & size);
    canvas.drawRect(Offset.zero & size, bg);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.18,
          size.height * 0.18,
          size.width * 0.48,
          size.height * 0.52,
        ),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFF1E8A8E),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.28,
        size.height * 0.28,
        size.width * 0.26,
        size.height * 0.12,
      ),
      Paint()..color = const Color(0xFFE6C384),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EnglishBookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF5F7682), Color(0xFFF4FAFF)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);
    final feather = Paint()..color = const Color(0xFFF6FDFF);
    final path = Path()
      ..moveTo(size.width * 0.75, size.height * 0.08)
      ..quadraticBezierTo(
        size.width * 0.62,
        size.height * 0.38,
        size.width * 0.5,
        size.height * 0.78,
      )
      ..quadraticBezierTo(
        size.width * 0.67,
        size.height * 0.46,
        size.width * 0.88,
        size.height * 0.08,
      )
      ..close();
    canvas.drawPath(path, feather);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BiologyBookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFB2D6FF), Color(0xFFEEF7FF)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.46),
      size.width * 0.28,
      Paint()..color = const Color(0xFFA6B0FF),
    );
    canvas.drawCircle(
      Offset(size.width * 0.52, size.height * 0.44),
      size.width * 0.18,
      Paint()..color = const Color(0xFF6D78E7),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.38, size.height * 0.58),
        width: 58,
        height: 24,
      ),
      Paint()..color = const Color(0xFFF1B8E8),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
