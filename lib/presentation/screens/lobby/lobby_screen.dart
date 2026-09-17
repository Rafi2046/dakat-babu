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
import '../../../core/utils/extensions.dart';
import '../../../data/models/room_model.dart';
import '../../viewmodels/lobby_viewmodel.dart';
import '../../widgets/animated_living_background.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/game_card.dart';
import '../../widgets/player_tile.dart';

/// Pre-game waiting room displaying joined players, readiness, and host launch control.
class LobbyScreen extends ConsumerStatefulWidget {
  final String roomCode;

  const LobbyScreen({super.key, required this.roomCode});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentPlayerIdProvider) ??
        ref.watch(supabaseServiceProvider).currentUserId;
    final lobbyState = ref.watch(lobbyViewModelProvider(widget.roomCode));

    // Listen to game status to automatically navigate guests when match starts
    ref.listen<LobbyState>(lobbyViewModelProvider(widget.roomCode), (prev, current) {
      if (current.room?.status == RoomStatus.inProgress) {
        context.go(AppRoutes.gameRoundPath(widget.roomCode));
      }
      if (current.errorMessage != null &&
          current.errorMessage != prev?.errorMessage) {
        context.showErrorSnackBar(current.errorMessage!);
      }
    });

    final isHost = lobbyState.isHost(currentUserId);
    final localPlayer = lobbyState.currentPlayer(currentUserId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Royal Lobby', style: AppTextStyles.heading2()),
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold)),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: AnimatedLivingBackground(
        child: SafeArea(
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSpacing.gapVSm,

                // --- Frosted Glassmorphism Room Code Header Card ---
                GameCard(
                  isGlass: true,
                  glowColor: AppColors.secondaryGlow,
                  borderColor: AppColors.secondary.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                PhosphorIcons.broadcast(PhosphorIconsStyle.fill),
                                size: 14,
                                color: AppColors.secondary,
                              ),
                              AppSpacing.gapHXs,
                              Text(
                                'ROOM CODE',
                                style: AppTextStyles.caption(color: AppColors.textLightSecondary)
                                    .copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.0),
                              ),
                            ],
                          ),
                          AppSpacing.gapVXs,
                          Text(
                            widget.roomCode,
                            style: AppTextStyles.heroTitle(color: AppColors.secondary)
                                .copyWith(fontSize: 34),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.5),
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            PhosphorIcons.copy(PhosphorIconsStyle.bold),
                            size: 22,
                            color: AppColors.secondary,
                          ),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.roomCode));
                            context.showSuccessSnackBar('Room code copied to clipboard!');
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                AppSpacing.gapVLg,

                // --- Player Count Header ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          PhosphorIcons.users(PhosphorIconsStyle.fill),
                          size: 18,
                          color: AppColors.primaryLight,
                        ),
                        AppSpacing.gapHSm,
                        Text(
                          'COURT PLAYERS (${lobbyState.players.length}/${AppConstants.maxPlayers})',
                          style: AppTextStyles.heading3().copyWith(
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (lobbyState.canStartGame ? AppColors.success : AppColors.warning)
                            .withValues(alpha: 0.15),
                        borderRadius: AppRadius.chipRadius,
                        border: Border.all(
                          color: lobbyState.canStartGame ? AppColors.success : AppColors.warning,
                        ),
                      ),
                      child: Text(
                        lobbyState.canStartGame ? 'READY TO PLAY' : 'WAITING FOR 4',
                        style: AppTextStyles.caption(
                          color: lobbyState.canStartGame ? AppColors.success : AppColors.warning,
                        ).copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapVSm,

                // --- 4 Player Slots ---
                Expanded(
                  child: ListView.separated(
                    itemCount: AppConstants.maxPlayers,
                    separatorBuilder: (context, index) => AppSpacing.gapVSm,
                    itemBuilder: (context, index) {
                      if (index < lobbyState.players.length) {
                        final player = lobbyState.players[index];
                        return PlayerTile(
                          player: player,
                          showReadyStatus: true,
                        );
                      }
                      // Empty slot placeholder with glassmorphism feel
                      return Container(
                        padding: AppSpacing.cardPadding,
                        decoration: BoxDecoration(
                          color: AppColors.glassFill.withValues(alpha: 0.4),
                          border: Border.all(
                            color: AppColors.glassBorder.withValues(alpha: 0.4),
                            style: BorderStyle.solid,
                          ),
                          borderRadius: AppRadius.cardRadius,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.surfaceElevatedDark,
                              child: Icon(
                                PhosphorIcons.userPlus(PhosphorIconsStyle.bold),
                                color: AppColors.textLightMuted,
                                size: 18,
                              ),
                            ),
                            AppSpacing.gapHMd,
                            Text(
                              'Waiting for Courtier ${index + 1}...',
                              style: AppTextStyles.bodyMedium(color: AppColors.textLightMuted),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // --- Action Controls ---
                if (isHost)
                  CustomButton(
                    label: lobbyState.canStartGame
                        ? 'Start Game'
                        : 'Waiting for Players (${lobbyState.players.length}/4)',
                    leading: Icon(
                      PhosphorIcons.play(PhosphorIconsStyle.fill),
                      color: Colors.white,
                      size: 18,
                    ),
                    isLoading: lobbyState.isStarting,
                    onPressed: lobbyState.canStartGame
                        ? () async {
                            final started = await ref
                                .read(lobbyViewModelProvider(widget.roomCode).notifier)
                                .startGame();
                            if (started && context.mounted) {
                              context.go(AppRoutes.gameRoundPath(widget.roomCode));
                            }
                          }
                        : null,
                  )
                else if (localPlayer != null)
                  CustomButton(
                    label: localPlayer.isReady ? 'Mark Not Ready' : 'I am Ready!',
                    leading: Icon(
                      localPlayer.isReady
                          ? PhosphorIcons.x(PhosphorIconsStyle.bold)
                          : PhosphorIcons.check(PhosphorIconsStyle.bold),
                      color: localPlayer.isReady ? Colors.white : AppColors.backgroundDark,
                      size: 18,
                    ),
                    variant: localPlayer.isReady
                        ? ButtonVariant.outlined
                        : ButtonVariant.secondary,
                    onPressed: () {
                      ref
                          .read(lobbyViewModelProvider(widget.roomCode).notifier)
                          .toggleReady(localPlayer.id);
                    },
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
