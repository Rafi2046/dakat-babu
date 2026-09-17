import '../../data/models/player_model.dart';
import '../../data/models/room_model.dart';

/// Abstract contract for room creation, player joining, and realtime lobby management.
abstract interface class RoomRepository {
  /// Creates a new room with [hostName] as creator, returning the [RoomModel].
  Future<RoomModel> createRoom({required String hostName});

  /// Joins an existing room with [roomCode] using [playerName], returning the joined [PlayerModel].
  Future<PlayerModel> joinRoom({
    required String roomCode,
    required String playerName,
  });

  /// Toggles the ready status of a player identified by [playerId].
  Future<void> setPlayerReady({
    required String playerId,
    required bool isReady,
  });

  /// Removes a player from the room or disbands it if host leaves.
  Future<void> leaveRoom({
    required String playerId,
    required String roomCode,
  });

  /// Retrieves a room by its alphanumeric [roomCode].
  Future<RoomModel?> getRoom(String roomCode);

  /// Retrieves the list of players currently in a room.
  Future<List<PlayerModel>> getPlayers(String roomCode);

  /// Streams realtime updates for a room.
  Stream<RoomModel?> watchRoom(String roomCode);

  /// Streams the list of players currently joined in a room.
  Stream<List<PlayerModel>> watchPlayers(String roomCode);

  /// Cancels and disbands a room, notifying all connected players.
  Future<void> cancelRoom(String roomCode);

  /// Host removes an unwanted or disconnected player from the room.
  Future<void> removePlayer({
    required String roomCode,
    required String playerId,
  });

  /// Updates room lifecycle status (e.g., playerLeft, inProgress).
  Future<void> updateRoomStatus({
    required String roomCode,
    required RoomStatus status,
  });

  /// Resets an active match back to lobby waiting state to replace a dropped player.
  Future<void> returnToLobby(String roomCode);
}
