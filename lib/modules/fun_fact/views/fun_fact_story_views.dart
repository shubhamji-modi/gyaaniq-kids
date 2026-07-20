import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/appcolors.dart';
import '../controller/fun_fact_bg_sound_player.dart';
import '../controller/fun_fact_controller.dart';
import '../fun_fact_image.dart';

/// Full-screen, Instagram-style story player for one subject's fun facts.
///
/// Plays the batch the Home strip already warmed, so opening is instant and no
/// extra API call is spent. It resumes at the first fact the child has not
/// seen, and reports progress back so the ring only greys out once the whole
/// batch has been watched.
class FunFactStoryViews extends StatefulWidget {
  const FunFactStoryViews({
    super.key,
    required this.subjectId,
    required this.subjectTitle,
    required this.subjectIcon,
    required this.subjectAccent,
    required this.subjectIconBackground,
  });

  final String subjectId;
  final String subjectTitle;
  final IconData subjectIcon;
  final Color subjectAccent;
  final Color subjectIconBackground;

  @override
  State<FunFactStoryViews> createState() => _FunFactStoryViewsState();
}

class _FunFactStoryViewsState extends State<FunFactStoryViews>
    with SingleTickerProviderStateMixin {
  static const Duration _perFactDuration = Duration(seconds: 6);

  late final AnimationController _progress;

  List<String> _urls = const [];
  int _index = 0;
  bool _isLoading = true;

  /// Completes once the ambient audio has loaded (or there's none / it failed).
  /// The first fact's countdown awaits this so progress never runs in silence.
  Future<void>? _audioReady;

  /// The current fact's image is decoded and on screen. The countdown is gated
  /// on this: a timer running over an image that has not arrived yet is what
  /// makes a story advance past a fact the child never saw.
  bool _isImageReady = false;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(vsync: this, duration: _perFactDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _next();
        }
      });
    // Deferred to after the first frame: precacheImage resolves an image
    // configuration off the context, which is an inherited-widget lookup and
    // therefore illegal during initState. A cached batch makes _start run
    // synchronously, so it would hit that on the very path we care about most.
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    // Silence the ambient bed as the story leaves the screen.
    unawaited(FunFactBgSoundPlayer.instance.stop());
    _progress.dispose();
    super.dispose();
  }

  /// initState cannot await this, so anything thrown here would escape as an
  /// unhandled async error and be swallowed by whatever the zone handler does.
  /// Catch and print it instead.
  Future<void> _start() async {
    try {
      final controller = FunFactController.instance;
      // Normally a cache hit from the Home-tab preload; only falls through to
      // the network if the child tapped before the preload finished.
      final batch =
          controller.batchFor(widget.subjectId) ??
          await controller.ensureBatch(widget.subjectId, widget.subjectTitle);

      if (!mounted) {
        return;
      }

      // No images for this class/subject is a valid response, not an error.
      if (batch == null || batch.urls.isEmpty) {
        debugPrint('[FunFact] "${widget.subjectTitle}": no facts, closing.');
        Get.back<void>();
        return;
      }

      debugPrint(
        '[FunFact] "${widget.subjectTitle}": ${batch.urls.length} fact(s), '
        'resuming at ${batch.resumeIndex}.',
      );

      setState(() {
        _urls = batch.urls;
        _isLoading = false;
      });

      // Warm the rest of the batch while the first fact plays. Each fact plays
      // its own background track — started per fact in [_showFactAt].
      _warmAll();
      await _showFactAt(batch.resumeIndex);
    } catch (error, stack) {
      debugPrint('[FunFact] story failed to start: $error\n$stack');
    }
  }

  /// Decodes every fact in the batch in the background.
  ///
  /// `onError` must be passed even though it does nothing: without it a failed
  /// decode is raised as an unhandled framework error instead.
  void _warmAll() {
    for (final url in _urls) {
      precacheImage(funFactImage(url), context, onError: (_, _) {});
    }
  }

  /// Shows one fact: wait for its image, and only then start its countdown.
  /// Nothing is timed while the screen is still blank.
  /// Callers do not await this, so it must never let an error escape.
  Future<void> _showFactAt(int index) async {
    try {
      // Reset to 0 (not just stop): the controller still holds the previous
      // fact's finished value of 1, and while we wait for this fact's image and
      // audio the bar would otherwise show full before snapping back to empty.
      _progress.reset();
      setState(() {
        _index = index;
        _isImageReady = false;
      });

      final startedAt = DateTime.now();
      // precacheImage reports failure through onError and still completes
      // normally, so the outcome has to be captured rather than caught.
      var hasFailed = false;
      await precacheImage(
        funFactImage(_urls[index]),
        context,
        onError: (_, _) => hasFailed = true,
      );
      debugPrint(
        '[FunFact] fact $index ready in '
        '${DateTime.now().difference(startedAt).inMilliseconds}ms '
        '(failed: $hasFailed)',
      );

      // The child tapped on while this was loading — that fact owns the screen.
      if (!mounted || _index != index) {
        return;
      }

      // A broken URL means a teacher deleted that image since the batch was
      // built. Skip the slot rather than stalling on a dead frame.
      if (hasFailed) {
        _next();
        return;
      }

      setState(() => _isImageReady = true);
      // A fact only counts as watched once it has actually been on screen.
      // Fire-and-forget, but never unhandled: a failed prefs write must not
      // take down the story.
      unawaited(
        FunFactController.instance
            .saveProgress(widget.subjectId, index + 1)
            .catchError((Object e) {
              debugPrint('[FunFact] saveProgress failed: $e');
            }),
      );

      // Play THIS fact's own background track, then hold the countdown until it
      // has loaded (or we've settled that there's none). The image is already
      // on screen — only the progress waits. A timeout keeps a slow/stuck load
      // from freezing the story.
      _audioReady = FunFactBgSoundPlayer.instance.playIndex(index);
      await _audioReady!.timeout(
        const Duration(seconds: 8),
        onTimeout: () {},
      );
      if (!mounted || _index != index) {
        return;
      }

      _progress.forward(from: 0);
    } catch (error, stack) {
      debugPrint('[FunFact] fact $index failed: $error\n$stack');
    }
  }

  void _next() {
    if (_index >= _urls.length - 1) {
      Get.back<void>();
      return;
    }
    _showFactAt(_index + 1);
  }

  void _previous() {
    if (_index == 0) {
      _progress.forward(from: 0);
      return;
    }
    _showFactAt(_index - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.white),
            )
          : GestureDetector(
              // Left third goes back, the rest advances — the gesture every
              // child already knows from Instagram.
              onTapUp: (details) {
                final width = MediaQuery.sizeOf(context).width;
                if (details.globalPosition.dx < width / 3) {
                  _previous();
                } else {
                  _next();
                }
              },
              onLongPressStart: (_) => _progress.stop(),
              // Never resume onto a fact whose image is still loading — same
              // skip-ahead bug the gating above prevents.
              onLongPressEnd: (_) {
                if (_isImageReady) {
                  _progress.forward();
                }
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Already decoded by _showFactAt, so this paints on its first
                  // frame. Until then the story holds on the previous state
                  // rather than showing a blank, un-timed fact.
                  if (_isImageReady)
                    Image(image: funFactImage(_urls[_index]), fit: BoxFit.cover),
                  // Keeps the header legible over a bright image.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [Color(0x99000000), Colors.transparent],
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Column(
                      children: [
                        _StoryProgressBars(
                          count: _urls.length,
                          currentIndex: _index,
                          progress: _progress,
                        ),
                        _StoryHeader(
                          title: widget.subjectTitle,
                          icon: widget.subjectIcon,
                          accent: widget.subjectAccent,
                          iconBackground: widget.subjectIconBackground,
                          onClose: () => Get.back<void>(),
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

class _StoryProgressBars extends StatelessWidget {
  const _StoryProgressBars({
    required this.count,
    required this.currentIndex,
    required this.progress,
  });

  final int count;
  final int currentIndex;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: List.generate(count, (index) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(
                  height: 3,
                  child: AnimatedBuilder(
                    animation: progress,
                    builder: (context, _) {
                      // Past facts stay full, future ones stay empty, and only
                      // the current one tracks the animation.
                      final double value = index < currentIndex
                          ? 1
                          : index > currentIndex
                          ? 0
                          : progress.value;
                      return LinearProgressIndicator(
                        value: value,
                        backgroundColor: AppColors.white.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StoryHeader extends StatelessWidget {
  const _StoryHeader({
    required this.title,
    required this.icon,
    required this.accent,
    required this.iconBackground,
    required this.onClose,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final Color iconBackground;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 0),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: accent, size: 21),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  "TODAY'S FACT",
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: AppColors.white),
          ),
        ],
      ),
    );
  }
}
