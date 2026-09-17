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

/// A tactile party-game button with spring scale micro-interaction and 3D depth.
class CustomButton extends StatefulWidget {
  /// Button label text.
  final String label;

  /// Callback when pressed (null disables the button).
  final VoidCallback? onPressed;

  /// Visual theme variant.
  final ButtonVariant variant;

  /// Whether an ongoing async operation should show a progress spinner.
  final bool isLoading;

  /// Optional leading icon.
  final Widget? leading;

  /// Optional legacy IconData.
  final IconData? icon;

  /// Full-width stretch across container.
  final bool isFullWidth;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.leading,
    this.icon,
    this.isFullWidth = true,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide? borderSide;

    switch (widget.variant) {
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

    final content = widget.isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          )
        : Row(
            mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                AppSpacing.gapHSm,
              ] else if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: foregroundColor),
                AppSpacing.gapHSm,
              ],
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: AppTextStyles.button(color: foregroundColor).copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          );

    return AnimatedScale(
      scale: _isPressed && isEnabled ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOutCubic,
      child: Container(
        width: widget.isFullWidth ? double.infinity : null,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: AppRadius.buttonRadius,
          boxShadow: isEnabled && widget.variant != ButtonVariant.outlined
              ? [
                  BoxShadow(
                    color: backgroundColor.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: isEnabled ? backgroundColor : backgroundColor.withValues(alpha: 0.35),
          borderRadius: AppRadius.buttonRadius,
          child: InkWell(
            onTap: isEnabled ? widget.onPressed : null,
            onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
            onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
            onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
            borderRadius: AppRadius.buttonRadius,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: AppRadius.buttonRadius,
                border: borderSide != null ? Border.fromBorderSide(borderSide) : null,
              ),
              alignment: Alignment.center,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
