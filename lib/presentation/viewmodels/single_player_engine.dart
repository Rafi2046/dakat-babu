import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio.dart';
import '../../domain/game/game_engine.dart';
import '../../domain/game/game_role.dart';
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

  /// Which of the 4 mystery slots the human tapped (0–3).
  final int? selectedCardIndex;

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
  });

  bool get humanIsPolice =>
      assignment != null && assignment!.policePlayerId == humanId;

  bool get cardsLocked =>
      selectedCardIndex != null ||
      (phase != SinglePlayerPhase.pickCard &&
          phase != SinglePlayerPhase.pickRole);

  /// Winner role for [RoundResultOverlay] (police catch vs chor escape).
  GameRole? get resultWinner {
    final r = result;
    if (r == null) return null;
    return r.isCorrect ? GameRole.police : GameRole.chor;
  }

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
    bool clearResult = false,
    bool clearSelection = false,
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
      selectedCardIndex: clearSelection
          ? null
          : (selectedCardIndex ?? this.selectedCardIndex),
    );
  }
}

/// Offline Vs Computer engine — classic mystery draw + practice role pick.
class SinglePlayerEngine extends Notifier<SinglePlayerState> {
  Random _rng = Random();

  static const humanId = 'human';
  static const botIds = ['bot_1', 'bot_2', 'bot_3'];
  static const botNames = ['Bot Rafi', 'Bot Sami', 'Bot Tanvir'];

  @override
  SinglePlayerState build() {
    return _idle('You', classic: true);
  }

  SinglePlayerState _idle(String name, {required bool classic}) {
    final players = [
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
      statusMessage: classic
          ? 'আপনার কার্ড বেছে নিন'
          : 'তোমার রোল কার্ড বেছে নাও',
    );
  }

  /// Begin / reset a classic mystery-card match.
  void startMatch({required String humanName, Random? seed}) {
    _rng = seed ?? Random();
    state = _idle(
      humanName.trim().isEmpty ? 'You' : humanName.trim(),
      classic: true,
    );
  }

  /// Begin / reset practice mode (choose exact role).
  void startPracticeMatch({required String humanName, Random? seed}) {
    _rng = seed ?? Random();
    state = _idle(
      humanName.trim().isEmpty ? 'You' : humanName.trim(),
      classic: false,
    );
  }

  /// Classic: tap any face-down card → shuffle roles, reveal user's draw.
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

    // Let the 3D flip + haptic settle.
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (state.phase != SinglePlayerPhase.revealing) return;

    await _afterReveal(assignment);
  }

  /// Practice: human picks an exact role; bots get the rest at random.
  Future<void> selectHumanRole(GameRole role) async {
    if (state.phase != SinglePlayerPhase.pickRole || state.busy) return;

    state = state.copyWith(
      phase: SinglePlayerPhase.revealing,
      humanRole: role,
      busy: true,
      statusMessage: 'বটরা কার্ড নিচ্ছে...',
    );

    final audio = ref.read(audioManagerProvider);
    final delayMs = 800 + _rng.nextInt(600);
    await Future<void>.delayed(Duration(milliseconds: delayMs));
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

    final audio = ref.read(audioManagerProvider);
    await audio.play(AudioEvent.buttonTap);

    // Bot police may only accuse the 3 non-police seats (bots + human if not police).
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

  /// Human Police taps a bot suspect.
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

  void playAgainPractice() {
    startPracticeMatch(humanName: state.humanName);
  }
}

final singlePlayerEngineProvider =
    NotifierProvider<SinglePlayerEngine, SinglePlayerState>(
  SinglePlayerEngine.new,
);
