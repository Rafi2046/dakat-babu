import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography definitions for DakatBabu using GoogleFonts.
///
/// Exposes standard typography styles and a pre-configured [TextTheme]
/// for light and dark application themes.
abstract final class AppTextStyles {
  /// Base primary font family used across the application.
  static String get fontFamily => GoogleFonts.outfit().fontFamily ?? 'Outfit';

  // --- Headings ---
  /// Grand dramatic hero game title with crisp depth and subtle gold warmth.
  static TextStyle heroTitle({Color? color}) => GoogleFonts.outfit(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.15,
        color: color ?? AppColors.raja,
        shadows: const [
          Shadow(
            color: Color(0x35FFB703),
            blurRadius: 16,
            offset: Offset(0, 2),
          ),
          Shadow(
            color: Color(0x60000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      );

  /// Display heading 1 (Hero screens, role reveals).
  static TextStyle heading1({Color? color}) => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.2,
        color: color ?? AppColors.textLightPrimary,
      );

  /// Section heading 2 (Dialogs, card titles, lobby headers).
  static TextStyle heading2({Color? color}) => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.25,
        color: color ?? AppColors.textLightPrimary,
      );

  /// Subtitle heading 3 (Player tiles, group titles).
  static TextStyle heading3({Color? color}) => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.3,
        color: color ?? AppColors.textLightPrimary,
      );

  // --- Body Styles ---
  /// High-emphasis primary body copy.
  static TextStyle bodyLarge({Color? color}) => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.4,
        color: color ?? AppColors.textLightPrimary,
      );

  /// Standard medium body copy.
  static TextStyle bodyMedium({Color? color}) => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.4,
        color: color ?? AppColors.textLightSecondary,
      );

  /// Subtle secondary body copy.
  static TextStyle bodySmall({Color? color}) => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.35,
        color: color ?? AppColors.textLightMuted,
      );

  // --- Interactive & Accent Styles ---
  /// Button label typography with high legibility.
  static TextStyle button({Color? color}) => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        height: 1.2,
        color: color ?? AppColors.textLightPrimary,
      );

  /// Small caption text for timestamps and room IDs.
  static TextStyle caption({Color? color}) => GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        height: 1.25,
        color: color ?? AppColors.textLightMuted,
      );

  /// Role badge and role card title typography.
  static TextStyle roleTitle({Color? color}) => GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.0,
        height: 1.1,
        color: color ?? AppColors.textLightPrimary,
      );

  /// Constructs a complete Material [TextTheme] for the given [brightness].
  static TextTheme createTextTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primaryColor =
        isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary;
    final secondaryColor =
        isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;

    return TextTheme(
      displayLarge: heading1(color: primaryColor),
      headlineMedium: heading2(color: primaryColor),
      titleLarge: heading3(color: primaryColor),
      bodyLarge: bodyLarge(color: primaryColor),
      bodyMedium: bodyMedium(color: secondaryColor),
      bodySmall: bodySmall(color: secondaryColor),
      labelLarge: button(color: primaryColor),
      labelSmall: caption(color: secondaryColor),
    );
  }
}
