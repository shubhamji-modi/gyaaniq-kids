import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../chapter/views/learn_subject_views.dart';

/// In-app browser used to open an e-book source page (e.g. the NCERT textbook
/// portal) without leaving the app.
class LearnEbookWebViewScreen extends StatefulWidget {
  const LearnEbookWebViewScreen({
    super.key,
    required this.url,
    this.title = 'E-Books',
  });

  final String url;
  final String title;

  @override
  State<LearnEbookWebViewScreen> createState() =>
      _LearnEbookWebViewScreenState();
}

class _LearnEbookWebViewScreenState extends State<LearnEbookWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _error = '';
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            // Ignore sub-resource failures; only surface main-frame errors.
            if (error.isForMainFrame == false) return;
            setState(() {
              _isLoading = false;
              _error = 'Unable to open the page. Please check your connection.';
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _reload() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    await _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        child: Column(
          children: [
            LearnTopBar(
              title: widget.title,
              trailing: IconButton(
                padding: EdgeInsets.zero,
                onPressed: _reload,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFF4A4FD9),
                  size: 24,
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_isLoading && _error.isEmpty)
                    const Center(child: CircularProgressIndicator()),
                  if (_error.isNotEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.wifi_off_rounded,
                              color: Color(0xFF9AA0B0),
                              size: 48,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _error,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF6B7080),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 18),
                            ElevatedButton(
                              onPressed: _reload,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A4FD9),
                                foregroundColor: Colors.white,
                                elevation: 0,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
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
