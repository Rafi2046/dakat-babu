import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/di/providers.dart';
import '../../../core/routes/app_routes.dart';
import '../../widgets/cpdb/cpdb.dart';

/// Home hub — uses shared CPDB component library.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(playerProfileStoreProvider);
    final level = (profile.gamesPlayed ~/ 3) + 1;

    return AppShell(
      padding: EdgeInsets.zero,
      topBar: TopBar(
        playerName: profile.playerName,
        level: level,
        coins: profile.highestScore * 10,
        actions: [
          TopBarSettingsButton(
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      bottomNavigation: CpdbBottomNavigation(
        items: [
          BottomNavItem(
            icon: Icons.military_tech,
            label: 'Badges',
            onTap: () => context.push(AppRoutes.badges),
          ),
          BottomNavItem(
            icon: Icons.leaderboard,
            label: 'Score',
            onTap: () => context.push(AppRoutes.personalScore),
          ),
          BottomNavItem(
            icon: Icons.help_outline,
            label: 'How to Play',
            onTap: () => context.push(AppRoutes.howToPlay),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(
              AppImages.logo,
              height: 72,
              errorBuilder: (_, __, ___) => Text(
                'CHOR POLICE DAKAT BABU',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading2(color: AppColors.raja),
              ),
            ),
            AppSpacing.gapVLg,
            Row(
              children: [
                _stat('Correct Guess', '${profile.correctGuesses}'),
                AppSpacing.gapHSm,
                _stat('Police Tag', '${profile.policeTags}'),
                AppSpacing.gapHSm,
                _stat('Highest', '${profile.highestScore}'),
              ],
            ),
            AppSpacing.gapVXl,
            GameButton(
              label: 'PLAY MULTIPLAYER',
              onPressed: () => context.push(AppRoutes.modeSelect),
            ),
            AppSpacing.gapVMd,
            GameButton(
              label: 'PLAY ONLINE',
              onPressed: () => context.push(AppRoutes.createJoin),
              variant: ButtonVariant.accent,
            ),
            AppSpacing.gapVMd,
            GameButton(
              label: 'PLAY WITH ROBOT',
              onPressed: () => context.push(AppRoutes.robot),
              variant: ButtonVariant.secondary,
            ),
            AppSpacing.gapVMd,
            GameButton(
              label: 'PLAY & PASS',
              onPressed: () => context.push(AppRoutes.passAndPlaySetup),
              variant: ButtonVariant.outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.glassFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.heading3(color: AppColors.raja)),
            Text(label,
                textAlign: TextAlign.center, style: AppTextStyles.caption()),
          ],
        ),
      ),
    );
  }
}
