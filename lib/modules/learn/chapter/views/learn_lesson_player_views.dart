import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F1720))
      ..loadRequest(Uri.parse(_normalizedVideoUrl(widget.videoUrl)));
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
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
            Icon(
              Icons.videocam_off_rounded,
              color: Colors.white70,
              size: 44,
            ),
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

class _LessonPdfWebView extends StatefulWidget {
  const _LessonPdfWebView({required this.title, required this.pdfUrl});

  final String title;
  final String pdfUrl;

  @override
  State<_LessonPdfWebView> createState() => _LessonPdfWebViewState();
}

class _LessonPdfWebViewState extends State<_LessonPdfWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    final viewerUrl = _pdfViewerUrl(widget.pdfUrl);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(viewerUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            LearnTopBar(title: widget.title),
            Expanded(child: WebViewWidget(controller: _controller)),
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
              color: isSelected
                  ? const Color(0xFF4A4FD9)
                  : Colors.transparent,
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
        () => _LessonPdfWebView(
          title: resource.title,
          pdfUrl: resource.url,
        ),
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

String _normalizedVideoUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) {
    return url;
  }

  if (uri.host.contains('youtube.com')) {
    final videoId = uri.queryParameters['v'];
    if (videoId != null && videoId.isNotEmpty) {
      return 'https://www.youtube.com/embed/$videoId';
    }
  }

  if (uri.host.contains('youtu.be')) {
    final segments = uri.pathSegments;
    if (segments.isNotEmpty && segments.first.isNotEmpty) {
      return 'https://www.youtube.com/embed/${segments.first}';
    }
  }

  return url;
}

String _pdfViewerUrl(String pdfUrl) {
  final encodedUrl = Uri.encodeComponent(pdfUrl);
  return 'https://docs.google.com/gview?embedded=1&url=$encodedUrl';
}
