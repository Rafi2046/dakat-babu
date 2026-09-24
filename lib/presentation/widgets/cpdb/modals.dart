import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import 'game_button.dart';

/// Frosted modal sheet / centered dialog shell.
class CpdbModal extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? child;
  final List<Widget>? actions;

  const CpdbModal({
    super.key,
    required this.title,
    this.message,
    this.child,
    this.actions,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? message,
    Widget? child,
    List<Widget>? actions,
  }) {
    return showDialog<T>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: CpdbModal(
          title: title,
          message: message,
          actions: actions,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: AppTextStyles.heading2()),
          if (message != null) ...[
            AppSpacing.gapVMd,
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(),
            ),
          ],
          if (child != null) ...[AppSpacing.gapVMd, child!],
          if (actions != null) ...[
            AppSpacing.gapVLg,
            ...actions!,
          ],
        ],
      ),
    );
  }
}

/// Leave / Exit / Restart confirmation.
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.confirmLabel = 'CONFIRM',
    this.cancelLabel = 'CANCEL',
    this.onCancel,
    this.isDestructive = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'CONFIRM',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConfirmationDialog(
          title: title,
          message: message,
          confirmLabel: confirmLabel,
          isDestructive: isDestructive,
          onConfirm: () => Navigator.pop(ctx, true),
          onCancel: () => Navigator.pop(ctx, false),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CpdbModal(
      title: title,
      message: message,
      actions: [
        GameButton(
          label: confirmLabel,
          onPressed: onConfirm,
          variant: isDestructive ? ButtonVariant.danger : ButtonVariant.primary,
        ),
        AppSpacing.gapVSm,
        GameButton(
          label: cancelLabel,
          onPressed: onCancel ?? () => Navigator.pop(context, false),
          variant: ButtonVariant.outlined,
        ),
      ],
    );
  }
}
