import 'package:dakat_babu/core/constants/app_constants.dart';
import 'package:dakat_babu/data/models/player_model.dart';
import 'package:dakat_babu/data/models/role_preset_model.dart';
import 'package:dakat_babu/data/models/room_model.dart';
import 'package:dakat_babu/data/models/round_model.dart';
import 'package:dakat_babu/presentation/viewmodels/pass_and_play_viewmodel.dart';
import 'package:dakat_babu/presentation/viewmodels/scoreboard_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('1. RolePresetModel & Custom Role Labels', () {
    test('Built-in presets provide expected default labels', () {
      final classic = RolePresetModel.classic;
      expect(classic.id, 'classic');
      expect(classic.getLabel(GameRole.raja), 'Raja');
      expect(classic.getLabel(GameRole.mantri), 'Mantri');
      expect(classic.getLabel(GameRole.police), 'Police');
      expect(classic.getLabel(GameRole.chor), 'Chor');
      expect(classic.getLabel(GameRole.chintaykari), 'Chintaykari');
      expect(classic.getLabel(GameRole.batpar), 'Batpar');

      final chorPoliceDakatBabu = RolePresetModel.chorPoliceDakatBabu;
      expect(chorPoliceDakatBabu.id, 'chor_police_dakat_babu');
      expect(chorPoliceDakatBabu.getLabel(GameRole.raja), 'Babu');
      expect(chorPoliceDakatBabu.getLabel(GameRole.mantri), 'Dewan');
      expect(chorPoliceDakatBabu.getLabel(GameRole.police), 'Police');
      expect(chorPoliceDakatBabu.getLabel(GameRole.chor), 'Dakat');
      expect(chorPoliceDakatBabu.getLabel(GameRole.chintaykari), 'Chintaykari');
      expect(chorPoliceDakatBabu.getLabel(GameRole.batpar), 'Batpar');
    });

    test('Custom role labels can be serialized and deserialized', () {
      final customPreset = RolePresetModel(
        id: 'custom',
        name: 'Custom Detective',
        description: 'Detective mystery theme',
        roleLabels: {
          GameRole.raja: 'Judge',
          GameRole.mantri: 'Lawyer',
          GameRole.police: 'Sheriff',
          GameRole.chor: 'Outlaw',
          GameRole.chintaykari: 'Pickpocket',
          GameRole.batpar: 'Con Artist',
        },
      );

      final json = customPreset.toLabelsJson();
      expect(json['raja'], 'Judge');
      expect(json['chor'], 'Outlaw');

      final reconstructed = RolePresetModel.fromJson(
        id: customPreset.id,
        name: customPreset.name,
        description: customPreset.description,
        labelsJson: json,
      );

      expect(reconstructed.getLabel(GameRole.raja), 'Judge');
      expect(reconstructed.getLabel(GameRole.chor), 'Outlaw');
      expect(reconstructed.getLabel(GameRole.chintaykari), 'Pickpocket');
      expect(reconstructed.getLabel(GameRole.batpar), 'Con Artist');
    });

    test('RoomModel getLabelForRole respects custom labels and preset fallback', () {
      final roomWithPreset = RoomModel(
        id: 'r_1',
        roomCode: 'PRESET',
        hostId: 'h_1',
        rolePreset: 'chor_police_dakat_babu',
        createdAt: DateTime.now(),
      );

      expect(roomWithPreset.getLabelForRole(GameRole.raja), 'Babu');
      expect(roomWithPreset.getLabelForRole(GameRole.chor), 'Dakat');

      final roomWithCustomLabels = RoomModel(
        id: 'r_2',
        roomCode: 'CUSTOM',
        hostId: 'h_2',
        rolePreset: 'classic',
        roleLabels: {
          'raja': 'King Arthur',
          'chor': 'Robin Hood',
        },
        createdAt: DateTime.now(),
      );

      expect(roomWithCustomLabels.getLabelForRole(GameRole.raja), 'King Arthur');
      expect(roomWithCustomLabels.getLabelForRole(GameRole.chor), 'Robin Hood');
      expect(roomWithCustomLabels.getLabelForRole(GameRole.police), 'Police');
    });
  });

  group('2. Customizable Scoring System', () {
    test('RoomModel getPointsForRole returns custom points when configured', () {
      final defaultRoom = RoomModel(
        id: 'r_def',
        roomCode: 'DEF001',
        hostId: 'h_1',
        createdAt: DateTime.now(),
      );

      expect(defaultRoom.getPointsForRole(GameRole.raja), 1000);
      expect(defaultRoom.getPointsForRole(GameRole.mantri), 800);
      expect(defaultRoom.getPointsForRole(GameRole.police), 500);
      expect(defaultRoom.getPointsForRole(GameRole.chor), 500);
      expect(defaultRoom.getPointsForRole(GameRole.chintaykari), 500);
      expect(defaultRoom.getPointsForRole(GameRole.batpar), 300);

      final customPointsRoom = RoomModel(
        id: 'r_custom',
        roomCode: 'CUST01',
        hostId: 'h_1',
        rolePoints: {
          'raja': 2000,
          'mantri': 1500,
          'police': 1000,
          'chor': 1000,
          'chintaykari': 750,
          'batpar': 600,
        },
        createdAt: DateTime.now(),
      );

      expect(customPointsRoom.getPointsForRole(GameRole.raja), 2000);
      expect(customPointsRoom.getPointsForRole(GameRole.mantri), 1500);
      expect(customPointsRoom.getPointsForRole(GameRole.police), 1000);
      expect(customPointsRoom.getPointsForRole(GameRole.chor), 1000);
      expect(customPointsRoom.getPointsForRole(GameRole.chintaykari), 750);
      expect(customPointsRoom.getPointsForRole(GameRole.batpar), 600);
    });
  });

  group('3. Extended 5-6 Player Pass & Play Gameplay', () {
    test('Initializes with 5 players and assigns Chintaykari', () {
      final vm = PassAndPlayViewModel();
      vm.initMatch(
        playerNames: ['Alice', 'Bob', 'Charlie', 'David', 'Eva'],
        totalRounds: 3,
      );

      expect(vm.state.players.length, 5);
      final roles = vm.state.players.map((p) => p.role).toSet();
      expect(roles, containsAll([
        GameRole.raja,
        GameRole.mantri,
        GameRole.police,
        GameRole.chor,
        GameRole.chintaykari,
      ]));

      // Suspects: all non-raja, non-police players (Mantri + Chor + Chintaykari)
      expect(vm.state.suspects.length, 3);
      final suspectRoles = vm.state.suspects.map((s) => s.role).toSet();
      expect(suspectRoles, containsAll([
        GameRole.mantri,
        GameRole.chor,
        GameRole.chintaykari,
      ]));
    });

    test('Initializes with 6 players and assigns Chintaykari and Batpar', () {
      final vm = PassAndPlayViewModel();
      vm.initMatch(
        playerNames: ['P1', 'P2', 'P3', 'P4', 'P5', 'P6'],
        totalRounds: 3,
      );

      expect(vm.state.players.length, 6);
      final roles = vm.state.players.map((p) => p.role).toSet();
      expect(roles, containsAll([
        GameRole.raja,
        GameRole.mantri,
        GameRole.police,
        GameRole.chor,
        GameRole.chintaykari,
        GameRole.batpar,
      ]));

      // Suspects: 4 players (Mantri, Chor, Chintaykari, Batpar)
      expect(vm.state.suspects.length, 4);
    });

    test('5-Player round: Police correctly identifies Chor among suspects', () {
      final vm = PassAndPlayViewModel();
      vm.initMatch(
        playerNames: ['P1', 'P2', 'P3', 'P4', 'P5'],
        totalRounds: 1,
      );

      final chor = vm.state.chorPlayer!;
      final police = vm.state.policePlayer!;
      final chintaykari = vm.state.players.firstWhere((p) => p.role == GameRole.chintaykari);

      // Police accuses the actual Chor
      vm.makeAccusation(chor.id);

      expect(vm.state.isGuessCorrect, isTrue);

      // Verify points
      final updatedChor = vm.state.players.firstWhere((p) => p.id == chor.id);
      final updatedPolice = vm.state.players.firstWhere((p) => p.id == police.id);
      final updatedChintaykari = vm.state.players.firstWhere((p) => p.id == chintaykari.id);

      expect(updatedPolice.roundScore, AppConstants.policeCorrectPoints);
      expect(updatedChor.roundScore, AppConstants.chorCaughtPoints); // 0
      expect(updatedChintaykari.roundScore, AppConstants.chintaykariDefaultPoints); // 500
    });

    test('6-Player round: Police mistakenly accuses Batpar instead of Chor', () {
      final vm = PassAndPlayViewModel();
      vm.initMatch(
        playerNames: ['P1', 'P2', 'P3', 'P4', 'P5', 'P6'],
        totalRounds: 1,
      );

      final chor = vm.state.chorPlayer!;
      final police = vm.state.policePlayer!;
      final batpar = vm.state.players.firstWhere((p) => p.role == GameRole.batpar);
      final chintaykari = vm.state.players.firstWhere((p) => p.role == GameRole.chintaykari);

      // Police mistakenly accuses Batpar
      vm.makeAccusation(batpar.id);

      expect(vm.state.isGuessCorrect, isFalse);

      final updatedChor = vm.state.players.firstWhere((p) => p.id == chor.id);
      final updatedPolice = vm.state.players.firstWhere((p) => p.id == police.id);
      final updatedBatpar = vm.state.players.firstWhere((p) => p.id == batpar.id);
      final updatedChintaykari = vm.state.players.firstWhere((p) => p.id == chintaykari.id);

      expect(updatedPolice.roundScore, AppConstants.policeWrongPoints); // 0
      expect(updatedChor.roundScore, AppConstants.chorSuccessPoints); // 500
      expect(updatedBatpar.roundScore, AppConstants.batparDefaultPoints); // 300
      expect(updatedChintaykari.roundScore, AppConstants.chintaykariDefaultPoints); // 500
    });
  });

  group('4. Dedicated Scoreboard Ranking & Round History', () {
    test('ScoreboardState ranks players and generates per-round breakdown', () {
      final players = [
        PlayerModel(id: 'p1', roomCode: 'ROOM1', name: 'Feluda', score: 1800, createdAt: DateTime.now()),
        PlayerModel(id: 'p2', roomCode: 'ROOM1', name: 'Topshe', score: 2500, createdAt: DateTime.now()),
        PlayerModel(id: 'p3', roomCode: 'ROOM1', name: 'Jatayu', score: 1000, createdAt: DateTime.now()),
      ];

      final round1 = RoundModel(
        id: 'rnd_1',
        roomCode: 'ROOM1',
        roundNumber: 1,
        rajaPlayerId: 'p2',
        mantriPlayerId: 'p1',
        policePlayerId: 'p3',
        chorPlayerId: 'p4',
        policeGuessPlayerId: 'p4',
        isGuessCorrect: true,
        status: RoundStatus.completed,
        createdAt: DateTime.now(),
      );

      final state = ScoreboardState(
        players: players,
        rounds: [round1],
        isLoading: false,
      );

      // Leader should be Topshe (score: 2500)
      expect(state.leader?.id, 'p2');
      expect(state.rankedPlayers.first.name, 'Topshe');
      expect(state.rankedPlayers.last.name, 'Jatayu');

      // Check Topshe's round 1 history (was Raja -> 1000 pts)
      final topsheHistory = state.getPlayerHistory('p2');
      expect(topsheHistory.length, 1);
      expect(topsheHistory.first.role, GameRole.raja);
      expect(topsheHistory.first.pointsEarned, 1000);

      // Check Feluda's round 1 history (was Mantri -> 800 pts)
      final feludaHistory = state.getPlayerHistory('p1');
      expect(feludaHistory.length, 1);
      expect(feludaHistory.first.role, GameRole.mantri);
      expect(feludaHistory.first.pointsEarned, 800);
    });
  });
}
