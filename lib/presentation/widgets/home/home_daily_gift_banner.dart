import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings_bn.dart';
import '../../../core/constants/home_text_styles.dart';

/// Daily gift banner with local claimed state.
class HomeDailyGiftBanner extends StatelessWidget {
  final bool claimed;
  final VoidCallback? onCollect;

  const HomeDailyGiftBanner({
    super.key,
    required this.claimed,
    this.onCollect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.raja.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.card_giftcard, color: AppColors.raja, size: 24),
          ),
          AppSpacing.gapHSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStringsBn.dailyGift,
                  style: HomeTextStyles.body(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  AppStringsBn.dailyGiftSub,
                  style: HomeTextStyles.caption(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: claimed ? AppColors.textLightMuted : AppColors.success,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: claimed ? null : onCollect,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  claimed ? AppStringsBn.collected : AppStringsBn.collect,
                  style: HomeTextStyles.chip(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
