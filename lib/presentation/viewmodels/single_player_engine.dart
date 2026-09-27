import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/game/game_engine.dart';
import '../../domain/game/player_view.dart';
import 'robot_match_viewmodel.dart';

/// Lifecycle phases for offline vs-bots match.
enum SinglePlayerPhase {
  /// Classic: 4 face-down mystery cards — tap any to draw a random role.
  pickCard,

  /// Practice: user deliberately picks an exact role.
  pickRole,

  /// User's mystery card is flipping / just revealed.
  revealing,

  /// A bot is Police — searching for Chor.
  policeSearching,

  /// Human is Police — pick a bot suspect.
  awaitingGuess,

  /// Guess resolved — show [RoundResultOverlay].
  result,

  /// All configured rounds finished.
  matchOver,
}

class SinglePlayerState {
  final SinglePlayerPhase phase;
  final String humanId;
  final String humanName;
  final List<EnginePlayer> players;
  final GameRole? humanRole;
  final RoleAssignment? assignment;
  final PlayerView? view;
  final GuessResult? result;
  final String? statusMessage;
  final bool busy;
  final int? selectedCardIndex;
  final int currentRound;
  final int totalRounds;

  const SinglePlayerState({
    required this.phase,
    required this.humanId,
    required this.humanName,
    required this.players,
    this.humanRole,
    this.assignment,
    this.view,
    this.result,
    this.statusMessage,
    this.busy = false,
    this.selectedCardIndex,
    this.currentRound = 1,
    this.totalRounds = AppConstants.defaultTotalRounds,
  });

  bool get humanIsPolice =>
      assignment != null && assignment!.policePlayerId == humanId;

  bool get isLastRound => currentRound >= totalRounds;

  bool get cardsLocked =>
      selectedCardIndex != null ||
      (phase != SinglePlayerPhase.pickCard &&
          phase != SinglePlayerPhase.pickRole);

  String get stageLabel {
    switch (phase) {
      case SinglePlayerPhase.pickCard:
      case SinglePlayerPhase.pickRole:
        return 'Role Draw';
      case SinglePlayerPhase.revealing:
        return 'Reveal';
      case SinglePlayerPhase.policeSearching:
        return 'Police Thinking';
      case SinglePlayerPhase.awaitingGuess:
        return 'Accusation';
      case SinglePlayerPhase.result:
        return 'Round Result';
      case SinglePlayerPhase.matchOver:
        return 'Match Over';
    }
  }

  GameRole? get resultWinner {
    final r = result;
    if (r == null) return null;
    return r.isCorrect ? GameRole.police : GameRole.chor;
  }

  /// Players sorted by score for the live scoreboard.
  List<EnginePlayer> get rankedPlayers {
    final list = List<EnginePlayer>.from(players);
    list.sort((a, b) => b.score.compareTo(a.score));
    return list;
  }

  GameRole? roleOf(String playerId) => assignment?.roleOf(playerId);

  SinglePlayerState copyWith({
    SinglePlayerPhase? phase,
    List<EnginePlayer>? players,
    GameRole? humanRole,
    RoleAssignment? assignment,
    PlayerView? view,
    GuessResult? result,
    String? statusMessage,
    bool? busy,
    int? selectedCardIndex,
    int? currentRound,
    int? totalRounds,
    bool clearResult = false,
    bool clearSelection = false,
    bool clearAssignment = false,
  }) {
    return SinglePlayerState(
      phase: phase ?? this.phase,
      humanId: humanId,
      humanName: humanName,
      players: players ?? this.players,
      humanRole: clearAssignment ? null : (humanRole ?? this.humanRole),
      assignment: clearAssignment ? null : (assignment ?? this.assignment),
      view: clearAssignment ? null : (view ?? this.view),
      result: clearResult ? null : (result ?? this.result),
      statusMessage: statusMessage ?? this.statusMessage,
      busy: busy ?? this.busy,
      selectedCardIndex: clearSelection
          ? null
          : (selectedCardIndex ?? this.selectedCardIndex),
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
    );
  }
}

/// Offline Vs Computer engine — classic mystery draw + multi-round scoring.
class SinglePlayerEngine extends Notifier<SinglePlayerState> {
  Random _rng = Random();

