import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:dakat_babu/domain/game/game_engine.dart';
import 'package:dakat_babu/domain/game/game_role.dart';
import 'package:dakat_babu/domain/game/player_view.dart';

void main() {
  final players = [
    const EnginePlayer(id: 'p1', name: 'Arman'),
    const EnginePlayer(id: 'p2', name: 'Tanvir'),
    const EnginePlayer(id: 'p3', name: 'Sami'),
    const EnginePlayer(id: 'p4', name: 'Rafi'),
  ];

  group('GameEngine.assignRoles', () {
    test('assigns exactly one of each role', () {
      final a = GameEngine.assignRoles(players, random: Random(42));
      final roles = {
        a.policePlayerId,
        a.babuPlayerId,
        a.chorPlayerId,
        a.dakatPlayerId,
      };
      expect(roles.length, 4);
      expect(a.byPlayerId.values.toSet(), GameRole.values.toSet());
    });

    test('rejects non-4 player counts', () {
      expect(
        () => GameEngine.assignRoles(players.take(3).toList()),
        throwsArgumentError,
      );
    });
  });

  group('GameEngine.buildPlayerView privacy', () {
    const assignment = RoleAssignment(
      policePlayerId: 'p1',
      babuPlayerId: 'p2',
      chorPlayerId: 'p3',
      dakatPlayerId: 'p4',
    );

    test('police sees babu known and chor/dakat hidden', () {
      final view = GameEngine.buildPlayerView(
        viewerId: 'p1',
        players: players,
        assignment: assignment,
      );
      expect(view.myRole, GameRole.police);
      expect(view.suspectIds, ['p2', 'p3', 'p4']);
      final byId = {for (final c in view.players) c.playerId: c};
      expect(byId['p2']!.visibleRole, GameRole.babu);
      expect(byId['p3']!.info, VisibleRoleInfo.hidden);
      expect(byId['p3']!.visibleRole, isNull);
      expect(byId['p4']!.info, VisibleRoleInfo.hidden);
    });

    test('chor view never leaks other hidden roles', () {
      final view = GameEngine.buildPlayerView(
        viewerId: 'p3',
        players: players,
        assignment: assignment,
      );
      expect(view.myRole, GameRole.chor);
      final known = view.players
          .where((c) => c.info == VisibleRoleInfo.known)
          .map((c) => c.visibleRole)
          .toSet();
      expect(known, {GameRole.police, GameRole.babu});
      expect(
        view.players.any(
          (c) =>
              c.playerId != 'p3' &&
              (c.visibleRole == GameRole.chor ||
                  c.visibleRole == GameRole.dakat),
        ),
        isFalse,
      );
    });
  });

  group('GameEngine.resolveGuess 1A scoring', () {
    const assignment = RoleAssignment(
      policePlayerId: 'p1',
      babuPlayerId: 'p2',
      chorPlayerId: 'p3',
      dakatPlayerId: 'p4',
    );

    test('correct chor guess awards police +1', () {
      final result = GameEngine.resolveGuess(
        players: players,
        assignment: assignment,
        suspectPlayerId: 'p3',
      );
      expect(result.isCorrect, isTrue);
      expect(result.scoresAfter['p1'], 1);
      expect(result.scoresAfter['p3'], 0);
    });

    test('wrong dakat guess awards suspect +1', () {
      final result = GameEngine.resolveGuess(
        players: players,
        assignment: assignment,
        suspectPlayerId: 'p4',
      );
      expect(result.isCorrect, isFalse);
      expect(result.scoresAfter['p1'], 0);
      expect(result.scoresAfter['p4'], 1);
    });

    test('wrong babu guess awards babu +1', () {
      final result = GameEngine.resolveGuess(
        players: players,
        assignment: assignment,
        suspectPlayerId: 'p2',
      );
      expect(result.isCorrect, isFalse);
      expect(result.scoresAfter['p2'], 1);
    });

    test('applyGuessResult increments police tags on correct', () {
      final result = GameEngine.resolveGuess(
        players: players,
        assignment: assignment,
        suspectPlayerId: 'p3',
      );
      final updated = GameEngine.applyGuessResult(players, result);
      final police = updated.firstWhere((p) => p.id == 'p1');
      expect(police.score, 1);
      expect(police.correctGuesses, 1);
      expect(police.policeTags, 1);
    });
  });

  group('GameEngine roller + match complete', () {
    test('round 1 uses game lead', () {
      expect(
        GameEngine.rollerForRound(
          roundNumber: 1,
          gameLeadId: 'host',
          previousPoliceId: 'p1',
        ),
        'host',
      );
    });

    test('later rounds use previous police', () {
      expect(
        GameEngine.rollerForRound(
          roundNumber: 2,
          gameLeadId: 'host',
          previousPoliceId: 'p1',
        ),
        'p1',
      );
    });

    test('match completes at maxRounds', () {
      expect(
        GameEngine.isMatchComplete(completedRounds: 5, maxRounds: 5),
        isTrue,
      );
      expect(
        GameEngine.isMatchComplete(completedRounds: 4, maxRounds: 5),
        isFalse,
      );
    });
  });
}
