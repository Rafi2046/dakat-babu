import 'package:dakat_babu/core/audio/audio_catalog.dart';
import 'package:dakat_babu/core/audio/audio_event.dart';
import 'package:dakat_babu/core/audio/audio_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AudioCatalog', () {
    test('every AudioEvent has a production path and placeholder', () {
      for (final event in AudioEvent.values) {
        expect(AudioCatalog.paths.containsKey(event), isTrue, reason: '$event path');
        expect(
          AudioCatalog.placeholders.containsKey(event),
          isTrue,
          reason: '$event placeholder',
        );
        expect(AudioCatalog.pathFor(event), isNotEmpty);
        expect(AudioCatalog.placeholderFor(event), isNotEmpty);
      }
    });

    test('homeTheme is music; others are sfx', () {
      expect(AudioCatalog.channelFor(AudioEvent.homeTheme), AudioChannel.music);
      expect(AudioCatalog.channelFor(AudioEvent.buttonTap), AudioChannel.sfx);
      expect(AudioCatalog.channelFor(AudioEvent.correctGuess), AudioChannel.sfx);
    });
  });

  group('AudioManager mute gates', () {
    test('respects music and sfx disabled flags without throwing', () async {
      var music = false;
      var sfx = false;
      final audio = AudioManager(
        musicEnabled: () => music,
        sfxEnabled: () => sfx,
        enablePlayback: false,
      );
      addTearDown(audio.dispose);

      await audio.play(AudioEvent.homeTheme);
      await audio.play(AudioEvent.buttonTap);

      music = true;
      sfx = true;
      await audio.play(AudioEvent.buttonTap);
      await audio.stopMusic();
      await audio.stopSfx();
    });
  });
}
