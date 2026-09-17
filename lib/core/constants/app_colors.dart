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

  // --- Distinct Role Glows for party cards and badges ---
  /// Raja ambient gold glow.
  static const Color rajaGlow = Color(0x66FFB703);

  /// Mantri ambient violet glow.
  static const Color mantriGlow = Color(0x668338EC);

  /// Police ambient cyan/blue glow.
  static const Color policeGlow = Color(0x6600B4D8);

  /// Chor ambient crimson glow.
  static const Color chorGlow = Color(0x66E63946);

  /// Brand primary ambient glow.
  static const Color primaryGlow = Color(0x556C5CE7);

  /// Secondary electric cyan glow.
  static const Color secondaryGlow = Color(0x5500CEC9);

  // --- Glassmorphism Surface Tokens ---
  /// Translucent frosted glass card fill - sleek, luminous and modern.
  static const Color glassFill = Color(0x38121624);

  /// Ultra-subtle inner glass highlight.
  static const Color glassHighlight = Color(0x14FFFFFF);

  /// Subtle iridescent hairline border for frosted glass.
  static const Color glassBorder = Color(0x1FFFFFFF);

  /// Active focused border for frosted glass cards.
  static const Color glassBorderFocused = Color(0x556C5CE7);

  // --- Game Gradients ---
  /// Multi-stop deep ambient background gradient with cosmic undertones.
  static const LinearGradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF141028), // Subtle royal midnight indigo
      Color(0xFF0C0E16), // Deep rich obsidian slate
      Color(0xFF08090E), // Base pure dark
    ],
    stops: [0.0, 0.55, 1.0],
  );

  /// Radiant gold gradient for Raja cards and headers.
  static const LinearGradient rajaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFD166),
      Color(0xFFFFB703),
      Color(0xFFFB8500),
    ],
  );

  /// Imperial violet gradient for Mantri.
  static const LinearGradient mantriGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFC77DFF),
      Color(0xFF9D4EDD),
      Color(0xFF7209B7),
    ],
  );

  /// Tactical azure gradient for Police.
  static const LinearGradient policeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF48CAE4),
      Color(0xFF0096C7),
      Color(0xFF023E8A),
    ],
  );

  /// Rogue crimson gradient for Chor.
  static const LinearGradient chorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF5D73),
      Color(0xFFE63946),
      Color(0xFF9E0012),
    ],
  );

  /// Primary button/header gradient with depth.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF7C6CF5),
      Color(0xFF6C5CE7),
      Color(0xFF4834D4),
    ],
  );
}
