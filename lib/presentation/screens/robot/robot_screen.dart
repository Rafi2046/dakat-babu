import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/home_text_styles.dart';
import '../../../core/di/providers.dart';
import '../../../core/routes/app_routes.dart';
import '../../viewmodels/robot_match_viewmodel.dart';
import '../../widgets/cpdb/cpdb.dart';

class RobotScreen extends ConsumerStatefulWidget {
  const RobotScreen({super.key});

  @override
  ConsumerState<RobotScreen> createState() => _RobotScreenState();
}

class _RobotScreenState extends ConsumerState<RobotScreen> {
  final _nameCtrl = TextEditingController(text: 'You');
  int _totalRounds = AppConstants.defaultTotalRounds;

  static const _roundChoices = [3, 5, 7];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final difficulty = ref.watch(robotDifficultyProvider);

    return AppShell(
      padding: EdgeInsets.zero,
      topBar: TopBar(
        title: 'Play with Robot',
        onBack: () => context.pop(),
        showProfile: false,
      ),
      body: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Your name'),
            ),
            AppSpacing.gapVLg,
            Text('Difficulty', style: AppTextStyles.heading3()),
            AppSpacing.gapVMd,
            GameButton(
              label: 'EASY',
              onPressed: () => ref
                  .read(robotDifficultyProvider.notifier)
                  .setDifficulty(RobotDifficulty.easy),
              variant: difficulty == RobotDifficulty.easy
                  ? ButtonVariant.primary
                  : ButtonVariant.outlined,
            ),
            AppSpacing.gapVSm,
            GameButton(
              label: 'MEDIUM',
              onPressed: () => ref
                  .read(robotDifficultyProvider.notifier)
                  .setDifficulty(RobotDifficulty.medium),
              variant: difficulty == RobotDifficulty.medium
                  ? ButtonVariant.accent
                  : ButtonVariant.outlined,
            ),
            AppSpacing.gapVSm,
            GameButton(
              label: 'HARD',
              onPressed: () => ref
                  .read(robotDifficultyProvider.notifier)
                  .setDifficulty(RobotDifficulty.hard),
              variant: difficulty == RobotDifficulty.hard
                  ? ButtonVariant.danger
                  : ButtonVariant.outlined,
            ),
            AppSpacing.gapVLg,
            Text('Rounds', style: AppTextStyles.heading3()),
            AppSpacing.gapVSm,
            Text(
              'কত রাউন্ড খেলবে সেট করো',
              style: HomeTextStyles.caption(color: AppColors.textLightSecondary),
            ),
            AppSpacing.gapVMd,
            Row(
              children: [
                for (final n in _roundChoices) ...[
                  Expanded(
                    child: GameButton(
                      label: '$n',
                      onPressed: () => setState(() => _totalRounds = n),
                      variant: _totalRounds == n
                          ? ButtonVariant.primary
                          : ButtonVariant.outlined,
                    ),
                  ),
                  if (n != _roundChoices.last) AppSpacing.gapHSm,
                ],
              ],
            ),
            const Spacer(),
            GameButton(
              label: 'START MATCH ($_totalRounds ROUNDS)',
              onPressed: () {
                final name = _nameCtrl.text.trim().isEmpty
                    ? 'You'
                    : _nameCtrl.text.trim();
                ref.read(playerProfileStoreProvider).setPlayerName(name);
                context.push(
                  AppRoutes.singlePlayer,
                  extra: {
                    'humanName': name,
                    'totalRounds': _totalRounds,
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
