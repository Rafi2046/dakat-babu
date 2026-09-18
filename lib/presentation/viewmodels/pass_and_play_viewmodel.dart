import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';

/// Single player representation in Pass & Play mode.
class PassAndPlayPlayer {
  final String id;
  final String name;
  final GameRole? role;
  final int totalScore;
  final int roundScore;

  const PassAndPlayPlayer({
    required this.id,
    required this.name,
    this.role,
    this.totalScore = 0,
    this.roundScore = 0,
  });

  PassAndPlayPlayer copyWith({
    String? id,
    String? name,
    GameRole? role,
    int? totalScore,
    int? roundScore,
  }) {
    return PassAndPlayPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      totalScore: totalScore ?? this.totalScore,
      roundScore: roundScore ?? this.roundScore,
    );
  }
}

/// Stages of a Pass & Play local round.
enum PassAndPlayStage {
  /// Prompting to pass device to current peeking player.
  passToPlayer,

  /// Player peeking their secret role card.
  peekRole,

  /// Prompting to hand device to the Police.
  handToPolice,

  /// Police interrogating suspects and tapping an accusation.
  policeAccusing,

  /// Reveal outcome banner, points awarded, and cumulative rankings.
  roundResults,

  /// Match concluded all rounds; grand winner podium.
  matchOver,
}

/// State of the Pass & Play match.
class PassAndPlayState {
  final List<PassAndPlayPlayer> players;
  final int currentRound;
  final int totalRounds;
  final int currentPeekIndex;
  final bool isCardRevealed;
  final PassAndPlayStage stage;
  final String? accusedPlayerId;
  final bool? isGuessCorrect;

  const PassAndPlayState({
    this.players = const [],
    this.currentRound = 1,
    this.totalRounds = 5,
    this.currentPeekIndex = 0,
    this.isCardRevealed = false,
    this.stage = PassAndPlayStage.passToPlayer,
    this.accusedPlayerId,
    this.isGuessCorrect,
  });

  /// Player currently slated to hold the phone and peek.
  PassAndPlayPlayer? get currentPeekingPlayer {
    if (players.isEmpty || currentPeekIndex >= players.length) return null;
    return players[currentPeekIndex];
  }

  /// The player assigned as Raja in the current round.
  PassAndPlayPlayer? get rajaPlayer {
    return players.cast<PassAndPlayPlayer?>().firstWhere(
          (p) => p?.role == GameRole.raja,
          orElse: () => null,
        );
  }

  /// The player assigned as Police in the current round.
  PassAndPlayPlayer? get policePlayer {
    return players.cast<PassAndPlayPlayer?>().firstWhere(
          (p) => p?.role == GameRole.police,
          orElse: () => null,
        );
  }

  /// The player assigned as Chor in the current round.
  PassAndPlayPlayer? get chorPlayer {
    return players.cast<PassAndPlayPlayer?>().firstWhere(
          (p) => p?.role == GameRole.chor,
          orElse: () => null,
        );
  }

  /// The player assigned as Mantri in the current round.
  PassAndPlayPlayer? get mantriPlayer {
    return players.cast<PassAndPlayPlayer?>().firstWhere(
          (p) => p?.role == GameRole.mantri,
          orElse: () => null,
        );
  }

  /// The accused player chosen by Police.
  PassAndPlayPlayer? get accusedPlayer {
    return players.cast<PassAndPlayPlayer?>().firstWhere(
          (p) => p?.id == accusedPlayerId,
          orElse: () => null,
        );
  }

  /// The suspects available for Police to interrogate (Mantri and Chor).
  List<PassAndPlayPlayer> get suspects {
    return players
        .where((p) => p.role != GameRole.police && p.role != GameRole.raja)
        .toList();
  }

  /// Leaderboard ordered by descending total score.
  List<PassAndPlayPlayer> get leaderboard {
    final list = List<PassAndPlayPlayer>.from(players);
    list.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return list;
  }

  /// Whether current match has reached its final round.
  bool get isLastRound => currentRound >= totalRounds;

  PassAndPlayState copyWith({
    List<PassAndPlayPlayer>? players,
    int? currentRound,
    int? totalRounds,
    int? currentPeekIndex,
    bool? isCardRevealed,
    PassAndPlayStage? stage,
    String? accusedPlayerId,
    bool? isGuessCorrect,
    bool clearAccusation = false,
  }) {
    return PassAndPlayState(
      players: players ?? this.players,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      currentPeekIndex: currentPeekIndex ?? this.currentPeekIndex,
      isCardRevealed: isCardRevealed ?? this.isCardRevealed,
      stage: stage ?? this.stage,
      accusedPlayerId: clearAccusation ? null : (accusedPlayerId ?? this.accusedPlayerId),
      isGuessCorrect: clearAccusation ? null : (isGuessCorrect ?? this.isGuessCorrect),
    );
  }
}

/// ViewModel coordinating the Pass & Play single-device workflow.
class PassAndPlayViewModel extends StateNotifier<PassAndPlayState> {
  final Random _random;

  PassAndPlayViewModel({Random? random})
      : _random = random ?? Random.secure(),
        super(const PassAndPlayState());

