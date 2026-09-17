import 'dart:math';

import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/repositories/game_repository.dart';
import '../models/player_model.dart';
import '../models/room_model.dart';
import '../models/round_model.dart';
import '../services/supabase_service.dart';

/// Production implementation of [GameRepository] handling role shuffling,
/// guessing mechanics, and score accumulation.
class GameRepositoryImpl implements GameRepository {
  final SupabaseService _supabaseService;

  GameRepositoryImpl({required SupabaseService supabaseService})
      : _supabaseService = supabaseService;

  @override
  Future<RoundModel> startRound({
    required String roomCode,
    required List<PlayerModel> players,
    required int roundNumber,
  }) async {
    final cleanCode = roomCode.trim().toUpperCase();

    try {
      // 0. Verify live player count from database to prevent race conditions
      final livePlayerList = await _supabaseService.fetchList(
        AppConstants.playersTable,
        matchField: 'room_code',
        matchValue: cleanCode,
      );

      if (livePlayerList.length != AppConstants.maxPlayers) {
        throw GameRuleFailure(
          'Cannot start: Exactly ${AppConstants.maxPlayers} players must be in the room (currently ${livePlayerList.length}).',
        );
      }

      final activePlayers = livePlayerList.map(PlayerModel.fromJson).toList();

      // 1. Shuffle players and assign the 4 classic roles
      final shuffledPlayers = List<PlayerModel>.from(activePlayers)..shuffle(Random.secure());
      final rajaPlayer = shuffledPlayers[0];
      final mantriPlayer = shuffledPlayers[1];
      final policePlayer = shuffledPlayers[2];
      final chorPlayer = shuffledPlayers[3];

      // 2. Persist assigned roles to players table
      await _supabaseService.update(
        AppConstants.playersTable,
        matchField: 'id',
        matchValue: rajaPlayer.id,
        values: {'role': GameRole.raja.name},
      );
      await _supabaseService.update(
        AppConstants.playersTable,
        matchField: 'id',
        matchValue: mantriPlayer.id,
        values: {'role': GameRole.mantri.name},
      );
      await _supabaseService.update(
        AppConstants.playersTable,
        matchField: 'id',
        matchValue: policePlayer.id,
        values: {'role': GameRole.police.name},
      );
      await _supabaseService.update(
        AppConstants.playersTable,
        matchField: 'id',
        matchValue: chorPlayer.id,
        values: {'role': GameRole.chor.name},
      );

      // 3. Create new Round record
      final roundId = 'rnd_${DateTime.now().millisecondsSinceEpoch}';
      final round = RoundModel(
        id: roundId,
        roomCode: roomCode,
        roundNumber: roundNumber,
        rajaPlayerId: rajaPlayer.id,
        mantriPlayerId: mantriPlayer.id,
        policePlayerId: policePlayer.id,
        chorPlayerId: chorPlayer.id,
        status: RoundStatus.roleReveal,
        createdAt: DateTime.now(),
      );

      await _supabaseService.insert(AppConstants.roundsTable, round.toJson());

      // 4. Update room status to in_progress
      await _supabaseService.update(
        AppConstants.roomsTable,
        matchField: 'room_code',
        matchValue: roomCode,
        values: {
          'status': RoomStatus.inProgress.toDbValue(),
          'current_round': roundNumber,
        },
      );

      return round;
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Failed to start round: $e');
    }
  }

  @override
  Future<void> startPoliceGuessingPhase({
    required String roundId,
    required String roomCode,
  }) async {
    try {
      await _supabaseService.update(
        AppConstants.roundsTable,
        matchField: 'id',
        matchValue: roundId,
        values: {'status': RoundStatus.policeGuessing.toDbValue()},
      );
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Failed to enter police guessing phase: $e');
    }
  }

  @override
  Future<RoundModel> submitPoliceGuess({
    required String roundId,
    required String roomCode,
    required String suspectPlayerId,
  }) async {
    try {
      // 1. Fetch round record
      final roundData = await _supabaseService.fetchSingle(
        AppConstants.roundsTable,
        matchField: 'id',
        matchValue: roundId,
      );

      if (roundData == null) {
        throw const GameRuleFailure('Round not found');
      }

      final round = RoundModel.fromJson(roundData);
      final isCorrect = suspectPlayerId == round.chorPlayerId;

      // 2. Compute points
      final rajaPoints = AppConstants.rajaPoints;
      final mantriPoints = AppConstants.mantriPoints;
      final policePoints =
          isCorrect ? AppConstants.policeCorrectPoints : AppConstants.policeWrongPoints;
      final chorPoints =
          isCorrect ? AppConstants.chorCaughtPoints : AppConstants.chorSuccessPoints;

      // 3. Update player scores
      await _addPlayerPoints(round.rajaPlayerId, rajaPoints);
      await _addPlayerPoints(round.mantriPlayerId, mantriPoints);
      await _addPlayerPoints(round.policePlayerId, policePoints);
      await _addPlayerPoints(round.chorPlayerId, chorPoints);

      // 4. Update round record
      await _supabaseService.update(
        AppConstants.roundsTable,
        matchField: 'id',
        matchValue: roundId,
        values: {
          'police_guess_player_id': suspectPlayerId,
          'is_guess_correct': isCorrect,
          'status': RoundStatus.completed.toDbValue(),
        },
      );

      // 5. Update room status to roundEnded
      await _supabaseService.update(
        AppConstants.roomsTable,
        matchField: 'room_code',
        matchValue: roomCode,
        values: {'status': RoomStatus.roundEnded.toDbValue()},
      );

      return round.copyWith(
        policeGuessPlayerId: suspectPlayerId,
        isGuessCorrect: isCorrect,
        status: RoundStatus.completed,
      );
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Failed to submit police guess: $e');
    }
  }

  @override
  Future<void> advanceToNextRound({
    required String roomCode,
    required int nextRoundNumber,
  }) async {
    try {
      await _supabaseService.update(
        AppConstants.roomsTable,
        matchField: 'room_code',
        matchValue: roomCode,
        values: {
          'status': RoomStatus.inProgress.toDbValue(),
          'current_round': nextRoundNumber,
        },
      );
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Failed to advance to next round: $e');
    }
  }

  @override
  Stream<RoundModel?> watchCurrentRound(String roomCode) {
    return _supabaseService
        .streamCurrentRound(roomCode.trim().toUpperCase())
        .map((data) => data != null ? RoundModel.fromJson(data) : null);
  }

  /// Helper to increment a player's cumulative score.
  Future<void> _addPlayerPoints(String playerId, int pointsToAdd) async {
    final playerData = await _supabaseService.fetchSingle(
      AppConstants.playersTable,
      matchField: 'id',
      matchValue: playerId,
    );
    if (playerData != null) {
      final currentScore = (playerData['score'] as num?)?.toInt() ?? 0;
      await _supabaseService.update(
        AppConstants.playersTable,
        matchField: 'id',
        matchValue: playerId,
        values: {'score': currentScore + pointsToAdd},
      );
    }
  }
}
