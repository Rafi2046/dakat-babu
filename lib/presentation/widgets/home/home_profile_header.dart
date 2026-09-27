import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings_bn.dart';
import '../../../core/constants/home_text_styles.dart';

/// Top profile strip: avatar, name, coins, sound, settings.
class HomeProfileHeader extends StatelessWidget {
  final String playerName;
  final int level;
  final int coins;
  final bool soundEnabled;
  final VoidCallback onToggleSound;
  final VoidCallback onSettings;

  const HomeProfileHeader({
    super.key,
    required this.playerName,
    required this.level,
    required this.coins,
    required this.soundEnabled,
    required this.onToggleSound,
    required this.onSettings,
  });

  String get _initial {
    final trimmed = playerName.trim();
    if (trimmed.isEmpty) return '?';
    return String.fromCharCode(trimmed.runes.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.primary.withValues(alpha: 0.35),
              child: Text(
                _initial,
                style: HomeTextStyles.title(color: Colors.white),
              ),
            ),
            Positioned(
              left: -4,
              bottom: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.raja,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${AppStringsBn.level} $level',
                  style: HomeTextStyles.chip(color: AppColors.textDarkPrimary),
                ),
              ),
            ),
          ],
        ),
        AppSpacing.gapHSm,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                playerName,
                style: HomeTextStyles.title(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                AppStringsBn.rankInspectorPolice,
                style: HomeTextStyles.caption(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        _coinsChip(coins),
        const SizedBox(width: 6),
        _roundIcon(
          icon: soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          onTap: onToggleSound,
        ),
        const SizedBox(width: 6),
        _roundIcon(icon: Icons.settings_rounded, onTap: onSettings),
      ],
    );
  }

  Widget _coinsChip(int coins) {
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: AppColors.raja, size: 18),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 36),
            child: Text(
              '$coins',
              style: HomeTextStyles.body(color: AppColors.raja),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, size: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _roundIcon({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: AppColors.surfaceElevatedDark,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: AppColors.textLightPrimary),
        ),
      ),
    );
  }
}
