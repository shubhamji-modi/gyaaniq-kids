import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import '../../chapter/views/learn_subject_views.dart';
import '../../common/learn_media.dart';
import '../controller/learn_notes_controller.dart';

/// Detail hub for a note. Renders the note's HTML body and every attachment it
/// carries — images inline, videos and PDFs as openable tiles. Nothing static
/// is shown: sections only appear when the API actually returns that data.
class LearnNotesDiscriptionViews extends StatelessWidget {
  const LearnNotesDiscriptionViews({super.key, required this.note});

  final LearnNoteModel note;

  @override
  Widget build(BuildContext context) {
    final images = note.imageResources;
    final videos = note.videoResources;
    final documents = note.documentResources;

    // Shortcut: a lone PDF with no readable body/images/videos opens straight
    // into the reader (preserves the previous one-tap behaviour).
    if (!note.hasHtmlContent &&
        images.isEmpty &&
        videos.isEmpty &&
        documents.length == 1) {
      return LearnPdfViewerView(title: note.title, pdfUrl: documents.first.url);
    }

    final paragraphs = note.detailParagraphs
        .where((p) => p.trim().isNotEmpty)
        .toList();
    final hasAttachments = videos.isNotEmpty || documents.isNotEmpty;

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
                          color: const Color(
                            0xFFD8DDF0,
                          ).withValues(alpha: 0.22),
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
                        const SizedBox(height: 16),
                        // Body: rendered HTML when the API sends HTML content,
                        // otherwise the plain paragraphs derived from it.
                        if (note.hasHtmlContent)
                          HtmlWidget(
                            note.content,
                            textStyle: const TextStyle(
                              color: Color(0xFF43485A),
                              fontSize: 15,
                              height: 1.7,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        else
                          for (final paragraph in paragraphs) ...[
                            Text(
                              paragraph,
                              style: const TextStyle(
                                color: Color(0xFF43485A),
                                fontSize: 15,
                                height: 1.8,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                        // Images ONLY when the API provides them.
                        if (images.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          for (final image in images) ...[
                            LearnInlineImage(
                              url: image.url,
                              caption: image.title,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],

                        // Videos and documents as openable tiles.
                        if (hasAttachments) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Attachments',
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
                              onTap: () => openLearnResource(context, video),
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
                        ],
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
