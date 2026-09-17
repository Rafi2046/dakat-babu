import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import 'custom_button.dart';

/// Centralized utility for high-polish, party-themed feedback:
/// error dialogs, floating snackbars, and action confirmation modals.
abstract final class AppFeedback {
  /// Displays a floating frosted snackbar with an icon and custom styling.
  static void showSnackBar(
    BuildContext context, {
    required String message,
    bool isError = false,
    bool isSuccess = false,
    IconData? icon,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final Color accentColor = isError
        ? AppColors.error
        : (isSuccess ? AppColors.success : AppColors.secondary);

    final IconData effectiveIcon = icon ??
        (isError
            ? PhosphorIcons.warningCircle(PhosphorIconsStyle.bold)
            : (isSuccess
                ? PhosphorIcons.checkCircle(PhosphorIconsStyle.bold)
                : PhosphorIcons.info(PhosphorIconsStyle.bold)));

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Icon(effectiveIcon, color: accentColor, size: 18),
            ),
            AppSpacing.gapHMd,
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium(color: Colors.white).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surfaceElevatedDark.withValues(alpha: 0.95),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
          side: BorderSide(
            color: accentColor.withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }

  /// Displays an error dialog with frosted glass backdrop and optional retry.
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: AppColors.surfaceElevatedDark.withValues(alpha: 0.92),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.dialogRadius,
            side: BorderSide(
              color: AppColors.error.withValues(alpha: 0.45),
              width: 1.5,
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIcons.warning(PhosphorIconsStyle.fill),
                  color: AppColors.error,
                  size: 22,
                ),
              ),
              AppSpacing.gapHSm,
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.heading3(color: Colors.white),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: AppTextStyles.bodyMedium(color: AppColors.textLightSecondary),
          ),
          actionsPadding: const EdgeInsets.all(AppSpacing.md),
          actions: [
            if (onRetry != null)
              CustomButton(
                label: 'Retry',
                leading: Icon(PhosphorIcons.arrowClockwise(PhosphorIconsStyle.bold), size: 16),
                variant: ButtonVariant.secondary,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onRetry();
                },
              ),
            AppSpacing.gapVSm,
            CustomButton(
              label: 'Dismiss',
              variant: ButtonVariant.outlined,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  /// Displays an interactive action confirmation modal.
  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: AppColors.surfaceElevatedDark.withValues(alpha: 0.94),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.dialogRadius,
            side: BorderSide(
              color: (isDestructive ? AppColors.error : AppColors.secondary)
                  .withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          title: Text(
            title,
            style: AppTextStyles.heading3(color: Colors.white),
          ),
          content: Text(
            message,
            style: AppTextStyles.bodyMedium(color: AppColors.textLightSecondary),
          ),
          actionsPadding: const EdgeInsets.all(AppSpacing.md),
          actions: [
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    label: cancelLabel,
                    variant: ButtonVariant.outlined,
                    onPressed: () => Navigator.of(ctx).pop(false),
                  ),
                ),
                AppSpacing.gapHSm,
                Expanded(
                  child: CustomButton(
                    label: confirmLabel,
                    variant: isDestructive ? ButtonVariant.danger : ButtonVariant.primary,
                    onPressed: () => Navigator.of(ctx).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  /// Displays a modal when the room has been cancelled or disbanded by the host.
  static Future<void> showRoomCancelledDialog(
    BuildContext context, {
    String message = 'The host has disbanded the room. Returning to the main hall.',
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: AppColors.surfaceElevatedDark.withValues(alpha: 0.95),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.dialogRadius,
            side: BorderSide(
              color: AppColors.warning.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          title: Row(
            children: [
              Icon(PhosphorIcons.warning(PhosphorIconsStyle.fill), color: AppColors.warning),
              AppSpacing.gapHSm,
              Text('Room Closed', style: AppTextStyles.heading3()),
            ],
          ),
          content: Text(
            message,
            style: AppTextStyles.bodyMedium(color: AppColors.textLightSecondary),
          ),
          actions: [
            CustomButton(
              label: 'Return Home',
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go(AppRoutes.home);
              },
            ),
          ],
        ),
      ),
    );
  }
}
