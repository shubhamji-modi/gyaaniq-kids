import 'package:just_audio/just_audio.dart';

/// Small app-wide sound effects helper. Loads short asset clips once and
/// replays them on demand. Failures are swallowed — sound is never critical.
class AppSounds {
  AppSounds._();
  static final AppSounds instance = AppSounds._();

  final AudioPlayer _player = AudioPlayer();
  bool _greatJobLoaded = false;

  /// Plays the "great job" encouragement voice (used on quiz Next).
  Future<void> playGreatJob() async {
    try {
      if (!_greatJobLoaded) {
        await _player.setAsset('assets/ringtone/voice_great_job.mp3');
        _greatJobLoaded = true;
      }
      await _player.seek(Duration.zero);
      await _player.play();
    } catch (_) {
      // Ignore — a missing/failed sound must not break the quiz flow.
    }
  }

  void dispose() {
    _player.dispose();
  }
}
