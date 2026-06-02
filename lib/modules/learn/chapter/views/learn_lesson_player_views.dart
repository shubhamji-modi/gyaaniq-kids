import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../../core/service/learn_progress_refresh_service.dart';
import '../controller/learn_chapter_controller.dart';
import '../../../dashboard_vc/views/dashboard_tabbar_views_screen.dart';
import 'learn_subject_views.dart';

class LearnLessonPlayerViews extends StatefulWidget {
  const LearnLessonPlayerViews({super.key, required this.topic});

  final LearnTopicModel topic;

  @override
  State<LearnLessonPlayerViews> createState() => _LearnLessonPlayerViewsState();
}

class _LearnLessonPlayerViewsState extends State<LearnLessonPlayerViews> {
  bool _showVideo = true;
  bool _isMarkingComplete = false;

  @override
  Widget build(BuildContext context) {
    final lesson = widget.topic.lesson;
    final hasVideo = lesson.videoUrl.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        child: SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isMarkingComplete ? null : _markLessonAsComplete,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4D49E8),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            icon: _isMarkingComplete
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.check_circle_rounded, size: 20),
            label: Text(
              _isMarkingComplete ? 'Please wait...' : 'Mark as Complete',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const LearnTopBar(title: 'Lesson Player'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
                children: [
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1720),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: hasVideo
                          ? _LessonVideoPlayer(videoUrl: lesson.videoUrl)
                          : const _VideoNotFoundCard(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      _PlayerTab(
                        label: 'Video',
                        isSelected: _showVideo,
                        onTap: () {
                          setState(() {
                            _showVideo = true;
                          });
                        },
                      ),
                      const SizedBox(width: 28),
                      _PlayerTab(
                        label: 'Notes',
                        isSelected: !_showVideo,
                        onTap: () {
                          setState(() {
                            _showVideo = false;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(height: 1.5, color: const Color(0xFFC9CBE3)),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _ChipTag(
                        label: lesson.subjectLabel,
                        background: const Color(0xFFDCD9FF),
                        foreground: const Color(0xFF1F238B),
                      ),
                      _ChipTag(
                        label: lesson.chapterLabel,
                        background: const Color(0xFFE7E8EE),
                        foreground: const Color(0xFF4C4F5E),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
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
                    _showVideo ? lesson.description : lesson.notes,
                    style: const TextStyle(
                      color: Color(0xFF4C4F5E),
                      fontSize: 14,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 34),
                  const Row(
                    children: [
                      Icon(
                        Icons.attach_file_rounded,
                        color: Color(0xFF4C4F5E),
                        size: 28,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'LESSON RESOURCES',
                        style: TextStyle(
                          color: Color(0xFF4C4F5E),
                          fontSize: 18,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markLessonAsComplete() async {
    if (_isMarkingComplete) {
      return;
    }

    setState(() {
      _isMarkingComplete = true;
    });

    final response = await LearnCatalogData.markLessonComplete(
      lessonId: widget.topic.lesson.id,
    );

    if (!mounted) {
      return;
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
      return;
    }

    LearnProgressRefreshService.instance.notifyRefresh();

    Get.offAll(
      () => const DashboardTabbarViewsScreen(),
      arguments: {
        'initialTab': 1,
        'successMessage': response.message,
        'forceReload': true,
      },
    );
  }
}

class _LessonVideoPlayer extends StatefulWidget {
  const _LessonVideoPlayer({required this.videoUrl});

  final String videoUrl;

  @override
  State<_LessonVideoPlayer> createState() => _LessonVideoPlayerState();
}

class _LessonVideoPlayerState extends State<_LessonVideoPlayer> {
  VideoPlayerController? _videoController;
  YoutubePlayerController? _youtubeController;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isNativeVideo = false;

  @override
  void initState() {
    super.initState();
    final videoUrl = widget.videoUrl.trim();
    debugPrint('LESSON PLAYER videoUrl: $videoUrl');
    _isNativeVideo = _isDirectVideoUrl(videoUrl);
    if (_isNativeVideo) {
      _initializeNativeVideo(videoUrl);
    } else {
      _initializeYoutubeVideo(videoUrl);
    }
  }

  Future<void> _initializeNativeVideo(String videoUrl) async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    _videoController = controller;
    try {
      await controller.initialize();
      await controller.play();
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _initializeYoutubeVideo(String videoUrl) {
    final videoId = YoutubePlayerController.convertUrlToId(videoUrl);
    if (videoId == null) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    _youtubeController = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        mute: false,
        enableCaption: true,
        showFullscreenButton: true,
        strictRelatedVideos: true,
        playsInline: true,
      ),
    );

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _youtubeController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoController = _videoController;
    final youtubeController = _youtubeController;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (_isNativeVideo &&
            videoController != null &&
            videoController.value.isInitialized)
          Center(
            child: AspectRatio(
              aspectRatio: videoController.value.aspectRatio,
              child: VideoPlayer(videoController),
            ),
          )
        else if (!_isNativeVideo && youtubeController != null)
          YoutubePlayer(
            controller: youtubeController,
            backgroundColor: const Color(0xFF0F1720),
          ),
        if (_isLoading)
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        if (_hasError)
          const Padding(
            padding: EdgeInsets.all(18),
            child: Text(
              'Unable to play this video in app.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        if (_isNativeVideo &&
            videoController != null &&
            videoController.value.isInitialized &&
            !_isLoading &&
            !_hasError)
          InkWell(
            onTap: () {
              setState(() {
                videoController.value.isPlaying
                    ? videoController.pause()
                    : videoController.play();
              });
            },
            borderRadius: BorderRadius.circular(36),
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.42),
              ),
              child: Icon(
                videoController.value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
      ],
    );
  }
}

class _VideoNotFoundCard extends StatelessWidget {
  const _VideoNotFoundCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF263A2F), Color(0xFF10151D)],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_rounded, color: Colors.white70, size: 44),
            SizedBox(height: 12),
            Text(
              'Video not found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
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

class _PlayerTab extends StatelessWidget {
  const _PlayerTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF4A4FD9)
                  : const Color(0xFF7A7D8E),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 70,
            height: 5,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF4A4FD9) : Colors.transparent,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipTag extends StatelessWidget {
  const _ChipTag({
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
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
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

bool _isDirectVideoUrl(String url) {
  final lowerUrl = url.toLowerCase();
  return lowerUrl.endsWith('.mp4') ||
      lowerUrl.endsWith('.mov') ||
      lowerUrl.endsWith('.m3u8') ||
      lowerUrl.contains('.mp4?') ||
      lowerUrl.contains('.mov?') ||
      lowerUrl.contains('.m3u8?');
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
