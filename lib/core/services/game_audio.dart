import 'audio/audio_event.dart';
import 'audio/audio_manager.dart';
import 'audio/audio_providers.dart';

export 'audio/audio_event.dart' show AudioEvent;

/// Back-compat aliases for older call sites.
typedef GameAudioEvent = AudioEvent;

/// Plays semantic audio when SFX are enabled (via [AudioManager]).
abstract final class GameAudio {
  static Future<void> play(
    AudioManager audio, {
    required AudioEvent event,
  }) =>
      audio.play(event);

  /// Prefer [audioManagerProvider] directly.
  @Deprecated('Pass AudioManager from audioManagerProvider')
  static Future<void> playLegacy({
    required AudioManager audio,
    required AudioEvent event,
    required bool enabled,
  }) async {
    if (!enabled) return;
    await audio.play(event);
  }
}

export 'audio/audio_providers.dart' show audioManagerProvider;
