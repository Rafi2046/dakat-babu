import 'package:flutter_test/flutter_test.dart';
import 'package:dakat_babu/core/constants/app_constants.dart';
import 'package:dakat_babu/presentation/viewmodels/pass_and_play_viewmodel.dart';

void main() {
  group('Pass & Play ViewModel & Game Logic Tests', () {
    late PassAndPlayViewModel viewModel;

    setUp(() {
      viewModel = PassAndPlayViewModel();
    });

    test(
        'Initializes match with 4 players, 5 rounds, and assigns all 4 distinct roles',
        () {
      final names = ['Rafi', 'Sakib', 'Tanvir', 'Rahul'];
      viewModel.initMatch(playerNames: names, totalRounds: 5);

      final state = viewModel.state;
      expect(state.players.length, equals(4));
      expect(state.currentRound, equals(1));
      expect(state.totalRounds, equals(5));
      expect(state.stage, equals(PassAndPlayStage.passToPlayer));

      final roles = state.players.map((p) => p.role).toSet();
      expect(
        roles,
        containsAll([
          GameRole.police,
          GameRole.babu,
          GameRole.chor,
          GameRole.dakat,
        ]),
      );
      expect(roles.length, equals(4));
    });

    test(
        'Peeking flow transitions sequentially through all 4 players and then to Police',
        () {
      final names = ['Rafi', 'Sakib', 'Tanvir', 'Rahul'];
      viewModel.initMatch(playerNames: names, totalRounds: 3);

      expect(viewModel.state.currentPeekIndex, equals(0));
      expect(viewModel.state.currentPeekingPlayer?.name, equals('Rafi'));
      viewModel.readyToPeek();
      expect(viewModel.state.stage, equals(PassAndPlayStage.peekRole));
      viewModel.finishPeekingCurrentPlayer();

      expect(viewModel.state.stage, equals(PassAndPlayStage.passToPlayer));
      expect(viewModel.state.currentPeekIndex, equals(1));
      expect(viewModel.state.currentPeekingPlayer?.name, equals('Sakib'));
      viewModel.readyToPeek();
      viewModel.finishPeekingCurrentPlayer();

      expect(viewModel.state.currentPeekIndex, equals(2));
      viewModel.readyToPeek();
      viewModel.finishPeekingCurrentPlayer();

      expect(viewModel.state.currentPeekIndex, equals(3));
      viewModel.readyToPeek();
      viewModel.finishPeekingCurrentPlayer();

      expect(viewModel.state.stage, equals(PassAndPlayStage.handToPolice));

      viewModel.beginPoliceInterrogation();
      expect(viewModel.state.stage, equals(PassAndPlayStage.policeAccusing));
    });

    test('Correct Accusation: Police catches Chor → Police +1', () {
      final names = ['Rafi', 'Sakib', 'Tanvir', 'Rahul'];
      viewModel.initMatch(playerNames: names, totalRounds: 3);

      final chor = viewModel.state.chorPlayer!;
      final police = viewModel.state.policePlayer!;
      final babu = viewModel.state.babuPlayer!;
      final dakat =
          viewModel.state.players.firstWhere((p) => p.role == GameRole.dakat);

      for (var i = 0; i < 4; i++) {
        viewModel.readyToPeek();
        viewModel.finishPeekingCurrentPlayer();
      }
      viewModel.beginPoliceInterrogation();

      viewModel.makeAccusation(chor.id);

      final state = viewModel.state;
      expect(state.stage, equals(PassAndPlayStage.roundResults));
      expect(state.isGuessCorrect, isTrue);

      final updatedPolice = state.players.firstWhere((p) => p.id == police.id);
      final updatedChor = state.players.firstWhere((p) => p.id == chor.id);
      final updatedBabu = state.players.firstWhere((p) => p.id == babu.id);
      final updatedDakat = state.players.firstWhere((p) => p.id == dakat.id);

      expect(updatedPolice.roundScore, equals(AppConstants.policeCorrectPoints));
      expect(updatedChor.roundScore, equals(0));
      expect(updatedBabu.roundScore, equals(0));
      expect(updatedDakat.roundScore, equals(0));

      expect(updatedPolice.totalScore, equals(AppConstants.policeCorrectPoints));
      expect(updatedChor.totalScore, equals(0));
    });

    test('Incorrect Accusation: Police accuses Dakat → Dakat +1', () {
      final names = ['Rafi', 'Sakib', 'Tanvir', 'Rahul'];
      viewModel.initMatch(playerNames: names, totalRounds: 3);

      final chor = viewModel.state.chorPlayer!;
      final police = viewModel.state.policePlayer!;
      final dakat =
          viewModel.state.players.firstWhere((p) => p.role == GameRole.dakat);

      for (var i = 0; i < 4; i++) {
        viewModel.readyToPeek();
        viewModel.finishPeekingCurrentPlayer();
      }
      viewModel.beginPoliceInterrogation();

      viewModel.makeAccusation(dakat.id);

      final state = viewModel.state;
      expect(state.stage, equals(PassAndPlayStage.roundResults));
      expect(state.isGuessCorrect, isFalse);

      final updatedPolice = state.players.firstWhere((p) => p.id == police.id);
      final updatedChor = state.players.firstWhere((p) => p.id == chor.id);
      final updatedDakat = state.players.firstWhere((p) => p.id == dakat.id);

      expect(updatedPolice.roundScore, equals(0));
      expect(updatedChor.roundScore, equals(0));
      expect(
        updatedDakat.roundScore,
        equals(AppConstants.wrongGuessSuspectPoints),
      );
    });

    test('Each round still assigns 4 distinct CPDB roles', () {
      final names = ['Rafi', 'Sakib', 'Tanvir', 'Rahul'];
      viewModel.initMatch(playerNames: names, totalRounds: 5);

      for (var round = 1; round < 5; round++) {
        final roles = viewModel.state.players.map((p) => p.role).toSet();
        expect(roles.length, equals(4));
        expect(
          roles,
          containsAll([
            GameRole.police,
            GameRole.babu,
            GameRole.chor,
            GameRole.dakat,
          ]),
        );
        viewModel.nextRound();
      }
    });
  });
}
