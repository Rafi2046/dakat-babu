import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';

/// Manages [ThemeMode]. Defaults to dark; persists via [PlayerProfileStore].
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final store = ref.read(playerProfileStoreProvider);
    return _parse(store.themeMode);
  }

  void toggleTheme() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(next);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await ref.read(playerProfileStoreProvider).setThemeMode(_encode(mode));
  }

  static ThemeMode _parse(String raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      case 'dark':
      default:
        return ThemeMode.dark;
    }
  }

  static String _encode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.dark:
        return 'dark';
    }
  }
}

/// App-wide theme mode. Watch in [MaterialApp] for live theme updates.
final themeModeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);
