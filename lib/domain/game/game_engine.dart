import 'dart:math';

import 'game_role.dart';
import 'player_view.dart';

/// Pure, authoritative game rules for Chor Police Dakat Babu (1A / 2A).
///
/// - Exactly 4 players, one of each role.
/// - Police target = Chor only.
/// - Correct → Police +1; Wrong → selected suspect +1.
/// - Everyone sees Police + Babu; Chor/Dakat stay hidden until result.
abstract final class GameEngine {
  static const int requiredPlayers = 4;
  static const int scoreDelta = 1;

  /// Assigns a unique role to each of exactly four players.
  static RoleAssignment assignRoles(
    List<EnginePlayer> players, {
    Random? random,
  }) {
    if (players.length != requiredPlayers) {
      throw ArgumentError(
        'CPDB requires exactly $requiredPlayers players, got ${players.length}',
      );
    }
    final ids = players.map((p) => p.id).toList();
    final rng = random ?? Random();
    ids.shuffle(rng);

    return RoleAssignment(
      policePlayerId: ids[0],
      babuPlayerId: ids[1],
      chorPlayerId: ids[2],
      dakatPlayerId: ids[3],
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

    // Suspects = everyone except Police (Babu visible but selectable).
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

  /// Resolves a Police guess. Authority-only; never trust clients.
  static GuessResult resolveGuess({
    required List<EnginePlayer> players,
    required RoleAssignment assignment,
    required String suspectPlayerId,
  }) {
    final policeId = assignment.policePlayerId;
    final chorId = assignment.chorPlayerId;

    if (suspectPlayerId == policeId) {
      throw ArgumentError('Police cannot select themselves');
    }
    if (!players.any((p) => p.id == suspectPlayerId)) {
      throw ArgumentError('Suspect not in this game');
    }

    final scores = {for (final p in players) p.id: p.score};
    final isCorrect = suspectPlayerId == chorId;
    final recipientId = isCorrect ? policeId : suspectPlayerId;
    scores[recipientId] = (scores[recipientId] ?? 0) + scoreDelta;

    return GuessResult(
      isCorrect: isCorrect,
      policePlayerId: policeId,
      suspectPlayerId: suspectPlayerId,
      chorPlayerId: chorId,
      scoreRecipientId: recipientId,
      scoreDelta: scoreDelta,
      scoresAfter: scores,
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
