import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';

/// Button visual variant presets.
enum ButtonVariant {
  primary,
  secondary,
  accent,
  outlined,
  danger,
}

/// A high-contrast, tactile party-game button with loading state support.
class CustomButton extends StatelessWidget {
  /// Button label text.
  final String label;

  /// Callback when pressed (null disables the button).
  final VoidCallback? onPressed;

  /// Visual theme variant.
  final ButtonVariant variant;

  /// Whether an ongoing async operation should show a progress spinner.
  final bool isLoading;

  /// Optional leading icon.
  final IconData? icon;

  /// Full-width stretch across container.
  final bool isFullWidth;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide? borderSide;

    switch (variant) {
      case ButtonVariant.primary:
        backgroundColor = AppColors.primary;
        foregroundColor = AppColors.textLightPrimary;
        break;
      case ButtonVariant.secondary:
        backgroundColor = AppColors.secondary;
        foregroundColor = AppColors.backgroundDark;
        break;
      case ButtonVariant.accent:
        backgroundColor = AppColors.accent;
        foregroundColor = AppColors.backgroundDark;
        break;
      case ButtonVariant.outlined:
        backgroundColor = Colors.transparent;
        foregroundColor = AppColors.textLightPrimary;
        borderSide = const BorderSide(color: AppColors.borderDark, width: 1.5);
        break;
      case ButtonVariant.danger:
        backgroundColor = AppColors.error;
        foregroundColor = AppColors.textLightPrimary;
        break;
    }

    final buttonChild = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          )
        : Row(
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: foregroundColor),
                AppSpacing.gapHSm,
              ],
              Text(
                label,
                style: AppTextStyles.button(color: foregroundColor),
              ),
            ],
          );

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 52,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.4),
          disabledForegroundColor: foregroundColor.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonRadius,
            side: borderSide ?? BorderSide.none,
          ),
          elevation: variant == ButtonVariant.outlined ? 0 : 2,
        ),
        child: buttonChild,
      ),
    );
  }
}
