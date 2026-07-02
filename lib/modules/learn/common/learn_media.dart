import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../chapter/views/learn_subject_views.dart';

/// The kind of a media/resource item coming from the API.
enum LearnMediaKind { image, video, pdf, other }

bool isYoutubeUrl(String url) {
  final u = url.toLowerCase();
  return u.contains('youtube.com') || u.contains('youtu.be');
}

/// Classifies a media entry using its mimeType first, then its URL extension.
LearnMediaKind classifyMedia(String mimeType, String url) {
  final m = mimeType.toLowerCase();
  if (m.startsWith('image/')) return LearnMediaKind.image;
  if (m.startsWith('video/')) return LearnMediaKind.video;
  if (m.contains('pdf')) return LearnMediaKind.pdf;

  final path = (Uri.tryParse(url)?.path ?? url).toLowerCase();
  if (path.endsWith('.pdf')) return LearnMediaKind.pdf;
  if (RegExp(r'\.(png|jpe?g|gif|webp|bmp|heic|heif)$').hasMatch(path)) {
    return LearnMediaKind.image;
  }
  if (RegExp(r'\.(mp4|mov|m4v|webm|mkv|avi|3gp)$').hasMatch(path)) {
    return LearnMediaKind.video;
  }
  if (isYoutubeUrl(url)) return LearnMediaKind.video;
  return LearnMediaKind.other;
}

/// A single openable resource (PDF / video / image) surfaced in a bottom sheet
/// or a detail hub, regardless of whether it came from `media[]`, `pdfUrl`, or
/// `videoUrl`.
class LearnResource {
  const LearnResource({
    required this.title,
    required this.url,
    required this.kind,
    this.size = 0,
  });

  final String title;
  final String url;
  final LearnMediaKind kind;
  final int size;
}

String readableSize(int bytes) {
  if (bytes <= 0) return '';
  const units = ['B', 'KB', 'MB', 'GB'];
  var size = bytes.toDouble();
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }
  return '${size.toStringAsFixed(size >= 10 || unit == 0 ? 0 : 1)} ${units[unit]}';
}

String fileNameFromUrl(String url, {String fallback = 'Document'}) {
  final uri = Uri.tryParse(url);
  final segment = uri != null && uri.pathSegments.isNotEmpty
      ? uri.pathSegments.last
      : '';
  final name = Uri.decodeComponent(segment).trim();
  return name.isEmpty ? fallback : name;
}

const Map<String, String> kPdfRequestHeaders = {
  'User-Agent':
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
  'Accept': 'application/pdf,application/octet-stream,*/*',
  'Referer': 'https://ncert.nic.in/',
};

/// Opens the correct viewer for a resource.
void openLearnResource(BuildContext context, LearnResource resource) {
  Widget page;
  switch (resource.kind) {
    case LearnMediaKind.video:
      page = LearnVideoPlayerView(title: resource.title, url: resource.url);
      break;
    case LearnMediaKind.image:
      page = LearnImageViewerView(title: resource.title, url: resource.url);
      break;
    case LearnMediaKind.pdf:
    case LearnMediaKind.other:
      page = LearnPdfViewerView(title: resource.title, pdfUrl: resource.url);
      break;
  }
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}

IconData learnMediaIcon(LearnMediaKind kind) {
  switch (kind) {
    case LearnMediaKind.image:
      return Icons.image_outlined;
    case LearnMediaKind.video:
      return Icons.play_circle_outline_rounded;
    case LearnMediaKind.pdf:
      return Icons.picture_as_pdf_rounded;
    case LearnMediaKind.other:
      return Icons.insert_drive_file_outlined;
  }
}

// ---------------------------------------------------------------------------
// PDF viewer (downloads then renders; falls back to WebView).
// ---------------------------------------------------------------------------

class LearnPdfViewerView extends StatefulWidget {
  const LearnPdfViewerView({
    super.key,
    required this.title,
    required this.pdfUrl,
  });

  final String title;
  final String pdfUrl;

  @override
  State<LearnPdfViewerView> createState() => _LearnPdfViewerViewState();
}

