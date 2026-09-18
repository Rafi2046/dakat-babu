import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/app_text_styles.dart';

/// Extension methods on [BuildContext] for responsive styling and notifications.
extension BuildContextX on BuildContext {
  /// Theme data of the current context.
  ThemeData get theme => Theme.of(this);

  /// Color scheme of the current context.
  ColorScheme get colorScheme => theme.colorScheme;

  /// Text theme of the current context.
  TextTheme get textTheme => theme.textTheme;

  /// Media query data of the current context.
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Total available screen width.
  double get screenWidth => mediaQuery.size.width;

  /// Total available screen height.
  double get screenHeight => mediaQuery.size.height;

  /// Safe area padding.
  EdgeInsets get safeAreaPadding => mediaQuery.padding;

  /// Shows a customized snackbar notification.
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

  /// Shows an error snackbar notification.
  void showErrorSnackBar(String message) {
    showSnackBar(message, backgroundColor: AppColors.error);
  }

  /// Shows a success snackbar notification.
  void showSuccessSnackBar(String message) {
    showSnackBar(message, backgroundColor: AppColors.success);
  }
}

/// Extension methods on [String] for text formatting.
extension StringX on String {
  /// Capitalizes the first letter of the string.
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Extracts up to 2 uppercase initials from a player name.
  String get initials {
    if (trim().isEmpty) return '?';
    final parts = trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  /// Cleans and formats an input room code string.
  String get cleanRoomCode => trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
}

/// Rich helper extensions on [GameRole] for UI rendering.
extension GameRoleX on GameRole {
  /// Human-readable Bengali / English title for the role.
  String get displayName {
    switch (this) {
      case GameRole.raja:
        return 'Raja (King)';
      case GameRole.mantri:
        return 'Mantri (Minister)';
      case GameRole.police:
        return 'Police (Inspector)';
      case GameRole.chor:
        return 'Chor (Thief)';
      case GameRole.chintaykari:
        return 'Chintaykari (Snatcher)';
      case GameRole.batpar:
        return 'Batpar (Swindler)';
    }
  }

  /// Short single-word title.
  String get shortName {
    switch (this) {
      case GameRole.raja:
        return 'Raja';
      case GameRole.mantri:
        return 'Mantri';
      case GameRole.police:
        return 'Police';
      case GameRole.chor:
        return 'Chor';
      case GameRole.chintaykari:
        return 'Chintaykari';
      case GameRole.batpar:
        return 'Batpar';
    }
  }

  /// Guaranteed base points value.
  int get points {
    switch (this) {
      case GameRole.raja:
        return AppConstants.rajaPoints;
      case GameRole.mantri:
        return AppConstants.mantriPoints;
      case GameRole.police:
        return AppConstants.policeCorrectPoints;
      case GameRole.chor:
        return AppConstants.chorSuccessPoints;
      case GameRole.chintaykari:
        return AppConstants.chintaykariDefaultPoints;
      case GameRole.batpar:
        return AppConstants.batparDefaultPoints;
    }
  }

  /// Primary color associated with this role.
  Color get color {
    switch (this) {
      case GameRole.raja:
        return AppColors.raja;
      case GameRole.mantri:
        return AppColors.mantri;
      case GameRole.police:
        return AppColors.police;
      case GameRole.chor:
        return AppColors.chor;
      case GameRole.chintaykari:
        return AppColors.chintaykari;
      case GameRole.batpar:
        return AppColors.batpar;
    }
  }

  /// Background container tint for badges.
  Color get containerColor {
    switch (this) {
      case GameRole.raja:
        return AppColors.rajaContainer;
      case GameRole.mantri:
        return AppColors.mantriContainer;
      case GameRole.police:
        return AppColors.policeContainer;
      case GameRole.chor:
        return AppColors.chorContainer;
      case GameRole.chintaykari:
        return AppColors.chintaykariContainer;
      case GameRole.batpar:
        return AppColors.batparContainer;
    }
  }

  /// Background card gradient for role reveal.
  LinearGradient get gradient {
    switch (this) {
      case GameRole.raja:
        return AppColors.rajaGradient;
      case GameRole.mantri:
        return AppColors.mantriGradient;
      case GameRole.police:
        return AppColors.policeGradient;
      case GameRole.chor:
        return AppColors.chorGradient;
      case GameRole.chintaykari:
        return AppColors.chintaykariGradient;
      case GameRole.batpar:
        return AppColors.batparGradient;
    }
  }

  /// Image asset path for role icon.
  String get iconAsset {
    switch (this) {
      case GameRole.raja:
        return AppAssets.rajaCrown;
      case GameRole.mantri:
        return AppAssets.mantriScroll;
      case GameRole.police:
        return AppAssets.policeBadge;
      case GameRole.chor:
      case GameRole.chintaykari:
      case GameRole.batpar:
        return AppAssets.chorMask;
    }
  }

  /// Game role objective instructions displayed on the secret card.
  String get instructions {
    switch (this) {
      case GameRole.raja:
        return 'You are the King! Reveal your identity to the court. You earn 1000 points automatically.';
      case GameRole.mantri:
        return 'You are the Minister! Support the King and observe quietly. You earn 800 points automatically.';
      case GameRole.police:
        return 'You are the Police! You must interrogate the suspects and deduce who the Chor is. Guess right for points!';
      case GameRole.chor:
        return 'You are the Chor (Thief)! Keep a straight face and deceive the Police. If they guess wrong, you steal points!';
      case GameRole.chintaykari:
        return 'You are the Chintaykari (Snatcher)! Blend into the crowd and confuse the Police. You earn your points safely!';
      case GameRole.batpar:
        return 'You are the Batpar (Swindler)! Act natural and keep the Police guessing. You earn your points safely!';
    }
  }
}
