import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/extensions.dart';
import 'character_avatar.dart';

/// Player card states for lobby / game room.
enum PlayerCardState {
  normal,
  selected,
  suspect,
  police,
  babu,
  winner,
  eliminated,
  waiting,
  ready,
  currentPlayer,
  hidden,
}

/// Reusable player card: avatar, name, role/status, selection glow.
class PlayerCard extends StatelessWidget {
  final String name;
  final String? playerNumber;
  final String? avatarAsset;
  final GameRole? visibleRole;
  final PlayerCardState state;
  final int? score;
  final VoidCallback? onTap;
  final bool isHost;
  final bool isYou;

  const PlayerCard({
    super.key,
    required this.name,
    this.playerNumber,
    this.avatarAsset,
    this.visibleRole,
    this.state = PlayerCardState.normal,
    this.score,
    this.onTap,
    this.isHost = false,
    this.isYou = false,
  });

  @override
  Widget build(BuildContext context) {
    final selected = state == PlayerCardState.selected ||
        state == PlayerCardState.suspect;
    final borderColor = switch (state) {
      PlayerCardState.selected || PlayerCardState.suspect => AppColors.raja,
      PlayerCardState.police => AppColors.police,
      PlayerCardState.babu => AppColors.raja,
      PlayerCardState.winner => AppColors.success,
      PlayerCardState.eliminated => AppColors.error,
      PlayerCardState.ready => AppColors.success,
      PlayerCardState.waiting => AppColors.textLightMuted,
      _ => AppColors.glassBorder,
    };

    return Material(
      color: selected
          ? AppColors.raja.withValues(alpha: 0.18)
          : AppColors.glassFill,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: selected ? 2.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.raja.withValues(alpha: 0.45),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CharacterAvatar(
                    name: name,
                    assetPath: avatarAsset ?? visibleRole?.standingAsset,
                    size: 56,
                    showRing: selected,
                    ringColor: borderColor,
                  ),
                  if (selected)
                    const Positioned(
                      right: -4,
                      top: -4,
                      child: Icon(Icons.check_circle,
                          color: AppColors.raja, size: 22),
                    ),
                  if (isHost)
                    const Positioned(
                      left: -4,
                      bottom: -4,
                      child: Icon(Icons.star, color: AppColors.raja, size: 18),
                    ),
                ],
              ),
              AppSpacing.gapVSm,
              Text(
                name,
                style: AppTextStyles.bodyMedium(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (isYou)
                Text('YOU', style: AppTextStyles.caption(color: AppColors.secondary)),
              Text(
                _statusLabel(),
                style: AppTextStyles.caption(color: borderColor),
              ),
              if (score != null)
                Text(
                  '$score',
                  style: AppTextStyles.heading3(color: AppColors.raja),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel() {
    if (visibleRole != null) return visibleRole!.shortName;
    return switch (state) {
      PlayerCardState.hidden => '?',
      PlayerCardState.ready => 'Ready',
      PlayerCardState.waiting => 'Waiting',
      PlayerCardState.winner => 'Winner',
      PlayerCardState.eliminated => 'Out',
      PlayerCardState.police => 'Police',
      PlayerCardState.babu => 'Babu',
      PlayerCardState.suspect || PlayerCardState.selected => 'Suspect',
      PlayerCardState.currentPlayer => 'Playing',
      PlayerCardState.normal => playerNumber ?? '',
    };
  }
}

/// Responsive grid of [PlayerCard]s.
class PlayerGrid extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;

  const PlayerGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.78,
      children: children,
    );
  }
}