  static const humanId = 'human';
  static const botIds = ['bot_1', 'bot_2', 'bot_3'];
  static const botNames = ['Bot Rafi', 'Bot Sami', 'Bot Tanvir'];

  @override
  SinglePlayerState build() {
    return _idle('You', classic: true, totalRounds: AppConstants.defaultTotalRounds);
  }

  SinglePlayerState _idle(
    String name, {
    required bool classic,
    required int totalRounds,
    List<EnginePlayer>? keepScores,
    int currentRound = 1,
  }) {
    final players = keepScores ??
        [
          EnginePlayer(id: humanId, name: name),
          for (var i = 0; i < 3; i++)
            EnginePlayer(id: botIds[i], name: botNames[i]),
        ];
    return SinglePlayerState(
      phase: classic
          ? SinglePlayerPhase.pickCard
          : SinglePlayerPhase.pickRole,
      humanId: humanId,
      humanName: name,
      players: players,
      currentRound: currentRound,
      totalRounds: totalRounds.clamp(1, 15),
      statusMessage: classic
          ? 'আপনার কার্ড বেছে নিন'
          : 'তোমার রোল কার্ড বেছে নাও',
    );
  }

  /// Begin / reset a classic mystery-card match.
  void startMatch({
    required String humanName,
    int totalRounds = AppConstants.defaultTotalRounds,
    Random? seed,
  }) {
    _rng = seed ?? Random();
    state = _idle(
      humanName.trim().isEmpty ? 'You' : humanName.trim(),
      classic: true,
      totalRounds: totalRounds,
    );
  }

  void startPracticeMatch({
    required String humanName,
    int totalRounds = AppConstants.defaultTotalRounds,
    Random? seed,
  }) {
    _rng = seed ?? Random();
    state = _idle(
      humanName.trim().isEmpty ? 'You' : humanName.trim(),
      classic: false,
      totalRounds: totalRounds,
    );
  }

  Future<void> pickMysteryCard(int cardIndex) async {
    if (state.phase != SinglePlayerPhase.pickCard || state.busy) return;
    if (cardIndex < 0 || cardIndex > 3) return;

    final deck = List<GameRole>.from(GameRole.values)..shuffle(_rng);
    final humanRole = deck.removeAt(0);

    final byId = <String, GameRole>{
      humanId: humanRole,
      for (var i = 0; i < botIds.length; i++) botIds[i]: deck[i],
    };
    final assignment = _assignmentFrom(byId);
    final view = GameEngine.buildPlayerView(
      viewerId: humanId,
      players: state.players,
      assignment: assignment,
    );

    state = state.copyWith(
      phase: SinglePlayerPhase.revealing,
      selectedCardIndex: cardIndex,
      humanRole: humanRole,
      assignment: assignment,
      view: view,
      busy: true,
      statusMessage: 'তোমার রোল: ${humanRole.label}',
    );

    await ref.read(audioManagerProvider).play(AudioEvent.roleCardFlip);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (state.phase != SinglePlayerPhase.revealing) return;

    await _afterReveal(assignment);
  }

  Future<void> selectHumanRole(GameRole role) async {
    if (state.phase != SinglePlayerPhase.pickRole || state.busy) return;

    state = state.copyWith(
      phase: SinglePlayerPhase.revealing,
      humanRole: role,
      busy: true,
      statusMessage: 'বটরা কার্ড নিচ্ছে...',
    );

    final audio = ref.read(audioManagerProvider);
    await Future<void>.delayed(Duration(milliseconds: 800 + _rng.nextInt(600)));
    await audio.play(AudioEvent.cardTap);

    final remaining = List<GameRole>.from(GameRole.values)..remove(role);
    remaining.shuffle(_rng);

    final byId = <String, GameRole>{
      humanId: role,
      for (var i = 0; i < botIds.length; i++) botIds[i]: remaining[i],
    };
    final assignment = _assignmentFrom(byId);
    final view = GameEngine.buildPlayerView(
      viewerId: humanId,
      players: state.players,
      assignment: assignment,
    );

    state = state.copyWith(
      assignment: assignment,
      view: view,
      statusMessage: 'তোমার রোল: ${role.label}',
    );

    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (state.phase != SinglePlayerPhase.revealing) return;

    await _afterReveal(assignment);
  }

