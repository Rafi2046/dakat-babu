import 'package:flutter_test/flutter_test.dart';
import 'package:dakat_babu/core/constants/app_constants.dart';
import 'package:dakat_babu/presentation/viewmodels/pass_and_play_viewmodel.dart';

void main() {
  group('Pass & Play ViewModel & Game Logic Tests', () {
    late PassAndPlayViewModel viewModel;

    setUp(() {
      viewModel = PassAndPlayViewModel();
    });

    test('Initializes match with 4 players, 5 rounds, and assigns all 4 distinct roles', () {
      final names = ['Rafi', 'Sakib', 'Tanvir', 'Rahul'];
      viewModel.initMatch(playerNames: names, totalRounds: 5);

      final state = viewModel.state;
      expect(state.players.length, equals(4));
      expect(state.currentRound, equals(1));
      expect(state.totalRounds, equals(5));
      expect(state.stage, equals(PassAndPlayStage.passToPlayer));

      final roles = state.players.map((p) => p.role).toSet();
      expect(roles, containsAll([GameRole.raja, GameRole.mantri, GameRole.police, GameRole.chor]));
      expect(roles.length, equals(4));
    });

    test('Peeking flow transitions sequentially through all 4 players and then to Police', () {
      final names = ['Rafi', 'Sakib', 'Tanvir', 'Rahul'];
      viewModel.initMatch(playerNames: names, totalRounds: 3);

      // Player 1
      expect(viewModel.state.currentPeekIndex, equals(0));
      expect(viewModel.state.currentPeekingPlayer?.name, equals('Rafi'));
      viewModel.readyToPeek();
      expect(viewModel.state.stage, equals(PassAndPlayStage.peekRole));
      viewModel.finishPeekingCurrentPlayer();

      // Player 2
      expect(viewModel.state.stage, equals(PassAndPlayStage.passToPlayer));
      expect(viewModel.state.currentPeekIndex, equals(1));
      expect(viewModel.state.currentPeekingPlayer?.name, equals('Sakib'));
      viewModel.readyToPeek();
      viewModel.finishPeekingCurrentPlayer();

      // Player 3
      expect(viewModel.state.currentPeekIndex, equals(2));
      viewModel.readyToPeek();
      viewModel.finishPeekingCurrentPlayer();

      // Player 4
      expect(viewModel.state.currentPeekIndex, equals(3));
      viewModel.readyToPeek();
      viewModel.finishPeekingCurrentPlayer();

      // All 4 checked -> Hand to Police
      expect(viewModel.state.stage, equals(PassAndPlayStage.handToPolice));

      // Police takes device
      viewModel.beginPoliceInterrogation();
      expect(viewModel.state.stage, equals(PassAndPlayStage.policeAccusing));
    });

    test('Correct Accusation: Police catches Chor -> Police 500, Chor 0', () {
      final names = ['Rafi', 'Sakib', 'Tanvir', 'Rahul'];
      viewModel.initMatch(playerNames: names, totalRounds: 3);

      final chor = viewModel.state.chorPlayer!;
      final police = viewModel.state.policePlayer!;
      final raja = viewModel.state.rajaPlayer!;
      final mantri = viewModel.state.mantriPlayer!;

      // Advance to interrogation
      for (var i = 0; i < 4; i++) {
        viewModel.readyToPeek();
        viewModel.finishPeekingCurrentPlayer();
      }
      viewModel.beginPoliceInterrogation();

      // Police accuses Chor correctly
      viewModel.makeAccusation(chor.id);

      final state = viewModel.state;
      expect(state.stage, equals(PassAndPlayStage.roundResults));
      expect(state.isGuessCorrect, isTrue);

      final updatedPolice = state.players.firstWhere((p) => p.id == police.id);
      final updatedChor = state.players.firstWhere((p) => p.id == chor.id);
      final updatedRaja = state.players.firstWhere((p) => p.id == raja.id);
      final updatedMantri = state.players.firstWhere((p) => p.id == mantri.id);

      expect(updatedRaja.roundScore, equals(1000));
      expect(updatedMantri.roundScore, equals(800));
      expect(updatedPolice.roundScore, equals(500));
      expect(updatedChor.roundScore, equals(0));

      expect(updatedRaja.totalScore, equals(1000));
      expect(updatedMantri.totalScore, equals(800));
      expect(updatedPolice.totalScore, equals(500));
      expect(updatedChor.totalScore, equals(0));
    });

    test('Incorrect Accusation: Police accuses Mantri -> Chor steals 500, Police 0', () {
      final names = ['Rafi', 'Sakib', 'Tanvir', 'Rahul'];
      viewModel.initMatch(playerNames: names, totalRounds: 3);

      final chor = viewModel.state.chorPlayer!;
      final police = viewModel.state.policePlayer!;
      final mantri = viewModel.state.mantriPlayer!;

      // Advance to interrogation
      for (var i = 0; i < 4; i++) {
        viewModel.readyToPeek();
        viewModel.finishPeekingCurrentPlayer();
      }
      viewModel.beginPoliceInterrogation();

      // Police mistakenly accuses Mantri
      viewModel.makeAccusation(mantri.id);

      final state = viewModel.state;
      expect(state.stage, equals(PassAndPlayStage.roundResults));
      expect(state.isGuessCorrect, isFalse);

      final updatedPolice = state.players.firstWhere((p) => p.id == police.id);
      final updatedChor = state.players.firstWhere((p) => p.id == chor.id);

      expect(updatedPolice.roundScore, equals(0));
      expect(updatedChor.roundScore, equals(500));
    });
  });
}
