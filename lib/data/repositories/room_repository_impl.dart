import 'dart:math';

import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/repositories/room_repository.dart';
import '../models/player_model.dart';
import '../models/room_model.dart';
import '../services/supabase_service.dart';

/// Production implementation of [RoomRepository] using [SupabaseService].
class RoomRepositoryImpl implements RoomRepository {
  final SupabaseService _supabaseService;

  RoomRepositoryImpl({required SupabaseService supabaseService})
      : _supabaseService = supabaseService;

  @override
  Future<RoomModel> createRoom({required String hostName}) async {
    final hostAuthId = await _supabaseService.getOrSignInAnonymousUserId();
    final now = DateTime.now();

    for (var attempt = 1; attempt <= AppConstants.maxRoomCodeRetries; attempt++) {
      final roomCode = _generateRoomCode();

      // 1. Check if room code already exists in DB to prevent collisions
      final existingRoom = await _supabaseService.fetchSingle(
        AppConstants.roomsTable,
        matchField: 'room_code',
        matchValue: roomCode,
      );

      if (existingRoom != null) {
        // Collision detected, retry with new code
        continue;
      }

      final hostPlayerId = '${hostAuthId}_${roomCode}_${DateTime.now().millisecondsSinceEpoch}';
      final roomId = 'room_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomSuffix()}';
      final hostPlayer = PlayerModel(
        id: hostPlayerId,
        roomCode: roomCode,
        name: hostName.trim(),
        isHost: true,
        isReady: true,
        createdAt: now,
      );

      final room = RoomModel(
        id: roomId,
        roomCode: roomCode,
        hostId: hostPlayerId,
        status: RoomStatus.waiting,
        currentRound: 0,
        maxRounds: AppConstants.defaultTotalRounds,
        createdAt: now,
      );

      try {
        // 2. Insert room record
        await _supabaseService.insert(AppConstants.roomsTable, room.toJson());

        // 3. Insert host player record
        await _supabaseService.insert(AppConstants.playersTable, hostPlayer.toJson());

        return room;
      } catch (e) {
        // If unique constraint error on room_code, retry
        final errStr = e.toString().toLowerCase();
        if (attempt < AppConstants.maxRoomCodeRetries &&
            (errStr.contains('duplicate') || errStr.contains('unique') || errStr.contains('23505'))) {
          continue;
        }
        if (e is Failure) rethrow;
        throw ServerFailure('Failed to create room: $e');
      }
    }

    throw const ServerFailure('Unable to generate a unique room code after multiple attempts. Please try again.');
  }

  @override
  Future<PlayerModel> joinRoom({
    required String roomCode,
    required String playerName,
  }) async {
    final cleanCode = roomCode.trim().toUpperCase();

    try {
      // 1. Verify room exists
      final roomData = await _supabaseService.fetchSingle(
        AppConstants.roomsTable,
        matchField: 'room_code',
        matchValue: cleanCode,
      );

      if (roomData == null) {
        throw RoomNotFoundFailure('Room "$cleanCode" not found. Please check the code.');
      }

      final room = RoomModel.fromJson(roomData);
      if (room.status == RoomStatus.cancelled) {
        throw const GameRuleFailure('This room has been cancelled by the host.');
      }
      if (room.status != RoomStatus.waiting) {
        throw const GameRuleFailure('Game in this room has already started.');
      }

      // 2. Verify capacity (< 4 players)
      final existingPlayers = await _supabaseService.fetchList(
        AppConstants.playersTable,
        matchField: 'room_code',
        matchValue: cleanCode,
      );

      if (existingPlayers.length >= AppConstants.maxPlayers) {
        throw const RoomFullFailure('This room is full (maximum 4 players).');
      }

      // 3. Get joining player's anonymous ID
      final authUserId = await _supabaseService.getOrSignInAnonymousUserId();
      final playerId = '${authUserId}_${cleanCode}_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomSuffix()}';

      final player = PlayerModel(
        id: playerId,
        roomCode: cleanCode,
        name: playerName.trim(),
        isHost: false,
        isReady: false,
        createdAt: DateTime.now(),
      );

      await _supabaseService.insert(AppConstants.playersTable, player.toJson());
      return player;
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Failed to join room: $e');
    }
  }

  @override
  Future<void> setPlayerReady({
    required String playerId,
    required bool isReady,
  }) async {
    try {
      await _supabaseService.update(
        AppConstants.playersTable,
        matchField: 'id',
        matchValue: playerId,
        values: {'is_ready': isReady},
      );
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Failed to update player readiness: $e');
    }
  }

