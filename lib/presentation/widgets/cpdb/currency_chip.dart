import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Gold coin / currency display chip.
class CurrencyChip extends StatelessWidget {
  final int amount;
  final VoidCallback? onTap;

  const CurrencyChip({super.key, required this.amount, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.raja.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on, color: AppColors.raja, size: 18),
              const SizedBox(width: 6),
              Text(
                _format(amount),
                style: AppTextStyles.bodyMedium(color: AppColors.raja),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _format(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    return '$n';
  }
}
