import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import 'character_avatar.dart';

/// Single scoreboard row.
class ScoreRow extends StatelessWidget {
  final int rank;
  final String name;
  final int score;
  final int? correct;
  final int? wrong;
  final int? policeTags;
  final bool highlight;
  final String? avatarAsset;

  const ScoreRow({
    super.key,
    required this.rank,
    required this.name,
    required this.score,
    this.correct,
    this.wrong,
    this.policeTags,
    this.highlight = false,
    this.avatarAsset,
  });

  Color _rankColor() {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppColors.textLightSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primary.withValues(alpha: 0.25)
            : AppColors.glassFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight ? AppColors.primary : AppColors.glassBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rank <= 3
                  ? _rankColor().withValues(alpha: 0.18)
                  : Colors.transparent,
            ),
            child: Text(
              '$rank',
              style: AppTextStyles.bodyMedium(
                color: _rankColor(),
              ).copyWith(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          CharacterAvatar(name: name, assetPath: avatarAsset, size: 26),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: AppTextStyles.bodyMedium(color: Colors.white).copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (correct != null) _mini('C', correct!, AppColors.success),
          if (wrong != null) _mini('W', wrong!, AppColors.error),
          if (policeTags != null) _mini('P', policeTags!, AppColors.police),
          const SizedBox(width: 6),
          Text(
            '$score',
            style: AppTextStyles.heading3(color: const Color(0xFFFFD700)).copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mini(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Text(
        '$label$value',
        style: AppTextStyles.caption(color: color).copyWith(fontSize: 11),
      ),
    );
  }
}

/// Compact scoreboard docked at the bottom of a game room or inside result cards.
class ScoreboardPanel extends StatelessWidget {
  final List<ScoreRow> rows;
  final String title;
  final BorderRadiusGeometry? borderRadius;
  final bool isExpanded;

  const ScoreboardPanel({
    super.key,
    required this.rows,
    this.title = 'SCOREBOARD',
    this.borderRadius,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget rowsContent;
    if (isExpanded) {
      rowsContent = Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final row in rows) row,
          ],
        ),
      );
    } else {
      rowsContent = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 5),
            rows[i],
          ],
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.94),
        borderRadius: borderRadius ??
            const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.leaderboard_rounded,
                size: 13,
                color: AppColors.textLightSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                title,
                style: AppTextStyles.caption().copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  fontSize: 11,
                  color: AppColors.textLightSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          rowsContent,
        ],
      ),
    );
  }
}



