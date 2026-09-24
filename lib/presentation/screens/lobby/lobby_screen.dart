import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/providers.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/room_model.dart';
import '../../viewmodels/lobby_viewmodel.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/cpdb/cpdb.dart';

/// Waiting room — RoomCode + QR + PlayerGrid + Host Start.
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

    ref.listen<LobbyState>(lobbyViewModelProvider(widget.roomCode),
        (prev, current) {
      if (current.isCancelled && !(prev?.isCancelled ?? false)) {
        AppFeedback.showRoomCancelledDialog(context);
        return;
      }
      if (current.room?.status == RoomStatus.inProgress) {
        context.go(AppRoutes.gameRoundPath(widget.roomCode));
      }
      if (current.errorMessage != null &&
          current.errorMessage != prev?.errorMessage) {
        AppToast.show(context, current.errorMessage!, error: true);
      }
    });

    final isHost = lobbyState.isHost(currentUserId);
    final localPlayer = lobbyState.currentPlayer(currentUserId);

    return AppShell(
      padding: EdgeInsets.zero,
      topBar: TopBar(
        title: 'Waiting Room',
        onBack: () => _handleLeave(context, isHost, currentUserId),
        showProfile: false,
        actions: [
          if (isHost)
            CpdbIconButton(
              icon: Icons.cancel_outlined,
              color: Colors.redAccent,
              onPressed: () => _handleCancelRoom(context),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RoomCodeCard(roomCode: widget.roomCode),
          const SizedBox(height: 16),
          Center(child: QRCard(roomCode: widget.roomCode, size: 140)),
          const SizedBox(height: 20),
          Text(
            'Players ${lobbyState.players.length} / ${lobbyState.requiredPlayers}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          PlayerGrid(
            crossAxisCount: 2,
            children: [
              for (final p in lobbyState.players)
                PlayerCard(
                  name: p.name,
                  isHost: p.isHost,
                  isYou: p.id == currentUserId,
                  state: p.isReady
                      ? PlayerCardState.ready
                      : PlayerCardState.waiting,
                  onTap: isHost && p.id != currentUserId
                      ? () => ref
                          .read(lobbyViewModelProvider(widget.roomCode).notifier)
                          .removePlayer(p.id)
                      : null,
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (isHost)
            GameButton(
              label: lobbyState.canStartGame
                  ? 'START GAME'
                  : 'WAITING (${lobbyState.players.length}/${lobbyState.requiredPlayers})',
              isLoading: lobbyState.isStarting,
              onPressed: lobbyState.canStartGame && !lobbyState.isStarting
                  ? () async {
                      final ok = await ref
                          .read(
                              lobbyViewModelProvider(widget.roomCode).notifier)
                          .startGame();
                      if (ok && context.mounted) {
                        context.go(AppRoutes.gameRoundPath(widget.roomCode));
                      }
                    }
                  : null,
            )
          else
            GameButton(
              label: localPlayer?.isReady == true
                  ? 'READY — WAITING FOR HOST'
                  : 'TAP TO READY',
              onPressed: localPlayer == null
                  ? null
                  : () => ref
                      .read(lobbyViewModelProvider(widget.roomCode).notifier)
                      .toggleReady(currentUserId!),
              variant: localPlayer?.isReady == true
                  ? ButtonVariant.outlined
                  : ButtonVariant.primary,
            ),
        ],
      ),
    );
  }

  Future<void> _handleLeave(
    BuildContext context,
    bool isHost,
    String? userId,
  ) async {
    final leave = await ConfirmationDialog.show(
      context,
      title: 'Leave Room?',
      message: 'You will leave this waiting room.',
      confirmLabel: 'LEAVE',
      isDestructive: true,
    );
    if (leave != true || !context.mounted) return;
    if (userId != null) {
      await ref
          .read(lobbyViewModelProvider(widget.roomCode).notifier)
          .leaveRoom(userId);
    }
    if (context.mounted) context.go(AppRoutes.home);
  }

  Future<void> _handleCancelRoom(BuildContext context) async {
    final ok = await ConfirmationDialog.show(
      context,
      title: 'Cancel Room?',
      message: 'All players will be kicked out.',
      confirmLabel: 'CANCEL ROOM',
      isDestructive: true,
    );
    if (ok != true) return;
    await ref
        .read(lobbyViewModelProvider(widget.roomCode).notifier)
        .cancelRoom();
    if (context.mounted) context.go(AppRoutes.home);
  }
}
