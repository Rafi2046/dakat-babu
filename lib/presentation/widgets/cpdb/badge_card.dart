import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';

/// Achievement badge tile (locked / unlocked).
class BadgeCard extends StatelessWidget {
  final String name;
  final String description;
  final String? iconAsset;
  final bool unlocked;

  const BadgeCard({
    super.key,
    required this.name,
    required this.description,
    this.iconAsset,
    this.unlocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: unlocked ? 1 : 0.4,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.glassFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked ? AppColors.raja : AppColors.glassBorder,
            width: unlocked ? 2 : 1,
          ),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                    color: AppColors.raja.withValues(alpha: 0.35),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Expanded(
              child: iconAsset != null
                  ? Image.asset(
                      iconAsset!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        unlocked ? Icons.emoji_events : Icons.lock,
                        size: 48,
                        color: AppColors.raja,
                      ),
                    )
                  : Icon(
                      unlocked ? Icons.emoji_events : Icons.lock,
                      size: 48,
                      color: AppColors.raja,
                    ),
            ),
            AppSpacing.gapVSm,
            Text(name,
                textAlign: TextAlign.center, style: AppTextStyles.bodyMedium()),
            Text(
              description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(),
            ),
          ],
        ),
      ),
    );
  }
}