  @override
  Future<void> leaveRoom({
    required String playerId,
    required String roomCode,
  }) async {
    final cleanCode = roomCode.trim().toUpperCase();
    try {
      final room = await getRoom(cleanCode);
      final players = await getPlayers(cleanCode);

      final isHost = (room?.hostId == playerId) ||
          players.any((p) => p.id == playerId && p.isHost);

      if (isHost) {
        final remainingPlayers = players.where((p) => p.id != playerId).toList();
        if (remainingPlayers.isEmpty) {
          // No one left, delete room
          await _supabaseService.delete(
            AppConstants.roomsTable,
            matchField: 'room_code',
            matchValue: cleanCode,
          );
        } else {
          // Reassign host to the next joined player
          final newHost = remainingPlayers.first;
          await _supabaseService.update(
            AppConstants.roomsTable,
            matchField: 'room_code',
            matchValue: cleanCode,
            values: {'host_id': newHost.id},
          );
          await _supabaseService.update(
            AppConstants.playersTable,
            matchField: 'id',
            matchValue: newHost.id,
            values: {'is_host': true},
          );
          await _supabaseService.delete(
            AppConstants.playersTable,
            matchField: 'id',
            matchValue: playerId,
          );

          if (room != null &&
              (room.status == RoomStatus.inProgress || room.status == RoomStatus.roundEnded)) {
            await updateRoomStatus(roomCode: cleanCode, status: RoomStatus.playerLeft);
          }
        }
      } else {
        // Non-host player leaving
        await _supabaseService.delete(
          AppConstants.playersTable,
          matchField: 'id',
          matchValue: playerId,
        );

        if (room != null &&
            (room.status == RoomStatus.inProgress || room.status == RoomStatus.roundEnded)) {
          await updateRoomStatus(roomCode: cleanCode, status: RoomStatus.playerLeft);
        }
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Failed to leave room: $e');
    }
  }

  @override
  Future<void> cancelRoom(String roomCode) async {
    final cleanCode = roomCode.trim().toUpperCase();
    try {
      // First update status to cancelled so realtime listeners immediately get notified
      await _supabaseService.update(
        AppConstants.roomsTable,
        matchField: 'room_code',
        matchValue: cleanCode,
        values: {'status': RoomStatus.cancelled.toDbValue()},
      );

      // Clean up room and cascading records
      await _supabaseService.delete(
        AppConstants.roomsTable,
        matchField: 'room_code',
        matchValue: cleanCode,
      );
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Failed to cancel room: $e');
    }
  }

  @override
  Future<void> removePlayer({
    required String roomCode,
    required String playerId,
  }) async {
    final cleanCode = roomCode.trim().toUpperCase();
    try {
      await _supabaseService.delete(
        AppConstants.playersTable,
        matchField: 'id',
        matchValue: playerId,
      );

      final room = await getRoom(cleanCode);
      if (room != null &&
          (room.status == RoomStatus.inProgress || room.status == RoomStatus.roundEnded)) {
        await updateRoomStatus(roomCode: cleanCode, status: RoomStatus.playerLeft);
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Failed to remove player: $e');
    }
  }

  @override
  Future<void> updateRoomStatus({
    required String roomCode,
    required RoomStatus status,
  }) async {
    final cleanCode = roomCode.trim().toUpperCase();
    try {
      await _supabaseService.update(
        AppConstants.roomsTable,
        matchField: 'room_code',
        matchValue: cleanCode,
        values: {'status': status.toDbValue()},
      );
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Failed to update room status: $e');
    }
  }

  @override
  Future<void> returnToLobby(String roomCode) async {
    final cleanCode = roomCode.trim().toUpperCase();
    try {
      // 1. Set room status back to waiting
      await _supabaseService.update(
        AppConstants.roomsTable,
        matchField: 'room_code',
        matchValue: cleanCode,
        values: {
          'status': RoomStatus.waiting.toDbValue(),
          'current_round': 0,
        },
      );

      // 2. Clear assigned roles and reset readiness (host stays ready)
      final players = await getPlayers(cleanCode);
      for (final p in players) {
        await _supabaseService.update(
          AppConstants.playersTable,
          matchField: 'id',
          matchValue: p.id,
          values: {
            'role': null,
            'is_ready': p.isHost,
          },
        );
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Failed to return room to lobby: $e');
    }
  }

  @override
  Future<RoomModel?> getRoom(String roomCode) async {
    try {
      final data = await _supabaseService.fetchSingle(
        AppConstants.roomsTable,
        matchField: 'room_code',
        matchValue: roomCode.trim().toUpperCase(),
      );
      if (data == null) return null;
      return RoomModel.fromJson(data);
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Failed to fetch room: $e');
    }
  }

  @override
  Future<List<PlayerModel>> getPlayers(String roomCode) async {
    try {
      final data = await _supabaseService.fetchList(
        AppConstants.playersTable,
        matchField: 'room_code',
        matchValue: roomCode.trim().toUpperCase(),
      );
      return data.map(PlayerModel.fromJson).toList();
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Failed to fetch players: $e');
    }
  }

  @override
  Stream<RoomModel?> watchRoom(String roomCode) {
    return _supabaseService
        .streamRoom(roomCode.trim().toUpperCase())
        .map((data) => data != null ? RoomModel.fromJson(data) : null);
  }

  @override
  Stream<List<PlayerModel>> watchPlayers(String roomCode) {
    return _supabaseService
        .streamPlayers(roomCode.trim().toUpperCase())
        .map((list) => list.map(PlayerModel.fromJson).toList());
  }

  /// Generates a random 6-character uppercase alphanumeric room code.
  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(
      AppConstants.roomCodeLength,
      (i) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// Generates a random numeric suffix.
  String _generateRandomSuffix() {
    final random = Random.secure();
    return random.nextInt(999999).toString().padLeft(6, '0');
  }
}