class _LearnPdfViewerViewState extends State<LearnPdfViewerView> {
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
          .get(Uri.parse(widget.pdfUrl.trim()), headers: kPdfRequestHeaders)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final directory = await getTemporaryDirectory();
      final fileName = _safePdfFileName(widget.pdfUrl);
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes, flush: true);

      if (!mounted) return;
      setState(() {
        _filePath = file.path;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
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
            if (mounted) setState(() => _isLoading = false);
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
      ..loadRequest(Uri.parse(widget.pdfUrl.trim()), headers: kPdfRequestHeaders);

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

String _safePdfFileName(String pdfUrl) {
  final uri = Uri.tryParse(pdfUrl);
  final pathName = uri?.pathSegments.isNotEmpty == true
      ? uri!.pathSegments.last
      : 'document.pdf';
  final sanitized = pathName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  return sanitized.toLowerCase().endsWith('.pdf')
      ? sanitized
      : '$sanitized.pdf';
}

// ---------------------------------------------------------------------------
// Video player (YouTube or direct file).
// ---------------------------------------------------------------------------

class LearnVideoPlayerView extends StatefulWidget {
  const LearnVideoPlayerView({
    super.key,
    required this.title,
    required this.url,
  });

  final String title;
  final String url;

  @override
  State<LearnVideoPlayerView> createState() => _LearnVideoPlayerViewState();
}

class _LearnVideoPlayerViewState extends State<LearnVideoPlayerView> {
  YoutubePlayerController? _ytController;
  VideoPlayerController? _videoController;
  bool _initializing = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    final url = widget.url.trim();
    if (isYoutubeUrl(url)) {
      final id = YoutubePlayerController.convertUrlToId(url);
      if (id == null) {
        setState(() {
          _error = 'Invalid video link.';
          _initializing = false;
        });
        return;
      }
      _ytController = YoutubePlayerController.fromVideoId(
        videoId: id,
        autoPlay: true,
        params: const YoutubePlayerParams(
          mute: false,
          enableCaption: true,
          showFullscreenButton: true,
          playsInline: true,
        ),
      );
      setState(() => _initializing = false);
      return;
    }

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _videoController = controller;
      await controller.initialize();
      if (!mounted) return;
      await controller.play();
      setState(() => _initializing = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to play this video.';
        _initializing = false;
      });
    }
  }

  @override
  void dispose() {
    _ytController?.close();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            LearnTopBar(title: widget.title),
            Expanded(child: Center(child: _buildPlayer())),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    if (_initializing) {
      return const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A4FD9)),
      );
    }
    if (_error.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          _error,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    if (_ytController != null) {
      return YoutubePlayer(
        controller: _ytController!,
        backgroundColor: const Color(0xFF0F1720),
      );
    }
    final controller = _videoController;
    if (controller != null && controller.value.isInitialized) {
      return AspectRatio(
        aspectRatio: controller.value.aspectRatio == 0
            ? 16 / 9
            : controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            VideoPlayer(controller),
            _VideoControls(controller: controller),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _VideoControls extends StatefulWidget {
  const _VideoControls({required this.controller});

  final VideoPlayerController controller;

  @override
  State<_VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<_VideoControls> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        VideoProgressIndicator(
          widget.controller,
          allowScrubbing: true,
          colors: const VideoProgressColors(playedColor: Color(0xFF4A4FD9)),
        ),
        Container(
          color: Colors.black26,
          child: IconButton(
            icon: Icon(
              widget.controller.value.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 34,
            ),
            onPressed: () {
              setState(() {
                widget.controller.value.isPlaying
                    ? widget.controller.pause()
                    : widget.controller.play();
              });
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Full-screen image viewer.
// ---------------------------------------------------------------------------

class LearnImageViewerView extends StatelessWidget {
  const LearnImageViewerView({
    super.key,
    required this.title,
    required this.url,
  });

  final String title;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            LearnTopBar(title: title),
            Expanded(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Center(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF4A4FD9),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Unable to load image.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline network image with graceful fallback, used inside detail pages.
class LearnInlineImage extends StatelessWidget {
  const LearnInlineImage({
    super.key,
    required this.url,
    this.caption = '',
    this.height = 180,
  });

  final String url;
  final String caption;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            url,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return SizedBox(
                height: height,
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A4FD9)),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),
        ),
        if (caption.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            caption,
            style: const TextStyle(
              color: Color(0xFF4A4E61),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

/// A tappable resource row used in bottom sheets and detail hubs.
class LearnResourceTile extends StatelessWidget {
  const LearnResourceTile({
    super.key,
    required this.resource,
    required this.onTap,
  });

  final LearnResource resource;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = readableSize(resource.size);
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
                color: const Color(0xFFECE9FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                learnMediaIcon(resource.kind),
                color: const Color(0xFF4A4FD9),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1D2231),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
