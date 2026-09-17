import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';

/// A card container with subtle borders and optional accent gradient glowing border.
class GameCard extends StatelessWidget {
  /// Internal child widget.
  final Widget child;

  /// Custom padding inside the card (defaults to [AppSpacing.paddingAllMd]).
  final EdgeInsetsGeometry padding;

  /// Optional background color override.
  final Color? backgroundColor;

  /// Optional border color override.
  final Color? borderColor;

  /// Optional gradient background (e.g. for role cards).
  final Gradient? gradient;

  /// Callback when tapped.
  final VoidCallback? onTap;

  const GameCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.paddingAllMd,
    this.backgroundColor,
    this.borderColor,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (backgroundColor ?? AppColors.surfaceDark) : null,
        gradient: gradient,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: borderColor ?? AppColors.borderDark,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: AppRadius.cardRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardRadius,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
