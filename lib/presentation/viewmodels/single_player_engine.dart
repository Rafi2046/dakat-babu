import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio.dart';
import '../../domain/game/game_engine.dart';
import '../../domain/game/game_role.dart';
import '../../domain/game/player_view.dart';
import 'robot_match_viewmodel.dart';

/// Lifecycle phases for offline vs-bots match.
enum SinglePlayerPhase {
  /// Human picks their role card first.
  pickRole,

  /// Bots are "thinking" / selecting remaining roles.
  botsThinking,

  /// Roles assigned; waiting for Police guess.
  awaitingGuess,

  /// Guess resolved — show winner.
  result,
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
  });

  bool get humanIsPolice =>
      assignment != null && assignment!.policePlayerId == humanId;

  SinglePlayerState copyWith({
    SinglePlayerPhase? phase,
    List<EnginePlayer>? players,
    GameRole? humanRole,
    RoleAssignment? assignment,
    PlayerView? view,
    GuessResult? result,
    String? statusMessage,
    bool? busy,
    bool clearResult = false,
  }) {
    return SinglePlayerState(
      phase: phase ?? this.phase,
      humanId: humanId,
      humanName: humanName,
      players: players ?? this.players,
      humanRole: humanRole ?? this.humanRole,
      assignment: assignment ?? this.assignment,
      view: view ?? this.view,
      result: clearResult ? null : (result ?? this.result),
      statusMessage: statusMessage ?? this.statusMessage,
      busy: busy ?? this.busy,
    );
  }
}

/// Offline Vs Computer engine: human picks a role card, bots get the rest.
class SinglePlayerEngine extends Notifier<SinglePlayerState> {
  Random _rng = Random();

  static const humanId = 'human';
  static const botIds = ['bot_1', 'bot_2', 'bot_3'];
  static const botNames = ['Bot Rafi', 'Bot Sami', 'Bot Tanvir'];

  @override
  SinglePlayerState build() {
    return _idle('You');
  }

  SinglePlayerState _idle(String name) {
    final players = [
      EnginePlayer(id: humanId, name: name),
      for (var i = 0; i < 3; i++)
        EnginePlayer(id: botIds[i], name: botNames[i]),
    ];
    return SinglePlayerState(
      phase: SinglePlayerPhase.pickRole,
      humanId: humanId,
      humanName: name,
      players: players,
      statusMessage: 'তোমার রোল কার্ড বেছে নাও',
    );
  }

  /// Begin / reset a match. Optional [seed] for tests.
  void startMatch({required String humanName, Random? seed}) {
    _rng = seed ?? Random();
    state = _idle(humanName.trim().isEmpty ? 'You' : humanName.trim());
  }

  /// Human selects their role first; remaining three go to bots after suspense.
  Future<void> selectHumanRole(GameRole role) async {
    if (state.phase != SinglePlayerPhase.pickRole || state.busy) return;

    state = state.copyWith(
      phase: SinglePlayerPhase.botsThinking,
      humanRole: role,
      busy: true,
      statusMessage: 'বটরা কার্ড নিচ্ছে...',
    );

    final audio = ref.read(audioManagerProvider);
    // Suspense: 1–2s with tactile clicks.
    final delayMs = 1000 + _rng.nextInt(1000);
    final ticks = 3 + _rng.nextInt(2);
    final step = delayMs ~/ ticks;
    for (var i = 0; i < ticks; i++) {
      await Future<void>.delayed(Duration(milliseconds: step));
      await audio.play(AudioEvent.cardTap);
    }

    final remaining = List<GameRole>.from(GameRole.values)..remove(role);
    remaining.shuffle(_rng);

    final byId = <String, GameRole>{
      humanId: role,
      for (var i = 0; i < botIds.length; i++) botIds[i]: remaining[i],
    };

    String idFor(GameRole r) =>
        byId.entries.firstWhere((e) => e.value == r).key;

    final assignment = RoleAssignment(
      policePlayerId: idFor(GameRole.police),
      babuPlayerId: idFor(GameRole.babu),
      chorPlayerId: idFor(GameRole.chor),
      dakatPlayerId: idFor(GameRole.dakat),
    );

    final view = GameEngine.buildPlayerView(
      viewerId: humanId,
      players: state.players,
      assignment: assignment,
    );

    await audio.play(AudioEvent.roleCardFlip);

    state = state.copyWith(
      phase: SinglePlayerPhase.awaitingGuess,
      assignment: assignment,
      view: view,
      busy: false,
      statusMessage: assignment.policePlayerId == humanId
          ? 'তুমি পুলিশ — চোরকে খুঁজে বের করো'
          : 'পুলিশ বট চিন্তা করছে...',
    );

    // If a bot is Police, auto-guess after another suspense beat.
    if (assignment.policePlayerId != humanId) {
      await _botPoliceGuess();
    }
  }

  Future<void> _botPoliceGuess() async {
    if (state.assignment == null) return;
    state = state.copyWith(busy: true, statusMessage: 'পুলিশ বট সিলেক্ট করছে...');

    final audio = ref.read(audioManagerProvider);
    await Future<void>.delayed(Duration(milliseconds: 1200 + _rng.nextInt(600)));
    await audio.play(AudioEvent.buttonTap);

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

  /// Human Police picks a suspect.
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
          policeTag: result.isCorrect,
        );

    final winnerName = updated
        .firstWhere((p) => p.id == result.scoreRecipientId)
        .name;

    state = state.copyWith(
      phase: SinglePlayerPhase.result,
      players: updated,
      result: result,
      busy: false,
      statusMessage: result.isCorrect
          ? 'পুলিশ জিতেছে! +1 → $winnerName'
          : 'চোর পালিয়ে গেছে! +1 → $winnerName',
    );
  }

  void playAgain() {
    startMatch(humanName: state.humanName);
  }
}

final singlePlayerEngineProvider =
    NotifierProvider<SinglePlayerEngine, SinglePlayerState>(
  SinglePlayerEngine.new,
);
