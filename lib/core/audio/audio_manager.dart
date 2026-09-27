import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../domain/game/game_role.dart';
import 'audio_catalog.dart';
import 'audio_event.dart';

typedef AudioEnabledGetter = bool Function();

/// Central audio hub. Widgets call [play] with [AudioEvent] — never asset paths.
class AudioManager {
  AudioManager({
    AudioEnabledGetter? musicEnabled,
    AudioEnabledGetter? sfxEnabled,
    AudioPlayer? musicPlayer,
    AudioPlayer? sfxPlayer,
  })  : _musicEnabled = musicEnabled ?? (() => true),
        _sfxEnabled = sfxEnabled ?? (() => true),
        _music = musicPlayer ?? AudioPlayer(),
        _sfx = sfxPlayer ?? AudioPlayer() {
    _music.setReleaseMode(ReleaseMode.loop);
    _sfx.setReleaseMode(ReleaseMode.stop);
  }

  final AudioEnabledGetter _musicEnabled;
  final AudioEnabledGetter _sfxEnabled;
  final AudioPlayer _music;
  final AudioPlayer _sfx;

  /// 0.0–1.0 master volumes (Settings toggles gate playback; volumes ready for sliders).
  double musicVolume = 0.45;
  double sfxVolume = 0.75;

  final Set<String> _missingProductionPaths = {};

  /// Play a semantic event. Honors Music / SFX enable flags.
  Future<void> play(AudioEvent event) async {
    final channel = AudioCatalog.channelFor(event);
    if (channel == AudioChannel.music) {
      if (!_musicEnabled()) return;
      await _playOn(
        _music,
        event,
        volume: musicVolume,
        loop: true,
      );
      return;
    }
    if (!_sfxEnabled()) return;
    await _playOn(
      _sfx,
      event,
      volume: sfxVolume,
      loop: false,
    );
  }

  Future<void> stopMusic() async {
    try {
      await _music.stop();
    } catch (e) {
      debugPrint('[AudioManager] stopMusic: $e');
    }
  }

  Future<void> stopSfx() async {
    try {
      await _sfx.stop();
    } catch (e) {
      debugPrint('[AudioManager] stopSfx: $e');
    }
  }

  /// ROLE DISTRIBUTION: shuffle → flip → role sting.
  Future<void> playRoleRevealSequence(GameRole role) async {
    if (!_sfxEnabled()) return;
    await play(AudioEvent.roleShuffle);
    await Future<void>.delayed(const Duration(milliseconds: 280));
    await play(AudioEvent.roleCardFlip);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await play(_roleEvent(role));
  }

  /// POLICE GUESS: confirm → lock → silence → result (+ optional tag).
  Future<void> playGuessResultSequence({
    required bool correct,
    bool policeTag = false,
  }) async {
    if (!_sfxEnabled()) return;
    await play(AudioEvent.confirmGuess);
    await play(AudioEvent.guessLocked);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    await play(correct ? AudioEvent.correctGuess : AudioEvent.wrongGuess);
    if (policeTag) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await play(AudioEvent.policeTag);
    }
  }

  AudioEvent _roleEvent(GameRole role) {
    switch (role) {
      case GameRole.police:
        return AudioEvent.rolePolice;
      case GameRole.chor:
        return AudioEvent.roleChor;
      case GameRole.dakat:
        return AudioEvent.roleDakat;
      case GameRole.babu:
        return AudioEvent.roleBabu;
    }
  }

  Future<void> _playOn(
    AudioPlayer player,
    AudioEvent event, {
    required double volume,
    required bool loop,
  }) async {
    final preferred = AudioCatalog.pathFor(event);
    final fallback = AudioCatalog.placeholderFor(event);
    try {
      await player.stop();
      await player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
      await player.setVolume(volume.clamp(0.0, 1.0));
      await player.play(AssetSource(preferred));
    } catch (_) {
      if (_missingProductionPaths.add(preferred)) {
        debugPrint(
          '[AudioManager] missing $preferred — using placeholder $fallback',
        );
      }
      try {
        await player.stop();
        await player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
        await player.setVolume(volume.clamp(0.0, 1.0));
        await player.play(AssetSource(fallback));
      } catch (e) {
        debugPrint('[AudioManager] play($event) failed: $e');
      }
    }
  }

  void dispose() {
    try {
      _music.dispose();
      _sfx.dispose();
    } catch (e) {
      debugPrint('[AudioManager] dispose: $e');
    }
  }
}
