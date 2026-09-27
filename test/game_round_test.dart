import 'package:flutter_test/flutter_test.dart';

import 'package:dakat_babu/core/constants/app_constants.dart';
import 'package:dakat_babu/data/models/player_model.dart';
import 'package:dakat_babu/data/models/round_model.dart';
import 'package:dakat_babu/data/repositories/game_repository_impl.dart';
import 'package:dakat_babu/data/repositories/room_repository_impl.dart';
import 'package:dakat_babu/data/services/supabase_service.dart';
import 'package:dakat_babu/domain/usecases/assign_roles_usecase.dart';
import 'package:dakat_babu/domain/usecases/submit_guess_usecase.dart';
import 'package:dakat_babu/presentation/viewmodels/game_round_viewmodel.dart';
import 'package:dakat_babu/presentation/viewmodels/results_viewmodel.dart';

void main() {
  group('Game Round & Results Flow', () {
    late SupabaseService supabaseService;
    late GameRepositoryImpl gameRepository;
    late RoomRepositoryImpl roomRepository;
    late AssignRolesUseCase assignRolesUseCase;
    late SubmitGuessUseCase submitGuessUseCase;

    setUp(() {
      supabaseService = SupabaseService();
      gameRepository = GameRepositoryImpl(supabaseService: supabaseService);
      roomRepository = RoomRepositoryImpl(supabaseService: supabaseService);
      assignRolesUseCase = AssignRolesUseCase(gameRepository);
      submitGuessUseCase = SubmitGuessUseCase(gameRepository);
    });

    test(
        'Full 4-player round cycle: role assignment, guessing, points, and next round',
        () async {
      const roomCode = 'RND101';
      final now = DateTime.now();

      final List<PlayerModel> players = [
        PlayerModel(
          id: 'p1',
          roomCode: roomCode,
          name: 'Akbar',
          isHost: true,
          score: 0,
          createdAt: now,
        ),
        PlayerModel(
          id: 'p2',
          roomCode: roomCode,
          name: 'Birbal',
          isHost: false,
          score: 0,
          createdAt: now,
        ),
        PlayerModel(
          id: 'p3',
          roomCode: roomCode,
          name: 'Man Singh',
          isHost: false,
          score: 0,
          createdAt: now,
        ),
        PlayerModel(
          id: 'p4',
          roomCode: roomCode,
          name: 'Tansen',
          isHost: false,
          score: 0,
          createdAt: now,
        ),
      ];

      for (final p in players) {
        await supabaseService.insert(AppConstants.playersTable, p.toJson());
      }

      final round1 = await assignRolesUseCase(
        roomCode: roomCode,
        players: players,
        roundNumber: 1,
      );

      expect(round1.roomCode, equals(roomCode));
      expect(round1.roundNumber, equals(1));
      expect(round1.status, equals(RoundStatus.roleReveal));

      final rolePlayerIds = {
        round1.babuPlayerId,
        round1.dakatPlayerId,
        round1.policePlayerId,
        round1.chorPlayerId,
      };
      expect(rolePlayerIds.length, equals(4));

      final roundViewModel = GameRoundViewModel(
        roomCode: roomCode,
        gameRepository: gameRepository,
        roomRepository: roomRepository,
        submitGuessUseCase: submitGuessUseCase,
      );

      expect(roundViewModel.state.isCardRevealed, isFalse);
      roundViewModel.toggleCardReveal();
      expect(roundViewModel.state.isCardRevealed, isTrue);

      roundViewModel.selectSuspect(round1.chorPlayerId);
      expect(roundViewModel.state.selectedSuspectId, equals(round1.chorPlayerId));

      final guessResult = await submitGuessUseCase(
        roundId: round1.id,
        roomCode: roomCode,
        suspectPlayerId: round1.chorPlayerId,
      );

      expect(guessResult.isGuessCorrect, isTrue);
      expect(guessResult.status, equals(RoundStatus.completed));
      expect(guessResult.policeGuessPlayerId, equals(round1.chorPlayerId));

      final babuPlayer = await supabaseService.fetchSingle(
        AppConstants.playersTable,
        matchField: 'id',
        matchValue: round1.babuPlayerId,
      );
      final dakatPlayer = await supabaseService.fetchSingle(
        AppConstants.playersTable,
        matchField: 'id',
        matchValue: round1.dakatPlayerId,
      );
      final policePlayer = await supabaseService.fetchSingle(
        AppConstants.playersTable,
        matchField: 'id',
        matchValue: round1.policePlayerId,
      );
      final chorPlayer = await supabaseService.fetchSingle(
        AppConstants.playersTable,
        matchField: 'id',
        matchValue: round1.chorPlayerId,
      );

      // CPDB +1: only Police scores on a correct catch.
      expect(policePlayer?['score'], equals(AppConstants.policeCorrectPoints));
      expect(chorPlayer?['score'], equals(0));
      expect(babuPlayer?['score'], equals(0));
      expect(dakatPlayer?['score'], equals(0));

      final resultsViewModel = ResultsViewModel(
        roomCode: roomCode,
        gameRepository: gameRepository,
        roomRepository: roomRepository,
        assignRolesUseCase: assignRolesUseCase,
      );

      final nextRoundStarted = await resultsViewModel.startNextRound();
      expect(nextRoundStarted, isTrue);

      final round2Data = await supabaseService.fetchSingle(
        AppConstants.roundsTable,
        matchField: 'room_code',
        matchValue: roomCode,
      );
      expect(round2Data, isNotNull);

      roundViewModel.dispose();
      resultsViewModel.dispose();
    });
  });
}
