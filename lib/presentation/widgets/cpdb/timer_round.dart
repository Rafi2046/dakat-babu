import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Round countdown timer chip.
class GameTimer extends StatelessWidget {
  final int remainingSeconds;
  final bool urgent;

  const GameTimer({
    super.key,
    required this.remainingSeconds,
    this.urgent = false,
  });

  @override
  Widget build(BuildContext context) {
    final mm = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final ss = (remainingSeconds % 60).toString().padLeft(2, '0');
    final color = urgent || remainingSeconds <= 5
        ? AppColors.error
        : AppColors.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, color: color, size: 18),
          const SizedBox(width: 6),
          Text('$mm:$ss', style: AppTextStyles.heading3(color: color)),
        ],
      ),
    );
  }
}

/// ROUND X / Y indicator.
class RoundIndicator extends StatelessWidget {
  final int current;
  final int total;

  const RoundIndicator({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary),
      ),
      child: Text(
        'ROUND $current / $total',
        style: AppTextStyles.bodyMedium(color: AppColors.primaryLight),
      ),
    );
  }
}
