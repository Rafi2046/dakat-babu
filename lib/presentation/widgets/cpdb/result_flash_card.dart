import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import 'game_button.dart';

/// Dramatic correct / wrong flash overlay card.
class ResultFlashCard extends StatelessWidget {
  final bool isCorrect;
  final String title;
  final String subtitle;
  final String? scoreLabel;
  final String? characterAsset;
  final VoidCallback? onContinue;
  final String continueLabel;

  const ResultFlashCard({
    super.key,
    required this.isCorrect,
    required this.title,
    required this.subtitle,
    this.scoreLabel,
    this.characterAsset,
    this.onContinue,
    this.continueLabel = 'CONTINUE',
  });

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? AppColors.success : AppColors.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 28),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.cancel,
            color: color,
            size: 64,
          ),
          AppSpacing.gapVMd,
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading1(color: color),
          ),
          AppSpacing.gapVSm,
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium(),
          ),
          if (characterAsset != null) ...[
            AppSpacing.gapVMd,
            Image.asset(characterAsset!, height: 140, fit: BoxFit.contain),
          ],
          if (scoreLabel != null) ...[
            AppSpacing.gapVMd,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(scoreLabel!, style: AppTextStyles.heading3(color: color)),
            ),
          ],
          if (onContinue != null) ...[
            AppSpacing.gapVLg,
            GameButton(label: continueLabel, onPressed: onContinue),
          ],
        ],
      ),
    );
  }
}
