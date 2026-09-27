import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/game/game_engine.dart';
import '../../domain/game/game_phase.dart';
import '../../domain/game/player_view.dart';

/// Single player in Pass & Pass mode.
class PassAndPlayPlayer {
  final String id;
  final String name;
  final GameRole? role;
  final int totalScore;
  final int roundScore;
  final int correctGuesses;
  final int policeTags;

  const PassAndPlayPlayer({
    required this.id,
    required this.name,
    this.role,
    this.totalScore = 0,
    this.roundScore = 0,
    this.correctGuesses = 0,
    this.policeTags = 0,
  });

  PassAndPlayPlayer copyWith({
    String? id,
    String? name,
    GameRole? role,
    int? totalScore,
    int? roundScore,
    int? correctGuesses,
    int? policeTags,
    bool clearRole = false,
  }) {
    return PassAndPlayPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      // Prefer explicit [role] when provided so reshuffles never stick.
      role: clearRole ? null : (role != null ? role : this.role),
      totalScore: totalScore ?? this.totalScore,
      roundScore: roundScore ?? this.roundScore,
      correctGuesses: correctGuesses ?? this.correctGuesses,
      policeTags: policeTags ?? this.policeTags,
    );
  }

  EnginePlayer toEngine() => EnginePlayer(
        id: id,
        name: name,
        score: totalScore,
        correctGuesses: correctGuesses,
        policeTags: policeTags,
      );
}

/// Stages of a Pass & Pass local round (maps onto [GamePhase]).
enum PassAndPlayStage {
  passToPlayer,
  peekRole,
  handToPolice,
  policeAccusing,
  confirmSuspect,
  roundResults,
  matchOver,
}

/// State of the Pass & Pass match.
class PassAndPlayState {
  final List<PassAndPlayPlayer> players;
  final int currentRound;
  final int totalRounds;
  final int currentPeekIndex;
  final bool isCardRevealed;
  final PassAndPlayStage stage;
  final String? accusedPlayerId;
  final bool? isGuessCorrect;
  final RoleAssignment? assignment;
  final String? gameLeadId;
  final String? previousPoliceId;
  final GamePhase phase;

  const PassAndPlayState({
    this.players = const [],
    this.currentRound = 1,
    this.totalRounds = 5,
    this.currentPeekIndex = 0,
    this.isCardRevealed = false,
    this.stage = PassAndPlayStage.passToPlayer,
    this.accusedPlayerId,
    this.isGuessCorrect,
    this.assignment,
    this.gameLeadId,
    this.previousPoliceId,
    this.phase = GamePhase.roleDistribution,
  });

  PassAndPlayPlayer? get currentPeekingPlayer {
    if (players.isEmpty || currentPeekIndex >= players.length) return null;
    return players[currentPeekIndex];
  }

  PassAndPlayPlayer? get policePlayer {
    final id = assignment?.policePlayerId;
    if (id == null) return null;
    return players.cast<PassAndPlayPlayer?>().firstWhere(
          (p) => p?.id == id,
          orElse: () => null,
        );
  }

  PassAndPlayPlayer? get babuPlayer {
    final id = assignment?.babuPlayerId;
    if (id == null) return null;
    return players.cast<PassAndPlayPlayer?>().firstWhere(
          (p) => p?.id == id,
          orElse: () => null,
        );
  }

  PassAndPlayPlayer? get chorPlayer {
    final id = assignment?.chorPlayerId;
    if (id == null) return null;
    return players.cast<PassAndPlayPlayer?>().firstWhere(
          (p) => p?.id == id,
          orElse: () => null,
        );
  }

  PassAndPlayPlayer? get accusedPlayer {
    return players.cast<PassAndPlayPlayer?>().firstWhere(
          (p) => p?.id == accusedPlayerId,
          orElse: () => null,
        );
  }

  /// Suspects for Police = everyone except Police.
  List<PassAndPlayPlayer> get suspects {
    final policeId = assignment?.policePlayerId;
    return players.where((p) => p.id != policeId).toList();
  }

