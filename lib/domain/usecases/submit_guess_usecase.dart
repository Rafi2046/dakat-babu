import '../../core/errors/failures.dart';
import '../../data/models/round_model.dart';
import '../repositories/game_repository.dart';

/// Business logic use case for the Police player to submit their suspect deduction.
class SubmitGuessUseCase {
  final GameRepository _gameRepository;

  const SubmitGuessUseCase(this._gameRepository);

  /// Submits the Police's accusation against [suspectPlayerId] and tallies round points.
  Future<RoundModel> call({
    required String roundId,
    required String roomCode,
    required String suspectPlayerId,
  }) async {
    if (suspectPlayerId.trim().isEmpty) {
      throw const ValidationFailure('Please select a player to accuse.');
    }

    return _gameRepository.submitPoliceGuess(
      roundId: roundId,
      roomCode: roomCode,
      suspectPlayerId: suspectPlayerId,
    );
  }
}
