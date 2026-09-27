import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Home-scoped Bangla typography (Noto Sans Bengali).
abstract final class HomeTextStyles {
  static TextStyle _base({
    required double fontSize,
    required FontWeight fontWeight,
    Color? color,
    double height = 1.3,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.notoSansBengali(
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
        color: color ?? AppColors.textLightPrimary,
      );

  static TextStyle hero({Color? color}) => _base(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.2,
      );

  static TextStyle title({Color? color}) => _base(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle subtitle({Color? color}) => _base(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.textLightSecondary,
      );

  static TextStyle body({Color? color}) => _base(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle caption({Color? color}) => _base(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.textLightSecondary,
      );

  static TextStyle chip({Color? color}) => _base(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle statValue({Color? color}) => _base(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: color ?? AppColors.raja,
      );

  static TextStyle nav({Color? color}) => _base(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textLightSecondary,
      );
}
