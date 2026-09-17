import 'dart:ui';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';

/// A card container supporting frosted glassmorphism, glowing shadows, and interactive ripples.
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

  /// Optional ambient glow color behind the card.
  final Color? glowColor;

  /// Whether to apply BackdropFilter frosted glassmorphism effect.
  final bool isGlass;

  /// Callback when tapped.
  final VoidCallback? onTap;

  const GameCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.paddingAllMd,
    this.backgroundColor,
    this.borderColor,
    this.gradient,
    this.glowColor,
    this.isGlass = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = borderColor ?? (isGlass ? AppColors.glassBorder : AppColors.borderDark);
    final effectiveBg = backgroundColor ?? (isGlass ? AppColors.glassFill : AppColors.surfaceDark);

    Widget innerBox = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? effectiveBg : null,
        gradient: gradient,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: effectiveBorder,
          width: 1.0,
        ),
        boxShadow: [
          if (glowColor != null)
            BoxShadow(
              color: glowColor!.withValues(alpha: 0.16),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (isGlass) {
      innerBox = ClipRRect(
        borderRadius: AppRadius.cardRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: innerBox,
        ),
      );
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: AppRadius.cardRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardRadius,
          child: innerBox,
        ),
      );
    }

    return innerBox;
  }
}
