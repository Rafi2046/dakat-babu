import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings_bn.dart';
import '../../../core/constants/home_text_styles.dart';

/// Career stats row with reserved height to avoid layout jumps.
class HomeCareerStats extends StatelessWidget {
  final int highestScore;
  final int policeWinPercent;
  final int badgeCount;

  const HomeCareerStats({
    super.key,
    required this.highestScore,
    required this.policeWinPercent,
    required this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: AppColors.raja, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  AppStringsBn.careerStats,
                  style: HomeTextStyles.body(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.raja.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.raja.withValues(alpha: 0.5)),
                ),
                child: Text(
                  AppStringsBn.seasonChip,
                  style: HomeTextStyles.chip(color: AppColors.raja),
                ),
              ),
            ],
          ),
          AppSpacing.gapVSm,
          Row(
            children: [
              Expanded(
                child: _tile(
                  label: AppStringsBn.highestScore,
                  value: '$highestScore ${AppStringsBn.pointsSuffix}',
                ),
              ),
              AppSpacing.gapHSm,
              Expanded(
                child: _tile(
                  label: AppStringsBn.policeWin,
                  value: '$policeWinPercent% ${AppStringsBn.winSuffix}',
                ),
              ),
              AppSpacing.gapHSm,
              Expanded(
                child: _tile(
                  label: AppStringsBn.badges,
                  value: '$badgeCount${AppStringsBn.countSuffix}',
                  leading: const Icon(Icons.military_tech, color: AppColors.raja, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tile({
    required String label,
    required String value,
    Widget? leading,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: HomeTextStyles.caption(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          // Fixed min height so value swaps don't jump layout.
          SizedBox(
            height: 22,
            child: Row(
              children: [
                if (leading != null) ...[
                  leading,
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    value,
                    style: HomeTextStyles.statValue(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