  /// Privacy view for the Police during accusation.
  PlayerView? get policeView {
    final a = assignment;
    if (a == null) return null;
    return GameEngine.buildPlayerView(
      viewerId: a.policePlayerId,
      players: players.map((p) => p.toEngine()).toList(),
      assignment: a,
    );
  }

  List<PassAndPlayPlayer> get leaderboard {
    final list = List<PassAndPlayPlayer>.from(players);
    list.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return list;
  }

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
    RoleAssignment? assignment,
    String? gameLeadId,
    String? previousPoliceId,
    GamePhase? phase,
    bool clearAccusation = false,
  }) {
    return PassAndPlayState(
      players: players ?? this.players,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      currentPeekIndex: currentPeekIndex ?? this.currentPeekIndex,
      isCardRevealed: isCardRevealed ?? this.isCardRevealed,
      stage: stage ?? this.stage,
      accusedPlayerId:
          clearAccusation ? null : (accusedPlayerId ?? this.accusedPlayerId),
      isGuessCorrect:
          clearAccusation ? null : (isGuessCorrect ?? this.isGuessCorrect),
      assignment: assignment ?? this.assignment,
      gameLeadId: gameLeadId ?? this.gameLeadId,
      previousPoliceId: previousPoliceId ?? this.previousPoliceId,
      phase: phase ?? this.phase,
    );
  }
}

/// ViewModel coordinating Pass & Pass using [GameEngine].
class PassAndPlayViewModel extends StateNotifier<PassAndPlayState> {
  PassAndPlayViewModel({Ref? ref, Random? random})
      : _ref = ref,
        super(const PassAndPlayState()) {
    if (random != null) {
      _testRandom = random;
    }
  }

  final Ref? _ref;
  Random? _testRandom;

  AudioManager? get _audio {
    final ref = _ref;
    if (ref == null) return null;
    return ref.read(audioManagerProvider);
  }

  void initMatch({
    required List<String> playerNames,
    int totalRounds = AppConstants.defaultTotalRounds,
  }) {
    if (playerNames.length != GameEngine.requiredPlayers) {
      throw ArgumentError(
        'Pass & Pass requires exactly ${GameEngine.requiredPlayers} players',
      );
    }

    final players = List.generate(
      playerNames.length,
      (i) => PassAndPlayPlayer(
        id: 'p_${i + 1}',
        name: playerNames[i].trim().isEmpty
            ? 'Player ${i + 1}'
            : playerNames[i].trim(),
      ),
    );

    state = PassAndPlayState(
      players: players,
      currentRound: 1,
      totalRounds: totalRounds,
      gameLeadId: players.first.id,
      stage: PassAndPlayStage.passToPlayer,
      phase: GamePhase.roleDistribution,
    );

    _assignRolesAndStartRound();
  }

  void _assignRolesAndStartRound() {
    final enginePlayers = state.players.map((p) => p.toEngine()).toList();
    final Random rng;
    final injected = _testRandom;
    if (injected != null) {
      rng = injected;
    } else {
      // Fresh entropy every deal so consecutive rounds never repeat a stream.
      rng = Random(
        DateTime.now().microsecondsSinceEpoch ^
            (state.currentRound * 0x9E3779B9) ^
            identityHashCode(state.players.map((p) => p.id).join()),
      );
    }
    final assignment = GameEngine.assignRoles(
      enginePlayers,
      random: rng,
    );

    final updatedPlayers = state.players.map((p) {
      final dealt = assignment.roleOf(p.id);
      if (dealt == null) {
        throw StateError('No role dealt for player ${p.id}');
      }
      return p.copyWith(
        role: dealt,
        roundScore: 0,
      );
    }).toList();

    state = state.copyWith(
      players: updatedPlayers,
      assignment: assignment,
      currentPeekIndex: 0,
      isCardRevealed: false,
      stage: PassAndPlayStage.passToPlayer,
      phase: GamePhase.roleReveal,
      clearAccusation: true,
    );
  }

  void readyToPeek() {
    // Privacy: ensure card starts face-down when phone is passed.
    state = state.copyWith(
      stage: PassAndPlayStage.peekRole,
      isCardRevealed: false,
      phase: GamePhase.roleReveal,
    );
  }

