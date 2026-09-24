import 'game_role.dart';

/// Lightweight player identity used by the pure game engine.
class EnginePlayer {
  final String id;
  final String name;
  final int score;
  final int correctGuesses;
  final int policeTags;

  const EnginePlayer({
    required this.id,
    required this.name,
    this.score = 0,
    this.correctGuesses = 0,
    this.policeTags = 0,
  });

  EnginePlayer copyWith({
    String? id,
    String? name,
    int? score,
    int? correctGuesses,
    int? policeTags,
  }) {
    return EnginePlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      score: score ?? this.score,
      correctGuesses: correctGuesses ?? this.correctGuesses,
      policeTags: policeTags ?? this.policeTags,
    );
  }
}

/// Full private role assignment for a round (authority-only).
class RoleAssignment {
  final String policePlayerId;
  final String babuPlayerId;
  final String chorPlayerId;
  final String dakatPlayerId;

  const RoleAssignment({
    required this.policePlayerId,
    required this.babuPlayerId,
    required this.chorPlayerId,
    required this.dakatPlayerId,
  });

  Map<String, GameRole> get byPlayerId => {
        policePlayerId: GameRole.police,
        babuPlayerId: GameRole.babu,
        chorPlayerId: GameRole.chor,
        dakatPlayerId: GameRole.dakat,
      };

  GameRole? roleOf(String playerId) => byPlayerId[playerId];

  String playerIdFor(GameRole role) {
    switch (role) {
      case GameRole.police:
        return policePlayerId;
      case GameRole.babu:
        return babuPlayerId;
      case GameRole.chor:
        return chorPlayerId;
      case GameRole.dakat:
        return dakatPlayerId;
    }
  }
}

/// Public visibility of another player from a viewer's perspective.
enum VisibleRoleInfo {
  /// Role is known (Police or Babu).
  known,

  /// Role is hidden (Chor or Dakat, or unknown).
  hidden,

  /// This is the viewer themselves.
  self,
}

/// Per-player public card shown in the game room.
class VisiblePlayerCard {
  final String playerId;
  final String name;
  final GameRole? visibleRole;
  final VisibleRoleInfo info;

  const VisiblePlayerCard({
    required this.playerId,
    required this.name,
    required this.info,
    this.visibleRole,
  });
}

/// Privacy-scoped view for a single client.
class PlayerView {
  final String viewerId;
  final GameRole myRole;
  final List<VisiblePlayerCard> players;
  final List<String> suspectIds;
  final String policePlayerId;
  final String babuPlayerId;

  const PlayerView({
    required this.viewerId,
    required this.myRole,
    required this.players,
    required this.suspectIds,
    required this.policePlayerId,
    required this.babuPlayerId,
  });
}

/// Outcome of a Police guess resolution.
class GuessResult {
  final bool isCorrect;
  final String policePlayerId;
  final String suspectPlayerId;
  final String chorPlayerId;
  final String? scoreRecipientId;
  final int scoreDelta;
  final Map<String, int> scoresAfter;

  const GuessResult({
    required this.isCorrect,
    required this.policePlayerId,
    required this.suspectPlayerId,
    required this.chorPlayerId,
    required this.scoreRecipientId,
    required this.scoreDelta,
    required this.scoresAfter,
  });
}
