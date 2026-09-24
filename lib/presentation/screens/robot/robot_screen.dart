import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/di/providers.dart';
import '../../../core/routes/app_routes.dart';
import '../../viewmodels/robot_match_viewmodel.dart';
import '../../widgets/animated_living_background.dart';
import '../../widgets/custom_button.dart';

/// Robot difficulty picker then launches Pass & Pass with bot names.
class RobotScreen extends ConsumerStatefulWidget {
  const RobotScreen({super.key});

  @override
  ConsumerState<RobotScreen> createState() => _RobotScreenState();
}

class _RobotScreenState extends ConsumerState<RobotScreen> {
  final _nameCtrl = TextEditingController(text: 'You');

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final difficulty = ref.watch(robotDifficultyProvider);

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
                    Text('Play with Robot', style: AppTextStyles.heading2()),
                  ],
                ),
                AppSpacing.gapVLg,
                TextField(
                  controller: _nameCtrl,
                  style: AppTextStyles.bodyLarge(),
                  decoration: const InputDecoration(labelText: 'Your name'),
                ),
                AppSpacing.gapVLg,
                Text('Difficulty', style: AppTextStyles.heading3()),
                AppSpacing.gapVMd,
                CustomButton(
                  label: 'EASY',
                  onPressed: () => ref
                      .read(robotDifficultyProvider.notifier)
                      .setDifficulty(RobotDifficulty.easy),
                  variant: difficulty == RobotDifficulty.easy
                      ? ButtonVariant.primary
                      : ButtonVariant.outlined,
                ),
                AppSpacing.gapVSm,
                CustomButton(
                  label: 'MEDIUM',
                  onPressed: () => ref
                      .read(robotDifficultyProvider.notifier)
                      .setDifficulty(RobotDifficulty.medium),
                  variant: difficulty == RobotDifficulty.medium
                      ? ButtonVariant.accent
                      : ButtonVariant.outlined,
                ),
                AppSpacing.gapVSm,
                CustomButton(
                  label: 'HARD',
                  onPressed: () => ref
                      .read(robotDifficultyProvider.notifier)
                      .setDifficulty(RobotDifficulty.hard),
                  variant: difficulty == RobotDifficulty.hard
                      ? ButtonVariant.danger
                      : ButtonVariant.outlined,
                ),
                const Spacer(),
                CustomButton(
                  label: 'START MATCH',
                  onPressed: () {
                    final name = _nameCtrl.text.trim().isEmpty
                        ? 'You'
                        : _nameCtrl.text.trim();
                    ref.read(playerProfileStoreProvider).setPlayerName(name);
                    context.push(
                      AppRoutes.passAndPlaySetup,
                      extra: {
                        'botMode': true,
                        'difficulty': difficulty.name,
                        'humanName': name,
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
