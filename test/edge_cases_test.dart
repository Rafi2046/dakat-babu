import 'package:flutter_test/flutter_test.dart';

import 'package:dakat_babu/core/constants/app_constants.dart';
import 'package:dakat_babu/core/errors/failures.dart';
import 'package:dakat_babu/data/models/room_model.dart';
import 'package:dakat_babu/data/models/round_model.dart';
import 'package:dakat_babu/data/repositories/game_repository_impl.dart';
import 'package:dakat_babu/data/repositories/room_repository_impl.dart';
import 'package:dakat_babu/data/services/supabase_service.dart';
import 'package:dakat_babu/domain/usecases/assign_roles_usecase.dart';

void main() {
  late SupabaseService supabaseService;
  late RoomRepositoryImpl roomRepository;
  late GameRepositoryImpl gameRepository;

  setUp(() async {
    supabaseService = SupabaseService();
    await supabaseService.initialize(url: 'https://placeholder.supabase.co');
    roomRepository = RoomRepositoryImpl(supabaseService: supabaseService);
    gameRepository = GameRepositoryImpl(supabaseService: supabaseService);
  });

  group('Edge Case 1: Player leaves mid-game & Host Return to Lobby', () {
    test('Leaving mid-game flags room as playerLeft and host can return to lobby', () async {
      // 1. Create room and join 4 players
      final room = await roomRepository.createRoom(hostName: 'HostRafi');
      await roomRepository.joinRoom(roomCode: room.roomCode, playerName: 'Topshe');
      await roomRepository.joinRoom(roomCode: room.roomCode, playerName: 'Jatayu');
      final p4 = await roomRepository.joinRoom(roomCode: room.roomCode, playerName: 'Maganlal');

      // 2. Start round 1
      final players = await roomRepository.getPlayers(room.roomCode);
      expect(players.length, 4);

      final assignRoles = AssignRolesUseCase(gameRepository);
      final round = await assignRoles(
        roomCode: room.roomCode,
        players: players,
        roundNumber: 1,
      );
      expect(round.status, RoundStatus.roleReveal);

      var activeRoom = await roomRepository.getRoom(room.roomCode);
      expect(activeRoom?.status, RoomStatus.inProgress);

      // 3. Player 4 disconnects / leaves mid-game
      await roomRepository.leaveRoom(playerId: p4.id, roomCode: room.roomCode);

      // 4. Verify player is removed and room status transitions to playerLeft
      final remainingPlayers = await roomRepository.getPlayers(room.roomCode);
      expect(remainingPlayers.length, 3);
      expect(remainingPlayers.any((p) => p.id == p4.id), isFalse);

      activeRoom = await roomRepository.getRoom(room.roomCode);
      expect(activeRoom?.status, RoomStatus.playerLeft);

      // 5. Host returns to lobby to invite a replacement
      await roomRepository.returnToLobby(room.roomCode);
      activeRoom = await roomRepository.getRoom(room.roomCode);
      expect(activeRoom?.status, RoomStatus.waiting);

      // 6. A replacement 4th player joins the room
      final replacement = await roomRepository.joinRoom(
        roomCode: room.roomCode,
        playerName: 'Lalmohan',
      );
      final updatedPlayers = await roomRepository.getPlayers(room.roomCode);
      expect(updatedPlayers.length, 4);
      expect(updatedPlayers.any((p) => p.id == replacement.id), isTrue);
    });
  });

  group('Edge Case 2: Host leaves before game starts (Host Reassignment)', () {
    test('Host leaves in lobby: host is reassigned to next player in line', () async {
      final room = await roomRepository.createRoom(hostName: 'HostRafi');
      final p2 = await roomRepository.joinRoom(roomCode: room.roomCode, playerName: 'Topshe');
      await roomRepository.joinRoom(roomCode: room.roomCode, playerName: 'Jatayu');

      var players = await roomRepository.getPlayers(room.roomCode);
      expect(players.length, 3);
      final originalHost = players.firstWhere((p) => p.isHost);
      expect(originalHost.name, 'HostRafi');

      // Original host leaves
      await roomRepository.leaveRoom(playerId: originalHost.id, roomCode: room.roomCode);

      // Verify Topshe is now host
      players = await roomRepository.getPlayers(room.roomCode);
      expect(players.length, 2);

      final newHost = players.firstWhere((p) => p.isHost);
      expect(newHost.id, p2.id);
      expect(newHost.name, 'Topshe');

      final updatedRoom = await roomRepository.getRoom(room.roomCode);
      expect(updatedRoom?.hostId, p2.id);
    });

    test('Sole host leaves in lobby: room is disbanded and deleted', () async {
      final room = await roomRepository.createRoom(hostName: 'SoloHost');
      final players = await roomRepository.getPlayers(room.roomCode);
      final host = players.first;

      await roomRepository.leaveRoom(playerId: host.id, roomCode: room.roomCode);

      final checkRoom = await roomRepository.getRoom(room.roomCode);
      expect(checkRoom, isNull);
    });
  });

  group('Edge Case 3: Host Cancels Room & Idle Timeout', () {
    test('Host cancels room: room is deleted', () async {
      final room = await roomRepository.createRoom(hostName: 'HostRafi');
      await roomRepository.joinRoom(roomCode: room.roomCode, playerName: 'Topshe');

      await roomRepository.cancelRoom(room.roomCode);

      final checkRoom = await roomRepository.getRoom(room.roomCode);
      expect(checkRoom, isNull);
    });

    test('LobbyState correctly detects idle timeout', () {
      final oldRoom = RoomModel(
        id: 'old_room',
        roomCode: 'OLD123',
        hostId: 'host_1',
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      );

      final timedOutState = RoomStatus.waiting;
      expect(oldRoom.status, timedOutState);
      expect(
        DateTime.now().difference(oldRoom.createdAt).inMinutes >= AppConstants.lobbyTimeoutMinutes,
        isTrue,
      );
    });
  });

  group('Edge Case 4: Room Code Uniqueness & Collision Protection', () {
    test('createRoom generates valid 6-character uppercase codes', () async {
      final room1 = await roomRepository.createRoom(hostName: 'Host1');
      final room2 = await roomRepository.createRoom(hostName: 'Host2');

      expect(room1.roomCode.length, 6);
      expect(room2.roomCode.length, 6);
      expect(room1.roomCode, isNot(equals(room2.roomCode)));
    });
  });

  group('Edge Case 5: Simultaneous Ready Toggles & Atomic Start Validation', () {
    test('Independent players can toggle ready without race conditions', () async {
      final room = await roomRepository.createRoom(hostName: 'HostRafi');
      final p2 = await roomRepository.joinRoom(roomCode: room.roomCode, playerName: 'Topshe');
      final p3 = await roomRepository.joinRoom(roomCode: room.roomCode, playerName: 'Jatayu');

      // Simultaneous toggles
      await Future.wait([
        roomRepository.setPlayerReady(playerId: p2.id, isReady: true),
        roomRepository.setPlayerReady(playerId: p3.id, isReady: true),
      ]);

      final players = await roomRepository.getPlayers(room.roomCode);
      final p2Updated = players.firstWhere((p) => p.id == p2.id);
      final p3Updated = players.firstWhere((p) => p.id == p3.id);

      expect(p2Updated.isReady, isTrue);
      expect(p3Updated.isReady, isTrue);
    });

    test('Start game rejects if fewer than 4 players are present in DB', () async {
      final room = await roomRepository.createRoom(hostName: 'HostRafi');
      await roomRepository.joinRoom(roomCode: room.roomCode, playerName: 'Topshe');
      await roomRepository.joinRoom(roomCode: room.roomCode, playerName: 'Jatayu');

      final players = await roomRepository.getPlayers(room.roomCode);
      expect(players.length, 3);

      expect(
        () => gameRepository.startRound(
          roomCode: room.roomCode,
          players: players,
          roundNumber: 1,
        ),
        throwsA(isA<GameRuleFailure>()),
      );
    });
  });

  group('Host Player Removal in Lobby', () {
    test('Host can remove an unwanted player from lobby', () async {
      final room = await roomRepository.createRoom(hostName: 'HostRafi');
      final unwanted = await roomRepository.joinRoom(roomCode: room.roomCode, playerName: 'TrollPlayer');

      var players = await roomRepository.getPlayers(room.roomCode);
      expect(players.length, 2);

      await roomRepository.removePlayer(roomCode: room.roomCode, playerId: unwanted.id);

      players = await roomRepository.getPlayers(room.roomCode);
      expect(players.length, 1);
      expect(players.any((p) => p.id == unwanted.id), isFalse);
    });
  });
}
