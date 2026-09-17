import 'package:flutter/material.dart';

/// 8pt grid spacing scale and common [EdgeInsets] and [SizedBox] spacing helpers.
abstract final class AppSpacing {
  // --- 8-Point Grid Scale (double values) ---
  /// Extra small spacing (4.0 pt).
  static const double xs = 4.0;

  /// Small spacing (8.0 pt).
  static const double sm = 8.0;

  /// Medium spacing (16.0 pt).
  static const double md = 16.0;

  /// Large spacing (24.0 pt).
  static const double lg = 24.0;

  /// Extra large spacing (32.0 pt).
  static const double xl = 32.0;

  /// Double extra large spacing (48.0 pt).
  static const double xxl = 48.0;

  /// Triple extra large spacing (64.0 pt).
  static const double xxxl = 64.0;

  // --- Common EdgeInsets Presets ---
  /// Zero insets.
  static const EdgeInsets zero = EdgeInsets.zero;

  /// Uniform padding of 4.0 pt.
  static const EdgeInsets paddingAllXs = EdgeInsets.all(xs);

  /// Uniform padding of 8.0 pt.
  static const EdgeInsets paddingAllSm = EdgeInsets.all(sm);

  /// Uniform padding of 16.0 pt.
  static const EdgeInsets paddingAllMd = EdgeInsets.all(md);

  /// Uniform padding of 24.0 pt.
  static const EdgeInsets paddingAllLg = EdgeInsets.all(lg);

  /// Uniform padding of 32.0 pt.
  static const EdgeInsets paddingAllXl = EdgeInsets.all(xl);

  /// Horizontal padding presets.
  static const EdgeInsets paddingHSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets paddingHMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingHXl = EdgeInsets.symmetric(horizontal: xl);

  /// Vertical padding presets.
  static const EdgeInsets paddingVSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets paddingVMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingVLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets paddingVXl = EdgeInsets.symmetric(vertical: xl);

  /// Screen scaffold content padding (24h, 16v).
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  /// Modal and card standard inner padding.
  static const EdgeInsets cardPadding = EdgeInsets.all(md);

  // --- Vertical Gap Widgets (SizedBox) ---
  static const SizedBox gapVXs = SizedBox(height: xs);
  static const SizedBox gapVSm = SizedBox(height: sm);
  static const SizedBox gapVMd = SizedBox(height: md);
  static const SizedBox gapVLg = SizedBox(height: lg);
  static const SizedBox gapVXl = SizedBox(height: xl);
  static const SizedBox gapVXxl = SizedBox(height: xxl);

  // --- Horizontal Gap Widgets (SizedBox) ---
  static const SizedBox gapHXs = SizedBox(width: xs);
  static const SizedBox gapHSm = SizedBox(width: sm);
  static const SizedBox gapHMd = SizedBox(width: md);
  static const SizedBox gapHLg = SizedBox(width: lg);
  static const SizedBox gapHXl = SizedBox(width: xl);
}
