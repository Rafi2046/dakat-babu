import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../data/models/player_model.dart';
import '../../../data/models/room_model.dart';
import '../../../data/models/round_model.dart';
import '../../viewmodels/game_round_viewmodel.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/cpdb/cpdb.dart';
import '../../widgets/flip_role_card.dart';
import '../../widgets/game_card.dart';
import '../../widgets/role_art.dart';

/// The active game round screen featuring secret 3D role flip unmasking,
/// Royal Proclamation, Police suspect selection grid, and non-police waiting radar.
class GameRoundScreen extends ConsumerStatefulWidget {
  final String roomCode;

  const GameRoundScreen({super.key, required this.roomCode});

  @override
  ConsumerState<GameRoundScreen> createState() => _GameRoundScreenState();
}

class _GameRoundScreenState extends ConsumerState<GameRoundScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentPlayerIdProvider) ??
        ref.watch(supabaseServiceProvider).currentUserId;
    final roundState = ref.watch(gameRoundViewModelProvider(widget.roomCode));
    final isHost = roundState.isHost(currentUserId);
    final myPlayer = roundState.myPlayer(currentUserId);
    final myRole = myPlayer?.role;
    final isPolice = roundState.isPolice(currentUserId);
    final isBabu = myRole == GameRole.babu;

    // When round completes or police submits guess, route all players to results screen
    ref.listen<GameRoundState>(gameRoundViewModelProvider(widget.roomCode), (prev, current) {
      if (current.isCancelled && !(prev?.isCancelled ?? false)) {
        AppFeedback.showRoomCancelledDialog(context);
        return;
      }
      if (current.room?.status == RoomStatus.waiting) {
        context.go(AppRoutes.lobbyPath(widget.roomCode));
        return;
      }
      final prevCompleted = prev?.round?.status == RoundStatus.completed ||
          prev?.round?.policeGuessPlayerId != null;
      final isCompleted = current.round?.status == RoundStatus.completed ||
          current.round?.policeGuessPlayerId != null;
      if (isCompleted && !prevCompleted) {
        context.go(AppRoutes.resultsPath(widget.roomCode));
      }

      // Play subtle clock tick when Police is deciding under pressure
      if (isPolice &&
          current.remainingSeconds != prev?.remainingSeconds &&
          current.remainingSeconds <= 15 &&
          current.remainingSeconds > 0) {
        ref.read(soundServiceProvider).playTick();
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

    final currentRound = roundState.round?.roundNumber ?? 1;
    final totalRounds = roundState.room?.maxRounds ?? 5;

    return AppShell(
      padding: EdgeInsets.zero,
      topBar: TopBar(
        showProfile: false,
        onBack: () => _handleLeave(context, isHost, currentUserId),
        actions: [
          RoundIndicator(current: currentRound, total: totalRounds),
          const SizedBox(width: 8),
          GameTimer(
            remainingSeconds: roundState.remainingSeconds,
            urgent: roundState.remainingSeconds <= 10,
          ),
          CpdbIconButton(
            icon: Icons.emoji_events_rounded,
            color: AppColors.accent,
            onPressed: () =>
                context.push(AppRoutes.scoreboardPath(widget.roomCode)),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md + 2,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 6),

                // --- 1. Secret Role Reveal Flip Card ---
                FlipRoleCard(
                  role: myRole,
                  isRevealed: roundState.isCardRevealed,
                  onToggle: () {
                    HapticFeedback.lightImpact();
                    ref
                        .read(gameRoundViewModelProvider(widget.roomCode).notifier)
                        .toggleCardReveal();
                  },
                ),

                const SizedBox(height: 14),

                // --- 2. Royal Proclamation Banner ---
                _buildPublicRolesBanner(roundState, isBabu: isBabu),

                const SizedBox(height: 16),

                // --- 3. Role-Specific Phase Interface ---
                if (isPolice)
                  _buildPoliceInterrogationSection(roundState, currentUserId)
                else
                  _buildNonPoliceWaitingSection(roundState, myRole),

                const SizedBox(height: 20),
              ],
            ),
          ),
          if (roundState.isPlayerLeft)
            _buildPlayerLeftOverlay(context, roundState, isHost, currentUserId),
        ],
      ),
    );
  }

  /// Public roles banner: Police + Babu are known to everyone.
  Widget _buildPublicRolesBanner(GameRoundState state, {required bool isBabu}) {
    final babu = state.babuPlayer;
    final police = state.policePlayer;

    return GameCard(
      isGlass: true,
      borderColor: AppColors.raja.withValues(alpha: 0.25),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIcons.megaphone(PhosphorIconsStyle.fill),
                size: 15,
                color: AppColors.raja,
              ),
              const SizedBox(width: 6),
              Text(
                'PUBLIC ROLES',
                style: AppTextStyles.caption(color: AppColors.raja).copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Babu identity announced to all
          Row(
            children: [
              const RoleVectorIcon(role: GameRole.babu, size: 20, hasGlow: false),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '🎩 Babu: ${babu?.name ?? 'Declaring...'} (public)',
                  style: AppTextStyles.bodyMedium(color: AppColors.raja).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          // Police is also public
          if (police != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const RoleVectorIcon(role: GameRole.police, size: 20, hasGlow: false),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '👮 Police: ${police.name}${isBabu ? ' (investigating)' : ''}',
                    style: AppTextStyles.bodyMedium(color: AppColors.police).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Police interrogation board — select a suspect via [PlayerCard]s.
  Widget _buildPoliceInterrogationSection(
    GameRoundState state,
    String? currentUserId,
  ) {
    // Suspects = everyone except Police (Babu is public but selectable).
    final otherPlayers = state.players.where((p) => p.id != currentUserId).toList();
    final selectedSuspect = otherPlayers.cast<PlayerModel?>().firstWhere(
          (p) => p?.id == state.selectedSuspectId,
          orElse: () => null,
        );

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0x3514101E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.error.withValues(
                alpha: 0.25 + 0.35 * _pulseAnimation.value,
              ),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withValues(
                  alpha: 0.10 + 0.18 * _pulseAnimation.value,
                ),
                blurRadius: 16 + 8 * _pulseAnimation.value,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold),
                  color: AppColors.error,
                  size: 15,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INTERROGATION CASE-BOARD',
                      style: AppTextStyles.heading3().copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: AppColors.error,
                      ),
                    ),
                    Text(
                      'Tap a suspect card to accuse',
                      style: AppTextStyles.caption(color: Colors.white60)
                          .copyWith(fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.fiber_manual_record,
                        size: 7, color: AppColors.error),
                    const SizedBox(width: 4),
                    Text(
                      'ACTIVE',
                      style: AppTextStyles.caption(color: AppColors.error)
                          .copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          PlayerGrid(
            crossAxisCount: otherPlayers.length > 3 ? 2 : 3,
            children: [
              for (final player in otherPlayers)
                PlayerCard(
                  name: player.name,
                  isYou: player.id == currentUserId,
                  state: state.selectedSuspectId == player.id
                      ? PlayerCardState.selected
                      : (player.id == state.round?.babuPlayerId
                          ? PlayerCardState.babu
                          : PlayerCardState.suspect),
                  visibleRole: player.id == state.round?.babuPlayerId
                      ? GameRole.babu
                      : null,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    ref
                        .read(
                            gameRoundViewModelProvider(widget.roomCode).notifier)
                        .selectSuspect(player.id);
                  },
                ),
            ],
          ),

          const SizedBox(height: 16),

          GameButton(
            label: selectedSuspect != null
                ? 'Accuse ${selectedSuspect.name} as Chor!'
                : 'Select a Suspect on the Case-Board',
            variant: ButtonVariant.danger,
            icon: PhosphorIcons.gavel(PhosphorIconsStyle.fill),
            isLoading: state.isSubmittingGuess,
            onPressed: selectedSuspect != null
                ? () async {
                    HapticFeedback.mediumImpact();
                    await ref
                        .read(
                            gameRoundViewModelProvider(widget.roomCode).notifier)
                        .submitGuess();
                  }
                : null,
          ),
        ],
      ),
    );
  }


  /// Non-Police Waiting Screen with animated interrogation radar.
  Widget _buildNonPoliceWaitingSection(GameRoundState state, GameRole? role) {
    final policeName = state.policePlayer?.name ?? 'Police';

    String advice;
    switch (role) {
      case GameRole.babu:
        advice = 'You are Babu! Your identity is public — stay calm while Police investigates.';
        break;
      case GameRole.chor:
        advice = 'You are the Chor! Keep a poker face. Police must catch you to score.';
        break;
      case GameRole.dakat:
        advice = 'You are Dakat — a decoy. Confuse the Police so they pick the wrong suspect.';
        break;
      default:
        advice = 'Maintain your poker face and wait for the Police to announce the verdict.';
    }

    return GameCard(
      isGlass: true,
      borderColor: Colors.white.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          // Animated Investigation Radar
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.85, end: 1.15),
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.police.withValues(alpha: 0.15),
                border: Border.all(
                  color: AppColors.police.withValues(alpha: 0.45),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.policeGlow,
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Icon(
                PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold),
                size: 28,
                color: AppColors.police,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Status Heading
          Text(
            'Police is Thinking...',
            style: AppTextStyles.heading2().copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),

          // Interrogation note
          Text(
            '👮 $policeName is interrogating the court suspects.',
            style: AppTextStyles.bodyMedium(color: AppColors.police).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Role specific psychology advice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0x30000000),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Text(
              advice,
              style: AppTextStyles.caption(
                color: Colors.white.withValues(alpha: 0.8),
              ).copyWith(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Full-screen frosted overlay when a player leaves or disconnects mid-match.
  Widget _buildPlayerLeftOverlay(
    BuildContext context,
    GameRoundState state,
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
                  'A courtier has left or lost network connection. DakatBabu requires all 4 players to continue the royal match.',
                  style: AppTextStyles.bodyMedium(color: AppColors.textLightSecondary),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapVMd,
                // Remaining players count chip
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
                  GameButton(
                    label: 'Return to Lobby (Invite 4th)',
                    icon: PhosphorIcons.userPlus(PhosphorIconsStyle.bold),
                    onPressed: () async {
                      await ref
                          .read(gameRoundViewModelProvider(widget.roomCode).notifier)
                          .returnToLobby();
                    },
                  ),
                  AppSpacing.gapVSm,
                  GameButton(
                    label: 'Disband Room',
                    variant: ButtonVariant.danger,
                    icon: PhosphorIcons.xCircle(PhosphorIconsStyle.bold),
                    onPressed: () async {
                      final confirm = await ConfirmationDialog.show(
                        context,
                        title: 'Disband Room?',
                        message:
                            'Are you sure you want to end this game and return all players to the main hall?',
                        confirmLabel: 'DISBAND',
                        isDestructive: true,
                      );
                      if (confirm == true && context.mounted) {
                        await ref
                            .read(gameRoundViewModelProvider(widget.roomCode).notifier)
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
                  GameButton(
                    label: 'Leave Match',
                    variant: ButtonVariant.outlined,
                    icon: PhosphorIcons.door(PhosphorIconsStyle.bold),
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

    final shouldLeave = await ConfirmationDialog.show(
      context,
      title: 'Leave Match?',
      message: isHost
          ? 'As host, leaving will pause the round and transfer leadership or disband the room.'
          : 'Leaving mid-match will pause the round for all other players. Are you sure you want to exit?',
      confirmLabel: 'LEAVE MATCH',
      isDestructive: true,
    );

    if (shouldLeave == true && context.mounted) {
      await ref.read(gameRoundViewModelProvider(widget.roomCode).notifier).leaveGame(currentUserId);
      if (context.mounted) context.go(AppRoutes.home);
    }
  }
}
