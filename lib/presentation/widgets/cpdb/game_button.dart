import 'package:flutter/material.dart';

import '../custom_button.dart';

export '../custom_button.dart' show ButtonVariant;

/// Canonical large CTA used across Home / Lobby / Game.
/// Thin wrapper over [CustomButton] for the CPDB design system name.
class GameButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;

  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      label: label,
      onPressed: onPressed,
      variant: variant,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      icon: icon,
    );
  }
}

/// Compact circular icon action (settings, copy, share).
class CpdbIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;

  const CpdbIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: color ?? Colors.white, size: size),
    );
  }
}
