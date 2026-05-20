import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../chapter/views/learn_subject_views.dart';
import '../controller/learn_notes_controller.dart';
import 'learn_notes_discription_views.dart';

class LearnNotesViews extends StatefulWidget {
  const LearnNotesViews({super.key});

  @override
  State<LearnNotesViews> createState() => _LearnNotesViewsState();
}

class _LearnNotesViewsState extends State<LearnNotesViews> {
  String _selectedFilter = 'All Notes';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filteredNotes = LearnNotesRepository.notes.where((note) {
      final matchesFilter = _selectedFilter == 'All Notes' ||
          note.subject == _selectedFilter;
      final q = _query.trim().toLowerCase();
      final matchesQuery = q.isEmpty ||
          note.title.toLowerCase().contains(q) ||
          note.description.toLowerCase().contains(q) ||
          note.subject.toLowerCase().contains(q);
      return matchesFilter && matchesQuery;
    }).toList();

    final grouped = <String, List<LearnNoteModel>>{};
    for (final note in filteredNotes) {
      grouped.putIfAbsent(note.subject, () => []).add(note);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        child: Column(
          children: [
            const LearnTopBar(title: 'Notes'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 24),
                children: [
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        _query = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search notes, chapters, or topics...',
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
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: LearnNotesRepository.filters.map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedFilter = filter;
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF4A4FD9)
                                    : const Color(0xFFE6E7EC),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  if (filter == 'All Notes') ...[
                                    Icon(
                                      Icons.tune_rounded,
                                      size: 14,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF474B5F),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    filter,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF474B5F),
                                      fontSize: 11,
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
                  const SizedBox(height: 20),
                  ...grouped.entries.map(
                    (entry) => _NotesSection(
                      subject: entry.key,
                      fileLabel: entry.value.first.fileCountLabel,
                      notes: entry.value,
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

class _NotesSection extends StatelessWidget {
  const _NotesSection({
    required this.subject,
    required this.fileLabel,
    required this.notes,
  });

  final String subject;
  final String fileLabel;
  final List<LearnNoteModel> notes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subject,
                  style: const TextStyle(
                    color: Color(0xFF1D2231),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                fileLabel,
                style: const TextStyle(
                  color: Color(0xFF4A4FD9),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...notes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: switch (note.cardStyle) {
                LearnNoteCardStyle.simple => _SimpleNoteCard(note: note),
                LearnNoteCardStyle.featured => _FeaturedNoteCard(note: note),
                LearnNoteCardStyle.author => _AuthorNoteCard(note: note),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleNoteCard extends StatelessWidget {
  const _SimpleNoteCard({required this.note});

  final LearnNoteModel note;

  @override
  Widget build(BuildContext context) {
    final isPrimary = note.type == LearnNoteType.teacher;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFC8CBE2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD5DBEE).withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
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
              const Icon(
                Icons.download_for_offline_outlined,
                color: Color(0xFFC6C7DB),
              ),
            ],
          ),
          const SizedBox(height: 18),
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
            style: const TextStyle(
              color: Color(0xFF474C60),
              fontSize: 13,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SmallTag(label: note.chapterOrAuthor),
              _SmallTag(label: note.secondaryLabel),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  Get.to(() => LearnNotesDiscriptionViews(note: note)),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPrimary
                    ? const Color(0xFF4A4FD9)
                    : const Color(0xFFE0E3E8),
                foregroundColor:
                    isPrimary ? Colors.white : const Color(0xFF1D2231),
                elevation: 0,
                minimumSize: const Size.fromHeight(45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              icon: const Icon(Icons.remove_red_eye_outlined, size: 19),
              label: const Text(
                'View Notes',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedNoteCard extends StatelessWidget {
  const _FeaturedNoteCard({required this.note});

  final LearnNoteModel note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFC8CBE2)),
      ),
      child: Row(
        children: [
          Container(
            width: 120,
            height: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF153246), Color(0xFF0A1720)],
              ),
            ),
            child: CustomPaint(
              painter: _PhysicsBoardPainter(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
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
                const SizedBox(height: 16),
                Text(
                  note.title,
                  style: const TextStyle(
                    color: Color(0xFF1D2231),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  note.description,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF474C60),
                    fontSize: 12,
                    height: 1.8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Get.to(
                          () => LearnNotesDiscriptionViews(note: note),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A4FD9),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        icon: const Icon(Icons.menu_book_outlined, size: 15),
                        label: const Text(
                          'View PDF',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(35, 30),
                        side: const BorderSide(color: Color(0xFFC8CBE2)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: const Icon(
                        Icons.download_rounded,
                        color: Color(0xFF4A4FD9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorNoteCard extends StatelessWidget {
  const _AuthorNoteCard({required this.note});

  final LearnNoteModel note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFF7D31E2), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: note.tagColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  note.tag,
                  style: const TextStyle(
                    color: Color(0xFF3E124E),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                note.secondaryLabel,
                style: const TextStyle(
                  color: Color(0xFF6F7282),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
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
            style: const TextStyle(
              color: Color(0xFF474C60),
              fontSize: 12,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: const [
              CircleAvatar(
                radius: 15,
                backgroundColor: Color(0xFF4A4FD9),
                child: Text(
                  'AJ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Align(
                widthFactor: 0.8,
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: Color(0xFFA46A00),
                  child: Text(
                    'SK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Spacer(),
            ],
          ),
          const SizedBox(height: 0),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Get.to(() => LearnNotesDiscriptionViews(note: note)),
              child: const Text(
                'View ->',
                style: TextStyle(
                  color: Color(0xFF4A4FD9),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallTag extends StatelessWidget {
  const _SmallTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EAEE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF55596B),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PhysicsBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final panelPaint = Paint()..color = const Color(0xFF21506A);
    final accentPaint = Paint()
      ..color = const Color(0xFF57C7FF).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final glowPaint = Paint()..color = const Color(0xFF5FE2FF).withValues(alpha: 0.25);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(10, 22, 48, 74),
        const Radius.circular(6),
      ),
      panelPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(92, 18, 10, 84),
        const Radius.circular(6),
      ),
      panelPaint,
    );
    canvas.drawCircle(Offset(size.width * 0.63, 62), 14, glowPaint);
    canvas.drawCircle(Offset(size.width * 0.83, 78), 8, glowPaint);
    canvas.drawOval(Rect.fromLTWH(10, 38, 10, 34), accentPaint);
    canvas.drawRect(Rect.fromLTWH(10, 110, 10, 28), accentPaint);
    canvas.drawRect(Rect.fromLTWH(10, 118, 10, 24), accentPaint);
    canvas.drawLine(
      const Offset(20, 70),
      Offset(size.width - 20, 120),
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
