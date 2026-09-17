import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/extensions.dart';

/// Visually distinct, color-coded badge representing a [GameRole].
class RoleBadge extends StatelessWidget {
  /// The game role to render.
  final GameRole role;

  /// Whether to render a compact chip (for lists) or an expanded badge (for round results).
  final bool isCompact;

  /// Whether to display the role's point value.
  final bool showPoints;

  const RoleBadge({
    super.key,
    required this.role,
    this.isCompact = false,
    this.showPoints = true,
  });

  IconData _roleIcon(GameRole role) {
    switch (role) {
      case GameRole.raja:
        return Icons.workspace_premium; // Crown
      case GameRole.mantri:
        return Icons.auto_stories; // Decree scroll
      case GameRole.police:
        return Icons.local_police; // Badge
      case GameRole.chor:
        return Icons.masks; // Thief mask
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = role.color;
    final containerColor = role.containerColor;

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: AppRadius.chipRadius,
          border: Border.all(color: roleColor.withValues(alpha: 0.5), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_roleIcon(role), size: 14, color: roleColor),
            AppSpacing.gapHXs,
            Text(
              role.shortName,
              style: AppTextStyles.caption(color: roleColor),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: AppRadius.buttonRadius,
        border: Border.all(color: roleColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_roleIcon(role), size: 20, color: roleColor),
          AppSpacing.gapHSm,
          Text(
            role.displayName,
            style: AppTextStyles.bodyLarge(color: roleColor),
          ),
          if (showPoints) ...[
            AppSpacing.gapHSm,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: roleColor,
                borderRadius: AppRadius.chipRadius,
              ),
              child: Text(
                '+${role.points}',
                style: AppTextStyles.caption(color: Colors.black),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
