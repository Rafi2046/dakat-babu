import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages the active [Locale]. Defaults to Bengali (`bn`).
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => const Locale('bn');

  /// Switches between Bengali and English.
  void toggleLocale() {
    state = state.languageCode == 'bn'
        ? const Locale('en')
        : const Locale('bn');
  }

  void setLocale(Locale locale) {
    state = locale;
  }
}

/// App-wide locale provider. Watch in [MaterialApp] for live language updates.
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);
