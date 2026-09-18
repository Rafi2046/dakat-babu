import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/errors/failures.dart';
import '../../data/models/player_model.dart';
import '../../data/models/room_model.dart';
import '../../domain/usecases/create_room_usecase.dart';
import '../../domain/usecases/join_room_usecase.dart';

/// State object for the Home landing screen.
class HomeState {
  final bool isLoading;
  final String? errorMessage;
  final RoomModel? createdRoom;
  final PlayerModel? joinedPlayer;

  const HomeState({
    this.isLoading = false,
    this.errorMessage,
    this.createdRoom,
    this.joinedPlayer,
  });

  HomeState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    RoomModel? createdRoom,
    PlayerModel? joinedPlayer,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      createdRoom: createdRoom ?? this.createdRoom,
      joinedPlayer: joinedPlayer ?? this.joinedPlayer,
    );
  }
}

/// ViewModel governing Room Creation and Room Joining flows.
class HomeViewModel extends StateNotifier<HomeState> {
  final CreateRoomUseCase _createRoomUseCase;
  final JoinRoomUseCase _joinRoomUseCase;
  final StateController<String?> _playerIdController;
  final StateController<String?> _roomCodeController;

  HomeViewModel({
    required CreateRoomUseCase createRoomUseCase,
    required JoinRoomUseCase joinRoomUseCase,
    required StateController<String?> playerIdController,
    required StateController<String?> roomCodeController,
  })  : _createRoomUseCase = createRoomUseCase,
        _joinRoomUseCase = joinRoomUseCase,
        _playerIdController = playerIdController,
        _roomCodeController = roomCodeController,
        super(const HomeState());

  /// Creates a new room with the given host name and custom settings.
  Future<RoomModel?> createRoom(
    String hostName, {
    int maxPlayers = 4,
    String rolePreset = 'classic',
    Map<String, String>? roleLabels,
    Map<String, int>? rolePoints,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final room = await _createRoomUseCase(
        hostName: hostName,
        maxPlayers: maxPlayers,
        rolePreset: rolePreset,
        roleLabels: roleLabels,
        rolePoints: rolePoints,
      );
      _playerIdController.state = room.hostId;
      _roomCodeController.state = room.roomCode;
      state = state.copyWith(isLoading: false, createdRoom: room);
      return room;
    } catch (e) {
      final message = e is Failure ? e.message : 'Failed to create room: $e';
      state = state.copyWith(isLoading: false, errorMessage: message);
      return null;
    }
  }

  /// Joins an existing room with code and player name.
  Future<PlayerModel?> joinRoom({
    required String roomCode,
    required String playerName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final player = await _joinRoomUseCase(
        roomCode: roomCode,
        playerName: playerName,
      );
      _playerIdController.state = player.id;
      _roomCodeController.state = player.roomCode;
      state = state.copyWith(isLoading: false, joinedPlayer: player);
      return player;
    } catch (e) {
      final message = e is Failure ? e.message : 'Failed to join room: $e';
      state = state.copyWith(isLoading: false, errorMessage: message);
      return null;
    }
  }

  /// Clears any visible error state.
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Riverpod provider for [HomeViewModel].
final homeViewModelProvider =
    StateNotifierProvider.autoDispose<HomeViewModel, HomeState>((ref) {
  return HomeViewModel(
    createRoomUseCase: ref.watch(createRoomUseCaseProvider),
    joinRoomUseCase: ref.watch(joinRoomUseCaseProvider),
    playerIdController: ref.watch(currentPlayerIdProvider.notifier),
    roomCodeController: ref.watch(currentRoomCodeProvider.notifier),
  );
});
