import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primary.withValues(alpha: 0.25)
            : AppColors.glassFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? AppColors.primary : AppColors.glassBorder,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: AppTextStyles.heading3(
                color: rank <= 3 ? AppColors.raja : AppColors.textLightSecondary,
              ),
            ),
          ),
          CharacterAvatar(name: name, assetPath: avatarAsset, size: 36),
          AppSpacing.gapHSm,
          Expanded(
            child: Text(name, style: AppTextStyles.bodyLarge()),
          ),
          if (correct != null)
            _mini('C', correct!, AppColors.success),
          if (wrong != null)
            _mini('W', wrong!, AppColors.error),
          if (policeTags != null)
            _mini('P', policeTags!, AppColors.police),
          AppSpacing.gapHSm,
          Text(
            '$score',
            style: AppTextStyles.heading3(color: AppColors.raja),
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
        style: AppTextStyles.caption(color: color),
      ),
    );
  }
}

/// Live scoreboard panel (bottom 40% of game room).
class ScoreboardPanel extends StatelessWidget {
  final List<ScoreRow> rows;
  final String title;

  const ScoreboardPanel({
    super.key,
    required this.rows,
    this.title = 'SCOREBOARD',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.92),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTextStyles.caption()),
          AppSpacing.gapVSm,
          ...rows,
        ],
      ),
    );
  }
}
