import 'package:flutter/material.dart';

import '../../chapter/views/learn_subject_views.dart';
import '../../common/learn_media.dart';
import '../controller/learn_ebook_controller.dart';

/// Detail hub for a single e-book. Handles every resource the API returns —
/// PDFs and videos as openable tiles, images inline — alongside the reading
/// text. A book that is nothing but a single PDF opens straight into the
/// reader.
class LearnEbookDiscriptionViews extends StatelessWidget {
  const LearnEbookDiscriptionViews({super.key, required this.book});

  final LearnEbookModel book;

  @override
  Widget build(BuildContext context) {
    final images = book.imageResources;
    final videos = book.videoResources;
    final documents = book.documentResources;

    // Single document, nothing else -> open it directly.
    if (documents.length == 1 && images.isEmpty && videos.isEmpty) {
      final doc = documents.first;
      if (doc.kind == LearnMediaKind.pdf || doc.kind == LearnMediaKind.other) {
        return LearnPdfViewerView(title: book.title, pdfUrl: doc.url);
      }
    }

    final paragraphs = book.detailParagraphs
        .where((p) => p.trim().isNotEmpty)
        .toList();
    final hasAttachments = videos.isNotEmpty || documents.isNotEmpty;

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
                              for (var i = 0; i < paragraphs.length; i++) ...[
                                Text(
                                  paragraphs[i],
                                  style: const TextStyle(
                                    color: Color(0xFF1D2231),
                                    fontSize: 15,
                                    height: 1.75,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                // API images placed after the first paragraph.
                                if (i == 0 && images.isNotEmpty) ...[
                                  for (final image in images) ...[
                                    LearnInlineImage(
                                      url: image.url,
                                      caption: image.title,
                                    ),
                                    const SizedBox(height: 22),
                                  ],
                                ],
                              ],
                              if (hasAttachments) ...[
                                const Text(
                                  'Documents & Media',
                                  style: TextStyle(
                                    color: Color(0xFF1D2231),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                for (final video in videos) ...[
                                  LearnResourceTile(
                                    resource: video,
                                    onTap: () =>
                                        openLearnResource(context, video),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                for (final doc in documents) ...[
                                  LearnResourceTile(
                                    resource: doc,
                                    onTap: () => openLearnResource(context, doc),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                const SizedBox(height: 12),
                              ],
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
