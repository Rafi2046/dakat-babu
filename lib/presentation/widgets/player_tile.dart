import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/extensions.dart';
import '../../data/models/player_model.dart';
import 'game_card.dart';
import 'role_badge.dart';

/// Reusable player tile used in Lobby, Game Deduction, and Result screens.
class PlayerTile extends StatelessWidget {
  /// The player represented by this tile.
  final PlayerModel player;

  /// Whether this tile is currently selected (e.g. Police choosing a suspect).
  final bool isSelected;

  /// Optional callback when tapped.
  final VoidCallback? onTap;

  /// Whether to reveal the player's secret role (typically in results).
  final bool revealRole;

  /// Whether to display lobby readiness state.
  final bool showReadyStatus;

  const PlayerTile({
    super.key,
    required this.player,
    this.isSelected = false,
    this.onTap,
    this.revealRole = false,
    this.showReadyStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? AppColors.primaryLight
        : (player.isHost ? AppColors.raja.withValues(alpha: 0.3) : AppColors.borderDark);

    return GameCard(
      onTap: onTap,
      borderColor: borderColor,
      backgroundColor: isSelected
          ? AppColors.primary.withValues(alpha: 0.15)
          : AppColors.surfaceDark,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Player Avatar with Initials
          CircleAvatar(
            radius: 22,
            backgroundColor: player.isHost
                ? AppColors.rajaContainer
                : AppColors.primary.withValues(alpha: 0.2),
            child: Text(
              player.name.initials,
              style: AppTextStyles.bodyLarge(
                color: player.isHost ? AppColors.raja : AppColors.textLightPrimary,
              ),
            ),
          ),
          AppSpacing.gapHMd,

          // Name and Host subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        player.name,
                        style: AppTextStyles.bodyLarge(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (player.isHost) ...[
                      AppSpacing.gapHXs,
                      const Icon(Icons.star, size: 16, color: AppColors.raja),
                    ],
                  ],
                ),
                Text(
                  'Score: ${player.score} pts',
                  style: AppTextStyles.caption(color: AppColors.textLightSecondary),
                ),
              ],
            ),
          ),

          // Role Badge or Lobby Readiness
          if (revealRole && player.role != null)
            RoleBadge(role: player.role!, isCompact: true)
          else if (showReadyStatus)
            _ReadyStatusChip(isReady: player.isReady, isHost: player.isHost)
          else if (isSelected)
            const Icon(Icons.check_circle, color: AppColors.primaryLight, size: 24),
        ],
      ),
    );
  }
}

class _ReadyStatusChip extends StatelessWidget {
  final bool isReady;
  final bool isHost;

  const _ReadyStatusChip({required this.isReady, required this.isHost});

  @override
  Widget build(BuildContext context) {
    if (isHost) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: const BoxDecoration(
          color: AppColors.rajaContainer,
          borderRadius: AppRadius.chipRadius,
        ),
        child: Text(
          'HOST',
          style: AppTextStyles.caption(color: AppColors.raja),
        ),
      );
    }

    final color = isReady ? AppColors.success : AppColors.textLightMuted;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.chipRadius,
      ),
      child: Text(
        isReady ? 'READY' : 'WAITING',
        style: AppTextStyles.caption(color: color),
      ),
    );
  }
}
