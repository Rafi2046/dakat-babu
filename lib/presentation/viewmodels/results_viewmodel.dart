import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/di/providers.dart';
import '../../core/errors/failures.dart';
import '../../data/models/player_model.dart';
import '../../data/models/round_model.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/repositories/room_repository.dart';
import '../../domain/usecases/assign_roles_usecase.dart';

/// State representation for round and match results screen.
class ResultsState {
  final RoundModel? round;
  final List<PlayerModel> players;
  final bool isAdvancing;
  final String? errorMessage;

  const ResultsState({
    this.round,
    this.players = const [],
    this.isAdvancing = false,
    this.errorMessage,
  });

  /// Leaderboard ordered by descending score.
  List<PlayerModel> get leaderboard {
    final list = List<PlayerModel>.from(players);
    list.sort((a, b) => b.score.compareTo(a.score));
    return list;
  }

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
      players.any((p) => p.id == myId && p.isHost);

  /// Whether this match has concluded all configured rounds.
  bool get isMatchOver =>
      (round?.roundNumber ?? 1) >= AppConstants.defaultTotalRounds;

  ResultsState copyWith({
    RoundModel? round,
    List<PlayerModel>? players,
    bool? isAdvancing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ResultsState(
      round: round ?? this.round,
      players: players ?? this.players,
      isAdvancing: isAdvancing ?? this.isAdvancing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
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

  @override
  void dispose() {
    _roundSub?.cancel();
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
