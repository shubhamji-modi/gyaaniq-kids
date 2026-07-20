import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/service/api_service.dart';

/// Plays ambient background music behind the Fun Fact story interstitials.
///
/// The server hands out N random ACTIVE tracks with no per-student history —
/// so the URLs are fetched once, kept in memory, and looped locally. The whole
/// feature is best-effort: a missing library, a network hiccup or a dead URL
/// must never interrupt the story, so every failure is swallowed.
class FunFactBgSoundPlayer {
  FunFactBgSoundPlayer._();
  static final FunFactBgSoundPlayer instance = FunFactBgSoundPlayer._();

  /// How loud the bed sits under the story. Ambient, not foreground.
  static const double _volume = 0.35;

  final AudioPlayer _player = AudioPlayer();

  List<String> _urls = const [];

  /// True once a *valid* response (even an empty library) has been cached, so
  /// we don't re-hit the endpoint per Fun Fact display. A network error leaves
  /// this false so the next open can retry.
  bool _fetched = false;

  /// GET the batch of background-sound URLs once and keep them in memory.
  ///
  /// [count] is clamped to the server's [1..20] window. Safe to call eagerly
  /// (e.g. from the dashboard preload) so playback starts without a fetch wait.
  Future<void> ensureFetched({int count = 5}) async {
    if (_fetched) {
      return;
    }
    try {
      final res = await ApiService.instance.get<dynamic>(
        endpoint: ApiService.FUN_FACT_BG_SOUNDS,
        showLoader: false,
        queryParameters: {'count': count.clamp(1, 20)},
        fromJson: (json) => json,
      );

      if (!res.success || res.data is! Map<String, dynamic>) {
        return; // Leave _fetched false — a transient failure may retry.
      }

      final body = res.data as Map<String, dynamic>;
      final data = (body['data'] as Map<String, dynamic>?) ?? const {};
      final list = data['sounds'] as List<dynamic>? ?? const [];

      final urls = <String>[];
      for (final item in list) {
        if (item is! Map<String, dynamic>) {
          continue;
        }
        final audio = item['audio'];
        final url = audio is Map<String, dynamic>
            ? (audio['url'] as String?) ?? ''
            : '';
        if (url.isNotEmpty) {
          urls.add(url);
        }
      }

      _urls = urls;
      _fetched = true; // Empty library is a valid answer — don't keep retrying.
      debugPrint('[FunFactBgSound] cached ${_urls.length} track(s).');
    } catch (e) {
      debugPrint('[FunFactBgSound] fetch failed: $e');
    }
  }

  /// Plays the track that belongs to the fact at [factIndex] — fact 1 gets the
  /// 1st track, fact 2 the 2nd, and so on, so every slide of a story sounds
  /// different. Uses the first tracks of the fetched batch (API sends 5, a
  /// 3-fact story uses the first 3); wraps with modulo if a story somehow has
  /// more facts than the library has tracks.
  ///
  /// The single track loops (LoopMode.one) so a short clip fills the whole
  /// slide. The returned Future completes once the track has **loaded** (or
  /// there is none / it failed) — never when playback ends — so the caller can
  /// hold that fact's countdown until its audio is ready.
  Future<void> playIndex(int factIndex, {int count = 5}) async {
    await ensureFetched(count: count);
    if (_urls.isEmpty) {
      return; // Nothing to play — story runs silent, which is fine.
    }
    final url = _urls[factIndex % _urls.length];
    try {
      await _player.setLoopMode(LoopMode.one);
      // setAudioSource completes once the source is buffered enough to report
      // duration — this is the "audio loaded" moment the story gates on. A URL
      // that 404s (deleted between fetch and play) throws here and is
      // swallowed, exactly as intended.
      await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
      await _player.setVolume(_volume);
      // Not awaited: play()'s Future only completes when playback ends, which
      // for a looping track is never. Fire it and return once loaded.
      unawaited(_player.play());
    } catch (e) {
      debugPrint('[FunFactBgSound] play index $factIndex failed: $e');
    }
  }

  /// Stops playback. Call when the story closes.
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {
      // Ignore — stopping is best-effort.
    }
  }

  void dispose() {
    _player.dispose();
  }
}
