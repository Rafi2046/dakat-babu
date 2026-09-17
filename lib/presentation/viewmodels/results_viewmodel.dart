import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/di/providers.dart';
import '../../core/errors/failures.dart';
import '../../data/models/player_model.dart';
import '../../data/models/room_model.dart';
import '../../data/models/round_model.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/repositories/room_repository.dart';
import '../../domain/usecases/assign_roles_usecase.dart';

/// State representation for round and match results screen.
class ResultsState {
  final RoundModel? round;
  final RoomModel? room;
  final List<PlayerModel> players;
  final bool isAdvancing;
  final String? errorMessage;
  final bool isCancelled;

  const ResultsState({
    this.round,
    this.room,
    this.players = const [],
    this.isAdvancing = false,
    this.errorMessage,
    this.isCancelled = false,
  });

  /// Leaderboard ordered by descending score.
  List<PlayerModel> get leaderboard {
    final list = List<PlayerModel>.from(players);
    list.sort((a, b) => b.score.compareTo(a.score));
    return list;
  }

  /// Whether a player dropped out mid-game.
  bool get isPlayerLeft =>
      (players.length < AppConstants.maxPlayers && players.isNotEmpty) ||
      (room?.status == RoomStatus.playerLeft);

  /// The player who was the Chor in this round.
  PlayerModel? get chorPlayer =>
      players.cast<PlayerModel?>().firstWhere(
            (p) => p?.id == round?.chorPlayerId,
            orElse: () => null,
          );

  /// The player who was the Police in this round.
  PlayerModel? get policePlayer =>
      players.cast<PlayerModel?>().firstWhere(
            (p) => p?.id == round?.policePlayerId,
            orElse: () => null,
          );

  /// The suspect chosen by the Police.
  PlayerModel? get accusedPlayer =>
      players.cast<PlayerModel?>().firstWhere(
            (p) => p?.id == round?.policeGuessPlayerId,
            orElse: () => null,
          );

  /// Whether current user is the room host.
  bool isHost(String? myId) =>
      players.any((p) => p.id == myId && p.isHost) || (room?.hostId == myId);

  /// Whether this match has concluded all configured rounds.
  bool get isMatchOver =>
      (round?.roundNumber ?? 1) >= AppConstants.defaultTotalRounds;

  ResultsState copyWith({
    RoundModel? round,
    RoomModel? room,
    List<PlayerModel>? players,
    bool? isAdvancing,
    String? errorMessage,
    bool clearError = false,
    bool? isCancelled,
  }) {
    return ResultsState(
      round: round ?? this.round,
      room: room ?? this.room,
      players: players ?? this.players,
      isAdvancing: isAdvancing ?? this.isAdvancing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isCancelled: isCancelled ?? this.isCancelled,
    );
  }
}

/// ViewModel coordinating round breakdown, leaderboard ranks, and match continuation.
class ResultsViewModel extends StateNotifier<ResultsState> {
  final String _roomCode;
  final GameRepository _gameRepository;
  final RoomRepository _roomRepository;
  final AssignRolesUseCase _assignRolesUseCase;

  StreamSubscription<RoundModel?>? _roundSub;
  StreamSubscription<RoomModel?>? _roomSub;
  StreamSubscription<List<PlayerModel>>? _playersSub;

  ResultsViewModel({
    required String roomCode,
    required GameRepository gameRepository,
    required RoomRepository roomRepository,
    required AssignRolesUseCase assignRolesUseCase,
  })  : _roomCode = roomCode,
        _gameRepository = gameRepository,
        _roomRepository = roomRepository,
        _assignRolesUseCase = assignRolesUseCase,
        super(const ResultsState()) {
    _initSubscriptions();
  }

  void _initSubscriptions() {
    _roundSub?.cancel();
    _roundSub = _gameRepository.watchCurrentRound(_roomCode).listen(
      (round) {
        if (mounted) state = state.copyWith(round: round);
      },
      onError: (err) {
        if (mounted) state = state.copyWith(errorMessage: err.toString());
      },
    );

    _roomSub?.cancel();
    _roomSub = _roomRepository.watchRoom(_roomCode).listen(
      (room) {
        if (!mounted) return;
        if (room == null || room.status == RoomStatus.cancelled) {
          state = state.copyWith(room: room, isCancelled: true);
        } else {
          state = state.copyWith(room: room);
        }
      },
      onError: (err) {
        if (mounted) state = state.copyWith(errorMessage: err.toString());
      },
    );

    _playersSub?.cancel();
    _playersSub = _roomRepository.watchPlayers(_roomCode).listen(
      (players) {
        if (mounted) state = state.copyWith(players: players);
      },
      onError: (err) {
        if (mounted) state = state.copyWith(errorMessage: err.toString());
      },
    );

    // Initial fetch to ensure players are available immediately
    _roomRepository.getPlayers(_roomCode).then((players) {
      if (mounted && state.players.isEmpty) {
        state = state.copyWith(players: players);
      }
    }).catchError((_) {});
  }

  /// Host triggers the next round of the match.
  Future<bool> startNextRound() async {
    final currentRoundNumber = state.round?.roundNumber ?? 1;
    final nextRoundNumber = currentRoundNumber + 1;

    state = state.copyWith(isAdvancing: true, clearError: true);
    try {
      var players = state.players;
      if (players.length != AppConstants.maxPlayers) {
        players = await _roomRepository.getPlayers(_roomCode);
      }

      await _assignRolesUseCase(
        roomCode: _roomCode,
        players: players,
        roundNumber: nextRoundNumber,
      );
      state = state.copyWith(isAdvancing: false, players: players);
      return true;
    } catch (e) {
      final message = e is Failure ? e.message : e.toString();
      if (mounted) state = state.copyWith(isAdvancing: false, errorMessage: message);
      return false;
    }
  }

  /// Host resets room back to lobby waiting room so a replacement can join.
  Future<bool> returnToLobby() async {
    try {
      await _roomRepository.returnToLobby(_roomCode);
      return true;
    } catch (e) {
      if (mounted) {
        final message = e is Failure ? e.message : e.toString();
        state = state.copyWith(errorMessage: message);
      }
      return false;
    }
  }

  /// Player leaves mid-game from results.
  Future<bool> leaveGame(String playerId) async {
    try {
      await _roomRepository.leaveRoom(playerId: playerId, roomCode: _roomCode);
      return true;
    } catch (e) {
      if (mounted) {
        final message = e is Failure ? e.message : e.toString();
        state = state.copyWith(errorMessage: message);
      }
      return false;
    }
  }

  /// Host cancels/disbands the game from results.
  Future<bool> cancelGame() async {
    try {
      await _roomRepository.cancelRoom(_roomCode);
      if (mounted) state = state.copyWith(isCancelled: true);
      return true;
    } catch (e) {
      if (mounted) {
        final message = e is Failure ? e.message : e.toString();
        state = state.copyWith(errorMessage: message);
      }
      return false;
    }
  }

  @override
  void dispose() {
    _roundSub?.cancel();
    _roomSub?.cancel();
    _playersSub?.cancel();
    super.dispose();
  }
}

/// Riverpod family provider for [ResultsViewModel] keyed by roomCode.
final resultsViewModelProvider =
    StateNotifierProvider.family.autoDispose<ResultsViewModel, ResultsState, String>(
  (ref, roomCode) {
    return ResultsViewModel(
      roomCode: roomCode,
      gameRepository: ref.watch(gameRepositoryProvider),
      roomRepository: ref.watch(roomRepositoryProvider),
      assignRolesUseCase: ref.watch(assignRolesUseCaseProvider),
    );
  },
);
