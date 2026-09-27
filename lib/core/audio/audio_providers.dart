import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio_manager.dart';
import 'audio_settings_provider.dart';

/// App-wide [AudioManager]. Gates playback via [audioSettingsProvider].
final audioManagerProvider = Provider<AudioManager>((ref) {
  final manager = AudioManager(
    musicEnabled: () => ref.read(audioSettingsProvider).isMusicOn,
    sfxEnabled: () => ref.read(audioSettingsProvider).isSfxOn,
  );
  ref.onDispose(manager.dispose);
  return manager;
});
