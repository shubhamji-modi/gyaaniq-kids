import 'package:flutter/material.dart';

import '../../chapter/views/learn_subject_views.dart';
import '../controller/learn_notes_controller.dart';

class LearnNotesDiscriptionViews extends StatelessWidget {
  const LearnNotesDiscriptionViews({super.key, required this.note});

  final LearnNoteModel note;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        child: Column(
          children: [
            const LearnTopBar(title: 'Notes'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 26),
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _MetaChip(
                        label: note.readTime,
                        background: const Color(0xFFDCD9FF),
                        foreground: const Color(0xFF3942D0),
                      ),
                      _MetaChip(
                        label: note.gradeLabel,
                        background: const Color(0xFFEED4FF),
                        foreground: const Color(0xFF7D31E2),
                      ),
                      _MetaChip(
                        label: note.statusLabel,
                        background: const Color(0xFFE3E5EA),
                        foreground: const Color(0xFF4E5366),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFE1E4EC)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD8DDF0).withValues(alpha: 0.22),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.detailTitle,
                          style: const TextStyle(
                            color: Color(0xFF1D2231),
                            fontSize: 16,
                            height: 1.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          note.detailParagraphs.first,
                          style: const TextStyle(
                            color: Color(0xFF43485A),
                            fontSize: 15,
                            height: 1.8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F8),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _NotesFigureCard(),
                              const SizedBox(height: 16),
                              Text(
                                note.figureCaption,
                                style: const TextStyle(
                                  color: Color(0xFF4A4E61),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          note.sectionHeading,
                          style: const TextStyle(
                            color: Color(0xFF1D2231),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...note.bulletPoints.map(
                          (point) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 11),
                                  child: Icon(
                                    Icons.circle,
                                    size: 8,
                                    color: Color(0xFF4A4FD9),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    point,
                                    style: const TextStyle(
                                      color: Color(0xFF4A4E61),
                                      fontSize: 14,
                                      height: 1.7,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8E8FF),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '3x + 5 = 14',
                                style: TextStyle(
                                  color: Color(0xFFB4B8FF),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                note.stepTitle,
                                style: const TextStyle(
                                  color: Color(0xFF3942D0),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          note.detailParagraphs.last,
                          style: const TextStyle(
                            color: Color(0xFF43485A),
                            fontSize: 15,
                            height: 1.8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 26),
                        Text(
                          note.secondSectionHeading,
                          style: const TextStyle(
                            color: Color(0xFF1D2231),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Imagine you are saving for a new video game that costs \$60. You already have \$15 and you earn \$5 a week in allowance. How many weeks until you can buy the game?',
                          style: const TextStyle(
                            color: Color(0xFF43485A),
                            fontSize: 15,
                            height: 1.8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF5E9),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFFFA31A)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(
                                  Icons.lightbulb_outline_rounded,
                                  color: Color(0xFFA46A00),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      note.calloutTitle,
                                      style: const TextStyle(
                                        color: Color(0xFF8B5A00),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      note.calloutEquation,
                                      style: const TextStyle(
                                        color: Color(0xFF1D2231),
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.w500,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NotesFigureCard extends StatelessWidget {
  const _NotesFigureCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D1923),
              Color(0xFF2A7395),
            ],
          ),
        ),
        child: Stack(
          children: const [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: SizedBox(
                width: 14,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Color(0xFF0B1016)),
                ),
              ),
            ),
            Positioned.fill(
              child: _MathBoardArtwork(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MathBoardArtwork extends StatelessWidget {
  const _MathBoardArtwork();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: 70,
              height: 2,
              color: const Color(0xFFFFA74A),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'x = 3i = 31 + 0',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFFFA74A),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFFFFA74A), width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
