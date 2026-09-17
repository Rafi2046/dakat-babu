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
  Future<RoomModel> createRoom({required String hostName}) async {
    return RoomModel(
      id: 'room_1',
      roomCode: 'ABC123',
      hostId: 'host_1',
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
  Stream<List<PlayerModel>> watchPlayers(String roomCode) => Stream.value([]);

  @override
  Stream<RoomModel?> watchRoom(String roomCode) => Stream.value(null);
}

void main() {
  group('Validators Unit Tests', () {
    test('validateRoomCode accepts valid 6-char alphanumeric', () {
      expect(Validators.validateRoomCode('ABC123'), isNull);
      expect(Validators.validateRoomCode('XYZ987'), isNull);
    });

    test('validateRoomCode rejects invalid lengths or characters', () {
      expect(Validators.validateRoomCode(null), isNotNull);
      expect(Validators.validateRoomCode(''), isNotNull);
      expect(Validators.validateRoomCode('ABC1'), isNotNull);
      expect(Validators.validateRoomCode('ABC1234'), isNotNull);
      expect(Validators.validateRoomCode('ABC@12'), isNotNull);
    });

    test('validatePlayerName validates 2-15 characters', () {
      expect(Validators.validatePlayerName('Rafi'), isNull);
      expect(Validators.validatePlayerName(''), isNotNull);
      expect(Validators.validatePlayerName('A'), isNotNull);
      expect(Validators.validatePlayerName('A very long name exceeding limits'), isNotNull);
    });
  });

  group('GameRole Rules & Points', () {
    test('role points match official rules', () {
      expect(GameRole.raja.points, 1000);
      expect(GameRole.mantri.points, 800);
      expect(GameRole.police.points, 500);
      expect(GameRole.chor.points, 500);
    });

    test('role display names are formatted', () {
      expect(GameRole.raja.displayName, contains('Raja'));
      expect(GameRole.mantri.displayName, contains('Mantri'));
      expect(GameRole.police.displayName, contains('Police'));
      expect(GameRole.chor.displayName, contains('Chor'));
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
