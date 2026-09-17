import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/di/providers.dart';
import '../../core/errors/failures.dart';
import '../../data/models/player_model.dart';
import '../../data/models/room_model.dart';
import '../../domain/repositories/room_repository.dart';
import '../../domain/usecases/assign_roles_usecase.dart';

/// State representation for the Lobby waiting room.
class LobbyState {
  final RoomModel? room;
  final List<PlayerModel> players;
  final bool isStarting;
  final String? errorMessage;

  const LobbyState({
    this.room,
    this.players = const [],
    this.isStarting = false,
    this.errorMessage,
  });

  /// Whether current local user is the room host.
  bool isHost(String? currentUserId) {
    if (currentUserId == null) return false;
    return room?.hostId == currentUserId ||
        players.any((p) => p.id == currentUserId && p.isHost);
  }

  /// Whether exactly 4 players have joined.
  bool get canStartGame => players.length == AppConstants.maxPlayers;

  /// Find the local player object.
  PlayerModel? currentPlayer(String? currentUserId) =>
      players.cast<PlayerModel?>().firstWhere(
            (p) => p?.id == currentUserId,
            orElse: () => null,
          );

  LobbyState copyWith({
    RoomModel? room,
    List<PlayerModel>? players,
    bool? isStarting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LobbyState(
      room: room ?? this.room,
      players: players ?? this.players,
      isStarting: isStarting ?? this.isStarting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// ViewModel controlling realtime player updates and match launching in Lobby.
class LobbyViewModel extends StateNotifier<LobbyState> {
  final String _roomCode;
  final RoomRepository _roomRepository;
  final AssignRolesUseCase _assignRolesUseCase;

  StreamSubscription<RoomModel?>? _roomSubscription;
  StreamSubscription<List<PlayerModel>>? _playersSubscription;

  LobbyViewModel({
    required String roomCode,
    required RoomRepository roomRepository,
    required AssignRolesUseCase assignRolesUseCase,
  })  : _roomCode = roomCode,
        _roomRepository = roomRepository,
        _assignRolesUseCase = assignRolesUseCase,
        super(const LobbyState()) {
    _subscribeToLobby();
  }

  void _subscribeToLobby() {
    _roomSubscription?.cancel();
    _roomSubscription = _roomRepository.watchRoom(_roomCode).listen(
      (room) {
        if (mounted) state = state.copyWith(room: room);
      },
      onError: (err) {
        if (mounted) state = state.copyWith(errorMessage: err.toString());
      },
    );

    _playersSubscription?.cancel();
    _playersSubscription = _roomRepository.watchPlayers(_roomCode).listen(
      (players) {
        if (mounted) state = state.copyWith(players: players);
      },
      onError: (err) {
        if (mounted) state = state.copyWith(errorMessage: err.toString());
      },
    );
  }

  /// Toggles the local player's ready indicator.
  Future<void> toggleReady(String playerId) async {
    final player = state.players.cast<PlayerModel?>().firstWhere(
          (p) => p?.id == playerId,
          orElse: () => null,
        );
    if (player == null) return;

    try {
      await _roomRepository.setPlayerReady(
        playerId: playerId,
        isReady: !player.isReady,
      );
    } catch (e) {
      if (mounted) {
        final message = e is Failure ? e.message : e.toString();
        state = state.copyWith(errorMessage: message);
      }
    }
  }

  /// Host triggers role assignment and starts round 1.
  Future<bool> startGame() async {
    if (!state.canStartGame) {
      state = state.copyWith(
        errorMessage: 'Need exactly ${AppConstants.maxPlayers} players to start (currently ${state.players.length}).',
      );
      return false;
    }

    state = state.copyWith(isStarting: true, clearError: true);
    try {
      await _assignRolesUseCase(
        roomCode: _roomCode,
        players: state.players,
        roundNumber: 1,
      );
      state = state.copyWith(isStarting: false);
      return true;
    } catch (e) {
      final message = e is Failure ? e.message : e.toString();
      if (mounted) state = state.copyWith(isStarting: false, errorMessage: message);
      return false;
    }
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _playersSubscription?.cancel();
    super.dispose();
  }
}

/// Riverpod family provider for [LobbyViewModel] keyed by roomCode.
final lobbyViewModelProvider =
    StateNotifierProvider.family.autoDispose<LobbyViewModel, LobbyState, String>(
  (ref, roomCode) {
    return LobbyViewModel(
      roomCode: roomCode,
      roomRepository: ref.watch(roomRepositoryProvider),
      assignRolesUseCase: ref.watch(assignRolesUseCaseProvider),
    );
  },
);
