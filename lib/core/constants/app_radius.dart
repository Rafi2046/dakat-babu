import 'package:flutter/material.dart';

/// Corner radius values and [BorderRadius] presets for cards, buttons, dialogs, and pills.
abstract final class AppRadius {
  // --- Raw Radius Values ---
  /// Extra small corner radius (4.0 pt).
  static const double xs = 4.0;

  /// Small corner radius (8.0 pt).
  static const double sm = 8.0;

  /// Medium corner radius (12.0 pt).
  static const double md = 12.0;

  /// Large corner radius (16.0 pt).
  static const double lg = 16.0;

  /// Extra large corner radius (24.0 pt).
  static const double xl = 24.0;

  /// Pill/circular corner radius (999.0 pt).
  static const double full = 999.0;

  // --- Radius Presets ---
  /// Standard Radius.circular for small tags and chips.
  static const Radius radiusSm = Radius.circular(sm);

  /// Standard Radius.circular for medium cards.
  static const Radius radiusMd = Radius.circular(md);

  /// Standard Radius.circular for elevated cards and modals.
  static const Radius radiusLg = Radius.circular(lg);

  // --- BorderRadius Presets ---
  /// Uniform border radius for chips and small tags (8pt).
  static const BorderRadius chipRadius = BorderRadius.all(Radius.circular(sm));

  /// Uniform border radius for standard buttons (12pt).
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(md));

  /// Uniform border radius for cards and tiles (16pt).
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(lg));

  /// Uniform border radius for dialogs and action sheets (24pt).
  static const BorderRadius dialogRadius = BorderRadius.all(Radius.circular(xl));

  /// Fully rounded pill border radius.
  static const BorderRadius pillRadius = BorderRadius.all(Radius.circular(full));

  /// Top rounded border radius for bottom sheets.
  static const BorderRadius bottomSheetRadius = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
}
