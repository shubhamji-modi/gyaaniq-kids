import 'package:flutter/material.dart';

import '../../chapter/views/learn_subject_views.dart';
import '../controller/learn_ebook_controller.dart';

class LearnEbookDiscriptionViews extends StatelessWidget {
  const LearnEbookDiscriptionViews({super.key, required this.book});

  final LearnEbookModel book;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        child: Column(
          children: [
            const LearnTopBar(title: 'E-Books'),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECD8FF),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            book.detailLabel,
                            style: const TextStyle(
                              color: Color(0xFF5B2390),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          book.detailTitle,
                          style: const TextStyle(
                            color: Color(0xFF4A4FD9),
                            fontSize: 16,
                            height: 1.45,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: const Color(0xFFC8C7F1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.detailParagraphs[0],
                                style: const TextStyle(
                                  color: Color(0xFF1D2231),
                                  fontSize: 15,
                                  height: 1.75,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 22),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: SizedBox(
                                  height: 180,
                                  width: double.infinity,
                                  child: _DetailIllustration(style: book.coverStyle),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Figure 1.1: Architecture of a mitochondrion showing layered internal structure.',
                                style: const TextStyle(
                                  color: Color(0xFF4A4E61),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 22),
                              Text(
                                book.detailParagraphs[1],
                                style: const TextStyle(
                                  color: Color(0xFF1D2231),
                                  fontSize: 15,
                                  height: 1.75,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 22),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD7A8),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF8A5A00),
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            book.quickFactTitle,
                                            style: const TextStyle(
                                              color: Color(0xFF412600),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            book.quickFact,
                                            style: const TextStyle(
                                              color: Color(0xFF412600),
                                              fontSize: 14,
                                              height: 1.7,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                book.detailParagraphs[2],
                                style: const TextStyle(
                                  color: Color(0xFF1D2231),
                                  fontSize: 15,
                                  height: 1.75,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    color: const Color(0xFFF7F8FD),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              book.pageText,
                              style: const TextStyle(
                                color: Color(0xFF4A4E61),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              book.progressText,
                              style: const TextStyle(
                                color: Color(0xFF4A4FD9),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: book.progress,
                            minHeight: 8,
                            backgroundColor: const Color(0xFFD9DCE4),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF4A4FD9),
                            ),
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

class _DetailIllustration extends StatelessWidget {
  const _DetailIllustration({required this.style});

  final LearnEbookCoverStyle style;

  @override
  Widget build(BuildContext context) {
    if (style == LearnEbookCoverStyle.biology) {
      return CustomPaint(painter: _MitochondriaPainter());
    }

    return CustomPaint(painter: _NeutralReaderPainter(style: style));
  }
}

class _MitochondriaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF4A5BA0), Color(0xFFEAF6FF)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.48),
      size.height * 0.36,
      Paint()..color = const Color(0xFFA7B5FF),
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.48),
      size.height * 0.28,
      Paint()..color = const Color(0xFF6C7AE7),
    );
    final cristae = Paint()
      ..color = const Color(0xFFD5D9FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    for (double i = 0; i < 5; i++) {
      canvas.drawArc(
        Rect.fromLTWH(
          size.width * 0.22 + i * 8,
          size.height * 0.2 + i * 10,
          size.width * 0.38,
          size.height * 0.22,
        ),
        0.3,
        2.7,
        false,
        cristae,
      );
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.72, size.height * 0.66),
        width: 70,
        height: 38,
      ),
      Paint()..color = const Color(0xFFF0B1EA),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NeutralReaderPainter extends CustomPainter {
  const _NeutralReaderPainter({required this.style});

  final LearnEbookCoverStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final colors = switch (style) {
      LearnEbookCoverStyle.math => [const Color(0xFFFFD8B0), const Color(0xFFFF8E1B)],
      LearnEbookCoverStyle.chemistry => [const Color(0xFF311B43), const Color(0xFFB05CFF)],
      LearnEbookCoverStyle.history => [const Color(0xFF08251F), const Color(0xFF1D8A7C)],
      LearnEbookCoverStyle.english => [const Color(0xFF8BA2AF), const Color(0xFFF2FBFF)],
      LearnEbookCoverStyle.biology => [const Color(0xFF89ACFF), const Color(0xFFEAF6FF)],
    };
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.18, size.height * 0.14, size.width * 0.6, size.height * 0.68),
        const Radius.circular(10),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
