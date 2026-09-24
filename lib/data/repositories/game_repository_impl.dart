import 'dart:math';

import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/game/game_engine.dart';
import '../../domain/game/player_view.dart';
import '../../domain/repositories/game_repository.dart';
import '../models/player_model.dart';
import '../models/room_model.dart';
import '../models/round_model.dart';
import '../services/supabase_service.dart';

/// Production [GameRepository] using [GameEngine] for CPDB 1A/2A rules.
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
      final livePlayerList = await _supabaseService.fetchList(
        AppConstants.playersTable,
        matchField: 'room_code',
        matchValue: cleanCode,
      );

      if (livePlayerList.length != GameEngine.requiredPlayers) {
        throw GameRuleFailure(
          'Cannot start: Exactly ${GameEngine.requiredPlayers} players required '
          '(currently ${livePlayerList.length}).',
        );
      }

      final activePlayers = livePlayerList.map(PlayerModel.fromJson).toList();
      final enginePlayers = activePlayers
          .map((p) => EnginePlayer(id: p.id, name: p.name, score: p.score))
          .toList();

      final assignment = GameEngine.assignRoles(
        enginePlayers,
        random: Random.secure(),
      );

      for (final p in activePlayers) {
        final role = assignment.roleOf(p.id)!;
        // Prefer private roles table; fall back to players.role for mock/dev.
        try {
          await _supabaseService.insert(
            AppConstants.privateRolesTable,
            {
              'player_id': p.id,
              'room_code': cleanCode,
              'round_number': roundNumber,
              'role': role.name,
            },
          );
          await _supabaseService.update(
            AppConstants.playersTable,
            matchField: 'id',
            matchValue: p.id,
            values: {'role': null},
          );
        } catch (_) {
          await _supabaseService.update(
            AppConstants.playersTable,
            matchField: 'id',
            matchValue: p.id,
            values: {'role': role.name},
          );
        }
      }

      final round = RoundModel(
        id: 'rnd_${DateTime.now().millisecondsSinceEpoch}',
        roomCode: cleanCode,
        roundNumber: roundNumber,
        policePlayerId: assignment.policePlayerId,
        babuPlayerId: assignment.babuPlayerId,
        chorPlayerId: assignment.chorPlayerId,
        dakatPlayerId: assignment.dakatPlayerId,
        status: RoundStatus.roleReveal,
        createdAt: DateTime.now(),
      );

      await _supabaseService.insert(AppConstants.roundsTable, round.toJson());

      await _supabaseService.update(
        AppConstants.roomsTable,
        matchField: 'room_code',
        matchValue: cleanCode,
        values: {
          'status': RoomStatus.inProgress.toDbValue(),
          'current_round': roundNumber,
          'max_players': GameEngine.requiredPlayers,
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
      final roundData = await _supabaseService.fetchSingle(
        AppConstants.roundsTable,
        matchField: 'id',
        matchValue: roundId,
      );
      if (roundData == null) {
        throw const GameRuleFailure('Round not found');
      }

      final round = RoundModel.fromJson(roundData);
      if (round.status == RoundStatus.completed) {
        throw const GameRuleFailure('Guess already submitted for this round');
      }

      final livePlayers = await _supabaseService.fetchList(
        AppConstants.playersTable,
        matchField: 'room_code',
        matchValue: roomCode.trim().toUpperCase(),
      );
      final players = livePlayers.map(PlayerModel.fromJson).toList();
      final enginePlayers = players
          .map((p) => EnginePlayer(id: p.id, name: p.name, score: p.score))
          .toList();

      final assignment = RoleAssignment(
        policePlayerId: round.policePlayerId,
        babuPlayerId: round.babuPlayerId,
        chorPlayerId: round.chorPlayerId,
        dakatPlayerId: round.dakatPlayerId,
      );

      final result = GameEngine.resolveGuess(
        players: enginePlayers,
        assignment: assignment,
        suspectPlayerId: suspectPlayerId,
      );

      for (final p in players) {
        final newScore = result.scoresAfter[p.id] ?? p.score;
        if (newScore != p.score) {
          await _supabaseService.update(
            AppConstants.playersTable,
            matchField: 'id',
            matchValue: p.id,
            values: {'score': newScore},
          );
        }
      }

      final updated = round.copyWith(
        policeGuessPlayerId: suspectPlayerId,
        isGuessCorrect: result.isCorrect,
        status: RoundStatus.completed,
      );

      await _supabaseService.update(
        AppConstants.roundsTable,
        matchField: 'id',
        matchValue: roundId,
        values: {
          'police_guess_player_id': suspectPlayerId,
          'is_guess_correct': result.isCorrect,
          'status': RoundStatus.completed.toDbValue(),
        },
      );

      await _supabaseService.update(
        AppConstants.roomsTable,
        matchField: 'room_code',
        matchValue: roomCode.trim().toUpperCase(),
        values: {'status': RoomStatus.roundEnded.toDbValue()},
      );

      return updated;
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Failed to submit guess: $e');
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
        matchValue: roomCode.trim().toUpperCase(),
        values: {
          'status': RoomStatus.inProgress.toDbValue(),
          'current_round': nextRoundNumber,
        },
      );
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Failed to advance round: $e');
    }
  }

  @override
  Stream<RoundModel?> watchCurrentRound(String roomCode) {
    return _supabaseService
        .streamCurrentRound(roomCode.trim().toUpperCase())
        .map((data) => data == null ? null : RoundModel.fromJson(data));
  }

  @override
  Stream<List<RoundModel>> watchAllRounds(String roomCode) {
    return _supabaseService
        .streamAllRounds(roomCode.trim().toUpperCase())
        .map((rows) => rows.map(RoundModel.fromJson).toList());
  }
}
