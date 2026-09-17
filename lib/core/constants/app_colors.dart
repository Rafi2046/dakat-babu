import 'package:flutter/material.dart';

/// Centralized color palette for DakatBabu.
///
/// Defines brand colors, background/surface layers, text tones,
/// and distinctive role-specific colors for Raja, Mantri, Police, and Chor.
abstract final class AppColors {
  // --- Brand Colors ---
  /// Deep royal purple primary brand color.
  static const Color primary = Color(0xFF6C5CE7);

  /// Slightly lighter primary variant for hover/press states.
  static const Color primaryLight = Color(0xFF8075E8);

  /// Deep primary shade for borders or active indicators.
  static const Color primaryDark = Color(0xFF4834D4);

  /// Vibrant electric teal secondary accent.
  static const Color secondary = Color(0xFF00CEC9);

  /// Warm secondary amber accent.
  static const Color accent = Color(0xFFFFD166);

  // --- Background and Surface Colors (Dark Theme First) ---
  /// Deep dark slate background.
  static const Color backgroundDark = Color(0xFF0B0E14);

  /// Card and container surface in dark mode.
  static const Color surfaceDark = Color(0xFF151922);

  /// Elevated surface for dialogs and modal sheets in dark mode.
  static const Color surfaceElevatedDark = Color(0xFF1F2432);

  /// Subtle border color for dark containers.
  static const Color borderDark = Color(0xFF282E3E);

  // --- Background and Surface Colors (Light Theme) ---
  /// Crisp warm light background.
  static const Color backgroundLight = Color(0xFFF7F8FA);

  /// Pure white card surface for light mode.
  static const Color surfaceLight = Color(0xFFFFFFFF);

  /// Elevated surface for dialogs in light mode.
  static const Color surfaceElevatedLight = Color(0xFFF0F2F6);

  /// Subtle border color for light containers.
  static const Color borderLight = Color(0xFFE2E8F0);

  // --- Distinct Role Colors for Chor-Police-Raja-Mantri ---
  /// Raja (King) - Majestic Royal Gold.
  static const Color raja = Color(0xFFFFB703);

  /// Raja role background tint for badges and highlights.
  static const Color rajaContainer = Color(0x33FFB703);

  /// Mantri (Minister) - Imperial Violet.
  static const Color mantri = Color(0xFF8338EC);

  /// Mantri role background tint for badges and highlights.
  static const Color mantriContainer = Color(0x338338EC);

  /// Police (Inspector) - Authority Ocean/Navy Blue.
  static const Color police = Color(0xFF0077B6);

  /// Police role background tint for badges and highlights.
  static const Color policeContainer = Color(0x330077B6);

  /// Chor (Thief) - Rogue Crimson Red.
  static const Color chor = Color(0xFFE63946);

  /// Chor role background tint for badges and highlights.
  static const Color chorContainer = Color(0x33E63946);

  // --- Feedback & State Colors ---
  /// Positive success green.
  static const Color success = Color(0xFF06D6A0);

  /// Error and destructive action red.
  static const Color error = Color(0xFFEF476F);

  /// Cautionary warning yellow.
  static const Color warning = Color(0xFFFFB703);

  /// Neutral info blue.
  static const Color info = Color(0xFF118AB2);

  // --- Text Colors ---
  /// High-emphasis text for dark themes.
  static const Color textLightPrimary = Color(0xFFF8FAFC);

  /// Medium-emphasis secondary text for dark themes.
  static const Color textLightSecondary = Color(0xFF94A3B8);

  /// Disabled or muted text for dark themes.
  static const Color textLightMuted = Color(0xFF64748B);

  /// High-emphasis text for light themes.
  static const Color textDarkPrimary = Color(0xFF0F172A);

  /// Medium-emphasis secondary text for light themes.
  static const Color textDarkSecondary = Color(0xFF475569);

  /// Disabled or muted text for light themes.
  static const Color textDarkMuted = Color(0xFF94A3B8);

  // --- Game Gradients ---
  /// Dark atmospheric ambient background gradient.
  static const LinearGradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF121622),
      Color(0xFF0B0E14),
    ],
  );

  /// Primary button/header gradient.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF6C5CE7),
      Color(0xFF4834D4),
    ],
  );

  /// Raja role reveal card gradient.
  static const LinearGradient rajaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFB703),
      Color(0xFFFB8500),
    ],
  );

  /// Mantri role reveal card gradient.
  static const LinearGradient mantriGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF9D4EDD),
      Color(0xFF7209B7),
    ],
  );

  /// Police role reveal card gradient.
  static const LinearGradient policeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00B4D8),
      Color(0xFF0077B6),
    ],
  );

  /// Chor role reveal card gradient.
  static const LinearGradient chorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF4D6D),
      Color(0xFFC9184A),
    ],
  );
}
