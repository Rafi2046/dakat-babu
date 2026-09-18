import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service responsible for playing lightweight game sound effects.
class SoundService {
  final AudioPlayer _player = AudioPlayer();

  SoundService() {
    _player.setReleaseMode(ReleaseMode.stop);
  }

  /// Plays a subtle clock tick during the tense Police guessing phase.
  Future<void> playTick() async {
    try {
      await _player.stop();
      await _player.setVolume(0.35);
      await _player.play(AssetSource('sounds/ticking.wav'));
    } catch (e) {
      debugPrint('[SoundService] playTick error: $e');
    }
  }

  /// Plays a short dramatic suspense sting right before results reveal.
  Future<void> playSting() async {
    try {
      await _player.stop();
      await _player.setVolume(0.65);
      await _player.play(AssetSource('sounds/sting.wav'));
    } catch (e) {
      debugPrint('[SoundService] playSting error: $e');
    }
  }

  /// Plays a victorious chime when Police correctly unmasks the Chor.
  Future<void> playSuccess() async {
    try {
      await _player.stop();
      await _player.setVolume(0.75);
      await _player.play(AssetSource('sounds/success.wav'));
    } catch (e) {
      debugPrint('[SoundService] playSuccess error: $e');
    }
  }

  /// Plays a low failure buzzer when the Chor outsmarts the Police.
  Future<void> playFailure() async {
    try {
      await _player.stop();
      await _player.setVolume(0.60);
      await _player.play(AssetSource('sounds/failure.wav'));
    } catch (e) {
      debugPrint('[SoundService] playFailure error: $e');
    }
  }

  /// Cleans up player resources.
  void dispose() {
    try {
      _player.dispose();
    } catch (e) {
      debugPrint('[SoundService] dispose error: $e');
    }
  }
}

/// Global provider for [SoundService].
final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService();
  ref.onDispose(service.dispose);
  return service;
});
