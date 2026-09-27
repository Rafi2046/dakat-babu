import 'audio/audio_event.dart';
import 'audio/audio_manager.dart';

export 'audio/audio_event.dart' show AudioEvent;
export 'audio/audio_providers.dart' show audioManagerProvider;

/// Back-compat alias.
typedef GameAudioEvent = AudioEvent;

/// Plays semantic audio through [AudioManager].
abstract final class GameAudio {
  static Future<void> play(
    AudioManager audio, {
    required AudioEvent event,
  }) =>
      audio.play(event);
}
