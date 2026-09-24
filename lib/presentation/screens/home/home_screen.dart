import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/di/providers.dart';
import '../../../core/routes/app_routes.dart';
import '../../widgets/animated_living_background.dart';
import '../../widgets/custom_button.dart';

/// Home / action hub with stats and four mode CTAs.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(playerProfileStoreProvider);

    return Scaffold(
      body: AnimatedLivingBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        profile.playerName.isNotEmpty
                            ? profile.playerName[0].toUpperCase()
                            : 'P',
                        style: AppTextStyles.heading2(),
                      ),
                    ),
                    AppSpacing.gapHMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.playerName,
                              style: AppTextStyles.heading3()),
                          Text(
                            'Lvl ${(profile.gamesPlayed ~/ 3) + 1}',
                            style: AppTextStyles.bodySmall(),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.push(AppRoutes.settings),
                      icon: const Icon(Icons.settings, color: Colors.white),
                    ),
                  ],
                ),
                AppSpacing.gapVLg,
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
                    _StatChip(
                      label: 'Correct Guess',
                      value: '${profile.correctGuesses}',
                    ),
                    AppSpacing.gapHSm,
                    _StatChip(
                      label: 'Police Tag',
                      value: '${profile.policeTags}',
                    ),
                    AppSpacing.gapHSm,
                    _StatChip(
                      label: 'Highest',
                      value: '${profile.highestScore}',
                    ),
                  ],
                ),
                AppSpacing.gapVXl,
                CustomButton(
                  label: 'PLAY MULTIPLAYER',
                  onPressed: () => context.push(AppRoutes.modeSelect),
                  backgroundColor: AppColors.primary,
                ),
                AppSpacing.gapVMd,
                CustomButton(
                  label: 'PLAY ONLINE',
                  onPressed: () => context.push(AppRoutes.modeSelect),
                  backgroundColor: const Color(0xFF00A896),
                ),
                AppSpacing.gapVMd,
                CustomButton(
                  label: 'PLAY WITH ROBOT',
                  onPressed: () => context.push(AppRoutes.robot),
                  backgroundColor: AppColors.police,
                ),
                AppSpacing.gapVMd,
                CustomButton(
                  label: 'PLAY & PASS',
                  onPressed: () => context.push(AppRoutes.passAndPlaySetup),
                  backgroundColor: AppColors.mantri,
                ),
                AppSpacing.gapVXl,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _NavChip(
                      icon: Icons.military_tech,
                      label: 'Badges',
                      onTap: () => context.push(AppRoutes.badges),
                    ),
                    _NavChip(
                      icon: Icons.leaderboard,
                      label: 'Score',
                      onTap: () => context.push(AppRoutes.personalScore),
                    ),
                    _NavChip(
                      icon: Icons.help_outline,
                      label: 'How to Play',
                      onTap: () => context.push(AppRoutes.howToPlay),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
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
                textAlign: TextAlign.center,
                style: AppTextStyles.caption()),
          ],
        ),
      ),
    );
  }
}

class _NavChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: AppColors.secondary, size: 28),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.caption()),
          ],
        ),
      ),
    );
  }
}
