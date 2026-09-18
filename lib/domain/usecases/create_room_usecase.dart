import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/validators.dart';
import '../../data/models/room_model.dart';
import '../repositories/room_repository.dart';

/// Business logic use case to create a new multiplayer room.
class CreateRoomUseCase {
  final RoomRepository _roomRepository;

  const CreateRoomUseCase(this._roomRepository);

  /// Executes room creation after validating [hostName] and parameters.
  Future<RoomModel> call({
    required String hostName,
    int maxPlayers = 4,
    String rolePreset = 'classic',
    Map<String, String>? roleLabels,
    Map<String, int>? rolePoints,
  }) async {
    final validationError = Validators.validatePlayerName(hostName);
    if (validationError != null) {
      throw ValidationFailure(validationError);
    }
    if (maxPlayers < AppConstants.minPlayers || maxPlayers > AppConstants.maxPlayers) {
      throw ValidationFailure(
        'Player count must be between ${AppConstants.minPlayers} and ${AppConstants.maxPlayers}',
      );
    }

    return _roomRepository.createRoom(
      hostName: hostName.trim(),
      maxPlayers: maxPlayers,
      rolePreset: rolePreset,
      roleLabels: roleLabels,
      rolePoints: rolePoints,
    );
  }
}
