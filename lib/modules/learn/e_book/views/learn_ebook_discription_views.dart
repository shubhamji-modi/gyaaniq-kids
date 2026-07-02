import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../chapter/views/learn_subject_views.dart';
import '../controller/learn_ebook_controller.dart';

class LearnEbookDiscriptionViews extends StatelessWidget {
  const LearnEbookDiscriptionViews({super.key, required this.book});

  final LearnEbookModel book;

  @override
  Widget build(BuildContext context) {
    if (book.pdfUrl.trim().isNotEmpty) {
      return _EbookPdfView(title: book.title, pdfUrl: book.pdfUrl);
    }
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
                                  child: _DetailIllustration(
                                    style: book.coverStyle,
                                  ),
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

class _EbookPdfView extends StatefulWidget {
  const _EbookPdfView({required this.title, required this.pdfUrl});

  final String title;
  final String pdfUrl;

  @override
  State<_EbookPdfView> createState() => _EbookPdfViewState();
}

class _EbookPdfViewState extends State<_EbookPdfView> {
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

      final response = await http
          .get(Uri.parse(widget.pdfUrl.trim()), headers: _pdfRequestHeaders)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final directory = await getTemporaryDirectory();
      final fileName = _safePdfFileName(widget.pdfUrl);
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
      debugPrint('Ebook PDF load error: $error');
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
        Uri.parse(widget.pdfUrl.trim()),
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
      LearnEbookCoverStyle.math => [
        const Color(0xFFFFD8B0),
        const Color(0xFFFF8E1B),
      ],
      LearnEbookCoverStyle.chemistry => [
        const Color(0xFF311B43),
        const Color(0xFFB05CFF),
      ],
      LearnEbookCoverStyle.history => [
        const Color(0xFF08251F),
        const Color(0xFF1D8A7C),
      ],
      LearnEbookCoverStyle.english => [
        const Color(0xFF8BA2AF),
        const Color(0xFFF2FBFF),
      ],
      LearnEbookCoverStyle.biology => [
        const Color(0xFF89ACFF),
        const Color(0xFFEAF6FF),
      ],
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
        Rect.fromLTWH(
          size.width * 0.18,
          size.height * 0.14,
          size.width * 0.6,
          size.height * 0.68,
        ),
        const Radius.circular(10),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String _safePdfFileName(String pdfUrl) {
  final uri = Uri.tryParse(pdfUrl);
  final pathName = uri?.pathSegments.isNotEmpty == true
      ? uri!.pathSegments.last
      : 'ebook.pdf';
  final sanitized = pathName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  return sanitized.toLowerCase().endsWith('.pdf')
      ? sanitized
      : '$sanitized.pdf';
}

const Map<String, String> _pdfRequestHeaders = {
  'User-Agent':
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
  'Accept': 'application/pdf,application/octet-stream,*/*',
  'Referer': 'https://ncert.nic.in/',
};
