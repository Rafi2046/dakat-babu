import 'sound_service.dart';

/// Named audio events mapped to [SoundService] helpers.
enum GameAudioEvent {
  buttonClick,
  roomJoined,
  countdown,
  roll,
  roleReveal,
  correctGuess,
  wrongGuess,
  policeTag,
  scoreIncrease,
  roundStart,
  finalVictory,
  badgeUnlock,
}

/// Plays [GameAudioEvent]s when sound is enabled.
abstract final class GameAudio {
  static Future<void> play(
    SoundService sound, {
    required GameAudioEvent event,
    required bool enabled,
  }) async {
    if (!enabled) return;
    switch (event) {
      case GameAudioEvent.roleReveal:
      case GameAudioEvent.roll:
      case GameAudioEvent.roundStart:
        await sound.playSting();
      case GameAudioEvent.correctGuess:
      case GameAudioEvent.policeTag:
      case GameAudioEvent.finalVictory:
      case GameAudioEvent.badgeUnlock:
      case GameAudioEvent.scoreIncrease:
        await sound.playSuccess();
      case GameAudioEvent.wrongGuess:
        await sound.playFailure();
      case GameAudioEvent.countdown:
      case GameAudioEvent.buttonClick:
      case GameAudioEvent.roomJoined:
        await sound.playTick();
    }
  }
}
