import '../../core/errors/failures.dart';
import '../../core/utils/validators.dart';
import '../../data/models/player_model.dart';
import '../repositories/room_repository.dart';

/// Business logic use case to join an existing multiplayer room.
class JoinRoomUseCase {
  final RoomRepository _roomRepository;

  const JoinRoomUseCase(this._roomRepository);

  /// Validates input parameters and joins the player into [roomCode].
  Future<PlayerModel> call({
    required String roomCode,
    required String playerName,
  }) async {
    final roomCodeError = Validators.validateRoomCode(roomCode);
    if (roomCodeError != null) {
      throw ValidationFailure(roomCodeError);
    }

    final nameError = Validators.validatePlayerName(playerName);
    if (nameError != null) {
      throw ValidationFailure(nameError);
    }

    return _roomRepository.joinRoom(
      roomCode: roomCode.trim().toUpperCase(),
      playerName: playerName.trim(),
    );
  }
}
