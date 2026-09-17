// ignore_for_file: avoid_print, depend_on_referenced_packages
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dakat_babu/core/constants/app_constants.dart';
import 'package:dakat_babu/core/utils/extensions.dart';
import 'package:dakat_babu/data/models/player_model.dart';
import 'package:dakat_babu/data/models/round_model.dart';
import 'package:dakat_babu/data/repositories/game_repository_impl.dart';
import 'package:dakat_babu/data/repositories/room_repository_impl.dart';
import 'package:dakat_babu/data/services/supabase_service.dart';
import 'package:dakat_babu/domain/usecases/assign_roles_usecase.dart';
import 'package:dakat_babu/domain/usecases/submit_guess_usecase.dart';

void main() {
  test('Live 4-client Game Round simulation test with Supabase', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues({});

    print('====================================================');
    print('🚀 Starting live Supabase 4-client Game Round test');
    print('====================================================\n');

    final supabaseService = SupabaseService();
    await supabaseService.initialize();

    final roomRepo = RoomRepositoryImpl(supabaseService: supabaseService);
    final gameRepo = GameRepositoryImpl(supabaseService: supabaseService);
    final assignRoles = AssignRolesUseCase(gameRepo);
    final submitGuess = SubmitGuessUseCase(gameRepo);

    String? roomCode;

    try {
      // 1. Host creates room
      print('[Step 1] Host creates room...');
      final room = await roomRepo.createRoom(hostName: 'Feluda (Host)');
      roomCode = room.roomCode;
      print('✅ Room created with code: $roomCode');

      // 2. Clients B, C, D join room
      print('\n[Step 2] 3 clients join the room...');
      final p2 = await roomRepo.joinRoom(roomCode: roomCode, playerName: 'Topshe');
      print('✅ Client B joined as: ${p2.name} (${p2.id})');

      final p3 = await roomRepo.joinRoom(roomCode: roomCode, playerName: 'Jatayu');
      print('✅ Client C joined as: ${p3.name} (${p3.id})');

      final p4 = await roomRepo.joinRoom(roomCode: roomCode, playerName: 'Maganlal');
      print('✅ Client D joined as: ${p4.name} (${p4.id})');

      // Fetch all 4 players
      final players = await roomRepo.getPlayers(roomCode);
      print('\n[Step 3] Verifying 4 joined players in lobby...');
      for (final p in players) {
        print('   - ${p.name} | Host: ${p.isHost} | ID: ${p.id}');
      }
      expect(players.length, equals(4));
      print('✅ Exactly 4 players verified!');

      // 3. Host starts game (Assigns roles & starts Round 1)
      print('\n[Step 4] Host starts game -> Shuffling and assigning roles for Round 1...');
      final round1 = await assignRoles(
        roomCode: roomCode,
        players: players,
        roundNumber: 1,
      );
      print('✅ Round 1 created: ID=${round1.id}, Status=${round1.status.name}');

      // Fetch players to see their assigned roles
      final updatedPlayers = await roomRepo.getPlayers(roomCode);
      PlayerModel? raja, mantri, police, chor;

      print('\n[Step 5] Role Reveal Verification:');
      for (final p in updatedPlayers) {
        print('   - ${p.name}: ${p.role?.displayName ?? 'None'} (+${p.role?.points ?? 0} pts)');
        if (p.id == round1.rajaPlayerId) raja = p;
        if (p.id == round1.mantriPlayerId) mantri = p;
        if (p.id == round1.policePlayerId) police = p;
        if (p.id == round1.chorPlayerId) chor = p;
      }

      expect(raja, isNotNull);
      expect(mantri, isNotNull);
      expect(police, isNotNull);
      expect(chor, isNotNull);
      print('✅ All 4 distinct roles (Raja, Mantri, Police, Chor) successfully assigned!');

      // 4. Police Player Interrogation & Accusation
      print('\n[Step 6] Police (${police!.name}) interrogates suspects...');
      print('   👑 Raja declared: ${raja!.name} (Immune)');
      print('   🔍 Suspects: ${mantri!.name} vs ${chor!.name}');
      print('   👉 Police accuses ${chor.name} as the Chor!');

      final guessResult = await submitGuess(
        roundId: round1.id,
        roomCode: roomCode,
        suspectPlayerId: chor.id,
      );

      print('\n[Step 7] Accusation Outcome:');
      print('   - Guess Correct: ${guessResult.isGuessCorrect}');
      print('   - Accused ID: ${guessResult.policeGuessPlayerId}');
      print('   - Round Status: ${guessResult.status.name}');
      expect(guessResult.isGuessCorrect, isTrue);
      expect(guessResult.status, equals(RoundStatus.completed));
      print('✅ Police correctly unmasked the Chor! Round marked completed.');

      // 5. Verify Cumulative Scores & Points Awarded
      print('\n[Step 8] Verifying Updated Cumulative Scores from database:');
      final finalPlayers = await roomRepo.getPlayers(roomCode);
      final sortedLeaderboard = List<PlayerModel>.from(finalPlayers)
        ..sort((a, b) => b.score.compareTo(a.score));

      for (var i = 0; i < sortedLeaderboard.length; i++) {
        final p = sortedLeaderboard[i];
        print('   #${i + 1}: ${p.name} (${p.role?.displayName}) -> ${p.score} pts');
      }

      final rajaFinal = finalPlayers.firstWhere((p) => p.id == raja!.id);
      final mantriFinal = finalPlayers.firstWhere((p) => p.id == mantri!.id);
      final policeFinal = finalPlayers.firstWhere((p) => p.id == police!.id);
      final chorFinal = finalPlayers.firstWhere((p) => p.id == chor!.id);

      expect(rajaFinal.score >= 1000, isTrue);
      expect(mantriFinal.score >= 800, isTrue);
      expect(policeFinal.score >= 500, isTrue);
      expect(chorFinal.score, equals(0));
      print('✅ All scores properly incremented according to official game rules!');

      // 6. Host starts Next Round (Round 2)
      print('\n[Step 9] Host taps "Start Next Round" (Round 2)...');
      final round2 = await assignRoles(
        roomCode: roomCode,
        players: finalPlayers,
        roundNumber: 2,
      );
      print('✅ Round 2 created: ID=${round2.id}, RoundNumber=${round2.roundNumber}');

      final round2Players = await roomRepo.getPlayers(roomCode);
      print('✅ Roles reshuffled for Round 2:');
      for (final p in round2Players) {
        print('   - ${p.name}: ${p.role?.displayName} (Score: ${p.score} pts)');
      }

      print('\n====================================================');
      print('🎉 ALL 4-CLIENT GAME ROUND FLOW TESTS PASSED PERFECTLY!');
      print('====================================================');
    } finally {
      // Cleanup
      if (roomCode != null) {
        print('\n[Cleanup] Cleaning up test room: $roomCode...');
        try {
          await supabaseService.update(
            AppConstants.roomsTable,
            matchField: 'room_code',
            matchValue: roomCode,
            values: {'status': 'archived'},
          );
          print('✅ Cleanup complete!');
        } catch (_) {}
      }
    }
  });
}
