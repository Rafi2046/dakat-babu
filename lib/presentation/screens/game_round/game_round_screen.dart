import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/di/providers.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/round_model.dart';
import '../../viewmodels/game_round_viewmodel.dart';
import '../../widgets/animated_living_background.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/game_card.dart';
import '../../widgets/player_tile.dart';
import '../../widgets/role_art.dart';

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
    final currentUserId = ref.watch(currentPlayerIdProvider) ??
        ref.watch(supabaseServiceProvider).currentUserId;
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
      extendBodyBehindAppBar: true,
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
                  ? AppColors.error.withValues(alpha: 0.25)
                  : AppColors.glassFill,
              borderRadius: AppRadius.pillRadius,
              border: Border.all(
                color: roundState.remainingSeconds <= 10
                    ? AppColors.error
                    : AppColors.glassBorder,
              ),
              boxShadow: [
                if (roundState.remainingSeconds <= 10)
                  BoxShadow(
                    color: AppColors.error.withValues(alpha: 0.4),
                    blurRadius: 10,
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PhosphorIcons.timer(PhosphorIconsStyle.bold),
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
      body: AnimatedLivingBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSpacing.gapVSm,

                // --- Secret Role Card (Tap to Peek) ---
                GestureDetector(
                  onTap: () => ref
                      .read(gameRoundViewModelProvider(widget.roomCode).notifier)
                      .toggleCardReveal(),
                  child: GameCard(
                    isGlass: true,
                    glowColor: roundState.isCardRevealed && myRole != null
                        ? myRole.color.withValues(alpha: 0.35)
                        : AppColors.primaryGlow,
                    borderColor: roundState.isCardRevealed && myRole != null
                        ? myRole.color
                        : AppColors.primaryLight,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Stack(
                      children: [
                        // Watermark pattern when revealed
                        if (roundState.isCardRevealed && myRole != null)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: RolePatternPainter(role: myRole),
                            ),
                          ),

                        Column(
                          children: [
                            if (roundState.isCardRevealed && myRole != null)
                              RoleVectorIcon(
                                role: myRole,
                                size: 56,
                                hasGlow: true,
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                ),
                                child: Icon(
                                  PhosphorIcons.eyeSlash(PhosphorIconsStyle.bold),
                                  size: 36,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            AppSpacing.gapVSm,
                            Text(
                              roundState.isCardRevealed && myRole != null
                                  ? myRole.displayName.toUpperCase()
                                  : 'TAP TO VIEW SECRET ROLE',
                              style: AppTextStyles.roleTitle(
                                color: roundState.isCardRevealed && myRole != null
                                    ? myRole.color
                                    : AppColors.textLightPrimary,
                              ).copyWith(fontSize: 24),
                            ),
                            AppSpacing.gapVXs,
                            Text(
                              roundState.isCardRevealed && myRole != null
                                  ? myRole.instructions
                                  : 'Tap to peek. Keep your screen hidden from rivals!',
                              style: AppTextStyles.bodyMedium(
                                color: roundState.isCardRevealed
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : AppColors.textLightSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                AppSpacing.gapVLg,

                // --- Court Proclamation (Who is Raja / Police) ---
                GameCard(
                  isGlass: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            PhosphorIcons.megaphone(PhosphorIconsStyle.fill),
                            size: 16,
                            color: AppColors.raja,
                          ),
                          AppSpacing.gapHXs,
                          Text(
                            'ROYAL PROCLAMATION',
                            style: AppTextStyles.caption(color: AppColors.textLightSecondary)
                                .copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.8),
                          ),
                        ],
                      ),
                      AppSpacing.gapVSm,
                      if (roundState.rajaPlayer != null)
                        Row(
                          children: [
                            const RoleVectorIcon(role: GameRole.raja, size: 22, hasGlow: false),
                            AppSpacing.gapHSm,
                            Text(
                              '👑 Raja: ${roundState.rajaPlayer!.name} (Declared)',
                              style: AppTextStyles.bodyLarge(color: AppColors.raja)
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      AppSpacing.gapVXs,
                      if (roundState.policePlayer != null)
                        Row(
                          children: [
                            const RoleVectorIcon(role: GameRole.police, size: 22, hasGlow: false),
                            AppSpacing.gapHSm,
                            Text(
                              '👮 Police: ${roundState.policePlayer!.name} (Investigating)',
                              style: AppTextStyles.bodyLarge(color: AppColors.police)
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                AppSpacing.gapVLg,

                // --- Suspect Accusation Section ---
                Text(
                  isPolice ? 'SELECT THE CHOR (THIEF):' : 'SUSPECTS UNDER QUESTIONING:',
                  style: AppTextStyles.heading3().copyWith(fontWeight: FontWeight.w800),
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
                    leading: Icon(
                      PhosphorIcons.gavel(PhosphorIconsStyle.fill),
                      color: Colors.white,
                      size: 20,
                    ),
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
                    isGlass: true,
                    backgroundColor: AppColors.glassFill.withValues(alpha: 0.3),
                    child: Center(
                      child: Text(
                        'Police is questioning the suspects... Keep a poker face!',
                        style: AppTextStyles.bodyMedium(color: AppColors.textLightSecondary),
                        textAlign: TextAlign.center,
                      ),
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
