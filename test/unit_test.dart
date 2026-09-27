import 'package:flutter_test/flutter_test.dart';

import 'package:dakat_babu/core/constants/app_constants.dart';
import 'package:dakat_babu/core/errors/failures.dart';
import 'package:dakat_babu/core/utils/extensions.dart';
import 'package:dakat_babu/core/utils/validators.dart';
import 'package:dakat_babu/data/models/player_model.dart';
import 'package:dakat_babu/data/models/room_model.dart';
import 'package:dakat_babu/domain/usecases/create_room_usecase.dart';
import 'package:dakat_babu/domain/usecases/join_room_usecase.dart';

// Fake RoomRepository for pure unit tests
import 'package:dakat_babu/domain/repositories/room_repository.dart';

class FakeRoomRepository implements RoomRepository {
  @override
  Future<RoomModel> createRoom({
    required String hostName,
    int maxPlayers = 4,
    String rolePreset = 'classic',
    Map<String, String>? roleLabels,
    Map<String, int>? rolePoints,
  }) async {
    return RoomModel(
      id: 'room_1',
      roomCode: 'ABC123',
      hostId: 'host_1',
      maxPlayers: maxPlayers,
      rolePreset: rolePreset,
      roleLabels: roleLabels,
      rolePoints: rolePoints,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<PlayerModel> joinRoom({
    required String roomCode,
    required String playerName,
  }) async {
    return PlayerModel(
      id: 'p_2',
      roomCode: roomCode,
      name: playerName,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<RoomModel?> getRoom(String roomCode) async => null;

  @override
  Future<void> leaveRoom({required String playerId, required String roomCode}) async {}

  @override
  Future<void> setPlayerReady({required String playerId, required bool isReady}) async {}

  @override
  Future<List<PlayerModel>> getPlayers(String roomCode) async => [];

  @override
  Stream<List<PlayerModel>> watchPlayers(String roomCode) => Stream.value([]);

  @override
  Stream<RoomModel?> watchRoom(String roomCode) => Stream.value(null);

  @override
  Future<void> cancelRoom(String roomCode) async {}

  @override
  Future<void> removePlayer({required String roomCode, required String playerId}) async {}

  @override
  Future<void> updateRoomStatus({required String roomCode, required RoomStatus status}) async {}

  @override
  Future<void> returnToLobby(String roomCode) async {}
}

void main() {
  group('Validators Unit Tests', () {
    test('validateRoomCode accepts valid ${AppConstants.roomCodeLength}-char alphanumeric', () {
      expect(Validators.validateRoomCode('ABC12'), isNull);
      expect(Validators.validateRoomCode('XYZ98'), isNull);
    });

    test('validateRoomCode rejects invalid lengths or characters', () {
      expect(Validators.validateRoomCode(null), isNotNull);
      expect(Validators.validateRoomCode(''), isNotNull);
      expect(Validators.validateRoomCode('ABC1'), isNotNull);
      expect(Validators.validateRoomCode('ABC123'), isNotNull);
      expect(Validators.validateRoomCode('AB@12'), isNotNull);
    });

    test('validatePlayerName validates 2-15 characters', () {
      expect(Validators.validatePlayerName('Rafi'), isNull);
      expect(Validators.validatePlayerName(''), isNotNull);
      expect(Validators.validatePlayerName('A'), isNotNull);
      expect(Validators.validatePlayerName('A very long name exceeding limits'), isNotNull);
    });
  });

  group('GameRole Rules & Points', () {
    test('role points match CPDB +1 rules', () {
      expect(GameRole.police.points, AppConstants.policeCorrectPoints);
      expect(GameRole.babu.points, AppConstants.wrongGuessSuspectPoints);
      expect(GameRole.chor.points, AppConstants.wrongGuessSuspectPoints);
      expect(GameRole.dakat.points, AppConstants.wrongGuessSuspectPoints);
    });

    test('role display names are formatted', () {
      expect(GameRole.police.displayName, contains('Police'));
      expect(GameRole.babu.displayName, contains('Babu'));
      expect(GameRole.chor.displayName, contains('Chor'));
      expect(GameRole.dakat.displayName, contains('Dakat'));
    });
  });

  group('Use Cases with Validation', () {
    final fakeRepo = FakeRoomRepository();

    test('CreateRoomUseCase throws ValidationFailure on empty name', () async {
      final useCase = CreateRoomUseCase(fakeRepo);
      expect(
        () => useCase(hostName: ''),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('CreateRoomUseCase succeeds with valid host name', () async {
      final useCase = CreateRoomUseCase(fakeRepo);
      final room = await useCase(hostName: 'Sherlock');
      expect(room.roomCode, 'ABC123');
    });

    test('JoinRoomUseCase throws ValidationFailure on invalid room code', () async {
      final useCase = JoinRoomUseCase(fakeRepo);
      expect(
        () => useCase(roomCode: '123', playerName: 'Watson'),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });
}
