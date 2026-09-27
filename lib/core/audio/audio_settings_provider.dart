import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';

/// Snapshot of music / SFX enable flags.
class AudioSettings {
  final bool isMusicOn;
  final bool isSfxOn;

  const AudioSettings({
    required this.isMusicOn,
    required this.isSfxOn,
  });

  AudioSettings copyWith({bool? isMusicOn, bool? isSfxOn}) => AudioSettings(
        isMusicOn: isMusicOn ?? this.isMusicOn,
        isSfxOn: isSfxOn ?? this.isSfxOn,
      );
}

/// Persists Music / SFX toggles via [PlayerProfileStore] (SharedPreferences).
class AudioSettingsNotifier extends Notifier<AudioSettings> {
  @override
  AudioSettings build() {
    final store = ref.read(playerProfileStoreProvider);
    return AudioSettings(
      isMusicOn: store.musicEnabled,
      isSfxOn: store.soundEnabled,
    );
  }

  Future<void> setMusicOn(bool value) async {
    state = state.copyWith(isMusicOn: value);
    await ref.read(playerProfileStoreProvider).setMusicEnabled(value);
  }

  Future<void> setSfxOn(bool value) async {
    state = state.copyWith(isSfxOn: value);
    await ref.read(playerProfileStoreProvider).setSoundEnabled(value);
  }

  Future<void> toggleMusic() => setMusicOn(!state.isMusicOn);

  Future<void> toggleSfx() => setSfxOn(!state.isSfxOn);
}

final audioSettingsProvider =
    NotifierProvider<AudioSettingsNotifier, AudioSettings>(
  AudioSettingsNotifier.new,
);
