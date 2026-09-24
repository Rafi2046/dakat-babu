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
import '../../../core/utils/extensions.dart';
import '../../../data/models/player_model.dart';
import '../../../data/models/room_model.dart';
import '../../../data/models/round_model.dart';
import '../../viewmodels/game_round_viewmodel.dart';
import '../../widgets/animated_living_background.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/custom_button.dart';
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Round ${roundState.round?.roundNumber ?? 1}',
          style: AppTextStyles.heading2(),
        ),
        leading: IconButton(
          icon: Icon(PhosphorIcons.door(PhosphorIconsStyle.bold)),
          tooltip: 'Leave Match',
          onPressed: () => _handleLeave(context, isHost, currentUserId),
        ),
        actions: [
          // Scoreboard live view button
          IconButton(
            icon: Icon(
              PhosphorIcons.trophy(PhosphorIconsStyle.fill),
              color: AppColors.accent,
              size: 20,
            ),
            tooltip: 'Scoreboard',
            onPressed: () => context.push(AppRoutes.scoreboardPath(widget.roomCode)),
          ),
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
                  : const Color(0x35000000),
              borderRadius: AppRadius.pillRadius,
              border: Border.all(
                color: roundState.remainingSeconds <= 10
                    ? AppColors.error
                    : Colors.white.withValues(alpha: 0.12),
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
                  size: 15,
                  color: roundState.remainingSeconds <= 10
                      ? AppColors.error
                      : AppColors.textLightPrimary,
                ),
                const SizedBox(width: 5),
                Text(
                  '${roundState.remainingSeconds}s',
                  style: AppTextStyles.button(
                    color: roundState.remainingSeconds <= 10
                        ? AppColors.error
                        : AppColors.textLightPrimary,
                  ).copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
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
            ),
          ),
          if (roundState.isPlayerLeft)
            _buildPlayerLeftOverlay(context, roundState, isHost, currentUserId),
        ],
      ),
    );
  }

  /// Royal Proclamation Card declaring the Raja to everyone,
  /// and showing Police identity to the Raja per game rules.
  Widget _buildRoyalProclamation(GameRoundState state, {required bool isRaja}) {
    final raja = state.rajaPlayer;
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
                'ROYAL PROCLAMATION',
                style: AppTextStyles.caption(color: AppColors.raja).copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Raja identity announced to all
          Row(
            children: [
              const RoleVectorIcon(role: GameRole.raja, size: 20, hasGlow: false),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '👑 Raja: ${raja?.name ?? 'Declaring...'} (Sovereign)',
                  style: AppTextStyles.bodyMedium(color: AppColors.raja).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          // If current user is Raja, they also see who the Police is
          if (isRaja && police != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const RoleVectorIcon(role: GameRole.police, size: 20, hasGlow: false),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '👮 Your Inspector: ${police.name} (Investigating)',
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

  /// Police "Interrogation Board" with detective case-board aesthetics,
  /// pinned-photo cards, subtle tilt angles, pulsing red tension glow, and swipe-to-accuse.
  Widget _buildPoliceInterrogationSection(
    GameRoundState state,
    String? currentUserId,
  ) {
    // Show the other players in the room (suspect pool + Raja who is unselectable)
    final otherPlayers = state.players.where((p) => p.id != currentUserId).toList();
    final selectedSuspect = otherPlayers.cast<PlayerModel?>().firstWhere(
          (p) => p?.id == state.selectedSuspectId,
          orElse: () => null,
        );

    // Subtle tilt angles per suspect position for pinned-photo feel
    const tiltAngles = [-0.035, 0.028, -0.022, 0.032, -0.018];

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
          // Detective Case-Board Header
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
                      'Tap or swipe up on a suspect card to accuse',
                      style: AppTextStyles.caption(color: Colors.white60).copyWith(fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.fiber_manual_record, size: 7, color: AppColors.error),
                    const SizedBox(width: 4),
                    Text(
                      'ACTIVE',
                      style: AppTextStyles.caption(color: AppColors.error).copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Central Clue Connector Tag
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.45)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIcons.fingerprint(PhosphorIconsStyle.bold),
                    size: 12,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'EVIDENCE • UNMASK THE CHOR',
                    style: AppTextStyles.caption(color: Colors.white70).copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 9.5,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Pinned Case-Board Photo Suspect Cards Grid
          GridView.builder(
            itemCount: otherPlayers.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: otherPlayers.length > 3 ? 2 : 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 12,
              childAspectRatio: otherPlayers.length > 3 ? 1.05 : 0.82,
            ),
            itemBuilder: (context, index) {
              final player = otherPlayers[index];
              final isRaja = player.id == state.round?.rajaPlayerId;
              final isSelected = state.selectedSuspectId == player.id;
              final tilt = tiltAngles[index % tiltAngles.length];

              return _buildSuspectCaseBoardCard(
                player: player,
                isRaja: isRaja,
                isSelected: isSelected,
                tiltAngle: tilt,
                onTap: isRaja
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        ref
                            .read(gameRoundViewModelProvider(widget.roomCode).notifier)
                            .selectSuspect(player.id);
                      },
                onSwipeUp: isRaja
                    ? null
                    : () async {
                        HapticFeedback.mediumImpact();
                        ref
                            .read(gameRoundViewModelProvider(widget.roomCode).notifier)
                            .selectSuspect(player.id);
                        await ref
                            .read(gameRoundViewModelProvider(widget.roomCode).notifier)
                            .submitGuess();
                      },
              );
            },
          ),

          const SizedBox(height: 16),

          // Accusation submission button
          CustomButton(
            label: selectedSuspect != null
                ? 'Accuse ${selectedSuspect.name} as Chor!'
                : 'Select a Suspect on the Case-Board',
            variant: ButtonVariant.danger,
            leading: Icon(
              PhosphorIcons.gavel(PhosphorIconsStyle.fill),
              color: Colors.white,
              size: 18,
            ),
            isLoading: state.isSubmittingGuess,
            onPressed: selectedSuspect != null
                ? () async {
                    HapticFeedback.mediumImpact();
                    await ref
                        .read(gameRoundViewModelProvider(widget.roomCode).notifier)
                        .submitGuess();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  /// Single suspect pinned-photo card with subtle rotation tilt, pushpin,
  /// dashed connection, and swipe-to-accuse gesture.
  Widget _buildSuspectCaseBoardCard({
    required PlayerModel player,
    required bool isRaja,
    required bool isSelected,
    required double tiltAngle,
    required VoidCallback? onTap,
    required VoidCallback? onSwipeUp,
  }) {
    Color borderColor;
    Color bgColor;

    if (isRaja) {
      borderColor = AppColors.raja.withValues(alpha: 0.3);
      bgColor = const Color(0x28000000);
    } else if (isSelected) {
      borderColor = AppColors.error;
      bgColor = AppColors.error.withValues(alpha: 0.18);
    } else {
      borderColor = Colors.white.withValues(alpha: 0.14);
      bgColor = const Color(0x38181D2A);
    }

    return Transform.rotate(
      angle: tiltAngle,
      child: GestureDetector(
        onTap: onTap,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! < -100) {
            onSwipeUp?.call();
          }
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: isSelected ? 2.0 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.error.withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 4),

                  // Polaroid Avatar Frame
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.error : Colors.white24,
                        width: 1.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 19,
                      backgroundColor: isRaja
                          ? AppColors.raja.withValues(alpha: 0.25)
                          : (isSelected
                              ? AppColors.error.withValues(alpha: 0.3)
                              : AppColors.primary.withValues(alpha: 0.2)),
                      child: Text(
                        player.name.initials,
                        style: AppTextStyles.bodyMedium(
                          color: isRaja ? AppColors.raja : Colors.white,
                        ).copyWith(fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Player Name
                  Text(
                    player.name,
                    style: AppTextStyles.bodyMedium().copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 3),

                  // Role Status / Accuse Indicator
                  if (isRaja)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.raja.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '👑 King (Immune)',
                        style: AppTextStyles.caption(color: AppColors.raja).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 8.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIcons.arrowUp(PhosphorIconsStyle.bold),
                            size: 9,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'SWIPE / TAP',
                            style: AppTextStyles.caption(color: AppColors.error).copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      'Suspect',
                      style: AppTextStyles.caption(
                        color: AppColors.textLightMuted,
                      ).copyWith(fontSize: 9.5),
                    ),
                ],
              ),
            ),

            // Top Pushpin (detective evidence photo pin)
            Positioned(
              top: -5,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.redAccent : const Color(0xFFE57373),
                    border: Border.all(color: Colors.white, width: 0.8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Non-Police Waiting Screen with animated interrogation radar.
  Widget _buildNonPoliceWaitingSection(GameRoundState state, GameRole? role) {
    final policeName = state.policePlayer?.name ?? 'Police';

    String advice;
    switch (role) {
      case GameRole.mantri:
        advice = 'You are the Minister! Look calm & innocent so the Police doesn\'t falsely accuse you.';
        break;
      case GameRole.chor:
        advice = 'You are the Thief! Maintain a poker face. If Police suspects the Minister, you steal 500 points!';
        break;
      case GameRole.raja:
        advice = 'You are the King! Observe your court silently as your Inspector investigates.';
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
                  CustomButton(
                    label: 'Return to Lobby (Invite 4th)',
                    leading: Icon(PhosphorIcons.userPlus(PhosphorIconsStyle.bold), size: 18),
                    onPressed: () async {
                      await ref
                          .read(gameRoundViewModelProvider(widget.roomCode).notifier)
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
          ? 'As host, leaving will pause the round and transfer leadership or disband the room.'
          : 'Leaving mid-match will pause the round for all other players. Are you sure you want to exit?',
      confirmLabel: 'Leave Match',
      isDestructive: true,
    );

    if (shouldLeave && context.mounted) {
      await ref.read(gameRoundViewModelProvider(widget.roomCode).notifier).leaveGame(currentUserId);
      if (context.mounted) context.go(AppRoutes.home);
    }
  }
}
