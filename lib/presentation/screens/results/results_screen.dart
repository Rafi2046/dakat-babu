import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/di/providers.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/round_model.dart';
import '../../viewmodels/results_viewmodel.dart';
import '../../widgets/animated_living_background.dart';
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
    final currentUserId = ref.watch(currentPlayerIdProvider) ??
        ref.watch(supabaseServiceProvider).currentUserId;
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Round ${round?.roundNumber ?? 1} Outcome',
          style: AppTextStyles.heading2(),
        ),
        automaticallyImplyLeading: false,
      ),
      body: AnimatedLivingBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSpacing.gapVSm,

                // --- Climax Outcome Banner ---
                GameCard(
                  isGlass: true,
                  glowColor: isGuessCorrect ? AppColors.policeGlow : AppColors.chorGlow,
                  borderColor: isGuessCorrect ? AppColors.police : AppColors.chor,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Icon(
                        isGuessCorrect
                            ? PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill)
                            : PhosphorIcons.maskHappy(PhosphorIconsStyle.fill),
                        size: 54,
                        color: isGuessCorrect ? AppColors.police : AppColors.chor,
                      ),
                      AppSpacing.gapVSm,
                      Text(
                        isGuessCorrect
                            ? 'POLICE CAUGHT THE CHOR!'
                            : 'THE CHOR ESCAPED!',
                        style: AppTextStyles.heading2(
                          color: isGuessCorrect ? const Color(0xFF48CAE4) : AppColors.chor,
                        ).copyWith(fontWeight: FontWeight.w900),
                        textAlign: TextAlign.center,
                      ),
                      AppSpacing.gapVXs,
                      Text(
                        isGuessCorrect
                            ? 'Police wins 500 points! Chor receives 0 points.'
                            : 'Chor deceived the Police and steals 500 points!',
                        style: AppTextStyles.bodyMedium(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                AppSpacing.gapVLg,

                // --- Roles Revealed Section ---
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.eye(PhosphorIconsStyle.fill),
                      size: 18,
                      color: AppColors.raja,
                    ),
                    AppSpacing.gapHSm,
                    Text(
                      'UNMASKED ROLES',
                      style: AppTextStyles.heading3().copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
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
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.trophy(PhosphorIconsStyle.fill),
                      size: 18,
                      color: AppColors.secondary,
                    ),
                    AppSpacing.gapHSm,
                    Text(
                      'MATCH LEADERBOARD',
                      style: AppTextStyles.heading3().copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                AppSpacing.gapVSm,

                ...resultsState.leaderboard.asMap().entries.map((entry) {
                  final rank = entry.key + 1;
                  final player = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: GameCard(
                      isGlass: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm + 2,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: rank == 1
                                  ? AppColors.raja.withValues(alpha: 0.2)
                                  : AppColors.glassFill,
                              border: Border.all(
                                color: rank == 1 ? AppColors.raja : AppColors.glassBorder,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '#$rank',
                              style: AppTextStyles.caption(
                                color: rank == 1 ? AppColors.raja : AppColors.textLightMuted,
                              ).copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          AppSpacing.gapHMd,
                          Expanded(
                            child: Text(
                              player.name,
                              style: AppTextStyles.bodyLarge().copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '${player.score} pts',
                            style: AppTextStyles.heading3(color: AppColors.secondary)
                                .copyWith(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                AppSpacing.gapVXl,

                // --- Continuation Controls ---
                if (isHost && !resultsState.isMatchOver)
                  CustomButton(
                    label: 'Start Next Round',
                    leading: Icon(
                      PhosphorIcons.fastForward(PhosphorIconsStyle.fill),
                      color: Colors.white,
                      size: 18,
                    ),
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
                    label: 'Return to Home',
                    variant: ButtonVariant.secondary,
                    leading: Icon(
                      PhosphorIcons.house(PhosphorIconsStyle.bold),
                      color: AppColors.backgroundDark,
                      size: 18,
                    ),
                    onPressed: () => context.go(AppRoutes.home),
                  )
                else
                  Text(
                    'Waiting for host to launch the next royal round...',
                    style: AppTextStyles.bodyMedium(color: AppColors.textLightSecondary),
                    textAlign: TextAlign.center,
                  ),
                AppSpacing.gapVMd,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
