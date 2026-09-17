import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      appBar: AppBar(
        title: Text('Room Lobby', style: AppTextStyles.heading2()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Room Code Header Card ---
              GameCard(
                backgroundColor: AppColors.surfaceElevatedDark,
                borderColor: AppColors.primary.withValues(alpha: 0.4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ROOM CODE',
                          style: AppTextStyles.caption(color: AppColors.textLightSecondary),
                        ),
                        AppSpacing.gapVXs,
                        Text(
                          widget.roomCode,
                          style: AppTextStyles.heading1(color: AppColors.secondary),
                        ),
                      ],
                    ),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: widget.roomCode));
                        context.showSuccessSnackBar('Room code copied to clipboard!');
                      },
                    ),
                  ],
                ),
              ),

              AppSpacing.gapVLg,

              // --- Player Count Header ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PLAYERS (${lobbyState.players.length}/${AppConstants.maxPlayers})',
                    style: AppTextStyles.heading3(),
                  ),
                  Text(
                    lobbyState.canStartGame ? 'READY TO PLAY' : 'WAITING FOR 4',
                    style: AppTextStyles.caption(
                      color: lobbyState.canStartGame ? AppColors.success : AppColors.warning,
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
                    // Empty slot placeholder
                    return Container(
                      padding: AppSpacing.cardPadding,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.borderDark.withValues(alpha: 0.5),
                          style: BorderStyle.solid,
                        ),
                        borderRadius: AppRadius.cardRadius,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.surfaceElevatedDark,
                            child: const Icon(Icons.person_outline, color: AppColors.textLightMuted),
                          ),
                          AppSpacing.gapHMd,
                          Text(
                            'Waiting for player ${index + 1}...',
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
                      ? 'START GAME (4/4 Ready)'
                      : 'START GAME (${lobbyState.players.length}/4 Players Joined)',
                  icon: Icons.play_arrow,
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
                  label: localPlayer.isReady ? 'MARK NOT READY' : 'I AM READY!',
                  icon: localPlayer.isReady ? Icons.close : Icons.check,
                  variant: localPlayer.isReady ? ButtonVariant.outlined : ButtonVariant.secondary,
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
    );
  }
}
