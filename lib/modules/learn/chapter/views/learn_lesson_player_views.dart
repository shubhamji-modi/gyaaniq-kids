import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/service/learn_progress_refresh_service.dart';
import '../../../../core/service/offline_download_service.dart';
import '../../../../core/utils/google_drive_url_utils.dart';
import '../../../../core/utils/text_sanitizer.dart';
import '../../../daily_quiz/practice_test/Views/practice_quiz_overview.dart';
import '../controller/learn_chapter_controller.dart';
import 'learn_subject_views.dart';

/// Toggle for the PDF UI in the Lesson Overview screen (Download PDF button and
/// the LESSON RESOURCES section). Set to `true` to bring the PDF features back.
const bool _kShowLessonPdf = false;

class LearnLessonPlayerViews extends StatefulWidget {
  const LearnLessonPlayerViews({
    super.key,
    required this.subject,
    required this.chapter,
    required this.topic,
    required this.isCompleted,
  });

  final LearnSubjectModel subject;
  final LearnChapterModel chapter;
  final LearnTopicModel topic;
  final bool isCompleted;

  @override
  State<LearnLessonPlayerViews> createState() => _LearnLessonPlayerViewsState();
}

class _LearnLessonPlayerViewsState extends State<LearnLessonPlayerViews> {
  bool _isMarkingComplete = false;
  late bool _isCompleted;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.isCompleted;
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.topic.lesson;
    final hasAdditionalContent = _hasAdditionalLessonContent(lesson);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      bottomNavigationBar: _LessonPlayerBottomActions(
        isCompleted: _isCompleted,
        isMarkingComplete: _isMarkingComplete,
        onMarkComplete: _showMarkCompleteDialog,
        onTakeQuiz: _openChapterQuiz,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const LearnTopBar(title: 'Lesson Overview'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ChipTag(
                        label: lesson.subjectLabel,
                        icon: Icons.menu_book_rounded,
                        background: const Color(0xFFDCD9FF),
                        foreground: const Color(0xFF1F238B),
                      ),
                      _ChipTag(
                        label: lesson.chapterLabel,
                        icon: Icons.bookmark_border_rounded,
                        background: const Color(0xFFE7E8EE),
                        foreground: const Color(0xFF4C4F5E),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    lesson.title,
                    style: const TextStyle(
                      color: Color(0xFF1D2231),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    lesson.description,
                    style: const TextStyle(
                      color: Color(0xFF4C4F5E),
                      fontSize: 14,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (hasAdditionalContent) ...[
                    const SizedBox(height: 18),
                    _LessonContentBody(
                      htmlContent: lesson.content,
                      fallbackText: lesson.notes,
                    ),
                  ],
                  // PDF UI (Download PDF button + LESSON RESOURCES section) is
                  // hidden. Flip `_kShowLessonPdf` to true to restore it.
                  if (_kShowLessonPdf) ...[
                    const SizedBox(height: 24),
                    _LessonDownloadActions(lesson: lesson),
                    const SizedBox(height: 34),
                    const Row(
                      children: [
                        Icon(
                          Icons.attach_file_rounded,
                          color: Color(0xFF4C4F5E),
                          size: 22,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'LESSON RESOURCES',
                          style: TextStyle(
                            color: Color(0xFF4C4F5E),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    if (lesson.resources.isEmpty)
                      const _NoPdfStateCard()
                    else
                      ...lesson.resources.map(
                        (resource) => Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: _LessonResourceCard(resource: resource),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMarkCompleteDialog() async {
    if (_isMarkingComplete) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      builder: (dialogContext) {
        return _MarkCompleteDialog(
          onTakeQuiz: () {
            Navigator.of(dialogContext).pop();
            _markCompleteAndOpenQuiz();
          },
          onSkipAndComplete: () {
            Navigator.of(dialogContext).pop();
            _markLessonAsComplete();
          },
        );
      },
    );
  }

  Future<void> _markLessonAsComplete() async {
    await _completeLesson(showSuccessSnack: true);
  }

  Future<void> _markCompleteAndOpenQuiz() async {
    final didComplete = await _completeLesson(showSuccessSnack: false);
    if (!mounted || !didComplete) {
      return;
    }

    _openChapterQuiz();
  }

  Future<bool> _completeLesson({required bool showSuccessSnack}) async {
    if (_isCompleted) {
      return true;
    }

    if (_isMarkingComplete || _isCompleted) {
      return false;
    }

    setState(() {
      _isMarkingComplete = true;
    });

    final response = await LearnCatalogData.markLessonComplete(
      lessonId: widget.topic.lesson.id,
    );

    if (!mounted) {
      return false;
    }

    setState(() {
      _isMarkingComplete = false;
    });

    if (!response.success) {
      Get.snackbar(
        'Unable to complete lesson',
        response.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFB42318),
        colorText: Colors.white,
        margin: const EdgeInsets.all(14),
      );
      return false;
    }

    setState(() {
      _isCompleted = true;
    });

    LearnProgressRefreshService.instance.notifyRefresh();

    if (showSuccessSnack) {
      Get.snackbar(
        'Lesson Completed',
        response.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF3FA34D),
        colorText: Colors.white,
        margin: const EdgeInsets.all(14),
      );
    }

    return true;
  }

  void _openChapterQuiz() {
    Get.to(
      () => PracticeQuizOverviewViews(
        subject: widget.subject,
        chapter: widget.chapter,
        returnToLessonOnResultBack: true,
      ),
    );
  }

  bool _hasAdditionalLessonContent(LearnLessonModel lesson) {
    final content = lesson.content.trim();
    final notes = lesson.notes.trim();
    final description = lesson.description.trim();
    return content.isNotEmpty || (notes.isNotEmpty && notes != description);
  }
}

class _LessonContentBody extends StatelessWidget {
  const _LessonContentBody({
    required this.htmlContent,
    required this.fallbackText,
  });

  final String htmlContent;
  final String fallbackText;

  @override
  Widget build(BuildContext context) {
    final html = htmlContent.trim();
    final teacherLine = _teacherLineFromFallback(fallbackText);
    if (html.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HtmlWidget(
            html,
            textStyle: const TextStyle(
              color: Color(0xFF4C4F5E),
              fontSize: 14,
              height: 1.58,
              fontWeight: FontWeight.w500,
            ),
            customStylesBuilder: (element) {
              switch (element.localName) {
                case 'h1':
                  return {
                    'color': '#1D2231',
                    'font-size': '24px',
                    'font-weight': '800',
                    'line-height': '1.25',
                    'margin': '18px 0 10px',
                  };
                case 'h2':
                  return {
                    'color': '#1D2231',
                    'font-size': '22px',
                    'font-weight': '800',
                    'line-height': '1.28',
                    'margin': '18px 0 10px',
                  };
                case 'h3':
                  return {
                    'color': '#1D2231',
                    'font-size': '18px',
                    'font-weight': '800',
                    'line-height': '1.32',
                    'margin': '16px 0 8px',
                  };
                case 'p':
                  return {'margin': '0 0 12px', 'line-height': '1.65'};
                case 'strong':
                case 'b':
                  return {'color': '#1D2231', 'font-weight': '800'};
                case 'em':
                case 'i':
                  return {'font-style': 'italic'};
                case 'ol':
                case 'ul':
                  return {'margin': '8px 0 12px', 'padding-left': '20px'};
                case 'li':
                  return {'margin': '0 0 8px', 'line-height': '1.58'};
                case 'blockquote':
                  return {
                    'border-left': '3px solid #D7DAEA',
                    'color': '#4C4F5E',
                    'font-style': 'italic',
                    'margin': '10px 0 14px',
                    'padding': '2px 0 2px 12px',
                  };
                case 'code':
                  return {
                    'background-color': '#EEF0FF',
                    'color': '#4D49E8',
                    'font-size': '13px',
                    'padding': '2px 4px',
                  };
              }
              return null;
            },
          ),
          if (teacherLine.isNotEmpty &&
              !html.toLowerCase().contains('teacher:')) ...[
            const SizedBox(height: 18),
            Text(
              teacherLine,
              style: const TextStyle(
                color: Color(0xFF4C4F5E),
                fontSize: 14,
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      );
    }

    final paragraphs = fallbackText
        .split(RegExp(r'\n{2,}'))
        .map((paragraph) => paragraph.trim())
        .where((paragraph) => paragraph.isNotEmpty)
        .toList();

    if (paragraphs.isEmpty) {
      return const Text(
        'Lesson notes will be available soon.',
        style: TextStyle(
          color: Color(0xFF4C4F5E),
          fontSize: 14,
          height: 1.6,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final paragraph in paragraphs) ...[
          Text(
            paragraph,
            style: const TextStyle(
              color: Color(0xFF4C4F5E),
              fontSize: 14,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  String _teacherLineFromFallback(String value) {
    final lines = value
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty);
    for (final line in lines) {
      if (line.toLowerCase().startsWith('teacher:')) {
        return line;
      }
    }
    return '';
  }
}

class _LessonPlayerBottomActions extends StatelessWidget {
  const _LessonPlayerBottomActions({
    required this.isCompleted,
    required this.isMarkingComplete,
    required this.onMarkComplete,
    required this.onTakeQuiz,
  });

  final bool isCompleted;
  final bool isMarkingComplete;
  final VoidCallback onMarkComplete;
  final VoidCallback onTakeQuiz;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isCompleted || isMarkingComplete
                  ? null
                  : onMarkComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted
                    ? const Color(0xFF3FA34D)
                    : const Color(0xFF4D49E8),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF3FA34D),
                disabledForegroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              icon: isMarkingComplete
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      isCompleted
                          ? Icons.check_rounded
                          : Icons.check_circle_rounded,
                      size: 20,
                    ),
              label: Text(
                isMarkingComplete
                    ? 'Please wait...'
                    : isCompleted
                    ? 'Completed'
                    : 'Mark as Complete',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (isCompleted) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 46,
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onTakeQuiz,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1B72E8),
                  side: const BorderSide(color: Color(0xFF1B72E8), width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.quiz_outlined, size: 18),
                label: const Text('Take Lesson Quiz'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MarkCompleteDialog extends StatelessWidget {
  const _MarkCompleteDialog({
    required this.onTakeQuiz,
    required this.onSkipAndComplete,
  });

  final VoidCallback onTakeQuiz;
  final VoidCallback onSkipAndComplete;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mark as Complete?',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Great job on finishing the lesson! Would you like to take a quick quiz to test your understanding before marking this as complete?',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 44,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTakeQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6765F5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: const Text('Take Quiz'),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: onSkipAndComplete,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4D49E8),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: const Text('Skip & Mark Complete'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoPdfStateCard extends StatelessWidget {
  const _NoPdfStateCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFC8C7F1)),
      ),
      child: const Text(
        'PDF not found for this lesson.',
        style: TextStyle(
          color: Color(0xFF4C4F5E),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LessonDownloadActions extends StatefulWidget {
  const _LessonDownloadActions({required this.lesson});

  final LearnLessonModel lesson;

  @override
  State<_LessonDownloadActions> createState() => _LessonDownloadActionsState();
}

class _LessonDownloadActionsState extends State<_LessonDownloadActions> {
  bool _isPdfDownloaded = false;
  bool _isDownloadingPdf = false;

  @override
  void initState() {
    super.initState();
    _refreshDownloadState();
  }

  Future<void> _refreshDownloadState() async {
    final service = OfflineDownloadService.instance;
    final pdfDownloaded = await service.isDownloaded(
      sourceId: widget.lesson.id,
      type: OfflineDownloadType.pdf,
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _isPdfDownloaded = pdfDownloaded;
    });
  }

  Future<void> _downloadPdf() async {
    if (_isDownloadingPdf || _isPdfDownloaded) {
      return;
    }

    final pdfUrl = widget.lesson.pdfUrl.trim();
    if (pdfUrl.isEmpty) {
      _showDownloadSnack('PDF not found for this lesson.');
      return;
    }

    setState(() => _isDownloadingPdf = true);
    try {
      await OfflineDownloadService.instance.download(
        sourceId: widget.lesson.id,
        title: '${widget.lesson.title} PDF',
        sectionTitle: widget.lesson.subjectLabel,
        badge: widget.lesson.chapterLabel,
        sourceUrl: pdfUrl,
        type: OfflineDownloadType.pdf,
        headers: _pdfRequestHeaders,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isPdfDownloaded = true;
        _isDownloadingPdf = false;
      });
      _showDownloadSnack('PDF saved for offline use.');
    } catch (error) {
      debugPrint('PDF download error: $error');
      if (!mounted) {
        return;
      }
      setState(() => _isDownloadingPdf = false);
      _showDownloadSnack(_pdfDownloadErrorMessage(error));
    }
  }

  void _showDownloadSnack(String message) {
    Get.snackbar(
      'Downloads',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
      colorText: const Color(0xFF1A1D27),
      margin: const EdgeInsets.all(12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPdf = widget.lesson.pdfUrl.trim().isNotEmpty;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _DownloadActionButton(
          label: _isPdfDownloaded ? 'PDF Offline' : 'Download PDF',
          icon: _isPdfDownloaded
              ? Icons.download_done_rounded
              : Icons.picture_as_pdf_outlined,
          isLoading: _isDownloadingPdf,
          isDisabled: !hasPdf || _isPdfDownloaded,
          onTap: _downloadPdf,
        ),
      ],
    );
  }
}

String _pdfDownloadErrorMessage(Object error) {
  final message = error.toString();
  if (message.contains('HTTP 401') || message.contains('HTTP 403')) {
    return 'PDF access denied. Please login again and retry.';
  }
  if (message.contains('HTTP 404')) {
    return 'PDF file not found on server.';
  }
  if (message.contains('TimeoutException')) {
    return 'PDF download timed out. Please check internet and retry.';
  }
  return 'Unable to download PDF: ${_shortErrorText(message)}';
}

String _shortErrorText(String message) {
  final cleaned = message
      .replaceFirst('Exception: ', '')
      .replaceFirst('Invalid argument(s): ', '')
      .trim();
  return safeTruncate(cleaned, 90);
}

class _DownloadActionButton extends StatelessWidget {
  const _DownloadActionButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.isDisabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = isDisabled
        ? const Color(0xFF777B8E)
        : const Color(0xFF4A4FD9);

    return OutlinedButton.icon(
      onPressed: isLoading || isDisabled ? null : onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: foreground,
        side: BorderSide(color: foreground.withValues(alpha: 0.35)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      ),
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _LessonPdfView extends StatefulWidget {
  const _LessonPdfView({required this.title, required this.pdfUrl});

  final String title;
  final String pdfUrl;

  @override
  State<_LessonPdfView> createState() => _LessonPdfViewState();
}

class _LessonPdfViewState extends State<_LessonPdfView> {
  String? _filePath;
  WebViewController? _webController;
  String _error = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      setState(() {
        _filePath = null;
        _webController = null;
        _error = '';
        _isLoading = true;
      });

      final sourceUrl = widget.pdfUrl.trim();
      final downloadUrl = pdfDownloadUrl(sourceUrl);
      final response = await http
          .get(Uri.parse(downloadUrl), headers: _pdfRequestHeaders)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }
      if (isHtmlResponse(response.headers) ||
          !looksLikePdfBytes(response.bodyBytes)) {
        throw Exception('Response is not a PDF');
      }

      final directory = await getTemporaryDirectory();
      final fileName = _safePdfFileName(sourceUrl);
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes, flush: true);

      if (!mounted) {
        return;
      }
      setState(() {
        _filePath = file.path;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      debugPrint('PDF load error: $error');
      _openPdfInWebViewFallback();
    }
  }

  void _openPdfInWebViewFallback() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onWebResourceError: (_) {
            if (mounted) {
              setState(() {
                _error = 'Unable to load PDF. Please try again.';
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadRequest(
        Uri.parse(pdfPreviewUrl(widget.pdfUrl)),
        headers: _pdfRequestHeaders,
      );

    setState(() {
      _webController = controller;
      _isLoading = true;
      _error = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            LearnTopBar(title: widget.title),
            Expanded(
              child: Stack(
                children: [
                  if (_filePath != null)
                    PDFView(
                      filePath: _filePath!,
                      fitPolicy: FitPolicy.WIDTH,
                      onError: (error) {
                        if (mounted) {
                          setState(
                            () => _error =
                                'Unable to render PDF. Please try again.',
                          );
                        }
                      },
                      onPageError: (page, error) {
                        if (mounted) {
                          setState(
                            () =>
                                _error = 'Unable to render page ${page ?? ''}.',
                          );
                        }
                      },
                    ),
                  if (_filePath == null && _webController != null)
                    WebViewWidget(controller: _webController!),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF4A4FD9),
                        ),
                      ),
                    ),
                  if (_error.isNotEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Text(
                          _error,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF4C4F5E),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  if (_error.isNotEmpty)
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: 28,
                      child: ElevatedButton(
                        onPressed: _loadPdf,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A4FD9),
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: const Text('Retry'),
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

/// A non-interactive informational tag (subject / chapter metadata).
/// Styled deliberately flat — no button affordance — so it doesn't invite taps.
class _ChipTag extends StatelessWidget {
  const _ChipTag({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: background.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: foreground.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon ?? Icons.label_outline_rounded,
            size: 13,
            color: foreground.withValues(alpha: 0.85),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonResourceCard extends StatelessWidget {
  const _LessonResourceCard({required this.resource});

  final LearnResourceModel resource;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.to(
        () => _LessonPdfView(title: resource.title, pdfUrl: resource.url),
      ),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFC8C7F1)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD8DDF0).withValues(alpha: 0.26),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: resource.iconBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(resource.icon, color: resource.accent, size: 30),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    style: const TextStyle(
                      color: Color(0xFF1D2231),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    resource.meta,
                    style: const TextStyle(
                      color: Color(0xFF4C4F5E),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF4A4FD9),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

const Map<String, String> _pdfRequestHeaders = {
  'User-Agent':
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
  'Accept': 'application/pdf,application/octet-stream,*/*',
  'Referer': 'https://ncert.nic.in/',
};

String _safePdfFileName(String pdfUrl) {
  final uri = Uri.tryParse(pdfUrl);
  final pathName = uri?.pathSegments.isNotEmpty == true
      ? uri!.pathSegments.last
      : 'lesson.pdf';
  final sanitized = pathName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  return sanitized.toLowerCase().endsWith('.pdf')
      ? sanitized
      : '$sanitized.pdf';
}
