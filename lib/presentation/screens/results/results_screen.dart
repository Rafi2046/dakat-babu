import 'dart:ui';
import 'package:confetti/confetti.dart';
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
import '../../../core/services/sound_service.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/player_model.dart';
import '../../../data/models/room_model.dart';
import '../../../data/models/round_model.dart';
import '../../viewmodels/results_viewmodel.dart';
import '../../widgets/animated_living_background.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/game_card.dart';
import '../../widgets/role_badge.dart';

/// Screen revealing round resolution, role unmaskings, round points, and overall leaderboard.
class ResultsScreen extends ConsumerStatefulWidget {
  final String roomCode;

  const ResultsScreen({super.key, required this.roomCode});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    // Play dramatic suspense sting right before unmasking, followed by success chime or failure buzz
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(soundServiceProvider).playSting();
      Future.delayed(const Duration(milliseconds: 750), () {
        if (!mounted) return;
        final state = ref.read(resultsViewModelProvider(widget.roomCode));
        if (state.round?.isGuessCorrect ?? false) {
          _confettiController.play();
          ref.read(soundServiceProvider).playSuccess();
        } else {
          ref.read(soundServiceProvider).playFailure();
        }
      });
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentPlayerIdProvider) ??
        ref.watch(supabaseServiceProvider).currentUserId;
    final resultsState = ref.watch(resultsViewModelProvider(widget.roomCode));
    final isHost = resultsState.isHost(currentUserId);

    // Listen for next round launch, cancellation, or return to lobby
    ref.listen<ResultsState>(resultsViewModelProvider(widget.roomCode), (prev, current) {
      if (current.isCancelled && !(prev?.isCancelled ?? false)) {
        AppFeedback.showRoomCancelledDialog(context);
        return;
      }
      if (current.room?.status == RoomStatus.waiting) {
        context.go(AppRoutes.lobbyPath(widget.roomCode));
        return;
      }
      // Only navigate to GameRound if a NEW active round has actually started.
      // Must NOT navigate if the round is completed (which is what this screen displays).
      final isNewActiveRound = current.round != null &&
          current.round!.status != RoundStatus.completed;
      final wasCompletedOrNew = prev?.round == null
          ? (current.round?.status == RoundStatus.roleReveal)
          : (prev!.round?.status == RoundStatus.completed ||
              (current.round != null &&
                  current.round!.roundNumber > prev.round!.roundNumber));

      if (isNewActiveRound && wasCompletedOrNew) {
        context.go(AppRoutes.gameRoundPath(widget.roomCode));
      }
      if (current.errorMessage != null &&
          current.errorMessage != prev?.errorMessage) {
        AppFeedback.showSnackBar(
          context,
          message: current.errorMessage!,
          isError: true,
        );
      }
    });

    final round = resultsState.round;
    final isGuessCorrect = round?.isGuessCorrect ?? false;
    final policePlayer = resultsState.policePlayer;
    final chorPlayer = resultsState.chorPlayer;
    final accusedPlayer = resultsState.accusedPlayer;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Round ${round?.roundNumber ?? 1} Results',
          style: AppTextStyles.heading2(),
        ),
        leading: IconButton(
          icon: Icon(PhosphorIcons.door(PhosphorIconsStyle.bold)),
          tooltip: 'Leave Match',
          onPressed: () => _handleLeave(context, isHost, currentUserId),
        ),
        actions: [
          IconButton(
            icon: Icon(
              PhosphorIcons.trophy(PhosphorIconsStyle.fill),
              color: AppColors.accent,
              size: 20,
            ),
            tooltip: 'Scoreboard',
            onPressed: () => context.push(AppRoutes.scoreboardPath(widget.roomCode)),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Confetti celebration burst
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              maxBlastForce: 28,
              minBlastForce: 10,
              gravity: 0.25,
              colors: const [
                AppColors.raja,
                AppColors.police,
                AppColors.secondary,
                AppColors.success,
                Colors.pinkAccent,
                Colors.amber,
              ],
            ),
          ),
          AnimatedLivingBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md + 2,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 6),

                    // --- 1. Climax Outcome Banner ---
                    GameCard(
                      isGlass: true,
                      glowColor: isGuessCorrect ? AppColors.policeGlow : AppColors.chorGlow,
                      borderColor: isGuessCorrect ? AppColors.police : AppColors.chor,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Column(
                        children: [
                          Icon(
                            isGuessCorrect
                                ? PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill)
                                : PhosphorIcons.maskHappy(PhosphorIconsStyle.fill),
                            size: 48,
                            color: isGuessCorrect ? AppColors.police : AppColors.chor,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            isGuessCorrect
                                ? 'POLICE CAUGHT THE CHOR!'
                                : 'THE CHOR ESCAPED!',
                            style: AppTextStyles.heading2(
                              color: isGuessCorrect ? const Color(0xFF48CAE4) : AppColors.chor,
                            ).copyWith(fontWeight: FontWeight.w900, fontSize: 22),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isGuessCorrect
                                ? '👮 ${policePlayer?.name ?? 'Police'} accused ${chorPlayer?.name ?? 'Chor'} correctly!'
                                : '👮 ${policePlayer?.name ?? 'Police'} accused ${accusedPlayer?.name ?? 'Suspect'} mistakenly! 🎭 ${chorPlayer?.name ?? 'Chor'} stole the 500 points.',
                            style: AppTextStyles.bodyMedium(color: Colors.white70).copyWith(fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- 2. All 4 Roles Revealed & Points Awarded ---
                    _buildAllRolesRevealedSection(resultsState),

                    const SizedBox(height: 20),

                    // --- 3. Match Leaderboard Standings ---
                    _buildLeaderboardSection(resultsState.leaderboard),

                    const SizedBox(height: 12),

                    // Dedicated Scoreboard Screen button
                    CustomButton(
                      label: 'View Detailed Scoreboard & History',
                      variant: ButtonVariant.outlined,
                      leading: Icon(
                        PhosphorIcons.chartBar(PhosphorIconsStyle.bold),
                        color: AppColors.accent,
                        size: 18,
                      ),
                      onPressed: () => context.push(AppRoutes.scoreboardPath(widget.roomCode)),
                    ),

                    const SizedBox(height: 16),

                    // --- 4. Continuation Controls ---
                    if (isHost && !resultsState.isMatchOver)
                      CustomButton(
                        label: 'Start Next Round (${(round?.roundNumber ?? 1) + 1})',
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0x25000000),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Text(
                          'Waiting for host to launch the next royal round...',
                          style: AppTextStyles.bodyMedium(color: AppColors.textLightSecondary)
                              .copyWith(fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          if (resultsState.isPlayerLeft)
            _buildPlayerLeftOverlay(context, resultsState, isHost, currentUserId),
        ],
      ),
    );
  }

  /// Section displaying all 4 unmasked courtiers and points earned this round.
  Widget _buildAllRolesRevealedSection(ResultsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              PhosphorIcons.eye(PhosphorIconsStyle.bold),
              size: 16,
              color: AppColors.secondary,
            ),
            const SizedBox(width: 6),
            Text(
              'ROLES UNMASKED THIS ROUND',
              style: AppTextStyles.heading3().copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Unmasked players list
        ...state.players.map((player) {
          final role = player.role;
          final roundPoints = _calculateRoundPoints(player, state.round, state.room);
          final customLabel = role != null ? state.room?.getLabelForRole(role) : null;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GameCard(
              isGlass: true,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              borderColor: role?.color.withValues(alpha: 0.35) ?? Colors.white.withValues(alpha: 0.1),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: role != null
                        ? role.color.withValues(alpha: 0.2)
                        : AppColors.primary.withValues(alpha: 0.2),
                    child: Text(
                      player.name.initials,
                      style: AppTextStyles.bodyMedium(
                        color: role?.color ?? Colors.white,
                      ).copyWith(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                player.name,
                                style: AppTextStyles.bodyMedium().copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (player.isHost) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.star,
                                size: 12,
                                color: AppColors.raja,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total: ${player.score} pts',
                          style: AppTextStyles.caption(
                            color: AppColors.textLightSecondary,
                          ).copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),

                  if (role != null) ...[
                    RoleBadge(
                      role: role,
                      customLabel: customLabel,
                      customPoints: roundPoints,
                      isCompact: true,
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Round points chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: roundPoints > 0
                          ? AppColors.success.withValues(alpha: 0.18)
                          : AppColors.textLightMuted.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: roundPoints > 0
                            ? AppColors.success.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.1),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      '+$roundPoints pts',
                      style: AppTextStyles.caption(
                        color: roundPoints > 0
                            ? AppColors.success
                            : AppColors.textLightMuted,
                      ).copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Leaderboard ranking all players by cumulative score.
  Widget _buildLeaderboardSection(List<PlayerModel> leaderboard) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              PhosphorIcons.trophy(PhosphorIconsStyle.fill),
              size: 16,
              color: AppColors.secondary,
            ),
            const SizedBox(width: 6),
            Text(
              'MATCH LEADERBOARD',
              style: AppTextStyles.heading3().copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        ...leaderboard.asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final player = entry.value;
          final isFirst = rank == 1;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GameCard(
              isGlass: true,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              borderColor: isFirst
                  ? AppColors.raja.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.08),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFirst
                          ? AppColors.raja.withValues(alpha: 0.2)
                          : const Color(0x30000000),
                      border: Border.all(
                        color: isFirst ? AppColors.raja : Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '#$rank',
                      style: AppTextStyles.caption(
                        color: isFirst ? AppColors.raja : AppColors.textLightMuted,
                      ).copyWith(fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      player.name,
                      style: AppTextStyles.bodyMedium().copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${player.score} pts',
                    style: AppTextStyles.heading3(
                      color: isFirst ? AppColors.raja : AppColors.secondary,
                    ).copyWith(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Full-screen frosted overlay when a player leaves or disconnects mid-match.
  Widget _buildPlayerLeftOverlay(
    BuildContext context,
    ResultsState state,
    bool isHost,
    String? currentUserId,
  ) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: const Color(0xB5000000),
          padding: const EdgeInsets.all(AppSpacing.lg),
          alignment: Alignment.center,
          child: GameCard(
            isGlass: true,
            borderColor: AppColors.error.withValues(alpha: 0.6),
            glowColor: AppColors.error.withValues(alpha: 0.3),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    PhosphorIcons.warning(PhosphorIconsStyle.fill),
                    color: AppColors.error,
                    size: 28,
                  ),
                ),
                AppSpacing.gapVMd,
                Text(
                  'Courtier Disconnected',
                  style: AppTextStyles.heading2(color: Colors.white).copyWith(fontSize: 22),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapVSm,
                Text(
                  'A player has left the match. DakatBabu requires 4 players to proceed to the next round.',
                  style: AppTextStyles.bodyMedium(color: AppColors.textLightSecondary),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapVMd,
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevatedDark,
                    borderRadius: AppRadius.chipRadius,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(PhosphorIcons.users(PhosphorIconsStyle.bold), size: 16, color: AppColors.primaryLight),
                      AppSpacing.gapHSm,
                      Text(
                        'Courtiers in Room: ${state.players.length}/${AppConstants.maxPlayers}',
                        style: AppTextStyles.caption(color: Colors.white).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapVLg,
                if (isHost) ...[
                  CustomButton(
                    label: 'Return to Lobby (Invite 4th)',
                    leading: Icon(PhosphorIcons.userPlus(PhosphorIconsStyle.bold), size: 18),
                    onPressed: () async {
                      await ref
                          .read(resultsViewModelProvider(widget.roomCode).notifier)
                          .returnToLobby();
                    },
                  ),
                  AppSpacing.gapVSm,
                  CustomButton(
                    label: 'Disband Room',
                    variant: ButtonVariant.danger,
                    leading: Icon(PhosphorIcons.xCircle(PhosphorIconsStyle.bold), size: 18),
                    onPressed: () async {
                      final confirm = await AppFeedback.showConfirmationDialog(
                        context,
                        title: 'Disband Room?',
                        message: 'Are you sure you want to end this game and return all players to the main hall?',
                        confirmLabel: 'Disband',
                        isDestructive: true,
                      );
                      if (confirm && context.mounted) {
                        await ref
                            .read(resultsViewModelProvider(widget.roomCode).notifier)
                            .cancelGame();
                      }
                    },
                  ),
                ] else ...[
                  Text(
                    'Waiting for the host to invite a replacement courtier...',
                    style: AppTextStyles.caption(color: AppColors.secondary).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.gapVMd,
                  CustomButton(
                    label: 'Leave Match',
                    variant: ButtonVariant.outlined,
                    leading: Icon(PhosphorIcons.door(PhosphorIconsStyle.bold), size: 18),
                    onPressed: () => _handleLeave(context, isHost, currentUserId),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLeave(BuildContext context, bool isHost, String? currentUserId) async {
    if (currentUserId == null) {
      context.go(AppRoutes.home);
      return;
    }

    final shouldLeave = await AppFeedback.showConfirmationDialog(
      context,
      title: 'Leave Match?',
      message: isHost
          ? 'As host, leaving will disband the room or reassign leadership.'
          : 'Leaving mid-match will pause the game for all other players. Are you sure you want to exit?',
      confirmLabel: 'Leave Match',
      isDestructive: true,
    );

    if (shouldLeave && context.mounted) {
      await ref.read(resultsViewModelProvider(widget.roomCode).notifier).leaveGame(currentUserId);
      if (context.mounted) context.go(AppRoutes.home);
    }
  }

  int _calculateRoundPoints(PlayerModel player, RoundModel? round, RoomModel? room) {
    if (round == null) return 0;
    final isCorrect = round.isGuessCorrect ?? false;
    final delta = room?.getPointsForRole(GameRole.police) ??
        AppConstants.policeCorrectPoints;

    // +1 system: correct → Police; wrong → selected suspect.
    if (isCorrect) {
      if (player.id == round.policePlayerId) return delta;
      return 0;
    }
    if (player.id == round.policeGuessPlayerId) {
      return room?.getPointsForRole(GameRole.chor) ??
          AppConstants.wrongGuessSuspectPoints;
    }
    return 0;
  }
}
