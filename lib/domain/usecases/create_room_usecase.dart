import '../../core/errors/failures.dart';
import '../../core/utils/validators.dart';
import '../../data/models/room_model.dart';
import '../repositories/room_repository.dart';

/// Business logic use case to create a new multiplayer room.
class CreateRoomUseCase {
  final RoomRepository _roomRepository;

  const CreateRoomUseCase(this._roomRepository);

  /// Executes room creation after validating [hostName].
  Future<RoomModel> call({required String hostName}) async {
    final validationError = Validators.validatePlayerName(hostName);
    if (validationError != null) {
      throw ValidationFailure(validationError);
    }

    return _roomRepository.createRoom(hostName: hostName.trim());
  }
}
