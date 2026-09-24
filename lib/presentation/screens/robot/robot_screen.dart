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

/// Robot difficulty picker then launches Pass & Pass-style flow with bots.
class RobotScreen extends ConsumerStatefulWidget {
  const RobotScreen({super.key});

  @override
  ConsumerState<RobotScreen> createState() => _RobotScreenState();
}

class _RobotScreenState extends ConsumerState<RobotScreen> {
  RobotDifficulty _difficulty = RobotDifficulty.medium;
  final _nameCtrl = TextEditingController(text: 'You');

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _start() {
    final name = _nameCtrl.text.trim().isEmpty ? 'You' : _nameCtrl.text.trim();
    ref.read(playerProfileStoreProvider).setPlayerName(name);
    ref.read(robotMatchViewModelProvider.notifier).start(
          humanName: name,
          difficulty: _difficulty,
        );
    // Reuse pass-and-play game screen with robot-seeded VM via shared pass provider.
    final robot = ref.read(robotMatchViewModelProvider.notifier);
    // Copy inner state into pass-and-play provider for shared UI.
    // For simplicity navigate to a dedicated robot game using pass-and-play after init.
    robot.controller; // ensure init
    // Seed global pass-and-play with same names then jump.
    context.push(AppRoutes.passAndPlaySetup);
  }

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
                  onPressed: () =>
                      setState(() => _difficulty = RobotDifficulty.easy),
                  variant: _difficulty == RobotDifficulty.easy
                      ? ButtonVariant.primary
                      : ButtonVariant.outlined,
                ),
                AppSpacing.gapVSm,
                CustomButton(
                  label: 'MEDIUM',
                  onPressed: () =>
                      setState(() => _difficulty = RobotDifficulty.medium),
                  variant: _difficulty == RobotDifficulty.medium
                      ? ButtonVariant.accent
                      : ButtonVariant.outlined,
                ),
                AppSpacing.gapVSm,
                CustomButton(
                  label: 'HARD',
                  onPressed: () =>
                      setState(() => _difficulty = RobotDifficulty.hard),
                  variant: _difficulty == RobotDifficulty.hard
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
                    // Use pass-and-play with 1 human + 3 bot names.
                    context.push(
                      AppRoutes.passAndPlaySetup,
                      extra: {
                        'botMode': true,
                        'difficulty': _difficulty.name,
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
