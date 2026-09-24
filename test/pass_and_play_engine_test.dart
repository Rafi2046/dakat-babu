import 'package:flutter_test/flutter_test.dart';

import 'package:dakat_babu/presentation/viewmodels/pass_and_play_viewmodel.dart';
import 'package:dakat_babu/domain/game/game_role.dart';

void main() {
  test('Pass & Pass full match awards +1 and ends', () {
    final vm = PassAndPlayViewModel(random: null);
    // Use fixed Random via re-init — assign then force accusation path
    vm.initMatch(
      playerNames: const ['A', 'B', 'C', 'D'],
      totalRounds: 2,
    );

    expect(vm.state.players.length, 4);
    expect(vm.state.assignment, isNotNull);
    expect(
      vm.state.players.map((p) => p.role).toSet(),
      GameRole.values.toSet(),
    );

    // Peek all
    for (var i = 0; i < 4; i++) {
      vm.readyToPeek();
      vm.toggleCardReveal();
      vm.finishPeekingCurrentPlayer();
    }
    expect(vm.state.stage, PassAndPlayStage.handToPolice);

    vm.beginPoliceInterrogation();
    final chorId = vm.state.assignment!.chorPlayerId;
    vm.makeAccusation(chorId);
    expect(vm.state.isGuessCorrect, isTrue);
    expect(vm.state.policePlayer!.totalScore, 1);

    vm.nextRound();
    expect(vm.state.currentRound, 2);

    // Finish second round wrong guess
    for (var i = 0; i < 4; i++) {
      vm.readyToPeek();
      vm.finishPeekingCurrentPlayer();
    }
    vm.beginPoliceInterrogation();
    final dakatId = vm.state.assignment!.dakatPlayerId;
    vm.makeAccusation(dakatId);
    expect(vm.state.isGuessCorrect, isFalse);

    vm.nextRound();
    expect(vm.state.stage, PassAndPlayStage.matchOver);
  });
}
