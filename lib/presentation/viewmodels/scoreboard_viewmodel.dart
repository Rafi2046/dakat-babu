import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/di/providers.dart';
import '../../core/utils/extensions.dart';
import '../../data/models/player_model.dart';
import '../../data/models/room_model.dart';
import '../../data/models/round_model.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/repositories/room_repository.dart';

/// Single round participation entry for a player on the scoreboard.
class ScoreboardRoundEntry {
  final int roundNumber;
  final GameRole role;
  final String roleLabel;
  final int pointsEarned;
  final bool? isGuessCorrect;

  const ScoreboardRoundEntry({
    required this.roundNumber,
    required this.role,
    required this.roleLabel,
    required this.pointsEarned,
    this.isGuessCorrect,
  });
}

/// State for the dedicated live Scoreboard screen.
class ScoreboardState {
  final RoomModel? room;
  final List<PlayerModel> players;
  final List<RoundModel> rounds;
  final bool isLoading;
  final String? errorMessage;

  const ScoreboardState({
    this.room,
    this.players = const [],
    this.rounds = const [],
    this.isLoading = true,
    this.errorMessage,
  });

  /// Ranked players sorted by cumulative score descending.
  List<PlayerModel> get rankedPlayers {
    final list = List<PlayerModel>.from(players);
    list.sort((a, b) => b.score.compareTo(a.score));
    return list;
  }

  /// Current match leader (highest cumulative score).
  PlayerModel? get leader => rankedPlayers.isNotEmpty ? rankedPlayers.first : null;

  /// Returns the per-round history breakdown for a given player ID.
  List<ScoreboardRoundEntry> getPlayerHistory(String playerId) {
    final entries = <ScoreboardRoundEntry>[];
    for (final round in rounds) {
      GameRole? role;
      if (round.rajaPlayerId == playerId) {
        role = GameRole.raja;
      } else if (round.mantriPlayerId == playerId) {
        role = GameRole.mantri;
      } else if (round.policePlayerId == playerId) {
        role = GameRole.police;
      } else if (round.chorPlayerId == playerId) {
        role = GameRole.chor;
      } else if (round.chintaykariPlayerId == playerId) {
        role = GameRole.chintaykari;
      } else if (round.batparPlayerId == playerId) {
        role = GameRole.batpar;
      }

      if (role == null) continue;

      final roleLabel = room?.getLabelForRole(role) ?? role.shortName;
      final isCorrect = round.isGuessCorrect ?? false;

      int points = 0;
      switch (role) {
        case GameRole.raja:
          points = room?.getPointsForRole(GameRole.raja) ?? AppConstants.rajaPoints;
          break;
        case GameRole.mantri:
          points = room?.getPointsForRole(GameRole.mantri) ?? AppConstants.mantriPoints;
          break;
        case GameRole.police:
          points = isCorrect
              ? (room?.getPointsForRole(GameRole.police) ?? AppConstants.policeCorrectPoints)
              : AppConstants.policeWrongPoints;
          break;
        case GameRole.chor:
          points = isCorrect
              ? AppConstants.chorCaughtPoints
              : (room?.getPointsForRole(GameRole.chor) ?? AppConstants.chorSuccessPoints);
          break;
        case GameRole.chintaykari:
          points = room?.getPointsForRole(GameRole.chintaykari) ??
              AppConstants.chintaykariDefaultPoints;
          break;
        case GameRole.batpar:
          points = room?.getPointsForRole(GameRole.batpar) ??
              AppConstants.batparDefaultPoints;
          break;
      }

      entries.add(
        ScoreboardRoundEntry(
          roundNumber: round.roundNumber,
          role: role,
          roleLabel: roleLabel,
          pointsEarned: points,
          isGuessCorrect: round.isGuessCorrect,
        ),
      );
    }
    return entries;
  }

  ScoreboardState copyWith({
    RoomModel? room,
    List<PlayerModel>? players,
    List<RoundModel>? rounds,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ScoreboardState(
      room: room ?? this.room,
      players: players ?? this.players,
      rounds: rounds ?? this.rounds,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// ViewModel managing realtime scoreboard streams and round histories.
class ScoreboardViewModel extends StateNotifier<ScoreboardState> {
  final RoomRepository _roomRepository;
  final GameRepository _gameRepository;
  final String _roomCode;

  StreamSubscription<RoomModel?>? _roomSub;
  StreamSubscription<List<PlayerModel>>? _playersSub;
  StreamSubscription<List<RoundModel>>? _roundsSub;

  ScoreboardViewModel({
    required RoomRepository roomRepository,
    required GameRepository gameRepository,
    required String roomCode,
  })  : _roomRepository = roomRepository,
        _gameRepository = gameRepository,
        _roomCode = roomCode,
        super(const ScoreboardState()) {
    _initStreams();
  }

  void _initStreams() {
    _roomSub = _roomRepository.watchRoom(_roomCode).listen(
      (room) {
        state = state.copyWith(room: room, isLoading: false);
      },
      onError: (err) {
        state = state.copyWith(errorMessage: err.toString(), isLoading: false);
      },
    );

    _playersSub = _roomRepository.watchPlayers(_roomCode).listen(
      (players) {
        state = state.copyWith(players: players, isLoading: false);
      },
      onError: (err) {
        state = state.copyWith(errorMessage: err.toString(), isLoading: false);
      },
    );

    _roundsSub = _gameRepository.watchAllRounds(_roomCode).listen(
      (rounds) {
        final sortedRounds = List<RoundModel>.from(rounds)
          ..sort((a, b) => a.roundNumber.compareTo(b.roundNumber));
        state = state.copyWith(rounds: sortedRounds, isLoading: false);
      },
      onError: (err) {
        state = state.copyWith(errorMessage: err.toString(), isLoading: false);
      },
    );
  }

  @override
  void dispose() {
    _roomSub?.cancel();
    _playersSub?.cancel();
    _roundsSub?.cancel();
    super.dispose();
  }
}

/// Riverpod family provider for [ScoreboardViewModel].
final scoreboardViewModelProvider = StateNotifierProvider.autoDispose
    .family<ScoreboardViewModel, ScoreboardState, String>((ref, roomCode) {
  final roomRepo = ref.watch(roomRepositoryProvider);
  final gameRepo = ref.watch(gameRepositoryProvider);
  return ScoreboardViewModel(
    roomRepository: roomRepo,
    gameRepository: gameRepo,
    roomCode: roomCode,
  );
});
