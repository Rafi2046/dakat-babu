import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../data/models/player_model.dart';
import '../../data/models/round_model.dart';
import '../repositories/game_repository.dart';

/// Business logic use case to assign roles and start a new game round.
class AssignRolesUseCase {
  final GameRepository _gameRepository;

  const AssignRolesUseCase(this._gameRepository);

  /// Validates that 4 players are present, assigns roles, and creates the round.
  Future<RoundModel> call({
    required String roomCode,
    required List<PlayerModel> players,
    required int roundNumber,
  }) async {
    if (players.length != AppConstants.maxPlayers) {
      throw GameRuleFailure(
        'Cannot start round: DakatBabu requires exactly ${AppConstants.maxPlayers} players. Currently ${players.length} present.',
      );
    }

    return _gameRepository.startRound(
      roomCode: roomCode,
      players: players,
      roundNumber: roundNumber,
    );
  }
}
