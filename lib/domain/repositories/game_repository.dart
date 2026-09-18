import '../../data/models/player_model.dart';
import '../../data/models/round_model.dart';

/// Abstract contract for game round lifecycle, role shuffling, and guess evaluation.
abstract interface class GameRepository {
  /// Shuffles roles among 4 players and launches a new round.
  Future<RoundModel> startRound({
    required String roomCode,
    required List<PlayerModel> players,
    required int roundNumber,
  });

  /// Transitions the round status from [RoundStatus.roleReveal] to [RoundStatus.policeGuessing].
  Future<void> startPoliceGuessingPhase({
    required String roundId,
    required String roomCode,
  });

  /// Evaluates the Police player's guess against the actual Chor and distributes points.
  Future<RoundModel> submitPoliceGuess({
    required String roundId,
    required String roomCode,
    required String suspectPlayerId,
  });

  /// Advances room and players to the subsequent round.
  Future<void> advanceToNextRound({
    required String roomCode,
    required int nextRoundNumber,
  });

  /// Streams realtime round changes for a given [roomCode].
  Stream<RoundModel?> watchCurrentRound(String roomCode);

  /// Streams all rounds history for a given [roomCode].
  Stream<List<RoundModel>> watchAllRounds(String roomCode);
}
