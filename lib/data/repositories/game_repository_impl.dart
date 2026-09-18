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

      final roomData = await _supabaseService.fetchSingle(
        AppConstants.roomsTable,
        matchField: 'room_code',
        matchValue: cleanCode,
      );
      final room = roomData != null ? RoomModel.fromJson(roomData) : null;
      final expectedPlayers = room?.maxPlayers ?? livePlayerList.length;

      if (livePlayerList.length != expectedPlayers) {
        throw GameRuleFailure(
          'Cannot start: Exactly $expectedPlayers players must be in the room (currently ${livePlayerList.length}).',
        );
      }

      final activePlayers = livePlayerList.map(PlayerModel.fromJson).toList();

      // 1. Shuffle players and assign roles (4, 5, or 6 players)
      final shuffledPlayers = List<PlayerModel>.from(activePlayers)..shuffle(Random.secure());
      final rajaPlayer = shuffledPlayers[0];
      final mantriPlayer = shuffledPlayers[1];
      final policePlayer = shuffledPlayers[2];
      final chorPlayer = shuffledPlayers[3];
      final chintaykariPlayer = shuffledPlayers.length >= 5 ? shuffledPlayers[4] : null;
      final batparPlayer = shuffledPlayers.length >= 6 ? shuffledPlayers[5] : null;

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
      if (chintaykariPlayer != null) {
        await _supabaseService.update(
          AppConstants.playersTable,
          matchField: 'id',
          matchValue: chintaykariPlayer.id,
          values: {'role': GameRole.chintaykari.name},
        );
      }
      if (batparPlayer != null) {
        await _supabaseService.update(
          AppConstants.playersTable,
          matchField: 'id',
          matchValue: batparPlayer.id,
          values: {'role': GameRole.batpar.name},
        );
      }

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
        chintaykariPlayerId: chintaykariPlayer?.id,
        batparPlayerId: batparPlayer?.id,
        status: RoundStatus.roleReveal,
        createdAt: DateTime.now(),
      );

      try {
        await _supabaseService.insert(
          AppConstants.roundsTable,
          round.toJson(includeExtendedRoles: true),
        );
      } catch (insertErr) {
        final errStr = insertErr.toString().toLowerCase();
        if (errStr.contains('column') ||
            errStr.contains('pgrst204') ||
            errStr.contains('42703')) {
          await _supabaseService.insert(
            AppConstants.roundsTable,
            round.toJson(includeExtendedRoles: false),
          );
        } else {
          rethrow;
        }
      }

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
      // 1. Fetch round record and room record (for custom points)
      final roundData = await _supabaseService.fetchSingle(
        AppConstants.roundsTable,
        matchField: 'id',
        matchValue: roundId,
      );

      if (roundData == null) {
        throw const GameRuleFailure('Round not found');
      }

      final roomData = await _supabaseService.fetchSingle(
        AppConstants.roomsTable,
        matchField: 'room_code',
        matchValue: roomCode,
      );
      final room = roomData != null ? RoomModel.fromJson(roomData) : null;

      final round = RoundModel.fromJson(roundData);
      final isCorrect = suspectPlayerId == round.chorPlayerId;

      // 2. Compute points using room's custom points or default
      final rajaPoints = room?.getPointsForRole(GameRole.raja) ?? AppConstants.rajaPoints;
      final mantriPoints = room?.getPointsForRole(GameRole.mantri) ?? AppConstants.mantriPoints;
      final policePoints = isCorrect
          ? (room?.getPointsForRole(GameRole.police) ?? AppConstants.policeCorrectPoints)
          : AppConstants.policeWrongPoints;
      final chorPoints = isCorrect
          ? AppConstants.chorCaughtPoints
          : (room?.getPointsForRole(GameRole.chor) ?? AppConstants.chorSuccessPoints);
      final chintaykariPoints =
          room?.getPointsForRole(GameRole.chintaykari) ?? AppConstants.chintaykariDefaultPoints;
      final batparPoints =
          room?.getPointsForRole(GameRole.batpar) ?? AppConstants.batparDefaultPoints;

      // 3. Update player scores
      await _addPlayerPoints(round.rajaPlayerId, rajaPoints);
      await _addPlayerPoints(round.mantriPlayerId, mantriPoints);
      await _addPlayerPoints(round.policePlayerId, policePoints);
      await _addPlayerPoints(round.chorPlayerId, chorPoints);
      if (round.chintaykariPlayerId != null) {
        await _addPlayerPoints(round.chintaykariPlayerId!, chintaykariPoints);
      }
      if (round.batparPlayerId != null) {
        await _addPlayerPoints(round.batparPlayerId!, batparPoints);
      }

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

  @override
  Stream<List<RoundModel>> watchAllRounds(String roomCode) {
    return _supabaseService
        .streamAllRounds(roomCode.trim().toUpperCase())
        .map((list) => list.map((json) => RoundModel.fromJson(json)).toList());
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
