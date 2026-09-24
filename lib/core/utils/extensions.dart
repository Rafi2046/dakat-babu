import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/app_images.dart';
import '../constants/app_text_styles.dart';

/// Extension methods on [BuildContext] for responsive styling and notifications.
extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  double get screenWidth => mediaQuery.size.width;
  double get screenHeight => mediaQuery.size.height;
  EdgeInsets get safeAreaPadding => mediaQuery.padding;

  void showSnackBar(
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodyMedium(color: AppColors.textLightPrimary),
        ),
        backgroundColor: backgroundColor ?? AppColors.surfaceElevatedDark,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: action,
      ),
    );
  }

  void showErrorSnackBar(String message) {
    showSnackBar(message, backgroundColor: AppColors.error);
  }

  void showSuccessSnackBar(String message) {
    showSnackBar(message, backgroundColor: AppColors.success);
  }
}

/// Extension methods on [String] for text formatting.
extension StringX on String {
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String get initials {
    if (trim().isEmpty) return '?';
    final parts = trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String get cleanRoomCode =>
      trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
}

/// Rich helper extensions on [GameRole] for UI rendering.
extension GameRoleX on GameRole {
  String get displayName {
    switch (this) {
      case GameRole.police:
        return 'Police';
      case GameRole.babu:
        return 'Babu';
      case GameRole.chor:
        return 'Chor';
      case GameRole.dakat:
        return 'Dakat';
    }
  }

  String get shortName => displayName;

  /// Points shown for UI hints (actual scoring is +1 via GameEngine).
  int get points {
    switch (this) {
      case GameRole.police:
        return AppConstants.policeCorrectPoints;
      case GameRole.babu:
      case GameRole.chor:
      case GameRole.dakat:
        return AppConstants.wrongGuessSuspectPoints;
    }
  }

  Color get color {
    switch (this) {
      case GameRole.police:
        return AppColors.police;
      case GameRole.babu:
        return AppColors.raja;
      case GameRole.chor:
        return AppColors.chor;
      case GameRole.dakat:
        return AppColors.batpar;
    }
  }

  Color get containerColor {
    switch (this) {
      case GameRole.police:
        return AppColors.policeContainer;
      case GameRole.babu:
        return AppColors.rajaContainer;
      case GameRole.chor:
        return AppColors.chorContainer;
      case GameRole.dakat:
        return AppColors.batparContainer;
    }
  }

  LinearGradient get gradient {
    switch (this) {
      case GameRole.police:
        return AppColors.policeGradient;
      case GameRole.babu:
        return AppColors.rajaGradient;
      case GameRole.chor:
        return AppColors.chorGradient;
      case GameRole.dakat:
        return AppColors.batparGradient;
    }
  }

  String get iconAsset {
    switch (this) {
      case GameRole.police:
        return AppImages.roleCardPolice;
      case GameRole.babu:
        return AppImages.roleCardBabu;
      case GameRole.chor:
        return AppImages.roleCardChor;
      case GameRole.dakat:
        return AppImages.roleCardDakat;
    }
  }

  String get standingAsset {
    switch (this) {
      case GameRole.police:
        return AppImages.policeStanding;
      case GameRole.babu:
        return AppImages.babuStanding;
      case GameRole.chor:
        return AppImages.chorStanding;
      case GameRole.dakat:
        return AppImages.dakatStanding;
    }
  }

  String get instructions {
    switch (this) {
      case GameRole.police:
        return 'তোমার কাজ: চোরকে খুঁজে বের করো!';
      case GameRole.babu:
        return 'You are Babu! Your identity is public. Stay calm.';
      case GameRole.chor:
        return 'You are the Chor! Stay hidden — Police is hunting you.';
      case GameRole.dakat:
        return 'You are Dakat — a decoy. Confuse the Police!';
    }
  }
}
