import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import 'character_avatar.dart';

/// Player name + level chip for the home TopBar.
class ProfileChip extends StatelessWidget {
  final String name;
  final int level;
  final String? avatarAsset;
  final VoidCallback? onTap;

  const ProfileChip({
    super.key,
    required this.name,
    this.level = 1,
    this.avatarAsset,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CharacterAvatar(
            name: name,
            assetPath: avatarAsset,
            size: 40,
          ),
          AppSpacing.gapHSm,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name, style: AppTextStyles.bodyLarge()),
              Text(
                'Lvl $level',
                style: AppTextStyles.caption(color: AppColors.textLightSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
