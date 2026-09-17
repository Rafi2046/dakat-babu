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
    final roomCode = _generateRoomCode();
    final hostId = await _supabaseService.getOrSignInAnonymousUserId();
    final roomId = 'room_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomSuffix()}';
    final now = DateTime.now();

    final hostPlayer = PlayerModel(
      id: hostId,
      roomCode: roomCode,
      name: hostName.trim(),
      isHost: true,
      isReady: true,
      createdAt: now,
    );

    final room = RoomModel(
      id: roomId,
      roomCode: roomCode,
      hostId: hostId,
      status: RoomStatus.waiting,
      currentRound: 0,
      maxRounds: AppConstants.defaultTotalRounds,
      createdAt: now,
    );

    try {
      // 1. Insert room record
      await _supabaseService.insert(AppConstants.roomsTable, room.toJson());

      // 2. Insert host player record
      await _supabaseService.insert(AppConstants.playersTable, hostPlayer.toJson());

      return room;
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Failed to create room: $e');
    }
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
      if (room.status != RoomStatus.waiting) {
        throw const GameRuleFailure('Game in this room has already started');
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
      final alreadyJoined = existingPlayers.any((p) => p['id'] == authUserId);
      final playerId = alreadyJoined
          ? '${authUserId}_${DateTime.now().millisecondsSinceEpoch}'
          : authUserId;

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
    try {
      await _supabaseService.update(
        AppConstants.playersTable,
        matchField: 'id',
        matchValue: playerId,
        values: {'room_code': 'LEFT_$roomCode'},
      );
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Failed to leave room: $e');
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