  Future<void> _afterReveal(RoleAssignment assignment) async {
    if (assignment.policePlayerId == humanId) {
      await ref.read(audioManagerProvider).playPoliceArrive();
      state = state.copyWith(
        phase: SinglePlayerPhase.awaitingGuess,
        busy: false,
        statusMessage: 'তুমি পুলিশ — চোরকে খুঁজে বের করো',
      );
      return;
    }

    state = state.copyWith(
      phase: SinglePlayerPhase.policeSearching,
      busy: true,
      statusMessage: 'পুলিশ চোর খুঁজছে...',
    );
    await ref.read(audioManagerProvider).playPoliceArrive();
    await Future<void>.delayed(const Duration(seconds: 2));
    if (state.phase != SinglePlayerPhase.policeSearching) return;
    await _botPoliceGuess();
  }

  RoleAssignment _assignmentFrom(Map<String, GameRole> byId) {
    String idFor(GameRole r) =>
        byId.entries.firstWhere((e) => e.value == r).key;
    return RoleAssignment(
      policePlayerId: idFor(GameRole.police),
      babuPlayerId: idFor(GameRole.babu),
      chorPlayerId: idFor(GameRole.chor),
      dakatPlayerId: idFor(GameRole.dakat),
    );
  }

  Future<void> _botPoliceGuess() async {
    if (state.assignment == null) return;
    state = state.copyWith(busy: true, statusMessage: 'পুলিশ চোর খুঁজছে...');

    await ref.read(audioManagerProvider).play(AudioEvent.buttonTap);

    final suspects = state.players
        .where((p) => p.id != state.assignment!.policePlayerId)
        .map((p) => p.id)
        .toList();
    final difficulty = ref.read(robotDifficultyProvider);
    final suspectId = RobotMatchViewModel.pickSuspect(
      suspectIds: suspects,
      difficulty: difficulty,
      random: _rng,
    );

    await _resolve(suspectId);
  }

  Future<void> submitHumanGuess(String suspectPlayerId) async {
    if (state.phase != SinglePlayerPhase.awaitingGuess ||
        !state.humanIsPolice ||
        state.busy) {
      return;
    }
    state = state.copyWith(busy: true);
    await ref.read(audioManagerProvider).play(AudioEvent.confirmGuess);
    await _resolve(suspectPlayerId);
  }

  Future<void> _resolve(String suspectPlayerId) async {
    final assignment = state.assignment!;
    final result = GameEngine.resolveGuess(
      players: state.players,
      assignment: assignment,
      suspectPlayerId: suspectPlayerId,
    );
    final updated = GameEngine.applyGuessResult(state.players, result);

    await ref.read(audioManagerProvider).playGuessResultSequence(
          correct: result.isCorrect,
          policeTag: false,
        );

    state = state.copyWith(
      phase: SinglePlayerPhase.result,
      players: updated,
      result: result,
      busy: false,
      statusMessage: result.isCorrect
          ? 'পুলিশ জিতেছে! Police +${result.deltaFor(result.policePlayerId)}'
          : 'চোর পালিয়ে গেছে! Chor +${result.deltaFor(result.chorPlayerId)}',
    );
  }

  /// After result overlay — next round or match over.
  void continueAfterResult() {
    if (state.phase != SinglePlayerPhase.result) return;

    if (state.isLastRound) {
      final leader = state.rankedPlayers.first;
      state = state.copyWith(
        phase: SinglePlayerPhase.matchOver,
        statusMessage: 'ম্যাচ শেষ! বিজয়ী: ${leader.name} (${leader.score})',
        clearResult: true,
      );
      return;
    }

    state = _idle(
      state.humanName,
      classic: true,
      totalRounds: state.totalRounds,
      keepScores: state.players,
      currentRound: state.currentRound + 1,
    );
  }

  void playAgain() {
    startMatch(
      humanName: state.humanName,
      totalRounds: state.totalRounds,
    );
  }

  void playAgainPractice() {
    startPracticeMatch(
      humanName: state.humanName,
      totalRounds: state.totalRounds,
    );
  }
}

final singlePlayerEngineProvider =
    NotifierProvider<SinglePlayerEngine, SinglePlayerState>(
  SinglePlayerEngine.new,
);
