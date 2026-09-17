import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/di/providers.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/round_model.dart';
import '../../viewmodels/game_round_viewmodel.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/game_card.dart';
import '../../widgets/player_tile.dart';

/// The active game round screen featuring secret role unmasking and Police interrogation.
class GameRoundScreen extends ConsumerStatefulWidget {
  final String roomCode;

  const GameRoundScreen({super.key, required this.roomCode});

  @override
  ConsumerState<GameRoundScreen> createState() => _GameRoundScreenState();
}

class _GameRoundScreenState extends ConsumerState<GameRoundScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentPlayerIdProvider);
    final roundState = ref.watch(gameRoundViewModelProvider(widget.roomCode));

    // When round completes, automatically route all players to results screen
    ref.listen<GameRoundState>(gameRoundViewModelProvider(widget.roomCode), (prev, current) {
      if (current.round?.status == RoundStatus.completed) {
        context.go(AppRoutes.resultsPath(widget.roomCode));
      }
      if (current.errorMessage != null &&
          current.errorMessage != prev?.errorMessage) {
        context.showErrorSnackBar(current.errorMessage!);
      }
    });

    final myPlayer = roundState.myPlayer(currentUserId);
    final myRole = myPlayer?.role;
    final isPolice = roundState.isPolice(currentUserId);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Round ${roundState.round?.roundNumber ?? 1}',
          style: AppTextStyles.heading2(),
        ),
        actions: [
          // Countdown Timer Pill
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.md),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: roundState.remainingSeconds <= 10
                  ? AppColors.error.withValues(alpha: 0.2)
                  : AppColors.surfaceElevatedDark,
              borderRadius: AppRadius.pillRadius,
              border: Border.all(
                color: roundState.remainingSeconds <= 10
                    ? AppColors.error
                    : AppColors.borderDark,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer,
                  size: 16,
                  color: roundState.remainingSeconds <= 10
                      ? AppColors.error
                      : AppColors.textLightPrimary,
                ),
                AppSpacing.gapHXs,
                Text(
                  '${roundState.remainingSeconds}s',
                  style: AppTextStyles.button(
                    color: roundState.remainingSeconds <= 10
                        ? AppColors.error
                        : AppColors.textLightPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Secret Role Card (Tap to Peek) ---
              GestureDetector(
                onTap: () => ref
                    .read(gameRoundViewModelProvider(widget.roomCode).notifier)
                    .toggleCardReveal(),
                child: GameCard(
                  gradient: roundState.isCardRevealed && myRole != null
                      ? myRole.gradient
                      : null,
                  backgroundColor: AppColors.surfaceElevatedDark,
                  borderColor: roundState.isCardRevealed && myRole != null
                      ? myRole.color
                      : AppColors.primaryLight,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Icon(
                        roundState.isCardRevealed
                            ? Icons.visibility
                            : Icons.visibility_off,
                        size: 32,
                        color: roundState.isCardRevealed
                            ? Colors.white
                            : AppColors.primaryLight,
                      ),
                      AppSpacing.gapVSm,
                      Text(
                        roundState.isCardRevealed && myRole != null
                            ? myRole.displayName.toUpperCase()
                            : 'YOUR SECRET ROLE',
                        style: AppTextStyles.roleTitle(
                          color: roundState.isCardRevealed
                              ? Colors.white
                              : AppColors.textLightPrimary,
                        ),
                      ),
                      AppSpacing.gapVXs,
                      Text(
                        roundState.isCardRevealed && myRole != null
                            ? myRole.instructions
                            : 'Tap to unmask and keep secret!',
                        style: AppTextStyles.bodyMedium(
                          color: roundState.isCardRevealed
                              ? Colors.white.withValues(alpha: 0.9)
                              : AppColors.textLightSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              AppSpacing.gapVXl,

              // --- Court Proclamation (Who is Raja / Police) ---
              GameCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COURT ANNOUNCEMENTS',
                      style: AppTextStyles.caption(color: AppColors.textLightSecondary),
                    ),
                    AppSpacing.gapVSm,
                    if (roundState.rajaPlayer != null)
                      Text(
                        '👑 Raja: ${roundState.rajaPlayer!.name} (Declared)',
                        style: AppTextStyles.bodyLarge(color: AppColors.raja),
                      ),
                    AppSpacing.gapVXs,
                    if (roundState.policePlayer != null)
                      Text(
                        '👮 Police: ${roundState.policePlayer!.name} (Investigating)',
                        style: AppTextStyles.bodyLarge(color: AppColors.police),
                      ),
                  ],
                ),
              ),

              AppSpacing.gapVLg,

              // --- Suspect Accusation Section ---
              Text(
                isPolice ? 'SELECT THE CHOR (THIEF):' : 'SUSPECTS UNDER QUESTIONING:',
                style: AppTextStyles.heading3(),
              ),
              AppSpacing.gapVSm,

              ...roundState.suspects.map((suspect) {
                final isSelected = roundState.selectedSuspectId == suspect.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: PlayerTile(
                    player: suspect,
                    isSelected: isSelected,
                    onTap: isPolice
                        ? () {
                            ref
                                .read(gameRoundViewModelProvider(widget.roomCode).notifier)
                                .selectSuspect(suspect.id);
                          }
                        : null,
                  ),
                );
              }),

              AppSpacing.gapVLg,

              // --- Accusation Submission Button ---
              if (isPolice)
                CustomButton(
                  label: 'ACCUSE AS CHOR!',
                  variant: ButtonVariant.danger,
                  icon: Icons.gavel,
                  isLoading: roundState.isSubmittingGuess,
                  onPressed: roundState.selectedSuspectId != null
                      ? () async {
                          await ref
                              .read(gameRoundViewModelProvider(widget.roomCode).notifier)
                              .submitGuess();
                        }
                      : null,
                )
              else
                GameCard(
                  backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.5),
                  child: Center(
                    child: Text(
                      'Police is questioning the suspects... Hold your nerve!',
                      style: AppTextStyles.bodyMedium(color: AppColors.textLightSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
