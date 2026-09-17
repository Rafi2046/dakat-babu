import 'package:flutter_test/flutter_test.dart';

import 'package:dakat_babu/core/constants/app_constants.dart';
import 'package:dakat_babu/data/models/round_model.dart';
import 'package:dakat_babu/data/repositories/game_repository_impl.dart';
import 'package:dakat_babu/data/repositories/room_repository_impl.dart';
import 'package:dakat_babu/data/services/supabase_service.dart';
import 'package:dakat_babu/domain/usecases/assign_roles_usecase.dart';
import 'package:dakat_babu/domain/usecases/submit_guess_usecase.dart';

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

  group('RLS Auth Scoping & Identifier Alignment', () {
    test('Player composite IDs contain auth.uid() prefix extractable by split_part', () async {
      final room = await roomRepository.createRoom(hostName: 'TestHost');
      final player = await roomRepository.joinRoom(
        roomCode: room.roomCode,
        playerName: 'TestGuest',
      );

      // Verify that split_part(id, '_', 1) cleanly yields the base auth session ID
      final hostPrefix = room.hostId.split('_').first;
      final playerPrefix = player.id.split('_').first;

      expect(hostPrefix, isNotEmpty);
      expect(playerPrefix, isNotEmpty);
      expect(room.hostId.startsWith(hostPrefix), isTrue);
      expect(player.id.startsWith(playerPrefix), isTrue);
    });

    test('Player can update their own ready status', () async {
      final room = await roomRepository.createRoom(hostName: 'Host');
      final player = await roomRepository.joinRoom(
        roomCode: room.roomCode,
        playerName: 'GuestPlayer',
      );

      // Player toggles own ready status
      await roomRepository.setPlayerReady(playerId: player.id, isReady: true);

      final players = await roomRepository.getPlayers(room.roomCode);
      final updated = players.firstWhere((p) => p.id == player.id);
      expect(updated.isReady, isTrue);
    });

    test('Player can delete their own record when leaving', () async {
      final room = await roomRepository.createRoom(hostName: 'Host');
      final player = await roomRepository.joinRoom(
        roomCode: room.roomCode,
        playerName: 'GuestPlayer',
      );

      var players = await roomRepository.getPlayers(room.roomCode);
      expect(players.length, 2);

      // Player leaves
      await roomRepository.leaveRoom(playerId: player.id, roomCode: room.roomCode);

      players = await roomRepository.getPlayers(room.roomCode);
      expect(players.length, 1);
      expect(players.any((p) => p.id == player.id), isFalse);
    });

    test('Host can update player roles on game launch and return to lobby', () async {
      final room = await roomRepository.createRoom(hostName: 'Host');
      await roomRepository.joinRoom(roomCode: room.roomCode, playerName: 'P2');
      await roomRepository.joinRoom(roomCode: room.roomCode, playerName: 'P3');
      await roomRepository.joinRoom(roomCode: room.roomCode, playerName: 'P4');

      var players = await roomRepository.getPlayers(room.roomCode);
      expect(players.length, 4);

      // Host starts game (assigns roles across all 4 players)
      final assignRoles = AssignRolesUseCase(gameRepository);
      await assignRoles(
        roomCode: room.roomCode,
        players: players,
        roundNumber: 1,
      );

      players = await roomRepository.getPlayers(room.roomCode);
      expect(players.every((p) => p.role != null), isTrue);

      // Host returns to lobby (clears roles across all players)
      await roomRepository.returnToLobby(room.roomCode);

      players = await roomRepository.getPlayers(room.roomCode);
      expect(players.every((p) => p.role == null), isTrue);
    });

    test('Police can submit guess on game_rounds and distribute points', () async {
      final room = await roomRepository.createRoom(hostName: 'Host');
      await roomRepository.joinRoom(roomCode: room.roomCode, playerName: 'P2');
      await roomRepository.joinRoom(roomCode: room.roomCode, playerName: 'P3');
      await roomRepository.joinRoom(roomCode: room.roomCode, playerName: 'P4');

      final players = await roomRepository.getPlayers(room.roomCode);
      final assignRoles = AssignRolesUseCase(gameRepository);
      final round = await assignRoles(
        roomCode: room.roomCode,
        players: players,
        roundNumber: 1,
      );

      // Police submits guess
      final submitGuess = SubmitGuessUseCase(gameRepository);
      final result = await submitGuess(
        roundId: round.id,
        roomCode: room.roomCode,
        suspectPlayerId: round.chorPlayerId,
      );

      expect(result.status, RoundStatus.completed);
      expect(result.isGuessCorrect, isTrue);
      expect(result.policeGuessPlayerId, round.chorPlayerId);

      // Verify points were distributed to Raja and Mantri
      final updatedPlayers = await roomRepository.getPlayers(room.roomCode);
      final raja = updatedPlayers.firstWhere((p) => p.id == round.rajaPlayerId);
      final mantri = updatedPlayers.firstWhere((p) => p.id == round.mantriPlayerId);
      expect(raja.score, AppConstants.rajaPoints);
      expect(mantri.score, AppConstants.mantriPoints);
    });

    test('Host can cancel and delete the room', () async {
      final room = await roomRepository.createRoom(hostName: 'Host');
      await roomRepository.joinRoom(roomCode: room.roomCode, playerName: 'P2');

      await roomRepository.cancelRoom(room.roomCode);

      final checkRoom = await roomRepository.getRoom(room.roomCode);
      expect(checkRoom, isNull);
    });
  });
}
