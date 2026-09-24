import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import 'currency_chip.dart';
import 'profile_chip.dart';

/// Standard top bar: back, title, profile, coins, actions.
class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final VoidCallback? onBack;
  final String? playerName;
  final int? level;
  final int? coins;
  final List<Widget>? actions;
  final bool showProfile;

  const TopBar({
    super.key,
    this.title,
    this.onBack,
    this.playerName,
    this.level,
    this.coins,
    this.actions,
    this.showProfile = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          if (showProfile && playerName != null) ...[
            ProfileChip(name: playerName!, level: level ?? 1),
            AppSpacing.gapHSm,
          ],
          if (title != null)
            Expanded(
              child: Text(
                title!,
                style: AppTextStyles.heading3(),
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            const Spacer(),
          if (coins != null) ...[
            CurrencyChip(amount: coins!),
            AppSpacing.gapHXs,
          ],
          ...?actions,
        ],
      ),
    );
  }
}

/// Compact settings gear for TopBar actions.
class TopBarSettingsButton extends StatelessWidget {
  final VoidCallback onPressed;

  const TopBarSettingsButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.settings_rounded, color: AppColors.textLightSecondary),
    );
  }
}
