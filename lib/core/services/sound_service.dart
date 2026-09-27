import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_event.dart';
import '../audio/audio_providers.dart';

/// Legacy thin wrapper — prefer [audioManagerProvider] + [AudioEvent].
@Deprecated('Use audioManagerProvider.play(AudioEvent...)')
class SoundService {
  SoundService(this._ref);

  final Ref _ref;

  Future<void> playTick() async {
    try {
      await _ref.read(audioManagerProvider).play(AudioEvent.timerTick);
    } catch (e) {
      debugPrint('[SoundService] playTick error: $e');
    }
  }

  Future<void> playSting() async {
    try {
      await _ref.read(audioManagerProvider).play(AudioEvent.tensionSting);
    } catch (e) {
      debugPrint('[SoundService] playSting error: $e');
    }
  }

  Future<void> playSuccess() async {
    try {
      await _ref.read(audioManagerProvider).play(AudioEvent.correctGuess);
    } catch (e) {
      debugPrint('[SoundService] playSuccess error: $e');
    }
  }

  Future<void> playFailure() async {
    try {
      await _ref.read(audioManagerProvider).play(AudioEvent.wrongGuess);
    } catch (e) {
      debugPrint('[SoundService] playFailure error: $e');
    }
  }

  void dispose() {}
}

/// Global provider for legacy [SoundService].
final soundServiceProvider = Provider<SoundService>((ref) {
  return SoundService(ref);
});
