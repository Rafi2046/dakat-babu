import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/extensions.dart';
import '../../data/models/player_model.dart';
import 'game_card.dart';
import 'role_badge.dart';

/// Reusable player tile used in Lobby, Game Deduction, and Result screens
/// featuring frosted glassmorphism, glowing borders, and Phosphor icons.
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
        : (player.isHost ? AppColors.raja.withValues(alpha: 0.45) : AppColors.glassBorder);

    return GameCard(
      isGlass: true,
      onTap: onTap,
      borderColor: borderColor,
      glowColor: isSelected
          ? AppColors.primaryGlow
          : (player.isHost ? AppColors.rajaGlow.withValues(alpha: 0.15) : null),
      backgroundColor: isSelected
          ? AppColors.primary.withValues(alpha: 0.22)
          : AppColors.glassFill,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          // Player Avatar with Initials
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: player.isHost
                  ? AppColors.rajaGradient
                  : LinearGradient(
                      colors: [
                        AppColors.primaryLight,
                        AppColors.primaryDark,
                      ],
                    ),
              boxShadow: [
                BoxShadow(
                  color: (player.isHost ? AppColors.raja : AppColors.primary)
                      .withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              player.name.initials,
              style: AppTextStyles.bodyLarge(
                color: player.isHost ? Colors.black : Colors.white,
              ).copyWith(fontWeight: FontWeight.w900),
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
                        style: AppTextStyles.bodyLarge().copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (player.isHost) ...[
                      AppSpacing.gapHXs,
                      Icon(
                        PhosphorIcons.crown(PhosphorIconsStyle.fill),
                        size: 16,
                        color: AppColors.raja,
                      ),
                    ],
                  ],
                ),
                AppSpacing.gapVXs,
                Text(
                  '${player.score} pts',
                  style: AppTextStyles.caption(color: AppColors.textLightSecondary).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
            Icon(
              PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
              color: AppColors.primaryLight,
              size: 26,
            ),
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
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.raja.withValues(alpha: 0.18),
          borderRadius: AppRadius.chipRadius,
          border: Border.all(color: AppColors.raja.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.crown(PhosphorIconsStyle.fill),
              size: 12,
              color: AppColors.raja,
            ),
            AppSpacing.gapHXs,
            Text(
              'HOST',
              style: AppTextStyles.caption(color: AppColors.raja).copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      );
    }

    final color = isReady ? AppColors.success : AppColors.textLightMuted;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: AppRadius.chipRadius,
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isReady
                ? PhosphorIcons.check(PhosphorIconsStyle.bold)
                : PhosphorIcons.hourglass(PhosphorIconsStyle.bold),
            size: 11,
            color: color,
          ),
          AppSpacing.gapHXs,
          Text(
            isReady ? 'READY' : 'WAITING',
            style: AppTextStyles.caption(color: color).copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
