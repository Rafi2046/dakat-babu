import 'dart:math';

import 'cpdb_scoring.dart';
import 'game_role.dart';
import 'player_view.dart';

/// Pure, authoritative game rules for Chor Police Dakat Babu.
///
/// - Exactly 4 players, one of each role.
/// - Police target = Chor only.
/// - Classic points: Babu 900 · Police 800 · Dakat 600 · Chor 400.
/// - Everyone sees Police + Babu; Chor/Dakat stay hidden until result.
abstract final class GameEngine {
  static const int requiredPlayers = 4;

  /// @Deprecated — use [CpdbScoring] role constants.
  static const int scoreDelta = CpdbScoring.police;

  /// Assigns a unique role to each of exactly four players.
  ///
  /// Shuffles the role deck, then deals one role per player in seating order.
  /// A fresh [random] should be passed each round so consecutive deals differ.
  static RoleAssignment assignRoles(
    List<EnginePlayer> players, {
    Random? random,
  }) {
    if (players.length != requiredPlayers) {
      throw ArgumentError(
        'CPDB requires exactly $requiredPlayers players, got ${players.length}',
      );
    }
    final rng = random ?? Random(DateTime.now().microsecondsSinceEpoch);
    final deck = List<GameRole>.from(GameRole.values)..shuffle(rng);

    final byId = <String, GameRole>{
      for (var i = 0; i < players.length; i++) players[i].id: deck[i],
    };

    String idFor(GameRole role) {
      for (final e in byId.entries) {
        if (e.value == role) return e.key;
      }
      throw StateError('Role $role missing after deal');
    }

    return RoleAssignment(
      policePlayerId: idFor(GameRole.police),
      babuPlayerId: idFor(GameRole.babu),
      chorPlayerId: idFor(GameRole.chor),
      dakatPlayerId: idFor(GameRole.dakat),
    );
  }

  /// Builds a privacy-scoped view for [viewerId]. Never leaks Chor/Dakat IDs.
  static PlayerView buildPlayerView({
    required String viewerId,
    required List<EnginePlayer> players,
    required RoleAssignment assignment,
  }) {
    final myRole = assignment.roleOf(viewerId);
    if (myRole == null) {
      throw ArgumentError('Viewer $viewerId is not in this round');
    }

    final cards = <VisiblePlayerCard>[];
    for (final p in players) {
      if (p.id == viewerId) {
        cards.add(
          VisiblePlayerCard(
            playerId: p.id,
            name: p.name,
            visibleRole: myRole,
            info: VisibleRoleInfo.self,
          ),
        );
        continue;
      }
      final role = assignment.roleOf(p.id)!;
      if (role == GameRole.police || role == GameRole.babu) {
        cards.add(
          VisiblePlayerCard(
            playerId: p.id,
            name: p.name,
            visibleRole: role,
            info: VisibleRoleInfo.known,
          ),
        );
      } else {
        cards.add(
          VisiblePlayerCard(
            playerId: p.id,
            name: p.name,
            visibleRole: null,
            info: VisibleRoleInfo.hidden,
          ),
        );
      }
    }

    final suspectIds = players
        .where((p) => p.id != assignment.policePlayerId)
        .map((p) => p.id)
        .toList(growable: false);

    return PlayerView(
      viewerId: viewerId,
      myRole: myRole,
      players: cards,
      suspectIds: suspectIds,
      policePlayerId: assignment.policePlayerId,
      babuPlayerId: assignment.babuPlayerId,
    );
  }

  /// Resolves a Police guess with classic childhood scoring.
  ///
  /// - Babu always +900.
  /// - Correct (Chor): Police +800, Chor +0, Dakat +600.
  /// - Wrong: Police +0, Chor +400, Dakat +600.
  static GuessResult resolveGuess({
    required List<EnginePlayer> players,
    required RoleAssignment assignment,
    required String suspectPlayerId,
  }) {
    final policeId = assignment.policePlayerId;
    final babuId = assignment.babuPlayerId;
    final chorId = assignment.chorPlayerId;
    final dakatId = assignment.dakatPlayerId;

    if (suspectPlayerId == policeId) {
      throw ArgumentError('Police cannot select themselves');
    }
    if (!players.any((p) => p.id == suspectPlayerId)) {
      throw ArgumentError('Suspect not in this game');
    }

    final isCorrect = suspectPlayerId == chorId;

    final roundDeltas = <String, int>{
      babuId: CpdbScoring.babu,
      dakatId: CpdbScoring.dakat,
      policeId: isCorrect ? CpdbScoring.police : 0,
      chorId: isCorrect ? 0 : CpdbScoring.chor,
    };

    final scoresAfter = <String, int>{
      for (final p in players) p.id: p.score + (roundDeltas[p.id] ?? 0),
    };

    final recipientId = isCorrect ? policeId : chorId;
    final recipientDelta = roundDeltas[recipientId] ?? 0;

    return GuessResult(
      isCorrect: isCorrect,
      policePlayerId: policeId,
      suspectPlayerId: suspectPlayerId,
      chorPlayerId: chorId,
      babuPlayerId: babuId,
      dakatPlayerId: dakatId,
      scoreRecipientId: recipientId,
      scoreDelta: recipientDelta,
      roundDeltas: roundDeltas,
      scoresAfter: scoresAfter,
    );
  }

  /// Applies [result] score deltas onto players; increments police stats.
  static List<EnginePlayer> applyGuessResult(
    List<EnginePlayer> players,
    GuessResult result,
  ) {
    return players.map((p) {
      final newScore = result.scoresAfter[p.id] ?? p.score;
      var correct = p.correctGuesses;
      var tags = p.policeTags;
      if (result.isCorrect && p.id == result.policePlayerId) {
        correct += 1;
        tags += 1;
      }
      return p.copyWith(
        score: newScore,
        correctGuesses: correct,
        policeTags: tags,
      );
    }).toList(growable: false);
  }

  /// Round 1 roller = game lead; later rounds = previous round's Police.
  static String rollerForRound({
    required int roundNumber,
    required String gameLeadId,
    required String? previousPoliceId,
  }) {
    if (roundNumber <= 1) return gameLeadId;
    return previousPoliceId ?? gameLeadId;
  }

  /// Whether the match is complete after finishing [completedRounds].
  static bool isMatchComplete({
    required int completedRounds,
    required int maxRounds,
  }) {
    return completedRounds >= maxRounds;
  }
}