  void toggleCardReveal() {
    final willReveal = !state.isCardRevealed;
    state = state.copyWith(isCardRevealed: !state.isCardRevealed);
    if (willReveal) {
      final role = state.currentPeekingPlayer?.role;
      if (role != null) {
        // Fire-and-forget role sting; police also gets whistle.
        _audio?.playRoleRevealSequence(role);
      }
    }
  }

  void finishPeekingCurrentPlayer() {
    // Clear reveal before advancing — privacy handoff.
    final nextIndex = state.currentPeekIndex + 1;
    if (nextIndex < state.players.length) {
      state = state.copyWith(
        currentPeekIndex: nextIndex,
        isCardRevealed: false,
        stage: PassAndPlayStage.passToPlayer,
      );
    } else {
      state = state.copyWith(
        isCardRevealed: false,
        stage: PassAndPlayStage.handToPolice,
        phase: GamePhase.policeTurn,
      );
      // Police arrives — whistle.
      _audio?.playPoliceArrive();
    }
  }

  void beginPoliceInterrogation() {
    state = state.copyWith(
      stage: PassAndPlayStage.policeAccusing,
      phase: GamePhase.suspectSelection,
      accusedPlayerId: null,
    );
    _audio?.playPoliceArrive();
  }

  void selectSuspect(String accusedPlayerId) {
    state = state.copyWith(
      accusedPlayerId: accusedPlayerId,
      stage: PassAndPlayStage.confirmSuspect,
      phase: GamePhase.guessConfirmation,
    );
  }

  void cancelSuspect() {
    state = state.copyWith(
      clearAccusation: true,
      stage: PassAndPlayStage.policeAccusing,
      phase: GamePhase.suspectSelection,
    );
  }

  void confirmAccusation() {
    final suspectId = state.accusedPlayerId;
    final assignment = state.assignment;
    if (suspectId == null || assignment == null) return;

    final enginePlayers = state.players.map((p) => p.toEngine()).toList();
    final result = GameEngine.resolveGuess(
      players: enginePlayers,
      assignment: assignment,
      suspectPlayerId: suspectId,
    );
    final applied = GameEngine.applyGuessResult(enginePlayers, result);

    final updatedPlayers = <PassAndPlayPlayer>[];
    for (var i = 0; i < state.players.length; i++) {
      final before = state.players[i];
      final after = applied[i];
      final delta = after.score - before.totalScore;
      updatedPlayers.add(
        before.copyWith(
          totalScore: after.score,
          roundScore: delta,
          correctGuesses: after.correctGuesses,
          policeTags: after.policeTags,
        ),
      );
    }

    state = state.copyWith(
      players: updatedPlayers,
      accusedPlayerId: suspectId,
      isGuessCorrect: result.isCorrect,
      stage: PassAndPlayStage.roundResults,
      phase: GamePhase.result,
      previousPoliceId: assignment.policePlayerId,
    );
  }

  /// Legacy alias used by older UI.
  void makeAccusation(String accusedPlayerId) {
    selectSuspect(accusedPlayerId);
    confirmAccusation();
  }

  void nextRound() {
    if (state.isLastRound) {
      state = state.copyWith(
        stage: PassAndPlayStage.matchOver,
        phase: GamePhase.finalScore,
      );
    } else {
      state = state.copyWith(
        currentRound: state.currentRound + 1,
        phase: GamePhase.nextRound,
      );
      _assignRolesAndStartRound();
    }
  }

  void restartMatch() {
    final resetPlayers = state.players
        .map(
          (p) => p.copyWith(
            totalScore: 0,
            roundScore: 0,
            correctGuesses: 0,
            policeTags: 0,
          ),
        )
        .toList();

    state = state.copyWith(
      players: resetPlayers,
      currentRound: 1,
      previousPoliceId: null,
      stage: PassAndPlayStage.passToPlayer,
      phase: GamePhase.roleDistribution,
    );
    _assignRolesAndStartRound();
  }
}

final passAndPlayViewModelProvider =
    StateNotifierProvider<PassAndPlayViewModel, PassAndPlayState>((ref) {
  return PassAndPlayViewModel(ref: ref);
});
