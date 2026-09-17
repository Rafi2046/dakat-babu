import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/di/providers.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/round_model.dart';
import '../../viewmodels/results_viewmodel.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/game_card.dart';
import '../../widgets/player_tile.dart';

/// Screen revealing round resolution, role unmaskings, and overall leaderboard.
class ResultsScreen extends ConsumerStatefulWidget {
  final String roomCode;

  const ResultsScreen({super.key, required this.roomCode});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentPlayerIdProvider);
    final resultsState = ref.watch(resultsViewModelProvider(widget.roomCode));

    // Listen for next round launch to transition players back to game screen
    ref.listen<ResultsState>(resultsViewModelProvider(widget.roomCode), (prev, current) {
      if (current.round?.status == RoundStatus.roleReveal &&
          prev?.round?.status == RoundStatus.completed) {
        context.go(AppRoutes.gameRoundPath(widget.roomCode));
      }
      if (current.errorMessage != null &&
          current.errorMessage != prev?.errorMessage) {
        context.showErrorSnackBar(current.errorMessage!);
      }
    });

    final round = resultsState.round;
    final isGuessCorrect = round?.isGuessCorrect ?? false;
    final isHost = resultsState.isHost(currentUserId);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Round ${round?.roundNumber ?? 1} Outcome',
          style: AppTextStyles.heading2(),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Climax Outcome Banner ---
              GameCard(
                backgroundColor: isGuessCorrect
                    ? AppColors.police.withValues(alpha: 0.15)
                    : AppColors.chor.withValues(alpha: 0.15),
                borderColor: isGuessCorrect ? AppColors.police : AppColors.chor,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Icon(
                      isGuessCorrect ? Icons.verified : Icons.dangerous,
                      size: 48,
                      color: isGuessCorrect ? AppColors.police : AppColors.chor,
                    ),
                    AppSpacing.gapVSm,
                    Text(
                      isGuessCorrect
                          ? 'POLICE CAUGHT THE CHOR!'
                          : 'THE CHOR ESCAPED!',
                      style: AppTextStyles.heading2(
                        color: isGuessCorrect ? AppColors.police : AppColors.chor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.gapVXs,
                    Text(
                      isGuessCorrect
                          ? 'Police wins 500 points! Chor receives 0 points.'
                          : 'Chor tricked the Police! Chor steals 500 points.',
                      style: AppTextStyles.bodyMedium(),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              AppSpacing.gapVLg,

              // --- Roles Revealed Section ---
              Text('UNMASKED ROLES', style: AppTextStyles.heading3()),
              AppSpacing.gapVSm,

              ...resultsState.players.map((player) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: PlayerTile(
                    player: player,
                    revealRole: true,
                  ),
                );
              }),

              AppSpacing.gapVLg,

              // --- Match Leaderboard Standings ---
              Text('MATCH LEADERBOARD', style: AppTextStyles.heading3()),
              AppSpacing.gapVSm,

              ...resultsState.leaderboard.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final player = entry.value;
                return GameCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '#$rank',
                        style: AppTextStyles.heading3(
                          color: rank == 1 ? AppColors.raja : AppColors.textLightMuted,
                        ),
                      ),
                      AppSpacing.gapHMd,
                      Expanded(
                        child: Text(
                          player.name,
                          style: AppTextStyles.bodyLarge(),
                        ),
                      ),
                      Text(
                        '${player.score} pts',
                        style: AppTextStyles.heading3(color: AppColors.secondary),
                      ),
                    ],
                  ),
                );
              }),

              AppSpacing.gapVXl,

              // --- Continuation Controls ---
              if (isHost && !resultsState.isMatchOver)
                CustomButton(
                  label: 'START NEXT ROUND',
                  icon: Icons.skip_next,
                  isLoading: resultsState.isAdvancing,
                  onPressed: () async {
                    final advanced = await ref
                        .read(resultsViewModelProvider(widget.roomCode).notifier)
                        .startNextRound();
                    if (advanced && context.mounted) {
                      context.go(AppRoutes.gameRoundPath(widget.roomCode));
                    }
                  },
                )
              else if (resultsState.isMatchOver)
                CustomButton(
                  label: 'FINISH MATCH & RETURN HOME',
                  variant: ButtonVariant.secondary,
                  onPressed: () => context.go(AppRoutes.home),
                )
              else
                Text(
                  'Waiting for host to start the next round...',
                  style: AppTextStyles.bodyMedium(color: AppColors.textLightSecondary),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
