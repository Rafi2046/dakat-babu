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
    test('Built-in CPDB preset provides expected default labels', () {
      final classic = RolePresetModel.classic;
      expect(classic.id, 'chor_police_dakat_babu');
      expect(classic.getLabel(GameRole.police), 'Police');
      expect(classic.getLabel(GameRole.babu), 'Babu');
      expect(classic.getLabel(GameRole.chor), 'Chor');
      expect(classic.getLabel(GameRole.dakat), 'Dakat');

      final cpdb = RolePresetModel.chorPoliceDakatBabu;
      expect(cpdb.id, 'chor_police_dakat_babu');
      expect(cpdb.getLabel(GameRole.police), 'Police');
      expect(cpdb.getLabel(GameRole.babu), 'Babu');
    });

    test('Custom role labels can be serialized and deserialized', () {
      final customPreset = RolePresetModel(
        id: 'custom',
        name: 'Custom Detective',
        description: 'Detective mystery theme',
        roleLabels: {
          GameRole.police: 'Sheriff',
          GameRole.babu: 'Judge',
          GameRole.chor: 'Outlaw',
          GameRole.dakat: 'Decoy',
        },
      );

      final json = customPreset.toLabelsJson();
      expect(json['babu'], 'Judge');
      expect(json['chor'], 'Outlaw');

      final reconstructed = RolePresetModel.fromJson(
        id: customPreset.id,
        name: customPreset.name,
        description: customPreset.description,
        labelsJson: json,
      );

      expect(reconstructed.getLabel(GameRole.babu), 'Judge');
      expect(reconstructed.getLabel(GameRole.chor), 'Outlaw');
      expect(reconstructed.getLabel(GameRole.dakat), 'Decoy');
      expect(reconstructed.getLabel(GameRole.police), 'Sheriff');
    });

    test('RoomModel getLabelForRole respects custom labels and preset fallback', () {
      final roomWithPreset = RoomModel(
        id: 'r_1',
        roomCode: 'PRESET',
        hostId: 'h_1',
        rolePreset: 'chor_police_dakat_babu',
        createdAt: DateTime.now(),
      );

      expect(roomWithPreset.getLabelForRole(GameRole.babu), 'Babu');
      expect(roomWithPreset.getLabelForRole(GameRole.chor), 'Chor');

      final roomWithCustomLabels = RoomModel(
        id: 'r_2',
        roomCode: 'CUSTOM',
        hostId: 'h_2',
        rolePreset: 'chor_police_dakat_babu',
        roleLabels: {
          'babu': 'King Arthur',
          'chor': 'Robin Hood',
        },
        createdAt: DateTime.now(),
      );

      expect(roomWithCustomLabels.getLabelForRole(GameRole.babu), 'King Arthur');
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

      expect(
        defaultRoom.getPointsForRole(GameRole.police),
        AppConstants.policeCorrectPoints,
      );
      expect(
        defaultRoom.getPointsForRole(GameRole.babu),
        AppConstants.wrongGuessSuspectPoints,
      );
      expect(
        defaultRoom.getPointsForRole(GameRole.chor),
        AppConstants.wrongGuessSuspectPoints,
      );
      expect(
        defaultRoom.getPointsForRole(GameRole.dakat),
        AppConstants.wrongGuessSuspectPoints,
      );

      final customPointsRoom = RoomModel(
        id: 'r_custom',
        roomCode: 'CUST01',
        hostId: 'h_1',
        rolePoints: {
          'police': 2,
          'babu': 3,
          'chor': 4,
          'dakat': 5,
        },
        createdAt: DateTime.now(),
      );

      expect(customPointsRoom.getPointsForRole(GameRole.police), 2);
      expect(customPointsRoom.getPointsForRole(GameRole.babu), 3);
      expect(customPointsRoom.getPointsForRole(GameRole.chor), 4);
      expect(customPointsRoom.getPointsForRole(GameRole.dakat), 5);
    });
  });

  group('3. Pass & Play 4-player CPDB gameplay', () {
    test('Initializes with exactly 4 players and all CPDB roles', () {
      final vm = PassAndPlayViewModel();
      vm.initMatch(
        playerNames: ['Alice', 'Bob', 'Charlie', 'David'],
        totalRounds: 3,
      );

      expect(vm.state.players.length, 4);
      final roles = vm.state.players.map((p) => p.role).toSet();
      expect(
        roles,
        containsAll([
          GameRole.police,
          GameRole.babu,
          GameRole.chor,
          GameRole.dakat,
        ]),
      );

      // Suspects = everyone except Police (Babu, Chor, Dakat).
      expect(vm.state.suspects.length, 3);
      expect(vm.state.suspects.map((s) => s.role), isNot(contains(GameRole.police)));
    });

    test('Police correctly identifies Chor → Police +1', () {
      final vm = PassAndPlayViewModel();
      vm.initMatch(
        playerNames: ['P1', 'P2', 'P3', 'P4'],
        totalRounds: 1,
      );

      final chor = vm.state.chorPlayer!;
      final police = vm.state.policePlayer!;
      final babu = vm.state.babuPlayer!;

      vm.makeAccusation(chor.id);

      expect(vm.state.isGuessCorrect, isTrue);

      final updatedPolice =
          vm.state.players.firstWhere((p) => p.id == police.id);
      final updatedChor = vm.state.players.firstWhere((p) => p.id == chor.id);
      final updatedBabu = vm.state.players.firstWhere((p) => p.id == babu.id);

      expect(updatedPolice.roundScore, AppConstants.policeCorrectPoints);
      expect(updatedChor.roundScore, 0);
      expect(updatedBabu.roundScore, 0);
    });

    test('Police mistakenly accuses Dakat → Dakat +1', () {
      final vm = PassAndPlayViewModel();
      vm.initMatch(
        playerNames: ['P1', 'P2', 'P3', 'P4'],
        totalRounds: 1,
      );

      final police = vm.state.policePlayer!;
      final dakat = vm.state.players.firstWhere((p) => p.role == GameRole.dakat);
      final chor = vm.state.chorPlayer!;

      vm.makeAccusation(dakat.id);

      expect(vm.state.isGuessCorrect, isFalse);

      final updatedPolice =
          vm.state.players.firstWhere((p) => p.id == police.id);
      final updatedDakat = vm.state.players.firstWhere((p) => p.id == dakat.id);
      final updatedChor = vm.state.players.firstWhere((p) => p.id == chor.id);

      expect(updatedPolice.roundScore, 0);
      expect(updatedDakat.roundScore, AppConstants.wrongGuessSuspectPoints);
      expect(updatedChor.roundScore, 0);
    });
  });

  group('4. Dedicated Scoreboard Ranking & Round History', () {
    test('ScoreboardState ranks players and generates per-round breakdown', () {
      final players = [
        PlayerModel(
          id: 'p1',
          roomCode: 'ROOM1',
          name: 'Feluda',
          score: 2,
          createdAt: DateTime.now(),
        ),
        PlayerModel(
          id: 'p2',
          roomCode: 'ROOM1',
          name: 'Topshe',
          score: 5,
          createdAt: DateTime.now(),
        ),
        PlayerModel(
          id: 'p3',
          roomCode: 'ROOM1',
          name: 'Jatayu',
          score: 1,
          createdAt: DateTime.now(),
        ),
        PlayerModel(
          id: 'p4',
          roomCode: 'ROOM1',
          name: 'Lalmohan',
          score: 0,
          createdAt: DateTime.now(),
        ),
      ];

      final round1 = RoundModel(
        id: 'rnd_1',
        roomCode: 'ROOM1',
        roundNumber: 1,
        babuPlayerId: 'p2',
        policePlayerId: 'p3',
        chorPlayerId: 'p4',
        dakatPlayerId: 'p1',
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

      expect(state.leader?.id, 'p2');
      expect(state.rankedPlayers.first.name, 'Topshe');
      expect(state.rankedPlayers.last.name, 'Lalmohan');

      // Topshe was Babu — no +1 on correct police catch.
      final topsheHistory = state.getPlayerHistory('p2');
      expect(topsheHistory.length, 1);
      expect(topsheHistory.first.role, GameRole.babu);
      expect(topsheHistory.first.pointsEarned, 0);

      // Jatayu was Police and caught Chor → +1.
      final jatayuHistory = state.getPlayerHistory('p3');
      expect(jatayuHistory.length, 1);
      expect(jatayuHistory.first.role, GameRole.police);
      expect(jatayuHistory.first.pointsEarned, AppConstants.policeCorrectPoints);
    });
  });
}
