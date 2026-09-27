import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
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

/// Reusable player card — safe in grids AND unbounded columns (confirm screen).
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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
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
          // No Expanded/Flexible — works in GridView cells AND unbounded Columns.
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  CharacterAvatar(
                    name: name,
                    assetPath: avatarAsset ??
                        visibleRole?.badgeAsset ??
                        visibleRole?.standingAsset,
                    size: 52,
                    showRing: selected,
                    ringColor: borderColor,
                  ),
                  if (selected)
                    const Positioned(
                      right: -4,
                      top: -4,
                      child: Icon(
                        Icons.check_circle,
                        color: AppColors.raja,
                        size: 20,
                      ),
                    ),
                  if (isHost)
                    const Positioned(
                      left: -4,
                      bottom: -4,
                      child: Icon(
                        Icons.star,
                        color: AppColors.raja,
                        size: 16,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                name,
                style: AppTextStyles.bodyMedium(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              if (isYou)
                Text(
                  'YOU',
                  style: AppTextStyles.caption(color: AppColors.secondary),
                ),
              Text(
                _statusLabel(),
                style: AppTextStyles.caption(color: borderColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) {
          return const SizedBox.shrink();
        }

        final maxW = constraints.maxWidth;
        final maxH =
            constraints.hasBoundedHeight && constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : 420.0;

        if (maxH < 8) {
          return const SizedBox.shrink();
        }

        final count = children.length;
        final rows = (count / crossAxisCount).ceil().clamp(1, 99);
        const gap = 12.0;

        final rawCellH = (maxH - gap * (rows - 1)) / rows;
        final cellH = rawCellH < 96
            ? rawCellH.clamp(72.0, 200.0)
            : rawCellH.clamp(96.0, 200.0);
        final cellW =
            ((maxW - gap * (crossAxisCount - 1)) / crossAxisCount)
                .clamp(80.0, 220.0);
        final aspect = (cellW / cellH).clamp(0.5, 1.2);

        return GridView.count(
          physics: const BouncingScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: gap,
          crossAxisSpacing: gap,
          childAspectRatio: aspect,
          padding: const EdgeInsets.only(bottom: 4),
          children: children,
        );
      },
    );
  }
}