  /// Initializes a new match with player names and total rounds.
  void initMatch({
    required List<String> playerNames,
    int totalRounds = AppConstants.defaultTotalRounds,
  }) {
    final players = List.generate(
      playerNames.length,
      (i) => PassAndPlayPlayer(
        id: 'p_${i + 1}',
        name: playerNames[i].trim().isEmpty ? 'Player ${i + 1}' : playerNames[i].trim(),
        totalScore: 0,
        roundScore: 0,
      ),
    );

    state = PassAndPlayState(
      players: players,
      currentRound: 1,
      totalRounds: totalRounds,
      stage: PassAndPlayStage.passToPlayer,
    );

    _assignRolesAndStartRound();
  }

  /// Shuffles roles and assigns 1 each to the players for the new round.
  /// Guarantees that no player gets the exact same role as their previous round.
  void _assignRolesAndStartRound() {
    final prevRoles = state.players.map((p) => p.role).toList();
    final hasPrevRoles = prevRoles.every((r) => r != null);
    final count = state.players.length;

    final allRoles = [
      GameRole.raja,
      GameRole.mantri,
      GameRole.police,
      GameRole.chor,
      if (count >= 5) GameRole.chintaykari,
      if (count >= 6) GameRole.batpar,
    ];

    List<GameRole> roles;
    int attempts = 0;
    do {
      roles = List<GameRole>.from(allRoles)..shuffle(_random);
      attempts++;
    } while (hasPrevRoles &&
        attempts < 50 &&
        List.generate(count, (i) => roles[i] == prevRoles[i]).any((same) => same));

    final updatedPlayers = <PassAndPlayPlayer>[];
    for (var i = 0; i < state.players.length; i++) {
      updatedPlayers.add(
        state.players[i].copyWith(
          role: roles[i],
          roundScore: 0,
        ),
      );
    }

    state = state.copyWith(
      players: updatedPlayers,
      currentPeekIndex: 0,
      isCardRevealed: false,
      stage: PassAndPlayStage.passToPlayer,
      clearAccusation: true,
    );
  }

  /// Current player confirms they have the phone and are ready to peek.
  void readyToPeek() {
    state = state.copyWith(
      stage: PassAndPlayStage.peekRole,
      isCardRevealed: false,
    );
  }

  /// Toggles the secret 3D flip card unmasking.
  void toggleCardReveal() {
    state = state.copyWith(isCardRevealed: !state.isCardRevealed);
  }

  /// Current player has finished peeking; hide card and advance to next player or Police.
  void finishPeekingCurrentPlayer() {
    final nextIndex = state.currentPeekIndex + 1;
    if (nextIndex < state.players.length) {
      // Advance to next player's turn to hold the phone
      state = state.copyWith(
        currentPeekIndex: nextIndex,
        isCardRevealed: false,
        stage: PassAndPlayStage.passToPlayer,
      );
    } else {
      // All players have peeked! Hand phone to the Police
      state = state.copyWith(
        isCardRevealed: false,
        stage: PassAndPlayStage.handToPolice,
      );
    }
  }

  /// Police confirms receipt of the phone; opens interrogation screen.
  void beginPoliceInterrogation() {
    state = state.copyWith(stage: PassAndPlayStage.policeAccusing);
  }

  /// Police selects their accused suspect.
  void makeAccusation(String accusedPlayerId) {
    final accused = state.players.firstWhere((p) => p.id == accusedPlayerId);
    final isCorrect = accused.role == GameRole.chor;

    final updatedPlayers = state.players.map((p) {
      int roundScore = 0;
      switch (p.role) {
        case GameRole.raja:
          roundScore = AppConstants.rajaPoints;
          break;
        case GameRole.mantri:
          roundScore = AppConstants.mantriPoints;
          break;
        case GameRole.police:
          roundScore = isCorrect
              ? AppConstants.policeCorrectPoints
              : AppConstants.policeWrongPoints;
          break;
        case GameRole.chor:
          roundScore = isCorrect
              ? AppConstants.chorCaughtPoints
              : AppConstants.chorSuccessPoints;
          break;
        case GameRole.chintaykari:
          roundScore = AppConstants.chintaykariDefaultPoints;
          break;
        case GameRole.batpar:
          roundScore = AppConstants.batparDefaultPoints;
          break;
        case null:
          roundScore = 0;
          break;
      }

      return p.copyWith(
        roundScore: roundScore,
        totalScore: p.totalScore + roundScore,
      );
    }).toList();

    state = state.copyWith(
      players: updatedPlayers,
      accusedPlayerId: accusedPlayerId,
      isGuessCorrect: isCorrect,
      stage: PassAndPlayStage.roundResults,
    );
  }

  /// Advances to the next round or finishes match.
  void nextRound() {
    if (state.isLastRound) {
      state = state.copyWith(stage: PassAndPlayStage.matchOver);
    } else {
      state = state.copyWith(currentRound: state.currentRound + 1);
      _assignRolesAndStartRound();
    }
  }

  /// Restart match with same players.
  void restartMatch() {
    final resetPlayers = state.players.map((p) {
      return p.copyWith(totalScore: 0, roundScore: 0);
    }).toList();

    state = state.copyWith(
      players: resetPlayers,
      currentRound: 1,
      stage: PassAndPlayStage.passToPlayer,
    );

    _assignRolesAndStartRound();
  }
}

/// Riverpod provider for Pass & Play state.
final passAndPlayViewModelProvider =
    StateNotifierProvider<PassAndPlayViewModel, PassAndPlayState>((ref) {
  return PassAndPlayViewModel();
});
