import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../widgets/animated_living_background.dart';
import '../../widgets/custom_button.dart';

/// Four game-mode cards.
class ModeSelectScreen extends StatelessWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedLivingBackground(
        child: SafeArea(
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Text('Select Mode', style: AppTextStyles.heading2()),
                  ],
                ),
                AppSpacing.gapVLg,
                Expanded(
                  child: ListView(
                    children: [
                      _ModeCard(
                        title: 'HOTSPOT MULTIPLAYER',
                        subtitle: 'Same Wi-Fi / Hotspot',
                        color: AppColors.primary,
                        onTap: () => context.push(AppRoutes.createJoin),
                      ),
                      _ModeCard(
                        title: 'ONLINE MULTIPLAYER',
                        subtitle: 'Play with friends anywhere',
                        color: const Color(0xFF00A896),
                        onTap: () => context.push(AppRoutes.createJoin),
                      ),
                      _ModeCard(
                        title: 'PLAY WITH ROBOT',
                        subtitle: 'Solo vs AI',
                        color: AppColors.police,
                        onTap: () => context.push(AppRoutes.robot),
                      ),
                      _ModeCard(
                        title: 'PLAY & PASS',
                        subtitle: 'Same phone, take turns',
                        color: AppColors.mantri,
                        onTap: () => context.push(AppRoutes.passAndPlaySetup),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.heading3(color: color)),
                const SizedBox(height: 6),
                Text(subtitle, style: AppTextStyles.bodyMedium()),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: CustomButton(
                    label: 'PLAY',
                    onPressed: onTap,
                    isFullWidth: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
