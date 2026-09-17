import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/extensions.dart';
import 'role_art.dart';

/// Visually distinct, color-coded badge representing a [GameRole]
/// featuring custom vector illustrations and ambient luminous glows.
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

  @override
  Widget build(BuildContext context) {
    final roleColor = role.color;

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: roleColor.withValues(alpha: 0.15),
          borderRadius: AppRadius.chipRadius,
          border: Border.all(color: roleColor.withValues(alpha: 0.6), width: 1),
          boxShadow: [
            BoxShadow(
              color: roleColor.withValues(alpha: 0.2),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RoleVectorIcon(role: role, size: 16, hasGlow: false),
            AppSpacing.gapHXs,
            Text(
              role.shortName,
              style: AppTextStyles.caption(color: roleColor).copyWith(
                fontWeight: FontWeight.w700,
              ),
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
        color: roleColor.withValues(alpha: 0.14),
        borderRadius: AppRadius.buttonRadius,
        border: Border.all(color: roleColor.withValues(alpha: 0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: roleColor.withValues(alpha: 0.30),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RoleVectorIcon(role: role, size: 26, hasGlow: true),
          AppSpacing.gapHMd,
          Text(
            role.displayName,
            style: AppTextStyles.bodyLarge(color: roleColor).copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (showPoints) ...[
            AppSpacing.gapHSm,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: roleColor,
                borderRadius: AppRadius.chipRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                '+${role.points}',
                style: AppTextStyles.caption(color: Colors.black).copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
