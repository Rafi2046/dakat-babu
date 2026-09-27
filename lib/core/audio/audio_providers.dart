import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';
import 'audio_manager.dart';

/// App-wide [AudioManager]. Reads Music/SFX flags from [PlayerProfileStore] at play time.
final audioManagerProvider = Provider<AudioManager>((ref) {
  final manager = AudioManager(
    musicEnabled: () => ref.read(playerProfileStoreProvider).musicEnabled,
    sfxEnabled: () => ref.read(playerProfileStoreProvider).soundEnabled,
  );
  ref.onDispose(manager.dispose);
  return manager;
});
